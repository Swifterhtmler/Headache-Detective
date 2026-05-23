import Foundation
import SwiftUI

enum PainSeverity: String, CaseIterable {
    case mild
    case moderate
    case severe

    static func from(painLevel: Int) -> PainSeverity {
        switch painLevel {
        case 1...3: return .mild
        case 4...6: return .moderate
        default: return .severe
        }
    }

    var color: Color {
        switch self {
        case .mild: return AppTheme.mildGreen
        case .moderate: return AppTheme.moderateYellow
        case .severe: return AppTheme.severeRed
        }
    }

    var label: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

enum BeforeTrigger: String, CaseIterable, Identifiable {
    case stress = "Stress"
    case lackOfSleep = "Lack of sleep"
    case caffeine = "Caffeine"
    case alcohol = "Alcohol"
    case screenTime = "Screen time"
    case dehydration = "Dehydration"
    case skippedMeal = "Skipped meal"
    case weatherChange = "Weather change"
    case hormonal = "Hormonal"

    var id: String { rawValue }
}

enum HeadSymptom: String, CaseIterable, Identifiable {
    case throbbing = "Throbbing"
    case nausea = "Nausea"
    case lightSound = "Light/Sound sensitivity"
    case aura = "Aura"

    var id: String { rawValue }
}

enum HeadSide: String, CaseIterable {
    case front
    case back
}

struct PainLocationZone: Identifiable, Hashable {
    let id: String
    let label: String
    let side: HeadSide
    /// Normalized center in head silhouette (0–1).
    let centerX: CGFloat
    let centerY: CGFloat
    let radius: CGFloat
}

enum HeadPainRegions {
    static let all: [PainLocationZone] = [
        // Front – aligned with round head (top 0.04, mid 0.25, chin 0.46, half-width 0.19)
        PainLocationZone(id: "forehead", label: "Forehead", side: .front, centerX: 0.5, centerY: 0.12, radius: 0.08),
        PainLocationZone(id: "left_temple", label: "Left temple", side: .front, centerX: 0.24, centerY: 0.25, radius: 0.08),
        PainLocationZone(id: "right_temple", label: "Right temple", side: .front, centerX: 0.76, centerY: 0.25, radius: 0.08),
        PainLocationZone(id: "left_eye", label: "Left eye area", side: .front, centerX: 0.36, centerY: 0.19, radius: 0.07),
        PainLocationZone(id: "right_eye", label: "Right eye area", side: .front, centerX: 0.64, centerY: 0.19, radius: 0.07),
        PainLocationZone(id: "nose", label: "Nose / sinus", side: .front, centerX: 0.5, centerY: 0.34, radius: 0.07),
        PainLocationZone(id: "jaw", label: "Jaw", side: .front, centerX: 0.5, centerY: 0.44, radius: 0.08),
        PainLocationZone(id: "left_cheek", label: "Left cheek", side: .front, centerX: 0.27, centerY: 0.34, radius: 0.07),
        PainLocationZone(id: "right_cheek", label: "Right cheek", side: .front, centerX: 0.73, centerY: 0.34, radius: 0.07),
        // Back
        PainLocationZone(id: "crown", label: "Crown", side: .back, centerX: 0.5, centerY: 0.14, radius: 0.08),
        PainLocationZone(id: "back_of_head", label: "Back of head", side: .back, centerX: 0.5, centerY: 0.30, radius: 0.09),
        PainLocationZone(id: "left_occipital", label: "Left back", side: .back, centerX: 0.28, centerY: 0.32, radius: 0.08),
        PainLocationZone(id: "right_occipital", label: "Right back", side: .back, centerX: 0.72, centerY: 0.32, radius: 0.08),
        PainLocationZone(id: "neck", label: "Neck", side: .back, centerX: 0.5, centerY: 0.52, radius: 0.09)
    ]

    static func zone(for id: String) -> PainLocationZone? {
        all.first { $0.id == id }
    }

    static func label(for id: String) -> String {
        zone(for: id)?.label ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
