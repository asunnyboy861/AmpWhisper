import Foundation

struct BYOChatMessage {
    var role: String
    var text: String
    var jpegData: Data?
}

enum BYOAdapterError: LocalizedError {
    case missingKey
    case badURL
    case http(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingKey: return "No API key stored for this provider."
        case .badURL: return "Base URL is missing or invalid."
        case .http(let code, let body): return "Provider returned \(code): \(body.prefix(120))"
        }
    }
}

protocol BYOAdapter {
    func complete(messages: [BYOChatMessage], maxTokens: Int, jsonMode: Bool) async throws -> String
}

struct OpenAICompatibleAdapter: BYOAdapter {
    var config: BYOProviderConfig
    var apiKey: String

    func complete(messages: [BYOChatMessage], maxTokens: Int, jsonMode: Bool) async throws -> String {
        guard !config.baseURL.isEmpty, let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw BYOAdapterError.badURL
        }
        guard !apiKey.isEmpty else { throw BYOAdapterError.missingKey }

        let messagePayloads: [[String: Any]] = messages.map { message in
            var content: [[String: Any]] = []
            if let jpeg = message.jpegData {
                content.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(jpeg.base64EncodedString())"]])
            }
            content.append(["type": "text", "text": message.text])
            return ["role": message.role, "content": content]
        }
        var payload: [String: Any] = [
            "model": config.textModel,
            "messages": messagePayloads,
            "max_tokens": maxTokens
        ]
        if jsonMode {
            payload["response_format"] = ["type": "json_object"]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BYOAdapterError.badURL }
        guard http.statusCode == 200 else { throw BYOAdapterError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "") }

        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { var content: String? }
                var message: Message
            }
            var choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}

struct AnthropicAdapter: BYOAdapter {
    var config: BYOProviderConfig
    var apiKey: String
    private let apiVersion = "2023-06-01"

    func complete(messages: [BYOChatMessage], maxTokens: Int, jsonMode: Bool) async throws -> String {
        guard !config.baseURL.isEmpty, let url = URL(string: "\(config.baseURL)/messages") else {
            throw BYOAdapterError.badURL
        }
        guard !apiKey.isEmpty else { throw BYOAdapterError.missingKey }

        let messagePayloads: [[String: Any]] = messages.map { message in
            var content: [[String: Any]] = []
            if let jpeg = message.jpegData {
                content.append([
                    "type": "image",
                    "source": ["type": "base64", "media_type": "image/jpeg", "data": jpeg.base64EncodedString()]
                ])
            }
            content.append(["type": "text", "text": message.text])
            let role = message.role == "assistant" ? "assistant" : "user"
            return ["role": role, "content": content]
        }
        let payload: [String: Any] = [
            "model": config.textModel,
            "max_tokens": maxTokens,
            "messages": messagePayloads
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BYOAdapterError.badURL }
        guard http.statusCode == 200 else { throw BYOAdapterError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "") }

        struct Response: Decodable {
            struct Block: Decodable { var text: String? }
            var content: [Block]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.content.compactMap(\.text).joined()
    }
}

enum BYOAdapterFactory {
    static func adapter(for config: BYOProviderConfig, apiKey: String) -> BYOAdapter {
        if config.provider.usesAnthropicProtocol {
            return AnthropicAdapter(config: config, apiKey: apiKey)
        }
        return OpenAICompatibleAdapter(config: config, apiKey: apiKey)
    }
}

struct BYOGearRecognitionService: GearRecognitionService {
    let engineName: String
    private var adapter: BYOAdapter
    private var visionModel: String

    init(config: BYOProviderConfig, apiKey: String) {
        self.engineName = "\(config.provider.displayName) Vision"
        self.adapter = BYOAdapterFactory.adapter(for: config, apiKey: apiKey)
        self.visionModel = config.visionModel ?? config.textModel
    }

    func recognize(jpegData: Data) async throws -> GearCandidates {
        let prompt = """
        Identify the guitar equipment in this photo (guitar headstock, amp panel, or pedalboard). \
        Return JSON: {"candidates":[{"brand":"...","model":"...","confidence":0.0}]} with up to 3 candidates, \
        confidence between 0 and 1. Brand and model must be real products.
        """
        let message = BYOChatMessage(role: "user", text: prompt, jpegData: jpegData)
        let raw = try await adapter.complete(messages: [message], maxTokens: 1024, jsonMode: true)
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(GearCandidates.self, from: data) else {
            throw AIError.networkFailure("unparseable response")
        }
        return GearCandidates(candidates: decoded.candidates, sourceEngine: engineName)
    }
}

@MainActor
enum AIRouter {
    static func recognitionService(
        purchase: PurchaseManager,
        quota: QuotaManager
    ) throws -> GearRecognitionService {
        if let config = AIProfileManager.shared.activeConfig, config.visionModel != nil, !(config.visionModel?.isEmpty ?? true) {
            if let key = AIProfileManager.shared.apiKey(for: config) {
                return BYOGearRecognitionService(config: config, apiKey: key)
            }
        }
        if purchase.isPro {
            return GLMService()
        }
        if quota.glmTrialAvailable {
            quota.consumeGLMTrial()
            return GLMService()
        }
        if quota.canRoughRecognize {
            quota.consumeFMRecognition()
            return VisionOCRService()
        }
        throw AIError.quotaExhausted
    }
}
