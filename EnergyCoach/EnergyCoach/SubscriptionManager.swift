import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyProductID = "com.Matthew.EnergyCoach.pro.monthly"
    static let yearlyProductID = "com.Matthew.EnergyCoach.pro.yearly"
    static let productIDs = [monthlyProductID, yearlyProductID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await Product.products(for: Self.productIDs)
            products = loaded.sorted { lhs, rhs in
                if lhs.id == Self.yearlyProductID { return true }
                if rhs.id == Self.yearlyProductID { return false }
                return lhs.price < rhs.price
            }
        } catch {
            errorMessage = "Subscriptions are temporarily unavailable. Please try again later."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .pending:
                errorMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "The purchase could not be completed. Please try again."
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro {
                errorMessage = "No active Energy Coach Pro subscription was found."
            }
        } catch {
            errorMessage = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlements() async {
        var hasProEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  Self.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }

            hasProEntitlement = true
        }

        isPro = hasProEntitlement
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.verified(result) else {
                    continue
                }

                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.failedVerification
        }
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
