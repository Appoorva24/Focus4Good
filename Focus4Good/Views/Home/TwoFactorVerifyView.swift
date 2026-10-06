import SwiftUI

struct TwoFactorVerifyView: View {
    @Environment(UserStore.self) private var userStore
    @State private var code: String = ""
    var email: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 40)
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(AppTheme.orange)
                    .padding(.bottom, 8)
                
                Text("Two-Factor Authentication")
                    .font(.title2.bold())
                
                Text("Enter the 6-digit code sent to your email to continue.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                TextField("000000", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(.title, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 48)
                
                if let error = userStore.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            
            Button {
                Task {
                    await userStore.verifyLoginMFA(email: email, code: code)
                }
            } label: {
                Group {
                    if userStore.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify Code")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule().fill(code.count == 6 ? AppTheme.orange : AppTheme.orange.opacity(0.4))
                )
            }
            .disabled(code.count != 6 || userStore.isLoading)
            .padding(.horizontal, 24)
            
            Button("Cancel") {
                // Return to normal sign in
                userStore.isMfaRequired = false
                userStore.currentMfaFactorId = nil
                userStore.signOut()
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}
