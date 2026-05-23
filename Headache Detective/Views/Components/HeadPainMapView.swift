import SwiftUI

struct HeadPainMapView: View {
    @Binding var selectedLocations: Set<String>
    @State private var headSide: HeadSide = .front

    private var zones: [PainLocationZone] {
        HeadPainRegions.all.filter { $0.side == headSide }
    }

    var body: some View {
        VStack(spacing: 14) {
            Picker("View", selection: $headSide) {
                Text("Front").tag(HeadSide.front)
                Text("Back").tag(HeadSide.back)
            }
            .pickerStyle(.segmented)
            .tint(AppTheme.accentPrimary)

            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    HeadSilhouetteShape(side: headSide)
                        .fill(AppTheme.accentPrimary.opacity(0.03))

                    HeadSilhouetteShape(side: headSide)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 2)

                    HeadFeaturesShape(side: headSide)
                        .stroke(Color.primary.opacity(0.35), lineWidth: 2)

                    ForEach(zones) { zone in
                        let point = CGPoint(x: zone.centerX * size.width, y: zone.centerY * size.height)
                        let isSelected = selectedLocations.contains(zone.id)
                        Circle()
                            .fill(isSelected ? AppTheme.accentPrimary.opacity(0.8) : Color.primary.opacity(0.06))
                            .frame(width: zone.radius * size.width * 2, height: zone.radius * size.width * 2)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? AppTheme.accentPrimary : Color.primary.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                            )
                            .position(point)
                            .scaleEffect(isSelected ? 1.15 : 1)
                            .animation(AppTheme.springAnimation, value: isSelected)
                            .onTapGesture {
                                AppTheme.haptic(.light)
                                toggle(zone.id)
                            }
                            .accessibilityLabel(zone.label)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .frame(height: 300)

            if !selectedLocations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedLocations.sorted(), id: \.self) { id in
                            Text(HeadPainRegions.label(for: id))
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.accentPrimary.opacity(0.12))
                                .foregroundStyle(AppTheme.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                Text("Tap areas on the head to mark pain locations")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedLocations.contains(id) {
            selectedLocations.remove(id)
        } else {
            selectedLocations.insert(id)
        }
    }
}

// MARK: - Head Outline
struct HeadSilhouetteShape: Shape {
    let side: HeadSide

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX

        switch side {
        case .front:
            return frontHeadPath(w: w, h: h, cx: cx)
        case .back:
            return backHeadPath(w: w, h: h, cx: cx)
        }
    }

    private func frontHeadPath(w: CGFloat, h: CGFloat, cx: CGFloat) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: cx, y: h * 0.04))
        path.addCurve(to: CGPoint(x: cx + w * 0.19, y: h * 0.25),
            control1: CGPoint(x: cx + w * 0.10, y: h * 0.04),
            control2: CGPoint(x: cx + w * 0.21, y: h * 0.12))
        path.addCurve(to: CGPoint(x: cx, y: h * 0.46),
            control1: CGPoint(x: cx + w * 0.21, y: h * 0.36),
            control2: CGPoint(x: cx + w * 0.10, y: h * 0.46))
        path.addCurve(to: CGPoint(x: cx - w * 0.19, y: h * 0.25),
            control1: CGPoint(x: cx - w * 0.10, y: h * 0.46),
            control2: CGPoint(x: cx - w * 0.21, y: h * 0.36))
        path.addCurve(to: CGPoint(x: cx, y: h * 0.04),
            control1: CGPoint(x: cx - w * 0.21, y: h * 0.12),
            control2: CGPoint(x: cx - w * 0.10, y: h * 0.04))
        path.closeSubpath()

        // Neck
        path.move(to: CGPoint(x: cx - w * 0.05, y: h * 0.45))
        path.addCurve(to: CGPoint(x: cx - w * 0.08, y: h * 0.59),
            control1: CGPoint(x: cx - w * 0.05, y: h * 0.52),
            control2: CGPoint(x: cx - w * 0.08, y: h * 0.55))
        path.addLine(to: CGPoint(x: cx + w * 0.08, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx + w * 0.05, y: h * 0.45),
            control1: CGPoint(x: cx + w * 0.08, y: h * 0.55),
            control2: CGPoint(x: cx + w * 0.05, y: h * 0.52))
        path.closeSubpath()

        return path
    }

    private func backHeadPath(w: CGFloat, h: CGFloat, cx: CGFloat) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: cx, y: h * 0.04))
        path.addCurve(to: CGPoint(x: cx + w * 0.18, y: h * 0.25),
            control1: CGPoint(x: cx + w * 0.09, y: h * 0.04),
            control2: CGPoint(x: cx + w * 0.20, y: h * 0.12))
        path.addCurve(to: CGPoint(x: cx, y: h * 0.46),
            control1: CGPoint(x: cx + w * 0.20, y: h * 0.36),
            control2: CGPoint(x: cx + w * 0.09, y: h * 0.46))
        path.addCurve(to: CGPoint(x: cx - w * 0.18, y: h * 0.25),
            control1: CGPoint(x: cx - w * 0.09, y: h * 0.46),
            control2: CGPoint(x: cx - w * 0.20, y: h * 0.36))
        path.addCurve(to: CGPoint(x: cx, y: h * 0.04),
            control1: CGPoint(x: cx - w * 0.20, y: h * 0.12),
            control2: CGPoint(x: cx - w * 0.09, y: h * 0.04))
        path.closeSubpath()

        // Neck – slightly wider than front
        path.move(to: CGPoint(x: cx - w * 0.07, y: h * 0.45))
        path.addCurve(to: CGPoint(x: cx - w * 0.10, y: h * 0.59),
            control1: CGPoint(x: cx - w * 0.07, y: h * 0.52),
            control2: CGPoint(x: cx - w * 0.10, y: h * 0.55))
        path.addLine(to: CGPoint(x: cx + w * 0.10, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx + w * 0.07, y: h * 0.45),
            control1: CGPoint(x: cx + w * 0.10, y: h * 0.55),
            control2: CGPoint(x: cx + w * 0.07, y: h * 0.52))
        path.closeSubpath()

        return path
    }
}

// MARK: - Facial Features (airline safety demo style)
struct HeadFeaturesShape: Shape {
    let side: HeadSide

    func path(in rect: CGRect) -> Path {
        switch side {
        case .front:
            return frontFeatures(w: rect.width, h: rect.height, cx: rect.midX)
        case .back:
            return backFeatures(w: rect.width, h: rect.height, cx: rect.midX)
        }
    }

    private func frontFeatures(w: CGFloat, h: CGFloat, cx: CGFloat) -> Path {
        var path = Path()

        // ---- Ears ----
        path.move(to: CGPoint(x: cx - w * 0.215, y: h * 0.20))
        path.addCurve(to: CGPoint(x: cx - w * 0.235, y: h * 0.25),
            control1: CGPoint(x: cx - w * 0.230, y: h * 0.20),
            control2: CGPoint(x: cx - w * 0.245, y: h * 0.22))
        path.addCurve(to: CGPoint(x: cx - w * 0.215, y: h * 0.30),
            control1: CGPoint(x: cx - w * 0.230, y: h * 0.28),
            control2: CGPoint(x: cx - w * 0.225, y: h * 0.30))
        path.move(to: CGPoint(x: cx - w * 0.225, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.228, y: h * 0.25),
            control: CGPoint(x: cx - w * 0.232, y: h * 0.23))

        // Right ear
        path.move(to: CGPoint(x: cx + w * 0.215, y: h * 0.20))
        path.addCurve(to: CGPoint(x: cx + w * 0.235, y: h * 0.25),
            control1: CGPoint(x: cx + w * 0.230, y: h * 0.20),
            control2: CGPoint(x: cx + w * 0.245, y: h * 0.22))
        path.addCurve(to: CGPoint(x: cx + w * 0.215, y: h * 0.30),
            control1: CGPoint(x: cx + w * 0.230, y: h * 0.28),
            control2: CGPoint(x: cx + w * 0.225, y: h * 0.30))
        path.move(to: CGPoint(x: cx + w * 0.225, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.228, y: h * 0.25),
            control: CGPoint(x: cx + w * 0.232, y: h * 0.23))

        // ---- Eyebrows ----
        path.move(to: CGPoint(x: cx - w * 0.14, y: h * 0.16))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.02, y: h * 0.15),
            control: CGPoint(x: cx - w * 0.08, y: h * 0.14))
        path.move(to: CGPoint(x: cx + w * 0.14, y: h * 0.16))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.02, y: h * 0.15),
            control: CGPoint(x: cx + w * 0.08, y: h * 0.14))

        // ---- Eyes (almond shapes) ----
        path.move(to: CGPoint(x: cx - w * 0.11, y: h * 0.19))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.03, y: h * 0.19),
            control: CGPoint(x: cx - w * 0.07, y: h * 0.17))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.11, y: h * 0.19),
            control: CGPoint(x: cx - w * 0.07, y: h * 0.21))
        path.move(to: CGPoint(x: cx + w * 0.11, y: h * 0.19))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.03, y: h * 0.19),
            control: CGPoint(x: cx + w * 0.07, y: h * 0.17))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.11, y: h * 0.19),
            control: CGPoint(x: cx + w * 0.07, y: h * 0.21))

        // ---- Nose bridge ----
        path.move(to: CGPoint(x: cx - w * 0.025, y: h * 0.17))
        path.addLine(to: CGPoint(x: cx - w * 0.02, y: h * 0.30))
        path.addLine(to: CGPoint(x: cx - w * 0.025, y: h * 0.32))
        path.move(to: CGPoint(x: cx + w * 0.025, y: h * 0.17))
        path.addLine(to: CGPoint(x: cx + w * 0.02, y: h * 0.30))
        path.addLine(to: CGPoint(x: cx + w * 0.025, y: h * 0.32))
        path.move(to: CGPoint(x: cx, y: h * 0.18))
        path.addLine(to: CGPoint(x: cx, y: h * 0.33))
        // Nostril flares
        path.move(to: CGPoint(x: cx - w * 0.04, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.01, y: h * 0.36),
            control: CGPoint(x: cx - w * 0.025, y: h * 0.355))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.035, y: h * 0.365),
            control: CGPoint(x: cx - w * 0.015, y: h * 0.365))
        path.move(to: CGPoint(x: cx + w * 0.04, y: h * 0.35))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.01, y: h * 0.36),
            control: CGPoint(x: cx + w * 0.025, y: h * 0.355))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.035, y: h * 0.365),
            control: CGPoint(x: cx + w * 0.015, y: h * 0.365))
        path.move(to: CGPoint(x: cx - w * 0.035, y: h * 0.365))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.035, y: h * 0.365),
            control: CGPoint(x: cx, y: h * 0.355))

        // ---- Mouth ----
        path.move(to: CGPoint(x: cx - w * 0.07, y: h * 0.40))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.07, y: h * 0.40),
            control: CGPoint(x: cx, y: h * 0.425))
        path.move(to: CGPoint(x: cx - w * 0.055, y: h * 0.40))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.055, y: h * 0.40),
            control: CGPoint(x: cx, y: h * 0.38))

        // ---- Jawline (strong angular) ----
        path.move(to: CGPoint(x: cx + w * 0.19, y: h * 0.34))
        path.addLine(to: CGPoint(x: cx + w * 0.14, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx + w * 0.05, y: h * 0.45))
        path.move(to: CGPoint(x: cx - w * 0.19, y: h * 0.34))
        path.addLine(to: CGPoint(x: cx - w * 0.14, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx - w * 0.05, y: h * 0.45))

        // ---- Cheekbone contours ----
        path.move(to: CGPoint(x: cx + w * 0.18, y: h * 0.29))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.08, y: h * 0.31),
            control: CGPoint(x: cx + w * 0.13, y: h * 0.27))
        path.move(to: CGPoint(x: cx - w * 0.18, y: h * 0.29))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.08, y: h * 0.31),
            control: CGPoint(x: cx - w * 0.13, y: h * 0.27))

        // ---- Forehead contour ----
        path.move(to: CGPoint(x: cx - w * 0.12, y: h * 0.08))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.12, y: h * 0.08),
            control: CGPoint(x: cx, y: h * 0.06))

        // ---- Hairline ----
        path.move(to: CGPoint(x: cx - w * 0.15, y: h * 0.06))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.15, y: h * 0.06),
            control: CGPoint(x: cx, y: h * 0.03))

        // ---- Chin/neck fold ----
        path.move(to: CGPoint(x: cx - w * 0.05, y: h * 0.46))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.05, y: h * 0.46),
            control: CGPoint(x: cx, y: h * 0.48))

        // ---- Shoulders ----
        path.move(to: CGPoint(x: cx - w * 0.08, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx - w * 0.28, y: h * 0.52),
            control1: CGPoint(x: cx - w * 0.14, y: h * 0.59),
            control2: CGPoint(x: cx - w * 0.22, y: h * 0.57))
        path.move(to: CGPoint(x: cx + w * 0.08, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx + w * 0.28, y: h * 0.52),
            control1: CGPoint(x: cx + w * 0.14, y: h * 0.59),
            control2: CGPoint(x: cx + w * 0.22, y: h * 0.57))

        return path
    }

    private func backFeatures(w: CGFloat, h: CGFloat, cx: CGFloat) -> Path {
        var path = Path()

        // ---- Ears ----
        path.move(to: CGPoint(x: cx - w * 0.20, y: h * 0.20))
        path.addCurve(to: CGPoint(x: cx - w * 0.215, y: h * 0.25),
            control1: CGPoint(x: cx - w * 0.212, y: h * 0.20),
            control2: CGPoint(x: cx - w * 0.225, y: h * 0.22))
        path.addCurve(to: CGPoint(x: cx - w * 0.20, y: h * 0.30),
            control1: CGPoint(x: cx - w * 0.212, y: h * 0.28),
            control2: CGPoint(x: cx - w * 0.208, y: h * 0.30))
        path.move(to: CGPoint(x: cx - w * 0.207, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.210, y: h * 0.25),
            control: CGPoint(x: cx - w * 0.214, y: h * 0.23))

        path.move(to: CGPoint(x: cx + w * 0.20, y: h * 0.20))
        path.addCurve(to: CGPoint(x: cx + w * 0.215, y: h * 0.25),
            control1: CGPoint(x: cx + w * 0.212, y: h * 0.20),
            control2: CGPoint(x: cx + w * 0.225, y: h * 0.22))
        path.addCurve(to: CGPoint(x: cx + w * 0.20, y: h * 0.30),
            control1: CGPoint(x: cx + w * 0.212, y: h * 0.28),
            control2: CGPoint(x: cx + w * 0.208, y: h * 0.30))
        path.move(to: CGPoint(x: cx + w * 0.207, y: h * 0.22))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.210, y: h * 0.25),
            control: CGPoint(x: cx + w * 0.214, y: h * 0.23))

        // ---- Back of head / occipital contour ----
        path.move(to: CGPoint(x: cx - w * 0.13, y: h * 0.08))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.13, y: h * 0.08),
            control: CGPoint(x: cx, y: h * 0.04))
        path.move(to: CGPoint(x: cx - w * 0.10, y: h * 0.30))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.10, y: h * 0.30),
            control: CGPoint(x: cx, y: h * 0.27))

        // ---- Spine / nape ----
        path.move(to: CGPoint(x: cx, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx, y: h * 0.56))

        // ---- Shoulders ----
        path.move(to: CGPoint(x: cx - w * 0.10, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx - w * 0.30, y: h * 0.52),
            control1: CGPoint(x: cx - w * 0.16, y: h * 0.59),
            control2: CGPoint(x: cx - w * 0.24, y: h * 0.57))
        path.move(to: CGPoint(x: cx + w * 0.10, y: h * 0.59))
        path.addCurve(to: CGPoint(x: cx + w * 0.30, y: h * 0.52),
            control1: CGPoint(x: cx + w * 0.16, y: h * 0.59),
            control2: CGPoint(x: cx + w * 0.24, y: h * 0.57))

        return path
    }
}
