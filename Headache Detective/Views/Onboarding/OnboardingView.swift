import RevenueCat
import StoreKit
import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "bolt.fill",
            iconColor: AppTheme.accentPrimary,
            title: "Log in Seconds",
            subtitle: "Tap a pain level to instantly log your headache. No forms, no fuss.",
            description: "Quick Log lets you record a headache in one tap. Add details later when you have more time."
        ),
        OnboardingPage(
            icon: "list.clipboard.fill",
            iconColor: AppTheme.accentTertiary,
            title: "Track Everything",
            subtitle: "Record triggers, locations, symptoms, medications, and relief methods.",
            description: "Know what caused it and what helped. Every detail matters for understanding your headaches."
        ),
        OnboardingPage(
            icon: "calendar",
            iconColor: AppTheme.moderateYellow,
            title: "See Your Patterns",
            subtitle: "A color-coded calendar shows your headache days at a glance.",
            description: "Spot trends over weeks and months. See how your headache frequency changes over time."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            iconColor: AppTheme.severeRed,
            title: "Understand Your Triggers",
            subtitle: "Discover which days, times, and triggers are linked to your headaches.",
            description: "Powerful insights reveal your personal patterns — so you can take control."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                skipButton
                tabView
                pageIndicators
                continueButton
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isComplete: $isComplete)
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                showPaywall = true
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .opacity(currentPage < pages.count - 1 ? 1 : 0)
    }

    private var tabView: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { index in
                FeaturePageView(page: pages[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? AppTheme.accentPrimary : AppTheme.textTertiary.opacity(0.3))
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
                    .animation(AppTheme.springAnimation, value: currentPage)
            }
        }
        .padding(.bottom, 24)
    }

    private var continueButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation { currentPage += 1 }
            } else {
                showPaywall = true
            }
        } label: {
            Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 40)
        .shadow(color: AppTheme.accentPrimary.opacity(0.3), radius: 12, y: 6)
    }
}

// MARK: - Feature Page

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}

struct FeaturePageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 130, height: 130)

                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(page.iconColor)
            }
            .padding(.bottom, 48)

            Text(page.title)
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 12)

            Text(page.subtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(AppTheme.accentPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            Text(page.description)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Paywall View

struct PaywallView: View {
    @Binding var isComplete: Bool
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedPackage: Package?
    @State private var purchaseError: String?

    private let features: [(icon: String, text: String)] = [
        ("bolt.fill", "Unlimited quick logging"),
        ("clock", "Full timing controls"),
        ("calendar", "Calendar view with patterns"),
        ("chart.bar.fill", "Advanced insights & analytics"),
        ("square.and.arrow.up", "CSV data export"),
        ("square.grid.2x2", "Widget & Siri support"),
        ("heart.fill", "HealthKit integration"),
        ("icloud.fill", "iCloud sync across devices")
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
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accentPrimary)
                .padding(.top, 60)
                .padding(.bottom, 16)

            Text("Unlock Full Access")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Get the complete headache tracking experience")
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
                    isComplete = false
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
                    if restored {
                        isComplete = false
                    } else {
                        purchaseError = "No purchases were found to restore."
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 4) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://www.revenuecat.com/terms") {
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

#Preview("Onboarding") {
    OnboardingView(isComplete: .constant(false))
}

#Preview("Paywall") {
    PaywallView(isComplete: .constant(false))
        .environmentObject(PurchaseManager.shared)
}
