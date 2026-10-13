import SwiftUI

struct BYOSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = AIProfileManager.shared
    @State private var editingConfig: BYOProviderConfig?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if profileManager.configs.isEmpty {
                        Text("No providers configured yet. Add one to unlock AI features on the BYO Lifetime plan.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(profileManager.configs) { config in
                        Button {
                            profileManager.setActive(config)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(config.provider.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(config.textModel.isEmpty ? "No model set" : config.textModel)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if profileManager.activeConfigID == config.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.amber)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            profileManager.delete(profileManager.configs[index])
                        }
                    }
                } header: {
                    Text("Your Providers")
                } footer: {
                    Text("Keys are stored in your Keychain and never leave your device except to call your chosen provider. Vision tasks (GearSnap) route only to providers with a vision model — if none has one, you'll see an explicit notice.")
                }

                Section {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add Provider", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.amber)
                    }
                }
            }
            .navigationTitle("BYO AI Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                providerSheet(nil)
            }
            .sheet(item: $editingConfig) { config in
                providerSheet(config)
            }
        }
    }

    private func providerSheet(_ existing: BYOProviderConfig?) -> some View {
        let initial = existing ?? BYOProviderConfig.makeDefault(provider: .glm)
        let existingKey = existing.flatMap { profileManager.apiKey(for: $0) } ?? ""
        return ProviderEditorView(config: initial, apiKey: existingKey) { updated, apiKey in
            profileManager.save(updated, apiKey: apiKey)
            if profileManager.activeConfigID == nil {
                profileManager.setActive(updated)
            }
        }
    }
}

private struct ProviderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var config: BYOProviderConfig
    @State var apiKey: String
    var onSave: (BYOProviderConfig, String?) -> Void
    @State private var testResult: String?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Type", selection: $config.provider) {
                        ForEach(BYOProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .onChange(of: config.provider) { _, newValue in
                        config.baseURL = newValue.defaultBaseURL
                        config.textModel = newValue.defaultTextModel
                        config.visionModel = newValue.defaultVisionModel
                    }
                    TextField("Base URL", text: $config.baseURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section("Models") {
                    TextField("Text model", text: $config.textModel)
                        .autocapitalization(.none)
                    TextField("Vision model (optional)", text: Binding(
                        get: { config.visionModel ?? "" },
                        set: { config.visionModel = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.none)
                }
                Section("API Key") {
                    SecureField("Paste your API key", text: $apiKey)
                }
                Section {
                    Button {
                        testConnection()
                    } label: {
                        if testing {
                            ProgressView()
                        } else {
                            Label("Test Connection", systemImage: "bolt.fill")
                        }
                    }
                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Connectivity")
                } footer: {
                    Text("The test sends one tiny completion and reports latency or the exact failure reason.")
                }
            }
            .navigationTitle(config.provider.displayName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(config, apiKey.isEmpty ? nil : apiKey)
                        dismiss()
                    }
                    .disabled(config.textModel.isEmpty || config.baseURL.isEmpty)
                }
            }
        }
    }

    private func testConnection() {
        testing = true
        testResult = nil
        let adapter = BYOAdapterFactory.adapter(for: config, apiKey: apiKey)
        let message = BYOChatMessage(role: "user", text: "Reply with OK", jpegData: nil)
        let start = Date()
        Task {
            do {
                _ = try await adapter.complete(messages: [message], maxTokens: 8, jsonMode: false)
                let ms = Int(Date().timeIntervalSince(start) * 1000)
                testResult = "Connected in \(ms) ms"
            } catch {
                testResult = "Failed: \(error.localizedDescription)"
            }
            testing = false
        }
    }
}
