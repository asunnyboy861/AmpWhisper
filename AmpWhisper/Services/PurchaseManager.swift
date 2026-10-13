import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro: Bool = false
    @Published var hasBYOLifetime: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String?

    private let monthlyID = "com.zzoutuo.AmpWhisper.pro.monthly"
    private let yearlyID = "com.zzoutuo.AmpWhisper.pro.yearly"
    private let lifetimeID = "com.zzoutuo.AmpWhisper.byo.lifetime"
    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    var productIDs: [String] { [monthlyID, yearlyID, lifetimeID] }
    var monthlyProduct: Product? { products.first { $0.id == monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == yearlyID } }
    var lifetimeProduct: Product? { products.first { $0.id == lifetimeID } }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
                .sorted { sortWeight($0) < sortWeight($1) }
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    private func sortWeight(_ product: Product) -> Int {
        switch product.id {
        case monthlyID: return 0
        case yearlyID: return 1
        default: return 2
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkEntitlements()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func checkEntitlements() async {
        let monthly = await currentEntitlement(for: monthlyID)
        let yearly = await currentEntitlement(for: yearlyID)
        let lifetime = await currentEntitlement(for: lifetimeID)
        isPro = monthly || yearly
        hasBYOLifetime = lifetime
    }

    private func currentEntitlement(for productID: String) async -> Bool {
        guard let result = await Transaction.currentEntitlement(for: productID) else { return false }
        if case .verified(let transaction) = result {
            return transaction.revocationDate == nil
        }
        return false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkEntitlements()
                    }
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }
}
