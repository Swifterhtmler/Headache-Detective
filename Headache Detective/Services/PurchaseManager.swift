import Combine
import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

final class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var isSubscribed = false
    @Published private(set) var isLoading = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var hasLoadedOfferings = false

    private override init() {
        super.init()
    }

    func configure(apiKey: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
    }

    func checkSubscriptionStatus() async {
        await MainActor.run { isLoading = true }
        do {
            let info = try await Purchases.shared.customerInfo()
            await update(from: info)
        } catch {
            print("RevenueCat: Failed to check subscription: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    func purchase(_ package: Package) async -> Bool {
        await MainActor.run { isLoading = true }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            await update(from: result.customerInfo)
            await MainActor.run { isLoading = false }
            return result.customerInfo.entitlements.active.first?.value.isActive == true
        } catch {
            print("RevenueCat: Purchase failed: \(error)")
            await MainActor.run { isLoading = false }
            return false
        }
    }

    func restore() async -> Bool {
        await MainActor.run { isLoading = true }
        do {
            let info = try await Purchases.shared.restorePurchases()
            await update(from: info)
            await MainActor.run { isLoading = false }
            return info.entitlements.active.first?.value.isActive == true
        } catch {
            print("RevenueCat: Restore failed: \(error)")
            await MainActor.run { isLoading = false }
            return false
        }
    }

    func loadOfferings() async {
        await MainActor.run { isLoading = true }
        do {
            let result = try await Purchases.shared.offerings()
            await MainActor.run {
                offerings = result
                hasLoadedOfferings = true
            }
        } catch {
            print("RevenueCat: Failed to load offerings: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private func update(from info: CustomerInfo) {
        Task { @MainActor in
            customerInfo = info
            let wasSubscribed = isSubscribed
            isSubscribed = info.entitlements.active.first?.value.isActive == true
            if wasSubscribed != isSubscribed {
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
            }
        }
    }
}

extension PurchaseManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        update(from: customerInfo)
    }
}

extension PurchaseManager {
    func customerCenterViewController() -> UIViewController {
        CustomerCenterViewController()
    }
}

struct CustomerCenterView: View {
    var body: some View {
        CustomerCenterViewRepresentable()
            .ignoresSafeArea()
    }
}

private struct CustomerCenterViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        CustomerCenterViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
