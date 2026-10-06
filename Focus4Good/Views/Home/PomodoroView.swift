import SwiftUI

struct PomodoroView: View {
    let task: UserTask
    @Environment(TaskStore.self)     private var taskStore
    @Environment(UserStore.self)     private var userStore
    @Environment(ProgressStore.self) private var progressStore
    @Environment(\.dismiss)          private var dismiss
    @Environment(\.scenePhase)       private var scenePhase

    @State private var timeRemaining: Int
    @State private var isBreak = false
    @State private var currentSession = 1
    @State private var distractedCount = 0
    @State private var showEndSessionAlert = false
    @State private var showOverwhelmedSheet = false
    @State private var showBreakScreen = false
    @State private var sessionComplete = false
    @State private var showPomodoroCompletePopup = false
    @State private var timer: Timer?
    @State private var totalFocusMinutes = 0
    @State private var breathePhase = false
    @State private var pulseRing = false
    @State private var rotateGlow = false
    @State private var showReturnPrompt = false
    @State private var wasRunningWhenBackgrounded = false

    private let focusQuotes = [
        "Deep work is the superpower of the 21st century.",
        "Where focus goes, energy flows.",
        "The successful warrior is the average person with laser focus.",
        "Starve your distractions. Feed your focus.",
        "Focus is not about saying yes. It's about saying no."
    ]

    private var currentQuote: String {
        let minute = Calendar.current.component(.minute, from: Date())
        return focusQuotes[minute % focusQuotes.count]
    }

    private let totalSessions: Int
    private let sessionDuration: Int
    private let breakDuration = 5 * 60
    private let pointsPerSession = 20
    private let pointsOnCompletion = 50

    init(task: UserTask) {
        self.task = task
        let duration = task.estimatedDuration ?? 25
        self.totalSessions = max(1, Int(ceil(Double(duration) / 25.0)))
        
        let sessionLength = (duration < 25 && duration > 0) ? duration : 25
        self.sessionDuration = sessionLength * 60
        self._timeRemaining = State(initialValue: sessionLength * 60)
    }

    private var progress: Double {
        let total = isBreak ? Double(breakDuration) : Double(sessionDuration)
        return 1.0 - (Double(timeRemaining) / total)
    }

    private var timeString: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    var body: some View {
        ZStack {
            Group {
                if sessionComplete {
                    SessionCompleteView(
                        totalSessions: totalSessions,
                        totalFocusMinutes: totalFocusMinutes,
                        distractedCount: distractedCount,
                        pointsEarned: pointsOnCompletion,
                        onDismiss: { dismiss() }
                    )
                } else if showBreakScreen {
                    breakView
                } else {
                    timerView
                }
            }

            // Pomodoro session complete popup overlay
            if showPomodoroCompletePopup {
                PomodoroSessionPopup(
                    sessionNumber: currentSession,
                    totalSessions: totalSessions,
                    pointsEarned: pointsPerSession,
                    onContinue: {
                        showPomodoroCompletePopup = false
                        showBreakScreen = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPomodoroCompletePopup)
        .onDisappear { timer?.invalidate() }
        .sheet(isPresented: $showOverwhelmedSheet) {
            OverwhelmedSheet {
                dismiss() // End session when user feels overwhelmed
            }
        }
        .alert("End Session?", isPresented: $showEndSessionAlert) {
            Button("Keep Going", role: .cancel) {}
            Button("End Anyway", role: .destructive) { dismiss() }
        } message: {
            Text("If you stop now, you won't earn focus points. Stay a little longer and stay focused.")
        }
        .alert("Welcome Back", isPresented: $showReturnPrompt) {
            Button("Continue") {
                startTimer()
            }
        } message: {
            Text("You left the app during a focus session. Ready to resume?")
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if timer != nil && timeRemaining > 0 && !showBreakScreen && !sessionComplete {
                    timer?.invalidate()
                    timer = nil
                    wasRunningWhenBackgrounded = true
                }
            } else if newPhase == .active {
                if wasRunningWhenBackgrounded {
                    showReturnPrompt = true
                    wasRunningWhenBackgrounded = false
                }
            }
        }
    }

    // MARK: - Timer View
    private var timerView: some View {
        ZStack {
            // Rich layered background
            LinearGradient(
                colors: [
                    Color(hex: "FFF8F0"),
                    Color(hex: "FFF1E0"),
                    Color(hex: "FFE8CC")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle floating ambient circles
            floatingAmbient

            VStack(spacing: 0) {
                // Top bar with close button
                HStack {
                    Button { showEndSessionAlert = true } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.8)))
                    }
                    Spacer()
                    modeBadge
                    Spacer()
                    // Invisible spacer for symmetry
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Text(task.title)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.warmTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                Spacer()
                timerRing
                Spacer()

                // Motivational quote
                Text("\"\(currentQuote)\"")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 12)

                sessionInfo.padding(.bottom, 24)

                distractedButton.padding(.horizontal, 40).padding(.bottom, 16)
                endSessionButton.padding(.bottom, 48)
            }
        }
        .onAppear {
            startTimer()
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotateGlow = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseRing = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Break View (Figma style)
    private var breakView: some View {
        ZStack {
            AppTheme.pageGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                // Breathing circle
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFF3E8"))
                        .frame(width: 220, height: 220)
                        .scaleEffect(breathePhase ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathePhase)

                    Circle()
                        .stroke(AppTheme.orange.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 220, height: 220)

                    VStack(spacing: 6) {
                        Text(breathePhase ? "EXHALE" : "INHALE")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundStyle(AppTheme.orange)
                            .kerning(3)
                        Text("~")
                            .font(.title2)
                            .foregroundStyle(AppTheme.orange.opacity(0.6))
                    }
                }
                .onAppear { breathePhase = true }

                Spacer()

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.orange)

                Text("Relaxation Break")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .padding(.top, 4)

                Spacer()

                Button { skipBreak() } label: {
                    HStack(spacing: 8) {
                        Text("Skip and start new session")
                            .font(.headline)
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(AppTheme.warmTextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.2)))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

                Button { dismiss() } label: {
                    Text("End Session")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear { startBreakTimer() }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Subviews

    private var floatingAmbient: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.orange.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: -200)
                .scaleEffect(pulseRing ? 1.1 : 0.9)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFD4A0").opacity(0.1), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 120, y: 300)
                .scaleEffect(pulseRing ? 0.9 : 1.1)
        }
    }

    private var modeBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.orange)
                .frame(width: 6, height: 6)
                .scaleEffect(pulseRing ? 1.3 : 1.0)
            Text("DEEP FOCUS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.orange)
                .kerning(1.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.white.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(AppTheme.orange.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var timerRing: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.orange.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 100,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseRing ? 1.05 : 0.95)

            // Background track
            Circle()
                .stroke(AppTheme.orange.opacity(0.1), lineWidth: 14)
                .frame(width: 240, height: 240)

            // Secondary subtle ring
            Circle()
                .stroke(AppTheme.orange.opacity(0.05), lineWidth: 28)
                .frame(width: 240, height: 240)

            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(hex: "FF8C42"),
                            AppTheme.orange,
                            Color(hex: "FFB347"),
                            Color(hex: "FF8C42")
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 0)

            // Glowing dot at progress tip
            Circle()
                .fill(.white)
                .frame(width: 18, height: 18)
                .shadow(color: AppTheme.orange.opacity(0.6), radius: 6)
                .offset(y: -120)
                .rotationEffect(.degrees(360 * progress - 90))
                .animation(.linear(duration: 1), value: progress)

            // Time display
            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.warmTextPrimary, AppTheme.warmTextPrimary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("remaining")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .kerning(1.5)
                    .textCase(.uppercase)
            }
        }
    }

    private var sessionInfo: some View {
        VStack(spacing: 10) {
            Text("SESSION \(currentSession) OF \(totalSessions)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.warmTextSecondary)
                .kerning(1.5)
            HStack(spacing: 8) {
                ForEach(0..<totalSessions, id: \.self) { index in
                    Capsule()
                        .fill(index < currentSession ? AppTheme.orange : AppTheme.orange.opacity(0.15))
                        .frame(width: index < currentSession ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: currentSession)
                }
            }
        }
    }

    private var distractionSFSymbol: String {
        switch distractedCount {
        case 0:  return "face.smiling"
        case 1:  return "face.smiling.inverse"
        case 2:  return "exclamationmark.circle"
        case 3:  return "wind"
        case 4:  return "alarm"
        default: return "brain.head.profile"
        }
    }

    private var distractionSymbolColor: Color {
        switch distractedCount {
        case 0:  return AppTheme.sage
        case 1:  return AppTheme.warmTextSecondary
        case 2:  return AppTheme.amber
        case 3:  return AppTheme.amber
        case 4:  return AppTheme.orange
        default: return Color(hex: "EF4444")
        }
    }

    private var distractionMessage: String {
        switch distractedCount {
        case 0:  return "Staying focused!"
        case 1:  return "It's okay, refocus!"
        case 2:  return "Try to stay on track"
        case 3:  return "Take a deep breath"
        case 4:  return "One more and we'll help"
        default: return "Let's take a break"
        }
    }

    private var distractedButton: some View {
        VStack(spacing: 12) {
            if distractedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: distractionSFSymbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(distractionSymbolColor)
                        .id(distractedCount)
                        .transition(.scale.combined(with: .opacity))
                    Text(distractionMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    distractedCount += 1
                }
                if distractedCount >= 5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOverwhelmedSheet = true
                    }
                }
            } label: {
                Text("Distracted").font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange))
            }
        }
    }

    private var endSessionButton: some View {
        Button { showEndSessionAlert = true } label: {
            Text("End Session").font(.subheadline).foregroundStyle(AppTheme.warmTextSecondary)
        }
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else { handleSessionEnd(); return }
            timeRemaining -= 1
        }
    }

    private func startBreakTimer() {
        timeRemaining = breakDuration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard timeRemaining > 0 else { handleBreakEnd(); return }
            timeRemaining -= 1
        }
    }

    private func handleSessionEnd() {
        timer?.invalidate()
        totalFocusMinutes += (sessionDuration / 60)

        if currentSession >= totalSessions {
            // All sessions done — award task completion bonus (+50)
            guard let userId = userStore.currentUser?.id else {
                sessionComplete = true
                return
            }
            Task {
                // Mark task complete
                await taskStore.toggleCompletion(for: task)
                // Award completion bonus points
                await userStore.updateFocusPoints(by: pointsOnCompletion)
                // Record focus time and points in ProgressStore
                await progressStore.addFocusTime(minutes: totalFocusMinutes, userId: userId)
                await progressStore.addPointsEarned(points: pointsOnCompletion, userId: userId)
            }
            sessionComplete = true
        } else {
            // Session complete but more to go — award per-session points (+20) and show popup
            if let userId = userStore.currentUser?.id {
                Task {
                    await userStore.updateFocusPoints(by: pointsPerSession)
                    await progressStore.addPointsEarned(points: pointsPerSession, userId: userId)
                }
            }
            showPomodoroCompletePopup = true
        }
    }

    private func handleBreakEnd() {
        timer?.invalidate()
        currentSession += 1
        timeRemaining = sessionDuration
        showBreakScreen = false
        startTimer()
    }

    private func skipBreak() {
        timer?.invalidate()
        currentSession += 1
        timeRemaining = sessionDuration
        showBreakScreen = false
        breathePhase = false
        startTimer()
    }
}

// MARK: - Pomodoro Session Complete Popup

struct PomodoroSessionPopup: View {
    let sessionNumber: Int
    let totalSessions: Int
    let pointsEarned: Int
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {} // block taps

            VStack(spacing: 24) {
                Spacer()

                // Badge icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFF3E8"))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.orange)
                }

                VStack(spacing: 8) {
                    Text("Well done!")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Session \(sessionNumber) of \(totalSessions) complete.\nTake a moment to notice how\nyour body feels")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Text("+ \(pointsEarned) Focus Points")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.orange)
                    .padding(.top, 8)

                Spacer()

                Button(action: onContinue) {
                    Text("Start Break")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.appGradient.ignoresSafeArea())
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
            .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        }
    }
}

// MARK: - Overwhelmed Sheet
struct OverwhelmedSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onGoToCalmCentre: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.orange)
                .padding(.top, 32)

            VStack(spacing: 8) {
                Text("Feeling a little overwhelmed?")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.warmTextPrimary)
                    .multilineTextAlignment(.center)
                Text("You seem quite distracted right now. Would you like to take a short break and reset your focus?")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    dismiss()
                    onGoToCalmCentre()
                } label: {
                    Text("End Session")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 32)

                Button {
                    dismiss()
                } label: {
                    Text("Stay in session")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
            }
            .padding(.bottom, 32)
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .background(AppTheme.pageGradient)
    }
}

// MARK: - Session Complete
struct SessionCompleteView: View {
    let totalSessions: Int
    let totalFocusMinutes: Int
    let distractedCount: Int
    let pointsEarned: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 8) {
                    Text("Well Done").font(.largeTitle.bold()).foregroundStyle(AppTheme.textPrimary)
                    Text("Focus session complete").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill").font(.system(size: 32)).foregroundStyle(.white.opacity(0.9))
                        Text("\(totalSessions) Session\(totalSessions > 1 ? "s" : "")").font(.headline.bold()).foregroundStyle(.white)
                        Text("COMPLETED").font(.caption.bold()).foregroundStyle(.white.opacity(0.85)).kerning(1.2)
                    }
                }

                HStack(spacing: 0) {
                    statItem(label: "TOTAL FOCUS", value: "\(totalFocusMinutes)m")
                    Divider().frame(height: 40)
                    statItem(label: "DISTRACTIONS", value: "\(distractedCount)")
                }
                .padding(.vertical, 20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal, 40)

                Text("+ \(pointsEarned) Focus Points").font(.title2.bold()).foregroundStyle(AppTheme.orange)

                Spacer()

                Button(action: onDismiss) {
                    Text("Go to Planner").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Capsule().fill(AppTheme.orange))
                }
                .padding(.horizontal, 32).padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary).kerning(0.5)
            Text(value).font(.title3.bold()).foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
