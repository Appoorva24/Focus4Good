import SwiftUI

struct OnboardingView: View {
    // Called by Focus4GoodApp when the user finishes/skips onboarding
    let onComplete: () -> Void

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages = DummyData.onboardingPages

    var body: some View {
        ZStack(alignment: .top) {
            // ── Rich gradient background ─────────────────────
            AppTheme.pageGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Navigation bar ───────────────────────────────
                HStack {
                    // Back button
                    Button {
                        if currentPage > 0 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage -= 1 }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(currentPage > 0 ? 1 : 0)
                            )
                    }
                    .disabled(currentPage == 0)
                    .opacity(currentPage > 0 ? 1 : 0)

                    Spacer()

                    Button("Skip") {
                        markSeenAndComplete()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // ── Page content ─────────────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageContent(
                            page: pages[index],
                            pageIndex: index,
                            totalPages: pages.count,
                            currentPage: $currentPage,
                            onFinish: markSeenAndComplete
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }

    private func markSeenAndComplete() {
        hasSeenOnboarding = true
        onComplete()
    }
}

// MARK: - Single page content

private struct OnboardingPageContent: View {
    let page: (title: String, subtitle: String, imageName: String)
    let pageIndex: Int
    let totalPages: Int
    @Binding var currentPage: Int
    let onFinish: () -> Void

    @State private var imageAppeared = false

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                // ── Image area ───────────────────────────────────
                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 32)
                    .scaleEffect(imageAppeared ? 1.0 : 0.85)
                    .opacity(imageAppeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: imageAppeared)

                Spacer(minLength: 32)

                // ── Text area ────────────────────────────────────
                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.warmTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)

                    Text(page.subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 36)
                }

                Spacer(minLength: 28)

                // ── Animated pill indicator ──────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == pageIndex
                                  ? AppTheme.orange
                                  : AppTheme.orange.opacity(0.25))
                            .frame(width: index == pageIndex ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pageIndex)
                    }
                }
                .padding(.bottom, 32)

                // ── Gradient CTA button ──────────────────────────
                Button(action: handleNext) {
                    Text(pageIndex == totalPages - 1 ? "Get Started" : "Next")
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            imageAppeared = false
            withAnimation { imageAppeared = true }
        }
    }

    private func handleNext() {
        if pageIndex == totalPages - 1 {
            onFinish()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { currentPage += 1 }
        }
    }
}
