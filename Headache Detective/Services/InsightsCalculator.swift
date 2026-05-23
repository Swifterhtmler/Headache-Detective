import Foundation

struct TriggerInsight: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
}

struct LocationInsight: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let percentage: Double
}

struct FrequencyStats {
    let thisMonth: Int
    let last30Days: Int
    let averagePain: Double
    let totalEntries: Int
}

struct WeekdayInsight: Identifiable {
    let id = UUID()
    let label: String
    let shortLabel: String
    let count: Int
    let percentage: Double
}

struct TimeOfDayInsight: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let count: Int
    let percentage: Double
}

struct TriggerCorrelation: Identifiable {
    let id = UUID()
    let name: String
    let avgPainWith: Double
    let avgPainWithout: Double
    let difference: Double
}

enum InsightsCalculator {
    static func topTriggers(from entries: [HeadacheEntry], limit: Int = 8) -> [TriggerInsight] {
        guard !entries.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for entry in entries {
            for trigger in entry.triggerList {
                counts[trigger, default: 0] += 1
            }
            if let text = entry.beforeActivityText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                counts[text, default: 0] += 1
            }
        }
        let total = Double(entries.count)
        return counts
            .map { TriggerInsight(name: $0.key, count: $0.value, percentage: Double($0.value) / total * 100) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    static func locationTrends(from entries: [HeadacheEntry], limit: Int = 6) -> [LocationInsight] {
        guard !entries.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for entry in entries {
            for id in entry.locationIDs {
                let label = HeadPainRegions.label(for: id)
                counts[label, default: 0] += 1
            }
        }
        guard !counts.isEmpty else { return [] }
        let total = Double(entries.count)
        return counts
            .map { LocationInsight(label: $0.key, count: $0.value, percentage: Double($0.value) / total * 100) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    static func frequencyStats(from entries: [HeadacheEntry], referenceDate: Date = Date()) -> FrequencyStats {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate

        let thisMonth = entries.filter { ($0.startDate ?? .distantPast) >= monthStart }.count
        let last30 = entries.filter { ($0.startDate ?? .distantPast) >= thirtyDaysAgo }.count
        let avgPain: Double
        if entries.isEmpty {
            avgPain = 0
        } else {
            avgPain = Double(entries.map(\.painLevelInt).reduce(0, +)) / Double(entries.count)
        }
        return FrequencyStats(
            thisMonth: thisMonth,
            last30Days: last30,
            averagePain: avgPain,
            totalEntries: entries.count
        )
    }

    static func weekdayPatterns(from entries: [HeadacheEntry]) -> [WeekdayInsight] {
        guard !entries.isEmpty else { return [] }
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for entry in entries {
            guard let date = entry.startDate else { continue }
            let weekday = calendar.component(.weekday, from: date)
            counts[weekday, default: 0] += 1
        }
        let total = Double(entries.count)
        let full = calendar.standaloneWeekdaySymbols
        let short = calendar.shortWeekdaySymbols
        // .weekday is 1-based, 1 = Sunday
        return (1...7).map { i in
            let count = counts[i] ?? 0
            return WeekdayInsight(
                label: full[i - 1],
                shortLabel: short[i - 1],
                count: count,
                percentage: Double(count) / total * 100
            )
        }
    }

    static func timeOfDayDistribution(from entries: [HeadacheEntry]) -> [TimeOfDayInsight] {
        guard !entries.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for entry in entries {
            guard let date = entry.startDate else { continue }
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12: counts["Morning", default: 0] += 1
            case 12..<17: counts["Afternoon", default: 0] += 1
            case 17..<22: counts["Evening", default: 0] += 1
            default:      counts["Night", default: 0] += 1
            }
        }
        let total = Double(entries.count)
        let slots: [(name: String, icon: String)] = [
            ("Morning", "sunrise.fill"),
            ("Afternoon", "sun.max.fill"),
            ("Evening", "sunset.fill"),
            ("Night", "moon.stars.fill")
        ]
        return slots.map { (name, icon) in
            let count = counts[name] ?? 0
            return TimeOfDayInsight(name: name, icon: icon, count: count, percentage: Double(count) / total * 100)
        }
    }

    static func triggerCorrelations(from entries: [HeadacheEntry]) -> [TriggerCorrelation] {
        let allTriggers = BeforeTrigger.allCases.map(\.rawValue)
        var result: [TriggerCorrelation] = []
        for trigger in allTriggers {
            let withTrigger = entries.filter { $0.triggerList.contains(trigger) }
            let withoutTrigger = entries.filter { !$0.triggerList.contains(trigger) }
            guard !withTrigger.isEmpty, !withoutTrigger.isEmpty else { continue }
            let avgWith = Double(withTrigger.reduce(0) { $0 + $1.painLevelInt }) / Double(withTrigger.count)
            let avgWithout = Double(withoutTrigger.reduce(0) { $0 + $1.painLevelInt }) / Double(withoutTrigger.count)
            result.append(TriggerCorrelation(
                name: trigger,
                avgPainWith: avgWith,
                avgPainWithout: avgWithout,
                difference: avgWith - avgWithout
            ))
        }
        return result.sorted { abs($0.difference) > abs($1.difference) }
    }
}
