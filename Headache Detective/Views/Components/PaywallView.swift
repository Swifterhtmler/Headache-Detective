import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedPackage: Package?
    @State private var purchaseError: String?
    @State private var dismissAllowed = false
    @State private var dismissProgress: CGFloat = 0

    private var dismissDelay: TimeInterval

    init(dismissDelay: TimeInterval = 0) {
        self.dismissDelay = dismissDelay
    }

    private let features: [(icon: String, text: String)] = [
        ("chart.bar.fill", "Advanced insights & analytics"),
        ("calendar.day.timeline.left", "Weekday & time-of-day patterns"),
        ("bolt.fill", "Top triggers ranked by frequency"),
        ("face.dashed", "Pain location hotspots"),
        ("chart.bar.xaxis", "Trigger impact on severity")
    ]

    private var packages: [Package] {
        purchaseManager.offerings?.current?.availablePackages ?? []
    }

    private var yearlyPackage: Package? {
        packages.first { $0.packageType == .annual }
    }

    private var monthlyPackage: Package? {
        packages.first { $0.packageType == .monthly }
    }

    var body: some View {
        ZStack {
            AppTheme.surfaceBackground.ignoresSafeArea()

            if !purchaseManager.hasLoadedOfferings {
                ProgressView()
                    .tint(AppTheme.accentPrimary)
                    .scaleEffect(1.2)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        featureList
                        pricingSection
                        trialButton
                        footnotes
                    }
                    .padding(.bottom, 32)
                }
            }

            if purchaseManager.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Completing your purchase...")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                        }
                    }
            }
        }
        .overlay(alignment: .topTrailing) {
            if dismissAllowed || dismissDelay == 0 {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                        .padding(20)
                }
                .transition(.opacity)
            } else {
                Circle()
                    .trim(from: 0, to: dismissProgress)
                    .stroke(AppTheme.textSecondary.opacity(0.5), lineWidth: 3)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                    .padding(20)
                    .transition(.opacity)
            }
        }
        .alert("Purchase Error", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK") { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
        .onAppear {
            if selectedPackage == nil {
                selectedPackage = yearlyPackage ?? monthlyPackage ?? packages.first
            }
            guard dismissDelay > 0 else { return }
            withAnimation(.linear(duration: dismissDelay)) {
                dismissProgress = 1
            }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(dismissDelay * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dismissAllowed = true
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accentPrimary)
                .padding(.top, 60)
                .padding(.bottom, 16)

            Text("Unlock Insights Pro")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Get powerful analytics to understand your headache patterns")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 32)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.text) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.accentTertiary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accentTertiary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(feature.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accentTertiary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 32)
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            Text("CHOOSE YOUR PLAN")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(2)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                if let yearly = yearlyPackage {
                    packageCard(package: yearly)
                }
                if let monthly = monthlyPackage {
                    packageCard(package: monthly)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }

    private func packageCard(package: Package, badge: String? = nil) -> some View {
        let isSelected = selectedPackage?.identifier == package.identifier
        let displayName: String = {
            switch package.packageType {
            case .lifetime: return "Lifetime"
            case .annual: return "Yearly"
            case .monthly: return "Monthly"
            default: return package.storeProduct.localizedTitle
            }
        }()

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedPackage = package
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.accentSecondary)
                                .clipShape(Capsule())
                        }
                        if package.packageType == .annual, let monthly = monthlyPackage {
                            let monthlyPrice = monthly.storeProduct.price
                            let yearlyPrice = package.storeProduct.price
                            if monthlyPrice != 0, let monthlyD = Double("\(monthlyPrice)"), let yearlyD = Double("\(yearlyPrice)") {
                                let discount = 1 - (yearlyD / (monthlyD * 12))
                                if discount > 0 {
                                    Text("Save \(Int(discount * 100))%")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.accentTertiary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Text(package.localizedPriceString)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.accentPrimary)

                    if package.packageType != .lifetime {
                        Text("/month")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentPrimary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppTheme.accentPrimary.opacity(0.08) : AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? AppTheme.accentPrimary : AppTheme.textTertiary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var trialButton: some View {
        Button {
            guard let package = selectedPackage else { return }
            Task {
                let success = await purchaseManager.purchase(package)
                if success {
                    dismiss()
                } else {
                    purchaseError = "The purchase could not be completed. Please try again."
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text("Continue")
                    .font(.headline.weight(.semibold))
                if let package = selectedPackage {
                    Text("\(package.localizedPriceString) · \(package.storeProduct.localizedTitle)")
                        .font(.caption)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .shadow(color: AppTheme.accentPrimary.opacity(0.3), radius: 12, y: 6)
        .padding(.bottom, 16)
        .opacity(selectedPackage != nil ? 1 : 0.5)
        .disabled(selectedPackage == nil)
    }

    private var footnotes: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task {
                    let restored = await purchaseManager.restore()
                    if !restored {
                        purchaseError = "No purchases were found to restore."
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 4) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }
                Text("·")
                    .foregroundStyle(AppTheme.textTertiary)
                Button("Privacy Policy") {
                    if let url = URL(string: "https://www.revenuecat.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.bottom, 8)
    }
}

#Preview("Paywall") {
    PaywallView()
        .environmentObject(PurchaseManager.shared)
}
