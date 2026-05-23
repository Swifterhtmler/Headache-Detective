import Combine
import CoreData
import SwiftUI

final class EntryFetchController: ObservableObject {
    @Published private(set) var entries: [HeadacheEntry] = []

    private let context: NSManagedObjectContext
    private var observer: NSObjectProtocol?

    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
        observer = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: context,
            queue: .main
        ) { [weak self] _ in
            self?.fetch()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func fetch() {
        let request = HeadacheEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HeadacheEntry.startDate, ascending: false)]
        entries = (try? context.fetch(request)) ?? []
    }

    func entries(on day: Date, calendar: Calendar = .current) -> [HeadacheEntry] {
        entries.filter { entry in
            guard let start = entry.startDate else { return false }
            return calendar.isDate(start, inSameDayAs: day)
        }
    }

    func maxPainLevel(on day: Date, calendar: Calendar = .current) -> Int? {
        let dayEntries = entries(on: day, calendar: calendar)
        return dayEntries.map(\.painLevelInt).max()
    }

    func delete(_ entry: HeadacheEntry) {
        context.delete(entry)
        PersistenceController.shared.save(context: context)
        fetch()
    }
}
