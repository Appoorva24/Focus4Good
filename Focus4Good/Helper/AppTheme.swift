import SwiftUI

// MARK: - App Theme — "Warm Earth"
//
// A rich, multi-color design system built around Deep Tangerine
// with Forest Sage and Deep Rose accents. Every color adapts
// gracefully between light and dark mode.

enum AppTheme {

    // ─── Primary Brand Colors ────────────────────────────────────

    /// Deep Tangerine — vibrant, punchy primary accent
    static let orange      = Color(hex: "F97316")
    /// Richer gradient end for buttons / rings
    static let orangeDeep  = Color(hex: "EA580C")
    /// Soft tint for icon backgrounds and subtle fills
    static let accentLight = Color(hex: "F97316").opacity(0.12)

    // ─── Secondary & Tertiary Accents ────────────────────────────

    /// Forest Sage — growth, calm, nature
    static let sage        = Color(hex: "22C55E")
    static let sageLight   = Color(hex: "22C55E").opacity(0.12)

    /// Deep Rose — warmth, energy, community
    static let rose        = Color(hex: "EC4899")
    static let roseLight   = Color(hex: "EC4899").opacity(0.12)

    /// Amber — warnings, streaks, rewards
    static let amber       = Color(hex: "F59E0B")
    static let amberLight  = Color(hex: "F59E0B").opacity(0.12)

    /// Sky — info, links, secondary actions
    static let sky         = Color(hex: "0EA5E9")
    static let skyLight    = Color(hex: "0EA5E9").opacity(0.12)

    // ─── Semantic Colors ─────────────────────────────────────────

    static let success     = Color(hex: "10B981")
    static let destructive = Color(hex: "EF4444")

    // ─── Text ────────────────────────────────────────────────────

    static let textPrimary   = Color(.label)
    static let textSecondary = Color(.secondaryLabel)

    
    /// Standard app-wide gradient using the brand accent
    static let appGradient = LinearGradient(
        colors: [
            Color(hex: "FFD5B3"), // Softer, lighter orange at the top
            Color(hex: "FFF2E6")  // Very pale cream orange at the bottom
            ],
        startPoint: .top, endPoint: .bottom
    )

    // ─── Layout ──────────────────────────────────────────────────

    static let cornerRadius: CGFloat = 20
    static let shadow = Color.black.opacity(0.08)

    // ─── Card Background (adapts to light / dark mode) ──────────

    static let cardBg = Color(.systemBackground)

    // ─── Gradient Backgrounds ────────────────────────────────────

    /// Page background gradient (top → bottom)
    static let pageBgTop = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x1C1917) : UIColor(hex6: 0xFFD5B3)
    })
    static let pageBgMid = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x211F1B) : UIColor(hex6: 0xFFE4CF)
    })
    static let pageBgBot = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x292524) : UIColor(hex6: 0xFFF2E6)
    })

    /// Card gradient end tint
    static let cardGradientEnd = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x2C2520) : UIColor(hex6: 0xFFF5EB)
    })

    /// Warm primary text (headings inside cards)
    static let warmTextPrimary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xF5E6D3) : UIColor(hex6: 0x44403C)
    })

    /// Warm secondary text (subtitles, captions)
    static let warmTextSecondary = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xC4A882) : UIColor(hex6: 0x78716C)
    })

    /// Card label text
    static let cardLabel = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0xD4BC9A) : UIColor(hex6: 0x78716C)
    })

    /// Thought card gradient
    static let thoughtCardStart = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x2A2218) : UIColor(hex6: 0xFFF8F0)
    })
    static let thoughtCardEnd = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark ? UIColor(hex6: 0x33291D) : UIColor(hex6: 0xFFEDD8)
    })

    // ─── Gradient Presets ────────────────────────────────────────

    /// Primary button gradient (tangerine)
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Standard app-wide gradient using the brand accent
//    static let appGradient = LinearGradient(
//        colors: [
//            Color(hex: "FDD2B1"), // Darker light orange at the top
//            Color(hex: "FFF4EC")  // Very light, soft orange at the bottom
//        ],
//        startPoint: .top,
//        endPoint: .bottom
//    )

    /// Warm page background gradient
    static let pageGradient = appGradient

    /// Timer ring gradient (multi-color arc)
    static let timerRingGradient = AngularGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EC4899"), Color(hex: "F59E0B"), Color(hex: "F97316")],
        center: .center
    )

    /// Success celebration gradient
    static let celebrationGradient = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "F97316"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Splash / onboarding gradient
    static let splashGradient = LinearGradient(
        colors: [
            Color(hex: "FFFBEB"),
            Color(hex: "FFF7E0"),
            Color(hex: "FFEDD5")
        ],
        startPoint: .top,
        endPoint: .bottom
    )


    static let splashGradientDark = LinearGradient(
        colors: [
            Color(hex: "1C1917"),
            Color(hex: "211F1B"),
            Color(hex: "292524")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(Color.white.opacity(0.85)) // Crisp, high-contrast base
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1) // Stronger border
            )
            .shadow(color: AppTheme.orange.opacity(0.12), radius: 15, x: 0, y: 6) // Warmer, more noticeable shadow
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Sharp inner shadow
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppTheme.buttonGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(gradient)
                    .shadow(color: AppTheme.orange.opacity(0.35), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 6)
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Staggered Fade-In Modifier

struct StaggeredFadeIn: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(index) * 0.08),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

extension View {
    func staggeredFadeIn(index: Int) -> some View {
        modifier(StaggeredFadeIn(index: index))
    }
}

// MARK: - UIColor Hex Helper

private extension UIColor {
    convenience init(hex6: UInt32) {
        self.init(
            red:   CGFloat((hex6 >> 16) & 0xFF) / 255,
            green: CGFloat((hex6 >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex6        & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
