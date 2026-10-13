import Foundation
import Vision
import StoreKit

enum AIError: LocalizedError {
    case quotaExhausted
    case noVisionProvider
    case notConfigured
    case networkFailure(String)

    var errorDescription: String? {
        switch self {
        case .quotaExhausted:
            return "You've used today's free recognitions. Upgrade for unlimited GearSnap."
        case .noVisionProvider:
            return "Your active provider doesn't support vision. Pick a provider with a vision model."
        case .notConfigured:
            return "No AI provider configured."
        case .networkFailure(let detail):
            return "Connection failed: \(detail)"
        }
    }
}

protocol GearRecognitionService {
    var engineName: String { get }
    func recognize(jpegData: Data) async throws -> GearCandidates
}

struct GLMProxyProfile {
    var apiKey: String
    var endpointURL: String
    var model: String
}

enum GLMProxyConfig {
    static let appID = "ampwhisper"
    static let primaryURL = "https://cramjam-api.calcs.top"
    static let backupURL = "https://cramjam-api-backup.calcs.top"

    static func profiles() -> [GLMProxyProfile] {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.hasPrefix("#") && !$0.isEmpty }
            .compactMap { line in
                let parts = line.split(separator: "|").map(String.init)
                guard parts.count >= 2, !parts[0].isEmpty else { return nil }
                let endpoint = parts.count >= 3 ? parts[1] : primaryURL
                let model = parts.count >= 3 ? parts[2] : "glm-5.3-flash"
                return GLMProxyProfile(apiKey: parts[0], endpointURL: endpoint, model: model)
            }
    }
}

final class GLMService: GearRecognitionService {
    let engineName = "GLM-5.3-Flash"
    private let userID: String

    init() {
        if let stored = KeychainHelper.readString(service: "AmpWhisper.User", account: "userId") {
            userID = stored
        } else {
            let fresh = UUID().uuidString
            KeychainHelper.saveString(fresh, service: "AmpWhisper.User", account: "userId")
            userID = fresh
        }
    }

    private var jwsRepresentation: String? {
        get async {
            guard let result = await Transaction.currentEntitlement(for: "com.zzoutuo.AmpWhisper.pro.yearly") else { return nil }
            if case .verified = result { return result.jwsRepresentation }
            return nil
        }
    }

    func recognize(jpegData: Data) async throws -> GearCandidates {
        let prompt = """
        Identify the guitar equipment in this photo (guitar headstock, amp panel, or pedalboard). \
        Return JSON: {"candidates":[{"brand":"...","model":"...","confidence":0.0}]} with up to 3 candidates, \
        confidence between 0 and 1. Brand and model must be real products.
        """
        let body = try buildBody(prompt: prompt, jpegData: jpegData, maxTokens: 8192)
        let response = try await send(body: body)
        return try parseCandidates(response)
    }

    func generateRecipeJSON(song: String, artist: String) async throws -> String {
        let prompt = """
        Create a guitar tone recipe for the song "\(song)" by \(artist). \
        Return JSON: {"song":"...","artist":"...","baseKnobs":{"gain":0,"treble":0,"middle":0,"bass":0,"presence":0,"level":0}, \
        "guitarPickup":"singleCoil|humbucker|p90","ampFamily":"fenderClean|marshallMid|voxChime|highGainModern", \
        "cabBrightness":0.0,"pedalFamilies":["tubeScreamer"],"summary":"one sentence why"} \
        with knob values 0-10 integers. Reconstructed from public performances.
        """
        let body = try buildBody(prompt: prompt, jpegData: nil, maxTokens: 4096)
        let response = try await send(body: body)
        guard let content = response.choices.first?.message.content else {
            throw AIError.networkFailure("empty response")
        }
        return content
    }

    private func buildBody(prompt: String, jpegData: Data?, maxTokens: Int) throws -> [String: Any] {
        var content: [[String: Any]] = []
        if let jpegData = jpegData {
            content.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpegData.base64EncodedString())"]])
        }
        content.append(["type": "text", "text": prompt])
        return [
            "appId": GLMProxyConfig.appID,
            "userId": userID,
            "messages": [["role": "user", "content": content.isEmpty ? [["type": "text", "text": prompt]] : content]],
            "thinking": ["level": "low"],
            "max_tokens": maxTokens,
            "response_format": ["type": "json_object"]
        ]
    }

    private func send(body: [String: Any]) async throws -> GLMChatResponse {
        let profiles = GLMProxyConfig.profiles()
        var lastError = AIError.notConfigured

        for profile in profiles {
            let urls = [profile.endpointURL, GLMProxyConfig.backupURL]
            for urlString in urls {
                guard let url = URL(string: "\(urlString)/v1/chat/completions") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 60
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(profile.apiKey)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let http = response as? HTTPURLResponse else { continue }
                    if http.statusCode == 200 {
                        return try JSONDecoder().decode(GLMChatResponse.self, from: data)
                    } else if http.statusCode == 401 {
                        lastError = AIError.networkFailure("authorization rejected (\(http.statusCode))")
                        break
                    } else {
                        lastError = AIError.networkFailure("server returned \(http.statusCode)")
                    }
                } catch {
                    lastError = AIError.networkFailure(error.localizedDescription)
                }
            }
        }
        throw lastError
    }

    private func parseCandidates(_ response: GLMChatResponse) throws -> GearCandidates {
        guard let content = response.choices.first?.message.content,
              let contentData = content.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(GearCandidates.self, from: contentData) else {
            throw AIError.networkFailure("unparseable response")
        }
        return GearCandidates(candidates: decoded.candidates, sourceEngine: engineName)
    }
}

struct GLMChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            var content: String?
        }
        var message: Message
    }
    var choices: [Choice]
}

final class VisionOCRService: GearRecognitionService {
    let engineName = "Apple On-Device OCR"
    private let catalog = GearCatalog.shared

    func recognize(jpegData: Data) async throws -> GearCandidates {
        let tokens = try await OCRRunner.extractTextTokens(from: jpegData)
        let matches = catalog.fuzzyMatch(tokens: tokens)
        guard !matches.isEmpty else {
            return GearCandidates(candidates: [], sourceEngine: engineName)
        }
        let candidates = matches.enumerated().map { index, item in
            GearCandidates.Candidate(brand: item.brand, model: item.model, confidence: max(0.85 - Double(index) * 0.1, 0.5))
        }
        return GearCandidates(candidates: candidates, sourceEngine: engineName)
    }
}

enum OCRRunner {
    static func extractTextTokens(from jpegData: Data) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let words = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .flatMap { $0.split(separator: " ").map(String.init) }
                    .filter { $0.count >= 3 }
                continuation.resume(returning: Array(Set(words)).prefix(12).map { $0 })
            }
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(data: jpegData, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
