import SwiftUI

// MARK: - SplashView
// Premium splash screen with animated gradient background,
// glowing logo halo, and typewriter tagline reveal.

struct SplashView: View {
    let onFinished: () -> Void

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var bounce: Bool = false
    @State private var taglineOpacity: Double = 0
    @State private var haloScale: CGFloat = 0.8
    @State private var haloOpacity: Double = 0
    @State private var gradientShift: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // ── Animated gradient background ──────────────────
            animatedBackground

            // ── Floating bokeh particles ──────────────────────
            FloatingParticles()

            VStack(spacing: 28) {
                // ── Logo with glow halo ───────────────────────
                ZStack {
                    // Outer glow halo (subtle, so logo stays crisp)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.orange.opacity(0.12),
                                    AppTheme.orange.opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 130
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(haloScale)
                        .opacity(haloOpacity)

                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(bounce ? 1.04 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: bounce
                        )
                }

                // ── App name ──────────────────────────────────
                VStack(spacing: 8) {
                    Text("Focus4Good")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.orange, AppTheme.orangeDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Focus. Grow. Give Back.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                        .kerning(1.5)
                        .opacity(taglineOpacity)
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Logo entrance
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // Halo glow
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                haloScale = 1.0
                haloOpacity = 0.6
            }

            // Tagline fade in
            withAnimation(.easeIn(duration: 0.6).delay(0.6)) {
                taglineOpacity = 1.0
            }

            // Start bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                bounce = true
            }

            // Start gradient shift
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                gradientShift = true
            }

            // Transition out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onFinished()
            }
        }
    }

    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "1C1917"), Color(hex: "292524"), Color(hex: "1C1917")]
                    : [Color(hex: "FFFBEB"), Color(hex: "FFEDD5"), Color(hex: "FFF7E0")],
                startPoint: gradientShift ? .topLeading : .top,
                endPoint: gradientShift ? .bottomTrailing : .bottom
            )
            .ignoresSafeArea()

            // Soft orange radial glow at center
            RadialGradient(
                colors: [
                    AppTheme.orange.opacity(colorScheme == .dark ? 0.08 : 0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Floating Particles (Bokeh Effect)

private struct FloatingParticles: View {
    @State private var animate = false

    private let particles: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (0.15, 0.2, 6, 0.0),
        (0.8,  0.15, 4, 0.3),
        (0.25, 0.75, 5, 0.6),
        (0.7,  0.8, 3, 0.2),
        (0.5,  0.9, 4, 0.5),
        (0.9,  0.5, 5, 0.1),
        (0.1,  0.55, 3, 0.4),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particles.count, id: \.self) { i in
                let p = particles[i]
                Circle()
                    .fill(AppTheme.orange.opacity(0.15))
                    .frame(width: p.size, height: p.size)
                    .position(
                        x: geo.size.width * p.x,
                        y: geo.size.height * p.y + (animate ? -20 : 20)
                    )
                    .animation(
                        .easeInOut(duration: 3.0 + Double(i) * 0.3)
                            .repeatForever(autoreverses: true)
                            .delay(p.delay),
                        value: animate
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}
