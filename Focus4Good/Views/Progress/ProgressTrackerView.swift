import SwiftUI

// MARK: - Period

enum ProgressPeriod: String, CaseIterable, Identifiable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}

// MARK: - ProgressTrackerView

struct ProgressTrackerView: View {
    @Environment(ProgressStore.self)      private var progressStore
    @Environment(UserStore.self)          private var userStore
    @Environment(TaskStore.self)          private var taskStore
    @Environment(CalmCentreStore.self)    private var calmStore

    @State private var selectedPeriod: ProgressPeriod = .weekly
    @State private var activeSheet: ProgressSheetType?

    private var progress: UserProgress? {
        switch selectedPeriod {
        case .weekly:  return progressStore.weeklyProgress
        case .monthly: return progressStore.monthlyProgress
        }
    }

    private var completionDates: Set<String> {
        var dates = Set<String>()
        for dateSet in taskStore.taskCompletions.values {
            dates.formUnion(dateSet)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for task in taskStore.tasks where task.isCompleted && task.repeatType == .never {
            let d = task.scheduledDate ?? task.createdAt
            dates.insert(formatter.string(from: d))
        }

        for record in progressStore.progressRecords where record.periodType == "daily" && (record.tasksCompleted > 0 || record.focusTimeMinutes > 0 || record.calmCentreMinutes > 0 || record.focusPointsEarned > 0) {
            dates.insert(formatter.string(from: record.periodStart))
        }

        for s in calmStore.breathingSessions {
            dates.insert(formatter.string(from: s.completedAt))
        }
        for s in calmStore.jpmrSessions {
            dates.insert(formatter.string(from: s.completedAt))
        }
        for s in calmStore.guidedMeditationSessions {
            dates.insert(formatter.string(from: s.completedAt))
        }
        return dates
    }

    private var dailyFocusMinutes: [String: Int] {
        var dict: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for record in progressStore.progressRecords where record.periodType == "daily" {
            let key = formatter.string(from: record.periodStart)
            dict[key] = (dict[key] ?? 0) + record.focusTimeMinutes
        }
        return dict
    }

    private var dailyCalmMinutes: [String: Int] {
        var dict: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for record in progressStore.progressRecords where record.periodType == "daily" {
            let key = formatter.string(from: record.periodStart)
            dict[key] = (dict[key] ?? 0) + record.calmCentreMinutes
        }
        for s in calmStore.breathingSessions {
            let key = formatter.string(from: s.completedAt)
            dict[key] = (dict[key] ?? 0) + (s.durationSeconds / 60)
        }
        for s in calmStore.jpmrSessions {
            let key = formatter.string(from: s.completedAt)
            dict[key] = (dict[key] ?? 0) + (s.durationSeconds / 60)
        }
        for s in calmStore.guidedMeditationSessions {
            let key = formatter.string(from: s.completedAt)
            dict[key] = (dict[key] ?? 0) + (s.durationSeconds / 60)
        }
        return dict
    }

    private var dailyPoints: [String: Int] {
        var dict: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for record in progressStore.progressRecords where record.periodType == "daily" {
            let key = formatter.string(from: record.periodStart)
            dict[key] = (dict[key] ?? 0) + record.focusPointsEarned
        }
        return dict
    }

    private var pointsBreakdown: (focus: Int, task: Int, calm: Int) {
        let total = userStore.currentUser?.focusPoints ?? 0
        guard total > 0 else { return (0, 0, 0) }

        let calmPts = calmStore.breathingSessions.count * 15 +
                      calmStore.jpmrSessions.count * 25 +
                      calmStore.guidedMeditationSessions.count * 20 +
                      calmStore.brainDumpEntries.count * 10
        
        let completedTaskCount = taskStore.completedTasks.count + taskStore.taskCompletions.values.reduce(0) { $0 + $1.count }
        let taskPts = completedTaskCount * 10

        let boundedCalm = min(calmPts, total)
        let boundedTask = min(taskPts, total - boundedCalm)
        let focusPts = max(0, total - boundedCalm - boundedTask)

        return (focus: focusPts, task: boundedTask, calm: boundedCalm)
    }

    // Motivational thoughts for the bottom card
    private let thoughts: [(title: String, subtitle: String)] = [
        ("Small steps, big change.", "Consistency today builds the focus you'll be proud of tomorrow."),
        ("Every minute counts.", "Your dedication is planting seeds of transformation."),
        ("Stay present, stay powerful.", "Focus is not about perfection, it's about progress.")
    ]

    private var currentThought: (title: String, subtitle: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return thoughts[dayOfYear % thoughts.count]
    }

    // Motivational message based on task progress
    private var motivationalMessage: String {
        let completed = progress?.tasksCompleted ?? 0
        let goal = progress?.taskGoal ?? (selectedPeriod == .weekly ? 75 : 300)
        let ratio = Double(completed) / Double(max(goal, 1))
        if ratio >= 1.0 {
            return "Amazing! You've crushed your goal!"
        } else if ratio >= 0.5 {
            return "Great progress! Keep it up!"
        } else if completed > 0 {
            return "Nice start! Keep the momentum going!"
        } else {
            return "Keep going! You're building momentum."
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header (subtitle only)
                    headerSection

                    // Segmented Picker
                    periodPicker

                    // Overview Section
                    overviewSection

                    // Key Metrics Section
                    keyMetricsSection

                    // Thought Card
                    thoughtCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(progressBackground)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $activeSheet) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await userStore.updateStreakFromCompletions(completionDates)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: ProgressSheetType) -> some View {
        switch sheet {
        case .streak:
            StreakDetailSheet(
                currentStreak: userStore.currentUser?.currentStreak ?? 0,
                bestStreak: userStore.currentUser?.bestStreak ?? 0,
                completionDates: completionDates
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)

        case .tasksCompleted:
            TasksCompletedDetailSheet(
                tasksCompleted: progress?.tasksCompleted ?? 0,
                taskGoal: progress?.taskGoal ?? (selectedPeriod == .weekly ? 75 : 300),
                period: selectedPeriod
            )
            .environment(taskStore)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)

        case .timeSpent:
            TimeSpentDetailSheet(
                focusMinutes: progress?.focusTimeMinutes ?? 0,
                calmMinutes: progress?.calmCentreMinutes ?? 0,
                period: selectedPeriod,
                dailyFocusMinutes: dailyFocusMinutes,
                dailyCalmMinutes: dailyCalmMinutes
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)

        case .focusPoints:
            let breakdown = pointsBreakdown
            FocusPointsDetailSheet(
                totalPoints: userStore.currentUser?.focusPoints ?? 0,
                currentLevel: userStore.currentUser?.currentLevel ?? 1,
                periodPoints: progress?.focusPointsEarned ?? 0,
                period: selectedPeriod,
                dailyPoints: dailyPoints,
                focusSessionPoints: breakdown.focus,
                taskCompletionPoints: breakdown.task,
                calmCentrePoints: breakdown.calm
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Background

    private var progressBackground: some View {
        ZStack {
            AppTheme.appGradient.ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Text("Track your focus. Celebrate growth.")
            .font(.subheadline)
            .foregroundStyle(AppTheme.warmTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    // MARK: - Period Picker (Native glass segmented control)

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(ProgressPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3.bold())

            HStack(spacing: 12) {
                // Tasks Completed Card
                Button { activeSheet = .tasksCompleted } label: {
                    tasksCompletedCard
                }
                .buttonStyle(.plain)

                // Time Spent Card
                Button { activeSheet = .timeSpent } label: {
                    timeSpentCard
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tasks Completed Card

    private var tasksCompletedCard: some View {
        VStack(spacing: 8) {
            Text("Tasks Completed")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.cardLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Custom Circular Progress Ring
            CircularProgressRing(
                completed: progress?.tasksCompleted ?? 0,
                goal: progress?.taskGoal ?? (selectedPeriod == .weekly ? 75 : 300)
            )
            .frame(width: 100, height: 100)
            .padding(.vertical, 4)

            Text(motivationalMessage)
                .font(.caption2)
                .foregroundStyle(AppTheme.warmTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassCard()
    }

    // MARK: - Time Spent Card

    private var timeSpentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Spent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.cardLabel)

            Spacer()

            TimeRow(
                systemImage: "person.fill",
                label:       "Focus",
                minutes:     progress?.focusTimeMinutes ?? 0,
                color:       AppTheme.orange
            )

            TimeRow(
                systemImage: "figure.mind.and.body",
                label:       "Calm",
                minutes:     progress?.calmCentreMinutes ?? 0,
                color:       AppTheme.sage
            )

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassCard()
    }

    // MARK: - Key Metrics

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.title3.bold())

            HStack(spacing: 12) {
                Button { activeSheet = .focusPoints } label: {
                    MetricCard(
                        systemImage: "scope",
                        value:       "\(userStore.currentUser?.focusPoints ?? 0)",
                        label:       "Focus Points",
                        color:       AppTheme.orange
                    )
                }
                .buttonStyle(.plain)

                Button { activeSheet = .streak } label: {
                    MetricCard(
                        systemImage: "flame.fill",
                        value:       "\(userStore.currentUser?.bestStreak ?? 0) Days",
                        label:       "Best Streak",
                        color:       AppTheme.amber
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Thought Card

    private var thoughtCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentThought.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text(currentThought.subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Potted plant image
            Image("potted_plant")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.thoughtCardStart, AppTheme.thoughtCardEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: AppTheme.orange.opacity(0.12), radius: 10, y: 3)
    }
}

// MARK: - Circular Progress Ring

private struct CircularProgressRing: View {
    let completed: Int
    let goal: Int

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(completed) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppTheme.orange.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            // Progress arc — multi-color gradient
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.orange, AppTheme.amber, AppTheme.sage, AppTheme.orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fraction)

            // Center label
            VStack(spacing: 2) {
                Text("\(completed)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("/ \(goal)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
    }
}

// MARK: - Time Row

private struct TimeRow: View {
    let systemImage: String
    let label: String
    let minutes: Int
    var color: Color = AppTheme.orange

    private var formatted: String {
        String(format: "%02d:%02d hrs", minutes / 60, minutes % 60)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.warmTextSecondary)
                Text(formatted)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
            }
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let systemImage: String
    let value: String
    let label: String
    var color: Color = AppTheme.orange

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.warmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }
}



// MARK: - Preview

#Preview {
    let progressStore     = ProgressStore.shared
    let userStore         = UserStore.shared
    let userId            = UUID()

    let _ = {
        progressStore.progressRecords = [
            UserProgress(
                userId: userId,
                periodType: "weekly",
                periodStart: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date(),
                tasksCompleted: 12,
                focusTimeMinutes: 145,
                calmCentreMinutes: 45,
                focusPointsEarned: 320,
                taskGoal: 30
            ),
            UserProgress(
                userId: userId,
                periodType: "monthly",
                periodStart: Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date(),
                tasksCompleted: 48,
                focusTimeMinutes: 580,
                calmCentreMinutes: 120,
                focusPointsEarned: 1280,
                taskGoal: 120
            )
        ]
    }()

    return ProgressTrackerView()
        .environment(progressStore)
        .environment(userStore)
        .environment(TaskStore.shared)
}
