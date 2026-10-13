import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var purchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    valueBanner
                    tierCards
                    if let error = purchaseManager.loadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    legalLinks
                    autoRenewalDisclosure
                }
                .padding()
            }
            .background(Color.tolex)
            .navigationTitle("AmpWhisper Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "guitars.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.amber)
            Text("Unlock AmpWhisper Pro")
                .font(.title.weight(.black))
                .foregroundStyle(Color.cream)
            Text("Feature-led, not usage-led — every plan includes the full tone engine.")
                .font(.caption)
                .foregroundStyle(Color.cream.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private var valueBanner: some View {
        HStack {
            Image(systemName: "gift.fill")
                .foregroundStyle(Color.amber)
            Text("One full match every day, free forever.")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.cream)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tolexCard))
    }

    private var tierCards: some View {
        VStack(spacing: 12) {
            if purchaseManager.products.isEmpty {
                if purchaseManager.isLoading {
                    ProgressView()
                        .tint(.amber)
                } else {
                    Text("Purchases are unavailable right now. Please try again later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let yearly = purchaseManager.yearlyProduct {
                tierCard(product: yearly, badge: "Best Value · 7-day free trial", highlight: true)
            }
            if let monthly = purchaseManager.monthlyProduct {
                tierCard(product: monthly, badge: "Flexible monthly", highlight: false)
            }
            if let lifetime = purchaseManager.lifetimeProduct {
                tierCard(product: lifetime, badge: "Bring your own API key", highlight: false)
            }
        }
    }

    private func tierCard(product: Product, badge: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(product.displayName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.cream)
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.weight(.black))
                    .foregroundStyle(Color.amber)
            }
            Text(badge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cream.opacity(0.65))
            Text(subtitle(for: product))
                .font(.caption)
                .foregroundStyle(Color.cream.opacity(0.55))
            Button {
                purchasing = true
                Task {
                    _ = await purchaseManager.purchase(product)
                    purchasing = false
                }
            } label: {
                if purchasing {
                    ProgressView().tint(.tolex)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                } else {
                    Text(product.id.contains("byo") ? "Buy Once" : "Subscribe")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.tolexCard))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlight ? Color.amber : Color.white.opacity(0.15), lineWidth: highlight ? 2 : 1))
    }

    private func subtitle(for product: Product) -> String {
        if product.id.contains("byo") {
            return "AI runs on your own provider key (GLM, OpenAI, Claude, Gemini, DeepSeek, or custom). No shared cloud quota."
        }
        if product.id.contains("yearly") {
            return "Unlimited ToneMatch, GearSnap model recognition, A/B preview, scene tiers, full Whisper Notes."
        }
        return "All Pro features, billed monthly. Cancel anytime."
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: AppConstants.paywallPrivacyURL)
            Link("Terms of Use", destination: AppConstants.paywallTermsURL)
        }
        .font(.caption2)
        .foregroundStyle(Color.amber)
    }

    private var autoRenewalDisclosure: some View {
        Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Settings.")
            .font(.caption2)
            .foregroundStyle(Color.cream.opacity(0.45))
            .multilineTextAlignment(.center)
    }
}

extension View {
    func manageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }
}
