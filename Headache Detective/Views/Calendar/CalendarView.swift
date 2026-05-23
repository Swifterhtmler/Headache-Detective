import SwiftUI

struct CalendarTabView: View {
    @EnvironmentObject private var fetchController: EntryFetchController
    @State private var displayedMonth = Date()
    @State private var selectedDay: Date?
    @State private var showDaySheet = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                monthHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    weekdayHeader
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(daysInMonth(), id: \.self) { day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(height: 44)
                            }
                        }
                    }
                    legend
                }
                .padding(16)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .cardShadow()
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .background(AppTheme.surfaceBackground)
            .navigationTitle("Calendar")
            .sheet(isPresented: $showDaySheet) {
                if let selectedDay {
                    DayEntriesSheet(date: selectedDay, entries: fetchController.entries(on: selectedDay))
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accentPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            Text(monthTitle)
                .font(.title3.weight(.semibold))
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accentPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let maxPain = fetchController.maxPainLevel(on: day)
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            AppTheme.haptic(.light)
            withAnimation(AppTheme.springAnimation) {
                selectedDay = day
            }
            if fetchController.entries(on: day).isEmpty == false {
                showDaySheet = true
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? AppTheme.accentPrimary : AppTheme.textPrimary)
                Circle()
                    .fill(dotColor(maxPain: maxPain))
                    .frame(width: 6, height: 6)
                    .opacity(maxPain == nil ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? AppTheme.accentPrimary.opacity(0.1) :
                          isToday ? AppTheme.accentPrimary.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(maxPain == nil)
    }

    private func dotColor(maxPain: Int?) -> Color {
        guard let maxPain else { return .clear }
        return AppTheme.painColor(level: maxPain)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(AppTheme.mildGreen, "Mild")
            legendItem(AppTheme.moderateYellow, "Moderate")
            legendItem(AppTheme.severeRed, "Severe")
        }
        .font(.caption2)
        .padding(.top, 4)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            withAnimation(AppTheme.quickAnimation) {
                displayedMonth = newMonth
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in dayRange {
            if let date = calendar.date(byAdding: .day, value: offset - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }
}

struct DayEntriesSheet: View {
    let date: Date
    let entries: [HeadacheEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(entries) { entry in
                NavigationLink(destination: EntryDetailView(entry: entry)) {
                    EntryRowView(entry: entry)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                }
            }
        }
    }

    private var dateTitle: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
