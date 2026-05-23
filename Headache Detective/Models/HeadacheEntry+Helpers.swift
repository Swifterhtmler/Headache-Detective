import Foundation
import CoreData

extension HeadacheEntry {
    var painLevelInt: Int {
        Int(painLevel)
    }

    var severity: PainSeverity {
        PainSeverity.from(painLevel: painLevelInt)
    }

    var duration: TimeInterval? {
        guard let start = startDate, let end = endDate else { return nil }
        return end.timeIntervalSince(start)
    }

    var durationText: String {
        guard let duration, duration > 0 else { return "Ongoing" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var triggerList: [String] {
        guard let raw = beforeTriggers, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: "|||").filter { !$0.isEmpty }
    }

    var locationIDs: [String] {
        guard let raw = painLocations, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    var locationLabels: [String] {
        locationIDs.map { HeadPainRegions.label(for: $0) }
    }

    var activeSymptoms: [HeadSymptom] {
        var list: [HeadSymptom] = []
        if symptomThrobbing { list.append(.throbbing) }
        if symptomNausea { list.append(.nausea) }
        if symptomLightSound { list.append(.lightSound) }
        if symptomAura { list.append(.aura) }
        return list
    }

    func setTriggers(_ triggers: Set<BeforeTrigger>) {
        beforeTriggers = triggers.map(\.rawValue).sorted().joined(separator: "|||")
    }

    func setLocations(_ ids: Set<String>) {
        painLocations = ids.sorted().joined(separator: ",")
    }

    static func create(
        in context: NSManagedObjectContext,
        startDate: Date,
        endDate: Date?,
        painLevel: Int,
        beforeText: String,
        triggers: Set<BeforeTrigger>,
        locations: Set<String>,
        symptoms: Set<HeadSymptom>,
        medications: String,
        relief: String,
        notes: String
    ) -> HeadacheEntry {
        let entry = HeadacheEntry(context: context)
        entry.id = UUID()
        entry.createdAt = Date()
        entry.startDate = startDate
        entry.endDate = endDate
        entry.painLevel = Int16(painLevel)
        entry.beforeActivityText = beforeText.isEmpty ? nil : beforeText
        entry.setTriggers(triggers)
        entry.setLocations(locations)
        entry.symptomThrobbing = symptoms.contains(.throbbing)
        entry.symptomNausea = symptoms.contains(.nausea)
        entry.symptomLightSound = symptoms.contains(.lightSound)
        entry.symptomAura = symptoms.contains(.aura)
        entry.medications = medications.isEmpty ? nil : medications
        entry.reliefMethods = relief.isEmpty ? nil : relief
        entry.notes = notes.isEmpty ? nil : notes
        return entry
    }
}
