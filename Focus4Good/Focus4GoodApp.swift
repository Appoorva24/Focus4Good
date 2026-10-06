import SwiftUI

// MARK: - App State Machine

enum AppState {
    /// Logo splash screen (initial + post-auth)
    case splash
    /// Onboarding slides (first launch only)
    case onboarding
    /// Sign-in / Sign-up
    case auth
    /// Main tab bar
    case app
}

@main
struct Focus4GoodApp: App {

    // ── Persistent flags ────────────────────────────────────────────
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // ── Stores ──────────────────────────────────────────────────────
    @State private var userStore    = UserStore.shared
    @State private var taskStore    = TaskStore.shared
    @State private var volunteerStore = VolunteerStore.shared
    @State private var progressStore  = ProgressStore.shared
    @State private var calmCentreStore = CalmCentreStore.shared
    @State private var communityStore  = CommunityStore.shared

    // ── Navigation state ────────────────────────────────────────────
    @State private var appState: AppState = .splash
    
    // ── Scene phase (for re-engagement notifications) ───────────────
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState {

                case .splash:
                    SplashView {
                        handleSplashFinished()
                    }

                case .onboarding:
                    OnboardingView(onComplete: {
                        if userStore.isAuthenticated {
                            appState = .app
                        } else {
                            appState = .auth
                        }
                    })

                case .auth:
                    AuthView(onSuccess: {
                        appState = .app
                    })

                case .app:
                    MainTabView()
                }
            }
            .environment(userStore)
            .environment(taskStore)
            .environment(volunteerStore)
            .environment(progressStore)
            .environment(calmCentreStore)
            .environment(communityStore)
            .onAppear {
                // Request notification permission on first launch
                Task { _ = await NotificationManager.shared.requestPermission() }
            }
            .onChange(of: userStore.isAuthenticated) { _, isAuth in
                if !isAuth && appState == .app {
                    appState = .auth
                }
            }
            .preferredColorScheme(.light) // Force light mode
        }
        // ── Re-engagement notifications: schedule on background, cancel on active ──
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // User left the app — schedule catchy comeback notifications
                Task {
                    let streak = userStore.currentUser?.currentStreak ?? 0
                    let points = userStore.currentUser?.focusPoints ?? 0
                    let level  = userStore.currentUser?.currentLevel ?? 1
                    await NotificationManager.shared.scheduleReengagementNotifications(
                        streak: streak,
                        points: points,
                        level: level
                    )
                }
            case .active:
                // User is back — cancel any pending re-engagement notifications
                NotificationManager.shared.cancelReengagementNotifications()
            default:
                break
            }
        }
    }


    // MARK: - Helpers

    private func handleSplashFinished() {
        Task {
            await userStore.checkExistingSession()
            if !hasSeenOnboarding {
                appState = .onboarding
            } else if userStore.isAuthenticated {
                appState = .app
            } else {
                appState = .auth
            }
        }
    }
}

// MARK: - Main Tab View

enum AppTab: Hashable {
    case home, progress, calm, community
}

struct MainTabView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(CalmCentreStore.self) private var store
    @State private var selectedTab: AppTab = .home
    
    @AppStorage("unlockedBadgeIds") private var unlockedBadgeIdsRaw: String = "[]"
    @State private var newlyUnlockedBadge: ImpactBadge? = nil
    
    private var unlockedIds: Set<String> {
        get {
            guard let data = unlockedBadgeIdsRaw.data(using: .utf8),
                  let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else { return [] }
            return ids
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                unlockedBadgeIdsRaw = str
            }
        }
    }

    var audio = ASMRAudioService.shared

    var body: some View {
        @Bindable var bindableStore = store
        
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: .home) {
                    HomeView()
                }
                Tab("Calm", systemImage: "figure.mind.and.body", value: .calm) {
                    CalmCentreView()
                }
                Tab("Community", systemImage: "person.3.fill", value: .community) {
                    CommunityHome()
                }
                Tab("Progress", systemImage: "chart.bar.fill", value: .progress) {
                    ProgressTrackerView()
                }
            }
            .tint(AppTheme.orange)
            
            let shouldShowMiniPlayer = audio.currentSoundName != nil && audio.isPlaying && !audio.isDeepFocusSound
            
            if shouldShowMiniPlayer {
                ASMRMiniPlayerView()
                    .padding(.bottom, 64) // Push above the tab bar
            }
        }
        .animation(.easeInOut, value: audio.isPlaying)
        .sheet(isPresented: $bindableStore.showGlobalASMRPlayer) {
            if let activeSound = store.activeAsmrSound {
                NavigationStack {
                    ASMRPlayerView(sound: activeSound)
                }
            }
        }
        .onAppear { checkBadges() }
        .onChange(of: userStore.totalPointsDonated) { _, _ in checkBadges() }
        .onChange(of: userStore.donationHistory.count) { _, _ in checkBadges() }
        .onChange(of: userStore.currentUser?.bestStreak) { _, _ in checkBadges() }
        .onChange(of: volunteerStore.volunteerRegistrations.count) { _, _ in checkBadges() }
        .alert("Badge Unlocked! 🏅", isPresented: .init(
            get: { newlyUnlockedBadge != nil },
            set: { if !$0 { newlyUnlockedBadge = nil } }
        ), presenting: newlyUnlockedBadge) { _ in
            Button("Awesome", role: .cancel) { }
        } message: { badge in
            Text("You just earned the '\(badge.title)' badge!\n\(badge.description)")
        }
    }
    
    private func checkBadges() {
        var currentUnlocked = unlockedIds
        
        let totalDonated = userStore.totalPointsDonated
        let donationCount = userStore.donationHistory.count
        let bestStreak = userStore.currentUser?.bestStreak ?? 0
        let eventsRegistered = volunteerStore.volunteerRegistrations.count
        
        for badge in ImpactBadge.allBadges {
            if !currentUnlocked.contains(badge.id) {
                if badge.isUnlocked(totalDonated: totalDonated, donationCount: donationCount, bestStreak: bestStreak, eventsRegistered: eventsRegistered) {
                    // New badge unlocked!
                    currentUnlocked.insert(badge.id)
                    unlockedIds = currentUnlocked
                    
                    // Show popup (if multiple unlock at once, it just shows the last one in the loop for now, which is fine)
                    newlyUnlockedBadge = badge
                }
            }
        }
    }
}

