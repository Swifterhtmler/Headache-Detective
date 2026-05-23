import Foundation
import CoreData

extension HeadacheEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeadacheEntry> {
        NSFetchRequest<HeadacheEntry>(entityName: "HeadacheEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var painLevel: Int16
    @NSManaged public var beforeActivityText: String?
    @NSManaged public var beforeTriggers: String?
    @NSManaged public var painLocations: String?
    @NSManaged public var symptomThrobbing: Bool
    @NSManaged public var symptomNausea: Bool
    @NSManaged public var symptomLightSound: Bool
    @NSManaged public var symptomAura: Bool
    @NSManaged public var medications: String?
    @NSManaged public var reliefMethods: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
}

extension HeadacheEntry: Identifiable {
    public var wrappedID: UUID {
        id ?? UUID()
    }
}
