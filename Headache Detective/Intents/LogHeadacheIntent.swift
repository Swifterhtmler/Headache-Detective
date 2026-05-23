import AppIntents
import CoreData

struct LogHeadacheIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Headache"
    static let description = IntentDescription("Quickly log a headache with a pain level.")

    @Parameter(title: "Pain Level", default: 5, controlStyle: .stepper, inclusiveRange: (1, 10))
    var painLevel: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.container.viewContext
        let now = Date()
        _ = HeadacheEntry.create(
            in: context,
            startDate: now.addingTimeInterval(-3600),
            endDate: now,
            painLevel: painLevel,
            beforeText: "",
            triggers: [],
            locations: [],
            symptoms: [],
            medications: "",
            relief: "",
            notes: ""
        )
        PersistenceController.shared.save(context: context)
        return .result(dialog: "Logged headache with pain level \(painLevel).")
    }
}
