import SwiftUI

// MARK: - Rescue Me Data Models

enum RescueTimeSlot: CaseIterable {
    case veryShort    // 5–10 min
    case short        // 15–20 min
    case medium       // 30–45 min
    case long         // 1+ hour

    var label: String {
        switch self {
        case .veryShort: return "5–10 min"
        case .short:     return "15–20 min"
        case .medium:    return "30–45 min"
        case .long:      return "1+ hour"
        }
    }

    var icon: String {
        switch self {
        case .veryShort: return "bolt.fill"
        case .short:     return "clock"
        case .medium:    return "clock.fill"
        case .long:      return "hourglass"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .veryShort: return 1...12
        case .short:     return 13...25
        case .medium:    return 26...50
        case .long:      return 51...999
        }
    }
}

enum RescueEnergyLevel: CaseIterable {
    case low, okay, high, veryHigh

    var label: String {
        switch self {
        case .low:      return "Low"
        case .okay:     return "Okay"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        }
    }

    var icon: String {
        switch self {
        case .low:      return "zzz"
        case .okay:     return "battery.50"
        case .high:     return "battery.100"
        case .veryHigh: return "flame.fill"
        }
    }

    var score: Int { // 1–4
        switch self {
        case .low:      return 1
        case .okay:     return 2
        case .high:     return 3
        case .veryHigh: return 4
        }
    }
}

enum RescueTaskType: CaseIterable {
    case thinkStudy
    case createWrite
    case computerWork
    case simpleRoutine
    case pickForMe

    var label: String {
        switch self {
        case .thinkStudy:    return "Think / Study"
        case .createWrite:   return "Create / Write"
        case .computerWork:  return "Work on computer"
        case .simpleRoutine: return "Simple / Routine"
        case .pickForMe:     return "Pick for me"
        }
    }

    var icon: String {
        switch self {
        case .thinkStudy:    return "book.fill"
        case .createWrite:   return "pencil.and.outline"
        case .computerWork:  return "laptopcomputer"
        case .simpleRoutine: return "checkmark.circle.fill"
        case .pickForMe:     return "dice.fill"
        }
    }

    /// Keywords to match against task title / category name
    var keywords: [String] {
        switch self {
        case .thinkStudy:    return ["study", "read", "learn", "think", "research", "math", "dsa", "algo", "exam", "notes", "lecture", "revise", "revision", "practice"]
        case .createWrite:   return ["write", "essay", "blog", "design", "art", "draw", "create", "draft", "report", "content", "story", "poem"]
        case .computerWork:  return ["code", "program", "dev", "build", "fix", "debug", "deploy", "computer", "laptop", "email", "slack", "meeting", "call", "zoom"]
        case .simpleRoutine: return ["clean", "organise", "organize", "laundry", "wash", "tidy", "reply", "message", "water", "walk", "gym", "exercise", "shop", "grocery", "admin", "form", "book"]
        case .pickForMe:     return []
        }
    }
}

// MARK: - Rescue Me Scoring Engine

struct RescueScorer {

    /// Score a single task against the user's current state.
    /// Higher = better match.
    static func score(
        task: UserTask,
        time: RescueTimeSlot,
        energy: RescueEnergyLevel,
        type: RescueTaskType
    ) -> Int {
        var pts = 0

        // ── Duration match (max 40 pts) ──────────────────────────────
        let duration = task.estimatedDuration ?? 25
        if time.range.contains(duration) {
            pts += 40                        // perfect fit
        } else {
            let diff = min(abs(duration - time.range.lowerBound),
                           abs(duration - time.range.upperBound))
            pts += max(0, 25 - diff)         // partial credit, decays with distance
        }

        // ── Priority × Energy match (max 30 pts) ─────────────────────
        let priorityScore: Int
        switch task.priority {
        case .high:   priorityScore = 4
        case .medium: priorityScore = 3
        case .low:    priorityScore = 2
        case .none:   priorityScore = 1
        }

        // High energy → reward high priority tasks
        // Low energy → penalize high priority (too demanding)
        let energyPriorityFit = 5 - abs(priorityScore - energy.score)
        pts += energyPriorityFit * 6

        // ── Difficulty × Energy match (max 20 pts) ─────────────────────
        let diffScore: Int
        switch task.difficulty {
        case .hard:   diffScore = 4
        case .medium: diffScore = 3
        case .easy:   diffScore = 2
        case .none:   diffScore = 1
        }
        
        let energyDiffFit = 5 - abs(diffScore - energy.score)
        pts += energyDiffFit * 4

        // ── Task type / keyword match (max 20 pts) ───────────────────
        if type != .pickForMe {
            let titleLower = task.title.lowercased()
            let matched = type.keywords.contains { titleLower.contains($0) }
            if matched { pts += 20 }
        } else {
            pts += 10 // neutral bonus for "pick for me"
        }

        // ── Low energy bonus for quick tasks (max 10 pts) ────────────
        if energy.score <= 2 && duration <= 20 {
            pts += 10
        }

        // ── Small bonus for tasks scheduled today ────────────────────
        if let scheduled = task.scheduledDate {
            if Calendar.current.isDateInToday(scheduled) {
                pts += 5
            }
        }

        return pts
    }

    /// Return tasks ranked best → worst, filtering out completed tasks.
    static func rank(
        tasks: [UserTask],
        completions: [UUID: Set<String>],
        time: RescueTimeSlot,
        energy: RescueEnergyLevel,
        type: RescueTaskType
    ) -> [UserTask] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let today = formatter.string(from: Calendar.current.startOfDay(for: Date()))

        let incomplete = tasks.filter { task in
            if task.repeatType == .never {
                return !task.isCompleted
            } else {
                return !(completions[task.id]?.contains(today) ?? false)
            }
        }

        return incomplete
            .map { ($0, score(task: $0, time: time, energy: energy, type: type)) }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}


// MARK: - Main Rescue Me View

struct RescueMeView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(\.dismiss) private var dismiss

    /// Called when user taps START with the chosen task
    var onStartTask: (UserTask) -> Void

    // ── Flow state ────────────────────────────────────────────────────
    @State private var step: Int = 0            // 0, 1, 2 = questions, 3 = result
    @State private var selectedTime: RescueTimeSlot?
    @State private var selectedEnergy: RescueEnergyLevel?
    @State private var selectedType: RescueTaskType?

    // ── Recommendation state ─────────────────────────────────────────
    @State private var rankedTasks: [UserTask] = []
    @State private var shownIndex: Int = 0
    @State private var cardFlip: Bool = false

    // ── Animation ────────────────────────────────────────────────────
    @State private var slideDir: CGFloat = 1    // +1 = forward, -1 = back
    @State private var transitionId: UUID = UUID()

    private var currentTask: UserTask? {
        guard !rankedTasks.isEmpty else { return nil }
        return rankedTasks[shownIndex % rankedTasks.count]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()

                // Soft ambient blobs
                ambientBackground

                VStack(spacing: 0) {
                    // Progress dots
                    if step < 3 {
                        stepIndicator
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    }

                    // Page content
                    Group {
                        switch step {
                        case 0: questionPage(
                            headerIcon: "clock",
                            title: "How much time\ndo you have?",
                            subtitle: "We'll match tasks to your window",
                            options: RescueTimeSlot.allCases,
                            selected: selectedTime,
                            label: { $0.label },
                            optionIcon: { $0.icon },
                            onSelect: { selectedTime = $0 }
                        )
                        case 1: questionPage(
                            headerIcon: "bolt.fill",
                            title: "How's your energy\nright now?",
                            subtitle: "Be honest — it helps us pick better",
                            options: RescueEnergyLevel.allCases,
                            selected: selectedEnergy,
                            label: { $0.label },
                            optionIcon: { $0.icon },
                            onSelect: { selectedEnergy = $0 }
                        )
                        case 2: questionPage(
                            headerIcon: "brain.head.profile",
                            title: "What sounds\neasiest right now?",
                            subtitle: "Go with your gut",
                            options: RescueTaskType.allCases,
                            selected: selectedType,
                            label: { $0.label },
                            optionIcon: { $0.icon },
                            onSelect: { selectedType = $0 }
                        )
                        case 3: resultPage
                        default: EmptyView()
                        }
                    }
                    .id(transitionId)
                    .transition(
                        .asymmetric(
                            insertion: .offset(x: 340 * slideDir).combined(with: .opacity),
                            removal:   .offset(x: -340 * slideDir).combined(with: .opacity)
                        )
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                slideDir = -1
                                transitionId = UUID()
                                step -= 1
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Back")
                                    .font(.system(size: 15))
                            }
                            .foregroundStyle(AppTheme.warmTextSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(.white.opacity(0.7)))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(i <= step ? AppTheme.orange : AppTheme.orange.opacity(0.18))
                    .frame(width: i == step ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
            }
        }
    }

    // MARK: - Generic Question Page

    @ViewBuilder
    private func questionPage<T: Equatable & Hashable>(
        headerIcon: String,
        title: String,
        subtitle: String,
        options: [T],
        selected: T?,
        label: @escaping (T) -> String,
        optionIcon: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.orange.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: headerIcon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppTheme.orange)
                }

                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)

            // Option chips
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    optionChip(
                        label: label(option),
                        icon: optionIcon(option),
                        isSelected: selected == option
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            onSelect(option)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Next button
            nextButton(isEnabled: selected != nil) {
                advance()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Option Chip

    private func optionChip(
        label: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .white : AppTheme.orange)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isSelected ? .white.opacity(0.25) : AppTheme.orange.opacity(0.08))
                    )

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AppTheme.warmTextPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected
                          ? LinearGradient(colors: [AppTheme.orange, AppTheme.orangeDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.75)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: isSelected ? AppTheme.orange.opacity(0.3) : Color.black.opacity(0.04),
                            radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.6), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Next Button

    private func nextButton(isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("Next")
                    .font(.system(size: 17, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(isEnabled
                          ? LinearGradient(colors: [AppTheme.orange, AppTheme.orangeDeep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: isEnabled ? AppTheme.orange.opacity(0.35) : .clear,
                            radius: 10, y: 5)
            )
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEnabled)
    }

    // MARK: - Advance Step Logic

    private func advance() {
        slideDir = 1

        if step == 2 {
            // Compute ranking, move to result
            guard let t = selectedTime, let e = selectedEnergy, let ty = selectedType else { return }
            rankedTasks = RescueScorer.rank(
                tasks: taskStore.tasks,
                completions: taskStore.taskCompletions,
                time: t,
                energy: e,
                type: ty
            )
            shownIndex = 0
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            transitionId = UUID()
            step += 1
        }
    }

    // MARK: - Result Page

    @ViewBuilder
    private var resultPage: some View {
        if rankedTasks.isEmpty {
            emptyResultView
        } else if let task = currentTask {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.orange.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "target")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(AppTheme.orange)
                    }
                    Text("Here's your task")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                    Text("Matched to your time & energy")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
                .padding(.bottom, 28)

                // Task card
                taskRecommendationCard(task: task)
                    .padding(.horizontal, 24)
                    .id(shownIndex) // Re-animate on task change
                    .transition(.asymmetric(
                        insertion: .offset(x: 200).combined(with: .opacity),
                        removal:   .offset(x: -200).combined(with: .opacity)
                    ))

                Spacer()

                // Action buttons
                VStack(spacing: 14) {
                    // START button
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onStartTask(task)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("START")
                                .font(.system(size: 17, weight: .bold))
                                .kerning(0.5)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [AppTheme.orange, AppTheme.orangeDeep],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 6)
                        )
                    }
                    .buttonStyle(HomeCardButtonStyle())

                    // Give me another
                    if rankedTasks.count > 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                shownIndex = (shownIndex + 1) % rankedTasks.count
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Give Me Another")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(AppTheme.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(AppTheme.orange.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Task Recommendation Card

    private func taskRecommendationCard(task: UserTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Priority badge + category
            HStack(spacing: 10) {
                priorityBadge(task.priority)
                Spacer()
                if let duration = task.estimatedDuration {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text("\(duration) min")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.08)))
                }
            }

            // Task title
            Text(task.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.warmTextPrimary)
                .lineLimit(3)

            // Match description
            Text(matchDescription(task: task))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.warmTextSecondary)
                .lineSpacing(3)

            // Divider + repeat type chip if applicable
            if task.repeatType != .never {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                    Text(task.repeatType.displayName)
                        .font(.caption.bold())
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.purple.opacity(0.1)))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: "FFF7ED"))
                .shadow(color: AppTheme.orange.opacity(0.14), radius: 16, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.orange.opacity(0.12), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.orange.opacity(0.4))
                .offset(x: -16, y: 16)
        }
    }

    // MARK: - Priority Badge

    private func priorityBadge(_ priority: UserTask.Priority) -> some View {
        let (label, color): (String, Color) = {
            switch priority {
            case .high:   return ("High Priority", Color(hex: "EF4444"))
            case .medium: return ("Medium", AppTheme.amber)
            case .low:    return ("Low Priority", AppTheme.sage)
            case .none:   return ("No Priority", AppTheme.warmTextSecondary)
            }
        }()

        return HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.1)))
    }

    // MARK: - Match Description

    private func matchDescription(task: UserTask) -> String {
        var reasons: [String] = []

        if let dur = task.estimatedDuration, let t = selectedTime, t.range.contains(dur) {
            reasons.append("fits your \(t.label) window")
        }
        if let e = selectedEnergy {
            switch (e, task.priority) {
            case (.high, .high), (.veryHigh, .high):
                reasons.append("matches your high energy")
            case (.low, .low), (.low, .none), (.okay, .medium):
                reasons.append("feels right for your energy level")
            default:
                reasons.append("aligns with your current energy")
            }
        }
        if reasons.isEmpty {
            return "Your time and energy match this task well."
        }
        return "This task " + reasons.joined(separator: " and ") + "."
    }

    // MARK: - Empty State

    private var emptyResultView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.sage.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(AppTheme.sage)
            }

            VStack(spacing: 8) {
                Text("All Clear!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                Text("No pending tasks found.\nAdd tasks to your Planner and\nwe'll help you pick the right one.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Go to Planner")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Capsule().fill(AppTheme.orange))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(AppTheme.orange.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 100, y: -180)

            Circle()
                .fill(AppTheme.sage.opacity(0.05))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: -100, y: 300)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}


