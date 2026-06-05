import RevenueCat
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var fetchController: EntryFetchController
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showPaywall = false

    private var entries: [HeadacheEntry] { fetchController.entries }
    private var triggers: [TriggerInsight] { InsightsCalculator.topTriggers(from: entries) }
    private var locations: [LocationInsight] { InsightsCalculator.locationTrends(from: entries) }
    private var stats: FrequencyStats { InsightsCalculator.frequencyStats(from: entries) }
    private var weekdays: [WeekdayInsight] { InsightsCalculator.weekdayPatterns(from: entries) }
    private var timeSlots: [TimeOfDayInsight] { InsightsCalculator.timeOfDayDistribution(from: entries) }
    private var correlations: [TriggerCorrelation] { InsightsCalculator.triggerCorrelations(from: entries) }

    var body: some View {
        NavigationView {
            if purchaseManager.isSubscribed {
                insightsContent
            } else {
                lockedView
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var insightsContent: some View {
        ScrollView {
            if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppTheme.sectionSpacing) {
                    frequencySection

                    if entries.count >= 7 {
                        weekdaySection
                    }

                    if entries.count >= 3 {
                        timeOfDaySection
                    }

                    if !triggers.isEmpty {
                        triggersSection
                    }

                    if !locations.isEmpty {
                        locationsSection
                    }

                    if !correlations.isEmpty {
                        correlationsSection
                    }
                }
                .padding(16)
            }
        }
        .background(AppTheme.surfaceBackground)
        .navigationTitle("Insights")
    }

    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(spacing: 8) {
                Text("Insights are Pro")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Unlock advanced analytics to discover your headache patterns, triggers, and trends.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(alignment: .leading, spacing: 12) {
                row("Weekday & time-of-day patterns")
                row("Top triggers ranked by frequency")
                row("Pain location hotspots")
                row("Trigger impact on severity")
            }
            .padding(.horizontal, 40)

            Button {
                Task {
                    await purchaseManager.loadOfferings()
                    showPaywall = true
                }
            } label: {
                Text("Unlock Insights")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 40)
            }
            .buttonStyle(.plain)
            .shadow(color: AppTheme.accentPrimary.opacity(0.3), radius: 12, y: 6)

            Button("Restore Purchases") {
                Task {
                    await purchaseManager.restore()
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)

            Spacer()
        }
        .background(AppTheme.surfaceBackground)
        .navigationTitle("Insights")
    }

    private func row(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(AppTheme.accentTertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)
            Text("Not enough data yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Log a few headaches to see patterns and insights.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
    }

    private var frequencySection: some View {
        CardSection("Frequency", icon: "number") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("This month", "\(stats.thisMonth)", AppTheme.accentPrimary)
                statCard("Last 30 days", "\(stats.last30Days)", AppTheme.accentSecondary)
                statCard("All time", "\(stats.totalEntries)", AppTheme.accentTertiary)
                statCard("Avg pain", String(format: "%.1f", stats.averagePain), AppTheme.moderateYellow)
            }
        }
    }

    private func statCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weekdaySection: some View {
        CardSection("Weekday patterns", icon: "calendar", subtitle: "Which days have the most headaches") {
            VStack(spacing: 8) {
                ForEach(weekdays) { day in
                    WeekdayBarRow(insight: day)
                }
            }
        }
    }

    private var timeOfDaySection: some View {
        CardSection("Time of day", icon: "clock", subtitle: "When headaches typically strike") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(timeSlots) { slot in
                    TimeSlotCard(insight: slot)
                }
            }
        }
    }

    private var triggersSection: some View {
        CardSection("Top triggers", icon: "bolt.fill", subtitle: "From quick picks & notes") {
            if triggers.isEmpty {
                Text("Add quick picks or notes when logging entries.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(triggers) { item in
                    InsightBarRow(
                        title: item.name,
                        subtitle: "\(item.count)× logged",
                        percentage: item.percentage,
                        color: AppTheme.accentPrimary
                    )
                }
            }
        }
    }

    private var locationsSection: some View {
        CardSection("Pain locations", icon: "face.dashed", subtitle: "Where it hurts most often") {
            if locations.isEmpty {
                Text("Mark pain on the head map when logging.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(locations) { item in
                    InsightBarRow(
                        title: item.label,
                        subtitle: String(format: "%.0f%% of all logged headaches", item.percentage),
                        percentage: item.percentage,
                        color: AppTheme.accentTertiary
                    )
                }
            }
        }
    }

    private var correlationsSection: some View {
        CardSection("Trigger impact", icon: "chart.bar.xaxis", subtitle: "How triggers affect pain severity") {
            if correlations.isEmpty {
                Text("Log more entries with triggers to see patterns.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(correlations) { corr in
                    CorrelationRow(correlation: corr)
                }
            }
        }
    }
}

// MARK: - Weekday Bar Row

struct WeekdayBarRow: View {
    let insight: WeekdayInsight
    @State private var animatedWidth: CGFloat = 0

    private var barColor: Color {
        let maxCount = insight.percentage
        if maxCount > 20 { return AppTheme.severeRed }
        if maxCount > 12 { return AppTheme.moderateYellow }
        return AppTheme.accentTertiary
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(insight.shortLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 32, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(barColor.opacity(0.12))
                    Capsule()
                        .fill(barColor)
                        .frame(width: animatedWidth)
                }
            }
            .frame(height: 10)

            Text("\(insight.count)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(width: 24, alignment: .trailing)
        }
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.05)) {
                let totalWidth = UIScreen.main.bounds.width - 112
                animatedWidth = totalWidth * CGFloat(min(insight.percentage, 100) / 100)
            }
        }
    }
}

// MARK: - Time Slot Card

struct TimeSlotCard: View {
    let insight: TimeOfDayInsight

    private var color: Color {
        switch insight.name {
        case "Morning":   return Color(red: 0.95, green: 0.72, blue: 0.25)
        case "Afternoon": return AppTheme.accentPrimary
        case "Evening":   return AppTheme.accentSecondary
        default:          return Color(red: 0.35, green: 0.35, blue: 0.65)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(insight.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("\(insight.count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)

            Text(String(format: "%.0f%%", insight.percentage))
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Correlation Row

struct CorrelationRow: View {
    let correlation: TriggerCorrelation
    @State private var animated: Bool = false

    private var impactLabel: String {
        if correlation.difference > 0.5 {
            return "Higher pain"
        } else if correlation.difference < -0.5 {
            return "Lower pain"
        }
        return "Little change"
    }

    private var impactColor: Color {
        if correlation.difference > 0.5 { return AppTheme.severeRed }
        if correlation.difference < -0.5 { return AppTheme.mildGreen }
        return AppTheme.textTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(correlation.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(impactLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(impactColor)
            }

            HStack(spacing: 0) {
                Text("Without")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                Text("With")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            GeometryReader { geo in
                let mid = geo.size.width / 2
                let withoutWidth = mid * CGFloat(min(correlation.avgPainWithout / 10, 1.0))
                let withWidth = mid * CGFloat(min(correlation.avgPainWith / 10, 1.0))

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.mildGreen)
                        .frame(width: animated ? withoutWidth : 0, alignment: .trailing)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.severeRed)
                        .frame(width: animated ? withWidth : 0, alignment: .leading)
                }
                .overlay(alignment: .center) {
                    Text("vs")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .frame(height: 14)

            HStack(spacing: 0) {
                Text(String(format: "%.1f", correlation.avgPainWithout))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.mildGreen)
                Spacer()
                Text(String(format: "%.1f", correlation.avgPainWith))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.severeRed)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.1)) {
                animated = true
            }
        }
    }
}

// MARK: - Insight Bar Row (existing)

struct InsightBarRow: View {
    let title: String
    let subtitle: String
    let percentage: Double
    let color: Color

    @State private var animatedWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.0f%%", min(percentage, 100)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: animatedWidth)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(AppTheme.springAnimation.delay(0.1)) {
                let totalWidth = UIScreen.main.bounds.width - 96
                animatedWidth = totalWidth * CGFloat(min(percentage, 100) / 100)
            }
        }
    }
}
