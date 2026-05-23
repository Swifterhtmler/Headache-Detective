import SwiftUI

enum AppTheme {
    // MARK: - Core Palette
    static let accentPrimary = Color(red: 0.55, green: 0.45, blue: 0.98)
    static let accentSecondary = Color(red: 0.95, green: 0.40, blue: 0.52)
    static let accentTertiary = Color(red: 0.30, green: 0.78, blue: 0.72)

    static let surfaceBackground = Color(red: 0.98, green: 0.97, blue: 0.97)
    static let cardBackground = Color.white
    static let groupedBackground = Color(red: 0.96, green: 0.95, blue: 0.94)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(red: 0.65, green: 0.64, blue: 0.64)

    // MARK: - Pain Colors
    static let mildGreen = Color(red: 0.35, green: 0.78, blue: 0.55)
    static let moderateYellow = Color(red: 0.95, green: 0.72, blue: 0.25)
    static let severeRed = Color(red: 0.88, green: 0.30, blue: 0.30)

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accentPrimary, accentSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradientVertical = LinearGradient(
        colors: [accentPrimary, accentSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Animation
    static let quickAnimation: Animation = .easeInOut(duration: 0.15)
    static let springAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.7)

    // MARK: - Layout
    static let sectionSpacing: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let innerCornerRadius: CGFloat = 12

    // MARK: - Shadows
    static let cardShadow = Shadow(
        color: Color.black.opacity(0.06),
        radius: 12,
        x: 0,
        y: 4
    )

    static let cardShadowSmall = Shadow(
        color: Color.black.opacity(0.04),
        radius: 6,
        x: 0,
        y: 2
    )

    // MARK: - Helpers
    static func painColor(level: Int) -> Color {
        PainSeverity.from(painLevel: level).color
    }

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Shadow Helper
struct Shadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}

extension View {
    func cardShadow() -> some View {
        modifier(AppTheme.cardShadow)
    }

    func cardShadowSmall() -> some View {
        modifier(AppTheme.cardShadowSmall)
    }
}

// MARK: - CardSection
struct CardSection<Content: View>: View {
    let title: String
    let icon: String?
    let subtitle: String?
    @ViewBuilder let content: Content

    init(_ title: String, icon: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.accentPrimary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accentPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .cardShadow()
    }
}

// MARK: - Divider
struct CardDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.textTertiary.opacity(0.2))
            .frame(height: 1)
    }
}
