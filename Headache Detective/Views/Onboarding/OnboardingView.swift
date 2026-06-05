import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false
    @EnvironmentObject private var purchaseManager: PurchaseManager

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
        ),
        OnboardingPage(
            icon: "heart.fill",
            iconColor: .red,
            title: "Integrated with Apple Health",
            subtitle: "Your entries sync directly to the Health app.",
            description: "Every headache you log is automatically saved to Apple Health as a headache sample. Your data stays private and works alongside your other health metrics."
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
            PaywallView(dismissDelay: 12)
                .environmentObject(purchaseManager)
        }
        .onChange(of: showPaywall) { showing in
            if !showing {
                isComplete = false
            }
        }
        .task {
            await purchaseManager.loadOfferings()
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                isComplete = false
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

#Preview("Onboarding") {
    OnboardingView(isComplete: .constant(false))
}
