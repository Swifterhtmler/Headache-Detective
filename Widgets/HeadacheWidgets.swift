import WidgetKit
import SwiftUI

// MARK: - Widget Colors
private extension Color {
    static let widgetAccent = Color(red: 0.42, green: 0.39, blue: 0.95)
    static let widgetAccentSecondary = Color(red: 0.95, green: 0.40, blue: 0.52)
    static let widgetSurface = Color(red: 0.98, green: 0.97, blue: 0.97)
    static let widgetTextPrimary = Color.primary
    static let widgetTextTertiary = Color(red: 0.65, green: 0.64, blue: 0.64)

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [widgetAccent, widgetAccentSecondary], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todaysCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), todaysCount: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = SimpleEntry(date: Date(), todaysCount: 0)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todaysCount: Int
}

// MARK: - Home Screen Widget
struct QuickAddWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.accentGradient)

            Text("Log Headache")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.widgetTextPrimary)

            Text("Tap to add a new entry")
                .font(.caption)
                .foregroundStyle(Color.widgetTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.widgetSurface)
        .widgetURL(URL(string: "headache-detective://add"))
    }
}

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickAddWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Add")
        .description("Tap to log a headache quickly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Lock Screen Widgets

struct LockScreenCircularWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.widgetAccent)
                Text("Log")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.widgetTextPrimary)
            }
        }
        .widgetURL(URL(string: "headache-detective://add"))
    }
}

struct LockScreenRectangularWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.widgetAccent)

            VStack(alignment: .leading, spacing: 1) {
                Text("Log Headache")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.widgetTextPrimary)

                Text("Tap to add a new entry")
                    .font(.caption)
                    .foregroundStyle(Color.widgetTextTertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "headache-detective://add"))
    }
}

struct LockScreenWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenRectangularWidgetEntryView(entry: entry)
        default:
            LockScreenCircularWidgetEntryView(entry: entry)
        }
    }
}

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Add")
        .description("Tap to log a headache from your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@main
struct HeadacheWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickAddWidget()
        LockScreenWidget()
    }
}
