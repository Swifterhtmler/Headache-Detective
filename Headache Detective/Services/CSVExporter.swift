import Foundation
import UIKit

enum CSVExporter {
    static func generateCSV(from entries: [HeadacheEntry]) -> String {
        let header = [
            "id", "start", "end", "duration_minutes", "pain_level", "severity",
            "before_activity", "before_triggers", "pain_locations",
            "throbbing", "nausea", "light_sound_sensitivity", "aura",
            "medications", "relief_methods", "notes", "created_at"
        ].joined(separator: ",")

        let formatter = ISO8601DateFormatter()
        let rows = entries.map { entry -> String in
            let start = entry.startDate.map { formatter.string(from: $0) } ?? ""
            let end = entry.endDate.map { formatter.string(from: $0) } ?? ""
            let durationMin: String
            if let d = entry.duration {
                durationMin = String(format: "%.1f", d / 60)
            } else {
                durationMin = ""
            }
            return [
                csvEscape(entry.wrappedID.uuidString),
                csvEscape(start),
                csvEscape(end),
                csvEscape(durationMin),
                csvEscape(String(entry.painLevelInt)),
                csvEscape(entry.severity.label),
                csvEscape(entry.beforeActivityText ?? ""),
                csvEscape(entry.triggerList.joined(separator: "; ")),
                csvEscape(entry.locationLabels.joined(separator: "; ")),
                csvEscape(entry.symptomThrobbing ? "yes" : "no"),
                csvEscape(entry.symptomNausea ? "yes" : "no"),
                csvEscape(entry.symptomLightSound ? "yes" : "no"),
                csvEscape(entry.symptomAura ? "yes" : "no"),
                csvEscape(entry.medications ?? ""),
                csvEscape(entry.reliefMethods ?? ""),
                csvEscape(entry.notes ?? ""),
                csvEscape(entry.createdAt.map { formatter.string(from: $0) } ?? "")
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    static func exportURL(from entries: [HeadacheEntry]) -> URL? {
        let csv = generateCSV(from: entries)
        let fileName = "headache_detective_export_\(ISO8601DateFormatter().string(from: Date())).csv"
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
