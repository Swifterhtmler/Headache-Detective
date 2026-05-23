import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var fetchController: EntryFetchController
    @State private var filterStart = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var filterEnd = Date()
    @State private var useDateFilter = false
    @State private var exportURL: URL?
    @State private var showShare = false

    private var filteredEntries: [HeadacheEntry] {
        guard useDateFilter else { return fetchController.entries }
        return fetchController.entries.filter { entry in
            guard let start = entry.startDate else { return false }
            return start >= filterStart && start <= filterEnd.addingTimeInterval(86400)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(destination: EntryDetailView(entry: entry)) {
                                EntryRowView(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(AppTheme.surfaceBackground)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportURL = CSVExporter.exportURL(from: fetchController.entries)
                        showShare = exportURL != nil
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(fetchController.entries.isEmpty)
                    .tint(AppTheme.accentPrimary)
                }
            }
            .sheet(isPresented: $showShare) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentPrimary)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.accentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Toggle("Filter by date range", isOn: $useDateFilter)
                    .font(.subheadline)
                    .tint(AppTheme.accentPrimary)
                    .animation(AppTheme.quickAnimation, value: useDateFilter)
            }
            if useDateFilter {
                CardDivider()
                    .padding(.leading, 34)
                VStack(spacing: 8) {
                    HStack {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 30, alignment: .leading)
                        Spacer()
                        DatePicker("", selection: $filterStart, displayedComponents: .date)
                            .labelsHidden()
                            .tint(AppTheme.accentPrimary)
                    }
                    HStack {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(width: 30, alignment: .leading)
                        Spacer()
                        DatePicker("", selection: $filterEnd, in: filterStart..., displayedComponents: .date)
                            .labelsHidden()
                            .tint(AppTheme.accentPrimary)
                    }
                }
                .padding(.leading, 34)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .cardShadow()
        .animation(AppTheme.springAnimation, value: useDateFilter)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)
            Text("No entries yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Log your first headache from the Add tab.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func deleteEntries(at offsets: IndexSet) {
        AppTheme.haptic(.medium)
        for index in offsets {
            fetchController.delete(filteredEntries[index])
        }
    }
}

struct EntryRowView: View {
    let entry: HeadacheEntry

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(entry.severity.color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(dateText)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text("Pain \(entry.painLevelInt)/10")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(entry.severity.color)
                    Text("·")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(entry.durationText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                if !entry.triggerList.isEmpty {
                    Text(entry.triggerList.prefix(2).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(entry.severity.label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(entry.severity.color.opacity(0.15))
                .foregroundStyle(entry.severity.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var dateText: String {
        guard let start = entry.startDate else { return "Unknown date" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: start)
    }
}

struct EntryDetailView: View {
    let entry: HeadacheEntry
    @EnvironmentObject private var fetchController: EntryFetchController
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    Text("\(entry.painLevelInt)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(entry.severity.color)
                    Text("/ 10 · \(entry.severity.label)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .cardShadow()

                detailGroup("Time") {
                    detailRow("Started", format(entry.startDate))
                    if let end = entry.endDate {
                        detailRow("Ended", format(end))
                    }
                    detailRow("Duration", entry.durationText)
                }

                if !entry.triggerList.isEmpty {
                    detailGroup("Triggers") {
                        ChipGroup(items: entry.triggerList, color: AppTheme.accentPrimary)
                    }
                }

                if let text = entry.beforeActivityText, !text.isEmpty {
                    detailGroup("Before activity") {
                        Text(text)
                            .font(.subheadline)
                    }
                }

                if !entry.locationLabels.isEmpty {
                    detailGroup("Pain locations") {
                        ChipGroup(items: entry.locationLabels, color: AppTheme.accentTertiary)
                    }
                }

                if !entry.activeSymptoms.isEmpty {
                    detailGroup("Symptoms") {
                        ChipGroup(items: entry.activeSymptoms.map(\.rawValue), color: AppTheme.accentSecondary)
                    }
                }

                if let meds = entry.medications, !meds.isEmpty {
                    detailGroup("Medications") {
                        Text(meds)
                            .font(.subheadline)
                    }
                }

                if let relief = entry.reliefMethods, !relief.isEmpty {
                    detailGroup("Relief") {
                        Text(relief)
                            .font(.subheadline)
                    }
                }

                if let notes = entry.notes, !notes.isEmpty {
                    detailGroup("Notes") {
                        Text(notes)
                            .font(.subheadline)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(16)
        }
        .background(AppTheme.surfaceBackground)
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    AppTheme.haptic(.heavy)
                    fetchController.delete(entry)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func detailGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(AppTheme.accentPrimary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .cardShadow()
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - ChipGroup
struct ChipGroup: View {
    let items: [String]
    let color: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.1))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
