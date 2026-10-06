import SwiftUI

// MARK: - AuthView

struct AuthView: View {
    @Environment(UserStore.self) private var userStore

    /// Called by Focus4GoodApp when authentication succeeds
    let onSuccess: () -> Void

    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    private var isFormValid: Bool {
        if isSignUp {
            return !fullName.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword
        } else {
            return !email.isEmpty && password.count >= 6
        }
    }

    var body: some View {
        ZStack {
            // ── Rich gradient background ─────────────────────
            AppTheme.pageGradient
                .ignoresSafeArea()

            if userStore.isMfaRequired {
                TwoFactorVerifyView(email: email)
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: 16)

                    // ── Logo / Header ─────────────────────────────
                    VStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)

                        Text("Focus4Good")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.orange, AppTheme.orangeDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }

                    Spacer(minLength: 20)

                    // ── Form Fields (native style) ───────────────
                    VStack(spacing: 0) {
                        if isSignUp {
                            AuthTextField(
                                icon: "person",
                                placeholder: "Full Name",
                                text: $fullName
                            )
                            Divider().padding(.leading, 48)
                        }

                        AuthTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        Divider().padding(.leading, 48)

                        AuthPasswordField(
                            placeholder: "Password",
                            text: $password,
                            showPassword: $showPassword
                        )

                        if isSignUp {
                            Divider().padding(.leading, 48)
                            AuthPasswordField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                showPassword: $showPassword
                            )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 24)



                    // ── Error Message ─────────────────────────────
                    if let error = userStore.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppTheme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 16)

                    // ── Submit Button (gradient) ─────────────────
                    Button {
                        Task {
                            if isSignUp {
                                await userStore.signUp(fullName: fullName, email: email, password: password)
                            } else {
                                await userStore.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if userStore.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule().fill(
                                isFormValid
                                    ? AnyShapeStyle(AppTheme.buttonGradient)
                                    : AnyShapeStyle(AppTheme.orange.opacity(0.3))
                            )
                        )
                        .shadow(color: isFormValid ? AppTheme.orange.opacity(0.3) : .clear, radius: 10, y: 4)
                    }
                    .disabled(!isFormValid || userStore.isLoading)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)

                    // ── Or Divider ───────────────────────────────
                    HStack(spacing: 12) {
                        Capsule()
                            .fill(AppTheme.warmTextSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .fixedSize()
                        Capsule()
                            .fill(AppTheme.warmTextSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)

                    // ── Google Sign-In ────────────────────────────
                    Button {
                        Task {
                            await userStore.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            GoogleGIcon()
                                .frame(width: 20, height: 20)
                            Text("Sign in with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .disabled(userStore.isLoading)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 12)

                    // ── Toggle Sign In / Sign Up ──────────────────
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSignUp.toggle()
                            fullName = ""
                            email = ""
                            password = ""
                            confirmPassword = ""
                            userStore.errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(AppTheme.warmTextSecondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.orange)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        // Watch for successful authentication → notify parent
        .onChange(of: userStore.isAuthenticated) { _, isAuth in
            if isAuth { onSuccess() }
        }
    }
}

// MARK: - Text Field Component

private struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .font(.system(size: 16))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .font(.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Password Field Component

private struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .font(.system(size: 16))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.body)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Google G Icon

private struct GoogleGIcon: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radius = min(w, h) / 2
            let innerRadius = radius * 0.55
            let thickness = radius - innerRadius

            // Blue arc (right + top-right)
            var bluePath = Path()
            bluePath.addArc(center: center, radius: radius, startAngle: .degrees(-45), endAngle: .degrees(10), clockwise: false)
            bluePath.addArc(center: center, radius: innerRadius, startAngle: .degrees(10), endAngle: .degrees(-45), clockwise: true)
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(Color(hex: "4285F4")))

            // Green arc (bottom-right)
            var greenPath = Path()
            greenPath.addArc(center: center, radius: radius, startAngle: .degrees(10), endAngle: .degrees(100), clockwise: false)
            greenPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(100), endAngle: .degrees(10), clockwise: true)
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(Color(hex: "34A853")))

            // Yellow arc (bottom-left)
            var yellowPath = Path()
            yellowPath.addArc(center: center, radius: radius, startAngle: .degrees(100), endAngle: .degrees(190), clockwise: false)
            yellowPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(190), endAngle: .degrees(100), clockwise: true)
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(Color(hex: "FBBC05")))

            // Red arc (top-left + left)
            var redPath = Path()
            redPath.addArc(center: center, radius: radius, startAngle: .degrees(190), endAngle: .degrees(315), clockwise: false)
            redPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(315), endAngle: .degrees(190), clockwise: true)
            redPath.closeSubpath()
            context.fill(redPath, with: .color(Color(hex: "EA4335")))

            // Horizontal bar (the crossbar of the G) — blue
            let barRect = CGRect(
                x: center.x - thickness * 0.1,
                y: center.y - thickness / 2,
                width: radius + thickness * 0.1,
                height: thickness
            )
            context.fill(Path(barRect), with: .color(Color(hex: "4285F4")))
        }
    }
}
