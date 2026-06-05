import CoreData
import SwiftUI

struct MainTabView: View {
    @StateObject private var fetchController: EntryFetchController
    @Binding var openAddScreen: Bool
    @State private var selection = 0

    init(context: NSManagedObjectContext, openAddScreen: Binding<Bool>) {
        _fetchController = StateObject(wrappedValue: EntryFetchController(context: context))
        _openAddScreen = openAddScreen
    }

    var body: some View {
        TabView(selection: $selection) {
            AddEntryView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(0)

            CalendarTabView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                .tag(2)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .environmentObject(fetchController)
        .environmentObject(PurchaseManager.shared)
        .tint(AppTheme.accentPrimary)
        .onChange(of: openAddScreen) { newValue in
            if newValue {
                selection = 0
                openAddScreen = false
            }
        }
    }
}
