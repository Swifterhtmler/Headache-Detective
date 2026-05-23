//
//  Headache_DetectiveApp.swift
//  Headache Detective
//

import CoreData
import SwiftUI

@main
struct Headache_DetectiveApp: App {
    @State private var openAddScreen = false
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView(context: persistenceController.container.viewContext, openAddScreen: $openAddScreen)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    if url.scheme == "headache-detective" && url.host == "add" {
                        openAddScreen = true
                    }
                }
        }
    }
}
