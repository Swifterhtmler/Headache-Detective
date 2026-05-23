import Foundation
import CoreData

@objc(HeadacheEntry)
public class HeadacheEntry: NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "HeadacheEntry", in: context)!
        self.init(entity: entity, insertInto: context)
    }
}
