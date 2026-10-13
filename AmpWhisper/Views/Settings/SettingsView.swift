import SwiftUI
import StoreKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isPro: Bool = false
    private let purchaseManager = PurchaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        purchaseManager.$isPro
            .receive(on: RunLoop.main)
            .assign(to: &$isPro)
    }
}

import Combine

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var showContact = false
    @State private var showBYO = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                proSection
                pricingSection
                aiSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showContact) { ContactSupportView() }
            .sheet(isPresented: $showBYO) { BYOSettingsView() }
        }
    }

    private var proSection: some View {
        Section {
            if viewModel.isPro || purchaseManager.hasBYOLifetime {
                Label("Pro active — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color.amber)
                Button {
                    manageSubscriptions()
                } label: {
                    Label("Manage Subscription", systemImage: "calendar.badge.clock")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(Color.amber)
                }
            }
            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("AmpWhisper Pro")
        }
    }

    private var pricingSection: some View {
        Section {
            priceRow("Pro Monthly", "$9.99 / month", "Auto-renewing")
            priceRow("Pro Annual", "$49.99 / year", "7-day free trial")
            priceRow("BYO Lifetime", "$39.99 once", "Bring your own API key")
        } header: {
            Text("Pricing")
        } footer: {
            Text("Same prices as our website and the App Store. One full ToneMatch every day is free forever.")
        }
    }

    private func priceRow(_ name: String, _ price: String, _ note: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(price).font(.subheadline.weight(.bold)).foregroundStyle(Color.amber)
        }
    }

    private var aiSection: some View {
        Section {
            Button {
                showBYO = true
            } label: {
                Label("Configure Your Own AI Provider", systemImage: "key.fill")
            }
        } header: {
            Text("AI Configuration")
        } footer: {
            Text("GearSnap uses Apple on-device recognition on the free plan and a cloud vision model on Pro. BYO Lifetime users can connect their own GLM, OpenAI, Claude, Gemini, DeepSeek, or custom OpenAI-compatible provider. Keys are stored in your Keychain.")
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: AppConstants.supportURL) {
                Label("Support Page", systemImage: "lifepreserver")
            }
            Button {
                showContact = true
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
            Link(destination: AppConstants.paywallPrivacyURL) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: AppConstants.paywallTermsURL) {
                Label("Terms of Use (EULA)", systemImage: "doc.text")
            }
        } header: {
            Text("Support & Legal")
        }
    }

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Open-source acknowledgments")
                    .font(.subheadline.weight(.semibold))
                Text("Audio preview uses a built-in modeled approximation. Architecture inspired by open projects: NeuralAudio (MIT), NeuralAmpModelerPlugin (MIT). NAM capture community models are credited to their authors. Brand and model names appear only as compatibility descriptions under nominative fair use; no brand logos are used.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("A/B preview is a modeled approximation — final result depends on your real gear. Song tone data is reconstructed from public performance videos and interviews.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AmpWhisper")
                    .font(.subheadline.weight(.semibold))
                Text(appVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 he zhou")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
}
