//
//  ContentView.swift
//  Headache Detective
//

import CoreData
import SwiftUI

/// Legacy preview entry point — app uses MainTabView.
struct ContentView: View {
    var body: some View {
        MainTabView(context: PersistenceController.shared.container.viewContext, openAddScreen: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    MainTabView(context: controller.container.viewContext, openAddScreen: .constant(false))
        .environment(\.managedObjectContext, controller.container.viewContext)
}
