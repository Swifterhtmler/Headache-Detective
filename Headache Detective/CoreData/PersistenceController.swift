import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HeadacheDetective")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.HeadacheDetective")?.appendingPathComponent("HeadacheDetective.sqlite") {
            container.persistentStoreDescriptions.first?.url = storeURL
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
}
