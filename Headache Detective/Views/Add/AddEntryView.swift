import SwiftUI
import CoreData
import StoreKit

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var fetchController: EntryFetchController
    @Environment(\.requestReview) private var requestReview

    @State private var startDate = Date().addingTimeInterval(-3600)
    @State private var endDate = Date()
    @State private var hasEndDate = true
    @State private var painLevel: Double = 5
    @State private var beforeText = ""
    @State private var selectedTriggers: Set<BeforeTrigger> = []
    @State private var selectedLocations: Set<String> = []
    @State private var selectedSymptoms: Set<HeadSymptom> = []
    @State private var medications = ""
    @State private var reliefMethods = ""
    @State private var notes = ""
    @State private var showSavedAlert = false
    @State private var saveError: String?
    @State private var isSaving = false
    @State private var quickLoggedLevel: Int?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    quickLogSection
                    headerSection
                    timingSection
                    painSection
                    beforeSection
                    headMapSection
                    symptomsSection
                    reliefSection
                    notesSection
                    saveButton
                }
                .padding(16)
            }
            .background(AppTheme.surfaceBackground)
            .overlay(alignment: .top) {
                toastOverlay
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Saved", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your headache entry was saved.")
            }
            .alert("Could not save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var quickLogSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Quick Log")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Tap a level to log instantly")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }

            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { level in
                    Button {
                        quickLog(level)
                    } label: {
                        Text("\(level)")
                            .font(.system(size: 11, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.painColor(level: level))
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .opacity(quickLoggedLevel == level ? 0.5 : 1)
                    .scaleEffect(quickLoggedLevel == level ? 0.85 : 1)
                    .animation(AppTheme.springAnimation, value: quickLoggedLevel)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [
                AppTheme.accentPrimary.opacity(0.9),
                AppTheme.accentSecondary.opacity(0.7)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .cardShadowSmall()
    }

    private var toastOverlay: some View {
        Group {
            if let level = quickLoggedLevel {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                    Text("Level \(level) logged")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(.ultraThinMaterial))
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(AppTheme.quickAnimation) {
                            quickLoggedLevel = nil
                        }
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("New Entry")
                    .font(.title3.weight(.bold))
                Text("Log your headache details")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var timingSection: some View {
        CardSection("When", icon: "clock") {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        ForEach(startQuickOptions, id: \.0) { label, offset in
                            startChip(label, offset: offset)
                        }
                    }

                    DatePicker("Custom", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(AppTheme.accentPrimary)
                }

                CardDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("End")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 6) {
                        endChip("Ongoing", isSelected: !hasEndDate) { hasEndDate = false }
                        endChip("Ended", isSelected: hasEndDate) { hasEndDate = true; endDate = Date() }
                    }

                    if hasEndDate {
                        DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .tint(AppTheme.accentPrimary)
                    }

                    if !hasEndDate, let text = estimatedText {
                        Text(text)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
    }

    private let startQuickOptions: [(String, TimeInterval)] = [
        ("Just now", 0),
        ("1h ago", -3600),
        ("2h ago", -7200),
        ("3h ago", -10800),
    ]

    private func startChip(_ label: String, offset: TimeInterval) -> some View {
        let diff = Date().timeIntervalSince(startDate)
        let isActive = abs(diff - abs(offset)) < 90
        return Button(label) {
            startDate = Date().addingTimeInterval(offset)
            if hasEndDate { endDate = Date() }
        }
        .buttonStyle(.plain)
        .font(.caption.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(isActive ? AppTheme.accentPrimary.opacity(0.15) : AppTheme.groupedBackground))
        .foregroundStyle(isActive ? AppTheme.accentPrimary : AppTheme.textSecondary)
        .animation(AppTheme.springAnimation, value: startDate)
    }

    private func endChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? AppTheme.accentPrimary.opacity(0.15) : AppTheme.groupedBackground))
                .foregroundStyle(isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary)
                .overlay(Capsule().stroke(isSelected ? AppTheme.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(AppTheme.springAnimation, value: isSelected)
    }

    private var averagePastDuration: TimeInterval? {
        let completed = fetchController.entries.filter { $0.startDate != nil && $0.endDate != nil }
        guard !completed.isEmpty else { return nil }
        let total = completed.reduce(0.0) { $0 + $1.endDate!.timeIntervalSince($1.startDate!) }
        return total / Double(completed.count)
    }

    private var estimatedEndTime: Date? {
        guard let avg = averagePastDuration else { return nil }
        return startDate.addingTimeInterval(avg)
    }

    private var estimatedText: String? {
        guard let avg = averagePastDuration, let estimated = estimatedEndTime else { return nil }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let timeStr = f.string(from: estimated)
        let hours = Int(avg) / 3600
        let minutes = (Int(avg) % 3600) / 60
        if hours > 0 {
            return "Estimated end ~ \(timeStr) (avg \(hours)h \(minutes)m)"
        }
        return "Estimated end ~ \(timeStr) (avg \(minutes)m)"
    }

    private var painSection: some View {
        CardSection("Pain level", icon: "waveform.path.ecg", subtitle: "\(Int(painLevel)) — \(PainSeverity.from(painLevel: Int(painLevel)).label)") {
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Slider(value: $painLevel, in: 1...10, step: 1)
                        .tint(AppTheme.painColor(level: Int(painLevel)))
                    HStack {
                        Text("1")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        Spacer()
                        Text("10")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                HStack(spacing: 12) {
                    legendBadge(AppTheme.mildGreen, "Mild", range: "1–3")
                    legendBadge(AppTheme.moderateYellow, "Moderate", range: "4–6")
                    legendBadge(AppTheme.severeRed, "Severe", range: "7–10")
                }
            }
        }
    }

    private func legendBadge(_ color: Color, _ label: String, range: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption.weight(.medium))
                Text(range)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var beforeSection: some View {
        CardSection("Before", icon: "eye", subtitle: "What were you doing 2–6 hours before?") {
            VStack(spacing: 14) {
                TextField("e.g. long meeting, wine with dinner…", text: $beforeText)
                    .font(.subheadline)
                    .padding(12)
                    .background(AppTheme.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.accentPrimary)
                        Text("Quick picks")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(BeforeTrigger.allCases) { trigger in
                            TriggerChip(
                                title: trigger.rawValue,
                                isSelected: selectedTriggers.contains(trigger)
                            ) {
                                AppTheme.haptic(.light)
                                toggleTrigger(trigger)
                            }
                        }
                    }
                }
            }
        }
    }

    private var headMapSection: some View {
        CardSection("Head pain map", icon: "face.dashed", subtitle: "Tap where it hurts") {
            HeadPainMapView(selectedLocations: $selectedLocations)
        }
    }

    private var symptomsSection: some View {
        CardSection("Symptoms", icon: "list.clipboard") {
            VStack(spacing: 8) {
                ForEach(HeadSymptom.allCases) { symptom in
                    SymptomToggle(
                        symptom: symptom,
                        isSelected: selectedSymptoms.contains(symptom)
                    ) {
                        AppTheme.haptic(.light)
                        if selectedSymptoms.contains(symptom) {
                            selectedSymptoms.remove(symptom)
                        } else {
                            selectedSymptoms.insert(symptom)
                        }
                    }
                }
            }
        }
    }

    private var reliefSection: some View {
        CardSection("Relief", icon: "cross.case", subtitle: "Medications & methods") {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "pills")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentTertiary)
                    TextField("Medications taken", text: $medications)
                        .font(.subheadline)
                }
                .padding(12)
                .background(AppTheme.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack {
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentTertiary)
                    TextField("Ice, rest, dark room…", text: $reliefMethods)
                        .font(.subheadline)
                }
                .padding(12)
                .background(AppTheme.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var notesSection: some View {
        CardSection("Notes", icon: "note.text") {
            TextEditor(text: $notes)
                .font(.subheadline)
                .frame(minHeight: 90)
                .padding(12)
                .background(AppTheme.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var saveButton: some View {
        Button(action: saveEntry) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                Text("Save Entry")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(AppTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .cardShadowSmall()
            .scaleEffect(isSaving ? 0.95 : 1)
            .animation(AppTheme.springAnimation, value: isSaving)
        }
        .padding(.bottom, 24)
        .disabled(isSaving)
    }

    private func toggleTrigger(_ trigger: BeforeTrigger) {
        if selectedTriggers.contains(trigger) {
            selectedTriggers.remove(trigger)
        } else {
            selectedTriggers.insert(trigger)
        }
    }

    private func saveEntry() {
        AppTheme.haptic(.medium)
        isSaving = true
        let capturedStart = startDate
        let capturedEnd = hasEndDate ? endDate : nil
        let capturedLevel = Int(painLevel)
        let end = hasEndDate ? endDate : nil
        _ = HeadacheEntry.create(
            in: viewContext,
            startDate: startDate,
            endDate: end,
            painLevel: capturedLevel,
            beforeText: beforeText,
            triggers: selectedTriggers,
            locations: selectedLocations,
            symptoms: selectedSymptoms,
            medications: medications,
            relief: reliefMethods,
            notes: notes
        )
        PersistenceController.shared.save(context: viewContext)
        fetchController.fetch()
        resetForm()
        Task {
            try? await HealthKitService.shared.requestAuthorization()
            try? await HealthKitService.shared.logHeadache(
                painLevel: capturedLevel,
                start: capturedStart,
                end: capturedEnd ?? Date()
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isSaving = false
            showSavedAlert = true
        }
        requestReviewIfNeeded()
    }

    private func quickLog(_ level: Int) {
        AppTheme.haptic(.medium)
        painLevel = Double(level)
        let now = Date()
        _ = HeadacheEntry.create(
            in: viewContext,
            startDate: now,
            endDate: now,
            painLevel: level,
            beforeText: "",
            triggers: [],
            locations: [],
            symptoms: [],
            medications: "",
            relief: "",
            notes: ""
        )
        PersistenceController.shared.save(context: viewContext)
        fetchController.fetch()
        Task {
            try? await HealthKitService.shared.requestAuthorization()
            try? await HealthKitService.shared.logHeadache(
                painLevel: level,
                start: now,
                end: now
            )
        }
        withAnimation(AppTheme.springAnimation) {
            quickLoggedLevel = level
        }
    }

    private func resetForm() {
        startDate = Date().addingTimeInterval(-3600)
        endDate = Date()
        hasEndDate = false
        painLevel = 5
        beforeText = ""
        selectedTriggers = []
        selectedLocations = []
        selectedSymptoms = []
        medications = ""
        reliefMethods = ""
        notes = ""
    }

    private func requestReviewIfNeeded() {
        let key = "totalSaves"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)
        let milestones = [3, 15, 50, 100]
        if milestones.contains(count) {
            requestReview()
        }
    }
}

// MARK: - Trigger Chip
struct TriggerChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.groupedBackground)
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : AppTheme.textTertiary.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(AppTheme.springAnimation, value: isSelected)
    }
}

// MARK: - Symptom Toggle
struct SymptomToggle: View {
    let symptom: HeadSymptom
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch symptom {
        case .throbbing: return "drop.fill"
        case .nausea: return "stomach"
        case .lightSound: return "sun.max"
        case .aura: return "sparkles"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? AppTheme.accentPrimary : AppTheme.textTertiary)
                    .frame(width: 24)

                Text(symptom.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? AppTheme.accentPrimary : AppTheme.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.accentPrimary.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(AppTheme.springAnimation, value: isSelected)
    }
}
