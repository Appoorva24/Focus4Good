import Foundation
import Supabase
import AuthenticationServices
import CryptoKit
import Auth

@MainActor
@Observable
class UserStore {
    
    // MARK: - State
    var currentUser: User?
    var userSettings: UserSettings?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var showNewUserBonusPopup = false
    /// Raw nonce for Apple Sign-In verification
    private var currentNonce: String?
    var isSessionReady = false
    var hasMfaEnabled = false
    var isMfaRequired = false
    var currentMfaFactorId: String?

    
    static let shared = UserStore()
    
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    init() {
        Task {
            await self.checkExistingSession()
        }
    }
    
    // MARK: - Session Check
    func checkExistingSession() async {
        isLoading = true
        do {
            let session = try await client.auth.session
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            if currentUser != nil {
                isAuthenticated = true
                await loadUserData(userId: userId)
            } else {
                isAuthenticated = false
                currentUser = nil
            }
        } catch {
            print("No active auth session: \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
        }
        isSessionReady = true
        isLoading = false
    }
    
    // MARK: - Auth
    func signUp(fullName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Create the auth account
            let _ = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]  // passed to trigger
            )
            
            let session = try await client.auth.session
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            
            isAuthenticated = true
            isMfaRequired = false
            await loadUserData(userId: userId)
            
            // TEMPORARILY DISABLED 2FA
            // self.isMfaRequired = true
            // self.isLoading = false
            // 
            // // Call Edge Function to send OTP
            // _ = try await client.functions.invoke(
            //     "send-otp",
            //     options: .init(body: ["email": email])
            // )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let _ = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            let session = try await client.auth.session
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            
            isAuthenticated = true
            isMfaRequired = false
            await loadUserData(userId: userId)
            
        } catch {
            print("⚠️ Sign-in error: \(error)")
            let msg = error.localizedDescription.lowercased()
            if msg.contains("invalid login") || msg.contains("invalid credentials") || msg.contains("wrong password") || msg.contains("email not found") {
                errorMessage = "Invalid email or password."
            } else if msg.contains("email not confirmed") || msg.contains("not confirmed") {
                errorMessage = "Please verify your email address before signing in. Check your inbox for a confirmation link."
            } else if msg.contains("rate limit") || msg.contains("too many") {
                errorMessage = "Too many sign-in attempts. Please wait a few minutes and try again."
            } else if msg.contains("network") || msg.contains("connection") || msg.contains("offline") || msg.contains("url session") {
                errorMessage = "Network error. Please check your connection and try again."
            } else if msg.contains("user not found") {
                errorMessage = "No account found with this email. Please sign up first."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
    
    // MARK: - Apple Sign-In
    
    /// Generates a cryptographic nonce for Apple Sign-In.
    /// Returns the SHA256 hash to pass to the ASAuthorizationAppleIDRequest.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    /// Handles the Apple Sign-In credential after successful authorization.
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            errorMessage = "Apple Sign-In failed: could not retrieve credentials."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            await loadUserData(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        currentNonce = nil
    }
    
    // MARK: - Google Sign-In (Supabase OAuth)
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "focus4good://login-callback")
            )
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            isAuthenticated = true
            await loadUserData(userId: userId)
        } catch {
            // Don't show error when user cancels the web auth session
            if let sessionError = error as? ASWebAuthenticationSessionError,
               sessionError.code == .canceledLogin {
                // User cancelled — no error to display
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
    
    func signOut() {
        let leavingUserId = currentUser?.id
        // Stop any active audio playback
        ASMRAudioService.shared.stop()
        // Sign out from Supabase (fire-and-forget is fine — we clear local state immediately)
        Task { try? await client.auth.signOut() }
        // Clear auth state
        currentUser = nil
        userSettings = nil
        isAuthenticated = false
        isLoading = false
        errorMessage = nil
        isMfaRequired = false
        // Clear ALL in-memory store data
        TaskStore.shared.clearData(for: leavingUserId)
        ProgressStore.shared.clearData()
        CommunityStore.shared.clearData()
        CalmCentreStore.shared.clearData()
        VolunteerStore.shared.clearData()
        // Cancel pending notifications
        NotificationManager.shared.cancelAllNotifications()
    }
    
    // MARK: - Password Reset
    func sendPasswordResetEmail(email: String) async throws {
        // For OTP-based password reset, we do NOT pass redirectTo.
        // Passing a custom URL scheme (e.g. focus4good://) causes Supabase's
        // email service to reject the request with "Error sending recovery email".
        // redirectTo is only needed for magic-link (non-OTP) mode.
        try await client.auth.resetPasswordForEmail(email)
    }
    
    func verifyPasswordResetOTP(email: String, code: String) async throws {
        _ = try await client.auth.verifyOTP(email: email, token: code, type: .recovery)
    }
    
    func updateUserPassword(newPassword: String) async throws {
        _ = try await client.auth.update(user: UserAttributes(password: newPassword))
    }
    // MARK: - Email 2FA Methods
    
    func verifyLoginMFA(email: String, code: String) async {
        isLoading = true
        errorMessage = nil
        do {
            // Call Edge Function to verify OTP
            _ = try await client.functions.invoke(
                "verify-otp",
                options: .init(body: ["email": email, "otp": code])
            )
            
            let session = try await client.auth.session
            let userId = session.user.id
            await fetchCurrentUser(userId: userId)
            
            isAuthenticated = true
            isMfaRequired = false
            await loadUserData(userId: userId)
        } catch {
            errorMessage = "Invalid or expired OTP."
        }
        isLoading = false
    }

    // MARK: - Bulk data load (called after every auth)
    private func loadUserData(userId: UUID) async {
        // Fetch tasks first since completions depend on task IDs
        await TaskStore.shared.fetchTasks(userId: userId)
        await TaskStore.shared.fetchTaskCompletions(userId: userId)
        
        async let progress: ()    = ProgressStore.shared.fetchProgress(userId: userId)
        async let communities: () = CommunityStore.shared.fetchCommunities()
        async let categories: ()  = CommunityStore.shared.fetchCommunityCategories()
        async let ngos: ()        = VolunteerStore.shared.fetchNGOs()
        async let events: ()      = VolunteerStore.shared.fetchVolunteerEvents()
        async let regs: ()        = VolunteerStore.shared.fetchRegistrations(userId: userId)
        async let breathing: ()   = CalmCentreStore.shared.fetchBreathingSessions(userId: userId)
        async let jpmr: ()        = CalmCentreStore.shared.fetchJpmrSessions(userId: userId)
        async let meditation: ()  = CalmCentreStore.shared.fetchGuidedMeditationSessions(userId: userId)
        async let asmrFavs: ()    = CalmCentreStore.shared.fetchFavouriteAsmrSounds(userId: userId)
        async let folders: ()     = CalmCentreStore.shared.fetchBrainDumpFolders(userId: userId)
        async let entries: ()     = CalmCentreStore.shared.fetchBrainDumpEntries(userId: userId)
        _ = await (progress, communities, categories, ngos, events, regs, breathing, jpmr, meditation, asmrFavs, folders, entries)
        
        // Ensure default community and posts exist
        await CommunityStore.shared.seedSondharaCommunityIfNeeded(userId: userId)
    }
    
    // MARK: - Profile CRUD
    func fetchCurrentUser(userId: UUID) async {
        isLoading = true
        do {
            let user: User = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentUser = user
        } catch {
            print("Profile fetch error, using fallback for \(userId): \(error)")
            let sessionUser = try? await client.auth.session.user
            let email = sessionUser?.email ?? ""
            let name = (sessionUser?.userMetadata["full_name"] as? String) ?? email.components(separatedBy: "@").first ?? "User"
            let newUser = User(
                id: userId,
                fullName: name.capitalized,
                email: email,
                profileImageUrl: nil,
                authProvider: "email",
                focusPoints: 0,
                currentLevel: 1,
                bestStreak: 0,
                currentStreak: 0
            )
            currentUser = newUser
            Task {
                try? await client.from("profiles").insert(newUser).execute()
            }
        }
        isLoading = false
    }
    
    func updateProfile(fullName: String, profileImageUrl: String?) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await client
                .from("profiles")
                .update([
                    "full_name": fullName,
                    "profile_image_url": profileImageUrl ?? ""
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Update local state
            currentUser?.fullName = fullName
            currentUser?.profileImageUrl = profileImageUrl
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateFocusPoints(by amount: Int) async {
        guard var user = currentUser else { return }
        let newPoints = max(0, user.focusPoints + amount)
        user.focusPoints = newPoints
        currentUser = user
        UserDefaults.standard.set(newPoints, forKey: "user_focus_points_\(user.id.uuidString)")
        print("⭐️ Focus points updated: \(newPoints) (delta: \(amount))")
        
        do {
            try await client
                .from("profiles")
                .update(["focus_points": newPoints])
                .eq("id", value: user.id.uuidString)
                .execute()
        } catch {
            print("⚠️ Supabase sync updateFocusPoints: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Focus Points Donation
    
    /// Total points donated across all time (persisted locally)
    var totalPointsDonated: Int {
        get { UserDefaults.standard.integer(forKey: "totalPointsDonated_\(currentUser?.id.uuidString ?? "")") }
        set { UserDefaults.standard.set(newValue, forKey: "totalPointsDonated_\(currentUser?.id.uuidString ?? "")") }
    }
    
    /// Donation history (persisted locally as JSON)
    var donationHistory: [DonationRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: "donationHistory_\(currentUser?.id.uuidString ?? "")") else { return [] }
            return (try? JSONDecoder().decode([DonationRecord].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "donationHistory_\(currentUser?.id.uuidString ?? "")")
            }
        }
    }
    
    /// Donate focus points toward an impact goal. Returns true on success.
    @discardableResult
    func donatePoints(for goal: ImpactGoal) async -> Bool {
        guard let user = currentUser, user.focusPoints >= goal.pointsCost else {
            errorMessage = "Not enough Focus Points"
            return false
        }
        
        // Deduct points
        await updateFocusPoints(by: -goal.pointsCost)
        
        // Track donation
        totalPointsDonated += goal.pointsCost
        let record = DonationRecord(goalTitle: goal.title, pointsSpent: goal.pointsCost, date: Date())
        donationHistory = [record] + donationHistory
        
        // Send Thank You Email asynchronously
        Task {
            await EmailService.shared.sendDonationThankYouEmail(
                to: user.email,
                userName: user.fullName,
                points: goal.pointsCost,
                ngoName: "Sondhara Welfare and Trust"
            )
        }
        
        return true
    }
    
    func calculateStreak(from completionDates: Set<String>) -> (current: Int, best: Int) {
        guard !completionDates.isEmpty else { return (0, 0) }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var currentStreak = 0
        var checkDate = today
        let todayStr = formatter.string(from: today)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let yesterdayStr = formatter.string(from: yesterday)

        if completionDates.contains(todayStr) {
            checkDate = today
        } else if completionDates.contains(yesterdayStr) {
            checkDate = yesterday
        } else {
            return (0, calculateBestStreak(from: completionDates, formatter: formatter, cal: cal))
        }

        while completionDates.contains(formatter.string(from: checkDate)) {
            currentStreak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        let bestStreak = max(currentStreak, calculateBestStreak(from: completionDates, formatter: formatter, cal: cal))
        return (currentStreak, bestStreak)
    }

    private func calculateBestStreak(from completionDates: Set<String>, formatter: DateFormatter, cal: Calendar) -> Int {
        let dates = completionDates.compactMap { formatter.date(from: $0) }.map { cal.startOfDay(for: $0) }.sorted()
        var bestStreak = 0
        var runningStreak = 0
        var prevDate: Date? = nil

        for d in dates {
            if let p = prevDate {
                let diff = cal.dateComponents([.day], from: p, to: d).day ?? 0
                if diff == 1 {
                    runningStreak += 1
                } else if diff > 1 {
                    runningStreak = 1
                }
            } else {
                runningStreak = 1
            }
            prevDate = d
            bestStreak = max(bestStreak, runningStreak)
        }
        return bestStreak
    }

    func updateStreakFromCompletions(_ completionDates: Set<String>) async {
        let (current, best) = calculateStreak(from: completionDates)
        guard var user = currentUser else { return }
        if user.currentStreak != current || user.bestStreak != best {
            user.currentStreak = current
            user.bestStreak = max(user.bestStreak, best)
            currentUser = user
            UserDefaults.standard.set(user.currentStreak, forKey: "user_current_streak_\(user.id.uuidString)")
            UserDefaults.standard.set(user.bestStreak, forKey: "user_best_streak_\(user.id.uuidString)")
            
            do {
                try await client
                    .from("profiles")
                    .update(["current_streak": current, "best_streak": user.bestStreak])
                    .eq("id", value: user.id.uuidString)
                    .execute()
            } catch {
                print("⚠️ Supabase sync streak error: \(error.localizedDescription)")
            }
        }
    }

    func updateStreak(newStreak: Int) async {
        guard var user = currentUser else { return }
        do {
            var updates: [String: Int] = ["current_streak": newStreak]
            if newStreak > user.bestStreak {
                updates["best_streak"] = newStreak
            }
            try await client
                .from("profiles")
                .update(updates)
                .eq("id", value: user.id.uuidString)
                .execute()
            user.currentStreak = newStreak
            if newStreak > user.bestStreak { user.bestStreak = newStreak }
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateLevel(to level: Int) async {
        guard var user = currentUser else { return }
        do {
            try await client
                .from("profiles")
                .update(["current_level": level])
                .eq("id", value: user.id.uuidString)
                .execute()
            user.currentLevel = level
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Settings
    func fetchSettings() async {
        guard let userId = currentUser?.id else { return }
        isLoading = true
        do {
            let settings: [UserSettings] = try await client
                .from("user_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            userSettings = settings.first
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func updateSettings(_ settings: UserSettings) async {
        do {
            try await client
                .from("user_settings")
                .upsert(settings)
                .execute()
            userSettings = settings
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Nonce Helpers (Apple Sign-In)
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Email Service

class EmailService {
    static let shared = EmailService()
    
    // TODO: Replace these with your actual EmailJS credentials from https://www.emailjs.com/
    private let serviceId = "YOUR_SERVICE_ID"
    private let templateId = "YOUR_TEMPLATE_ID"
    private let publicKey = "YOUR_PUBLIC_KEY"
    
    private let endpoint = URL(string: "https://api.emailjs.com/api/v1.0/email/send")!
    
    private init() {}
    
    func sendDonationThankYouEmail(to email: String, userName: String, points: Int, ngoName: String) async {
        let payload: [String: Any] = [
            "service_id": serviceId,
            "template_id": templateId,
            "user_id": publicKey,
            "template_params": [
                "to_name": userName,
                "to_email": email,
                "points": points,
                "ngo_name": ngoName
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Email sent successfully to \(email)")
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? ""
                print("❌ Failed to send email. Response: \(responseString)")
            }
        } catch {
            print("❌ Failed to send email. Error: \(error.localizedDescription)")
        }
    }
}
