import CoreData
import SwiftUI

@main
struct Headache_DetectiveApp: App {
    @State private var openAddScreen = false
    @State private var showOnboarding: Bool
    @StateObject private var purchaseManager = PurchaseManager.shared
    let persistenceController = PersistenceController.shared

    init() {
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        _showOnboarding = State(initialValue: !hasCompleted)

        PurchaseManager.shared.configure(
            apiKey: "appl_mriTUYuoMPluBUJBFNSyxJwTkHt"
        )
    }

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(isComplete: $showOnboarding)
                    .environmentObject(purchaseManager)
                    .onChange(of: showOnboarding) { completed in
                        if !completed {
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        }
                    }
            } else {
                MainTabView(context: persistenceController.container.viewContext, openAddScreen: $openAddScreen)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(purchaseManager)
                    .onOpenURL { url in
                        if url.scheme == "headache-detective" && url.host == "add" {
                            openAddScreen = true
                        }
                    }
                    .task {
                        await purchaseManager.loadOfferings()
                        await purchaseManager.checkSubscriptionStatus()
                    }
            }
        }
    }
}
