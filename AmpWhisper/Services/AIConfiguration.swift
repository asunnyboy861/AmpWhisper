import Foundation

enum BYOProvider: String, Codable, CaseIterable, Identifiable {
    case glm, openai, anthropic, gemini, deepseek, custom
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glm: return "GLM (Z.ai)"
        case .openai: return "OpenAI"
        case .anthropic: return "Claude"
        case .gemini: return "Gemini"
        case .deepseek: return "DeepSeek"
        case .custom: return "Custom Endpoint"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .glm: return "https://api.z.ai/api/paas/v4"
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .deepseek: return "https://api.deepseek.com/v1"
        case .custom: return ""
        }
    }

    var defaultTextModel: String {
        switch self {
        case .glm: return "glm-4.6"
        case .openai: return "gpt-4o"
        case .anthropic: return "claude-sonnet-4-5"
        case .gemini: return "gemini-2.0-flash"
        case .deepseek: return "deepseek-chat"
        case .custom: return ""
        }
    }

    var defaultVisionModel: String? {
        switch self {
        case .glm: return "glm-4.6v"
        case .openai: return "gpt-4o"
        case .anthropic: return "claude-sonnet-4-5"
        case .gemini: return "gemini-2.0-flash"
        case .deepseek: return nil
        case .custom: return nil
        }
    }

    var usesAnthropicProtocol: Bool { self == .anthropic }
}

struct BYOProviderConfig: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var provider: BYOProvider
    var baseURL: String
    var textModel: String
    var visionModel: String?
    var enabled: Bool = false

    var keychainAccount: String { "byo-key-\(id.uuidString)" }

    static func makeDefault(provider: BYOProvider) -> BYOProviderConfig {
        BYOProviderConfig(
            provider: provider,
            baseURL: provider.defaultBaseURL,
            textModel: provider.defaultTextModel,
            visionModel: provider.defaultVisionModel
        )
    }
}

@MainActor
final class AIProfileManager: ObservableObject {
    static let shared = AIProfileManager()
    private let storageKey = "byoProviderConfigs"

    @Published var configs: [BYOProviderConfig] = []
    @Published var activeConfigID: UUID?

    private init() {
        load()
    }

    var activeConfig: BYOProviderConfig? {
        guard let id = activeConfigID else { return nil }
        return configs.first { $0.id == id && $0.enabled }
    }

    var hasVisionProvider: Bool {
        guard let config = activeConfig else { return false }
        return config.visionModel != nil && !(config.visionModel?.isEmpty ?? true)
    }

    func save(_ config: BYOProviderConfig, apiKey: String?) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
        } else {
            configs.append(config)
        }
        if let key = apiKey, !key.isEmpty {
            KeychainHelper.saveString(key, service: "AmpWhisper.BYO", account: config.keychainAccount)
        }
        persist()
    }

    func apiKey(for config: BYOProviderConfig) -> String? {
        KeychainHelper.readString(service: "AmpWhisper.BYO", account: config.keychainAccount)
    }

    func delete(_ config: BYOProviderConfig) {
        KeychainHelper.delete(service: "AmpWhisper.BYO", account: config.keychainAccount)
        configs.removeAll { $0.id == config.id }
        if activeConfigID == config.id { activeConfigID = nil }
        persist()
    }

    func setActive(_ config: BYOProviderConfig) {
        activeConfigID = config.id
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        configs = stored.configs
        activeConfigID = stored.activeID
    }

    private func persist() {
        let stored = Stored(configs: configs, activeID: activeConfigID)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private struct Stored: Codable {
        var configs: [BYOProviderConfig]
        var activeID: UUID?
    }
}
