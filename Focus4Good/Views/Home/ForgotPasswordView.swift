import SwiftUI

enum ForgotPasswordStep {
    case email
    case otp
    case newPassword
}

struct ForgotPasswordView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    
    /// Bound to AuthView so it can suppress the auth-state-change navigation
    /// while we're in the middle of the password-reset flow.
    @Binding var isInPasswordReset: Bool
    
    @State private var step: ForgotPasswordStep = .email
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundStyle(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    switch step {
                    case .email:
                        emailSection
                    case .otp:
                        otpSection
                    case .newPassword:
                        newPasswordSection
                    }
                    
                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Step 1: Email
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter your email address to receive a password reset code.")
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline.bold())
                
                TextField("name@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Button {
                Task {
                    await sendResetCode()
                }
            } label: {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Send Code")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background(Capsule().fill(email.isEmpty ? AppTheme.orange.opacity(0.4) : AppTheme.orange))
            .disabled(email.isEmpty || isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 2: OTP
    private var otpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter the 6-digit code sent to \(email)")
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Reset Code")
                    .font(.subheadline.bold())
                
                TextField("000000", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(.title, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Button {
                Task {
                    await verifyCode()
                }
            } label: {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Verify Code")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background(Capsule().fill(code.isEmpty ? AppTheme.orange.opacity(0.4) : AppTheme.orange))
            .disabled(code.isEmpty || isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Step 3: New Password
    private var newPasswordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter your new password below.")
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.subheadline.bold())
                    SecureField("At least 6 characters", text: $newPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline.bold())
                    SecureField("Confirm new password", text: $confirmPassword)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            Button {
                Task {
                    await updatePassword()
                }
            } label: {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Update Password")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(.white)
            .background(Capsule().fill(newPassword.isEmpty || newPassword != confirmPassword || newPassword.count < 6 ? AppTheme.orange.opacity(0.4) : AppTheme.orange))
            .disabled(newPassword.isEmpty || newPassword != confirmPassword || newPassword.count < 6 || isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Actions
    private func humanizedError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("rate limit") || msg.contains("too many") {
            return "Too many attempts. Please wait a few minutes before trying again."
        } else if msg.contains("error sending recovery") || msg.contains("sending recovery email") {
            return "Could not send reset email. Please check your email address and try again in a few minutes."
        } else if msg.contains("invalid") && msg.contains("email") {
            return "Please enter a valid email address."
        } else if msg.contains("not found") || msg.contains("user not found") {
            return "No account found with that email address."
        } else if msg.contains("redirect") || msg.contains("redirect_to") {
            return "Configuration error. Please contact support."
        } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") {
            return "Network error. Please check your connection and try again."
        }
        return error.localizedDescription
    }
    
    private func sendResetCode() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await userStore.sendPasswordResetEmail(email: email)
            successMessage = "Code sent successfully!"
            step = .otp
        } catch {
            errorMessage = humanizedError(error)
        }
        isLoading = false
    }
    
    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await userStore.verifyPasswordResetOTP(email: email, code: code)
            // OTP verified — Supabase now signs in with a recovery session.
            // Keep isInPasswordReset = true so AuthView doesn't navigate away.
            isInPasswordReset = true
            successMessage = "Code verified. Please set your new password."
            step = .newPassword
        } catch {
            errorMessage = humanizedError(error)
        }
        isLoading = false
    }
    
    private func updatePassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await userStore.updateUserPassword(newPassword: newPassword)
            successMessage = "Password updated! Please sign in with your new password."
            // Wait briefly so user can read the message, then clean up
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            // Sign out the recovery session so the user must log in fresh
            userStore.signOut()
            isInPasswordReset = false
            dismiss()
        } catch {
            errorMessage = humanizedError(error)
        }
        isLoading = false
    }
}
