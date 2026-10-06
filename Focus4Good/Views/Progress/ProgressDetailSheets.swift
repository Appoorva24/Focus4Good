import SwiftUI

// MARK: - Sheet Type Enum

enum ProgressSheetType: Identifiable {
    case streak
    case tasksCompleted
    case timeSpent
    case focusPoints

    var id: String {
        switch self {
        case .streak:         return "streak"
        case .tasksCompleted: return "tasksCompleted"
        case .timeSpent:      return "timeSpent"
        case .focusPoints:    return "focusPoints"
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 1. Streak Detail Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StreakDetailSheet: View {
    let currentStreak: Int
    let bestStreak: Int
    var completionDates: Set<String> = []

    @Environment(\.dismiss) private var dismiss

    // Generate last 91 days (13 weeks) for the heatmap
    private let totalDays = 91
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    // Real active days based on actual task completion dates
    private var activeDays: Set<Int> {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var days = Set<Int>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for dateString in completionDates {
            if let date = formatter.date(from: dateString) {
                let dayOffset = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: today).day ?? 0
                if dayOffset >= 0 && dayOffset < totalDays {
                    days.insert(totalDays - 1 - dayOffset)
                }
            }
        }
        return days
    }

    private var dayLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var labels: [String] = []
        // Starting from Monday
        let cal = Calendar(identifier: .gregorian)
        let base = cal.date(from: DateComponents(year: 2024, month: 1, day: 1))! // Monday
        for i in 0..<7 {
            let d = cal.date(byAdding: .day, value: i, to: base)!
            labels.append(formatter.string(from: d))
        }
        return labels
    }

    private var monthLabels: [(label: String, column: Int)] {
        let cal = Calendar.current
        let today = Date()
        var result: [(label: String, column: Int)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var lastMonth = -1
        for i in 0..<totalDays {
            let date = cal.date(byAdding: .day, value: -(totalDays - 1 - i), to: today)!
            let month = cal.component(.month, from: date)
            if month != lastMonth {
                lastMonth = month
                let weekIndex = i / 7
                result.append((formatter.string(from: date), weekIndex))
            }
        }
        return result
    }

    // Streak milestones
    private var milestones: [(days: Int, label: String, icon: String)] {
        [
            (7,   "1 Week",    "flame.fill"),
            (14,  "2 Weeks",   "flame.fill"),
            (30,  "1 Month",   "star.fill"),
            (60,  "2 Months",  "star.fill"),
            (90,  "3 Months",  "trophy.fill"),
            (180, "6 Months",  "trophy.fill"),
            (365, "1 Year",    "crown.fill"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak summary
                    streakSummaryRow

                    // Heatmap
                    heatmapSection

                    // Milestones
                    milestonesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Streak Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    // MARK: Streak Summary

    private var streakSummaryRow: some View {
        HStack(spacing: 16) {
            streakStatBox(
                value: "\(currentStreak)",
                label: "Current Streak",
                icon: "flame.fill",
                color: AppTheme.orange
            )
            streakStatBox(
                value: "\(bestStreak)",
                label: "Best Streak",
                icon: "trophy.fill",
                color: AppTheme.amber
            )
        }
    }

    private func streakStatBox(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.warmTextSecondary)

            Text("days")
                .font(.caption2)
                .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard()
    }

    // MARK: Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity — Last 13 Weeks")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            // Month labels row
            HStack(spacing: 0) {
                ForEach(0..<13, id: \.self) { week in
                    if let match = monthLabels.first(where: { $0.column == week }) {
                        Text(match.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }

            // Heatmap grid
            HStack(alignment: .top, spacing: 3) {
                // Day labels
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(row % 2 == 0 ? "" : dayLabels[row])
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .frame(width: 24, height: 14)
                    }
                }

                // Grid cells
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(14), spacing: 3), count: 7), spacing: 3) {
                    ForEach(0..<totalDays, id: \.self) { index in
                        let isActive = activeDays.contains(index)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(cellColor(for: index, isActive: isActive))
                            .frame(width: 14, height: 14)
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                ForEach(0..<4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(legendColor(level: level))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func cellColor(for index: Int, isActive: Bool) -> Color {
        if !isActive {
            return AppTheme.sage.opacity(0.08)
        }
        // Vary intensity for recent vs older activity
        let recency = Double(index) / Double(totalDays)
        if recency > 0.85 { return AppTheme.sage.opacity(0.9) }
        if recency > 0.6  { return AppTheme.sage.opacity(0.65) }
        if recency > 0.3  { return AppTheme.sage.opacity(0.45) }
        return AppTheme.sage.opacity(0.25)
    }

    private func legendColor(level: Int) -> Color {
        switch level {
        case 0: return AppTheme.sage.opacity(0.08)
        case 1: return AppTheme.sage.opacity(0.3)
        case 2: return AppTheme.sage.opacity(0.6)
        default: return AppTheme.sage.opacity(0.9)
        }
    }

    // MARK: Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            ForEach(milestones, id: \.days) { milestone in
                let achieved = bestStreak >= milestone.days
                HStack(spacing: 12) {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(achieved ? AppTheme.amber : AppTheme.warmTextSecondary.opacity(0.4))
                        .frame(width: 36, height: 36)
                        .background((achieved ? AppTheme.amber : AppTheme.warmTextSecondary).opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(achieved ? AppTheme.warmTextPrimary : AppTheme.warmTextSecondary.opacity(0.5))
                        Text("\(milestone.days) day streak")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }

                    Spacer()

                    if achieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.sage)
                            .font(.title3)
                    } else {
                        Text("\(milestone.days - bestStreak) to go")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 2. Tasks Completed Detail Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TasksCompletedDetailSheet: View {
    let tasksCompleted: Int
    let taskGoal: Int
    let period: ProgressPeriod

    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var taskStore

    // Generate daily task data for the bar graph
    private var dailyData: [(label: String, value: Int)] {
        let cal = Calendar.current
        let today = Date()
        let dayCount = period == .weekly ? 7 : 28
        let formatter = DateFormatter()
        formatter.dateFormat = period == .weekly ? "EEE" : "d"

        return (0..<dayCount).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let label = formatter.string(from: date)
            let completed = taskStore.tasks(for: date).filter {
                taskStore.isTaskCompleted($0, on: date)
            }.count
            return (label, completed)
        }
    }

    private var completionRate: Double {
        guard taskGoal > 0 else { return 0 }
        return min(Double(tasksCompleted) / Double(taskGoal), 1.0)
    }

    private var recentlyCompleted: [UserTask] {
        Array(taskStore.completedTasks.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary stats
                    taskSummaryRow

                    // Bar graph
                    barGraphSection

                    // Recent tasks
                    recentTasksSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Tasks Completed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    // MARK: Summary

    private var taskSummaryRow: some View {
        HStack(spacing: 16) {
            // Progress ring (larger)
            VStack(spacing: 8) {
                CircularProgressRingPublic(
                    completed: tasksCompleted,
                    goal: taskGoal
                )
                .frame(width: 90, height: 90)

                Text("Goal Progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 16)
            .glassCard()

            // Completion rate
            VStack(spacing: 8) {
                Text("\(Int(completionRate * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.orange)

                Text("Completion Rate")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)

                Text("\(tasksCompleted) of \(taskGoal) tasks")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 16)
            .glassCard()
        }
    }

    // MARK: Bar Graph

    private var barGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            BarGraphView(
                data: dailyData,
                barColor: AppTheme.orange,
                gradientEnd: AppTheme.amber
            )
            .frame(height: 180)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: Recent Tasks

    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Completed")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            if recentlyCompleted.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.4))
                        Text("No completed tasks yet")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(recentlyCompleted) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.sage)
                            .font(.body)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.warmTextPrimary)
                                .lineLimit(1)

                            if let date = task.scheduledDate {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.warmTextSecondary)
                            }
                        }

                        Spacer()

                        if task.priority != .none {
                            Text(task.priority.rawValue.capitalized)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(priorityColor(task.priority))
                                )
                        }
                    }

                    if task.id != recentlyCompleted.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func priorityColor(_ priority: UserTask.Priority) -> Color {
        switch priority {
        case .high:   return AppTheme.destructive
        case .medium: return AppTheme.amber
        case .low:    return AppTheme.sage
        case .none:   return AppTheme.warmTextSecondary
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 3. Time Spent Detail Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TimeSpentDetailSheet: View {
    let focusMinutes: Int
    let calmMinutes: Int
    let period: ProgressPeriod
    var dailyFocusMinutes: [String: Int] = [:]
    var dailyCalmMinutes: [String: Int] = [:]

    @Environment(\.dismiss) private var dismiss

    private var totalMinutes: Int { focusMinutes + calmMinutes }

    private var focusHours: String {
        String(format: "%d:%02d", focusMinutes / 60, focusMinutes % 60)
    }

    private var calmHours: String {
        String(format: "%d:%02d", calmMinutes / 60, calmMinutes % 60)
    }

    private var totalHours: String {
        String(format: "%d:%02d", totalMinutes / 60, totalMinutes % 60)
    }

    private var avgDailyMinutes: Int {
        let days = period == .weekly ? 7 : 30
        return totalMinutes / max(days, 1)
    }

    // Real daily time data from tracked sessions
    private var dailyTimeData: [(label: String, focus: Int, calm: Int)] {
        let dayCount = period == .weekly ? 7 : 28
        let formatter = DateFormatter()
        formatter.dateFormat = period == .weekly ? "EEE" : "d"
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        keyFormatter.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        let today = Date()

        return (0..<dayCount).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let label = formatter.string(from: date)
            let key = keyFormatter.string(from: date)
            let focusForDay = dailyFocusMinutes[key] ?? 0
            let calmForDay = dailyCalmMinutes[key] ?? 0
            return (label, focusForDay, calmForDay)
        }
    }

    // Convert to single-value data for bar graph display
    private var barData: [(label: String, value: Int)] {
        dailyTimeData.map { ($0.label, $0.focus + $0.calm) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time summary
                    timeSummaryRow

                    // Bar graph
                    timeBarGraphSection

                    // Breakdown
                    breakdownSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Time Spent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    // MARK: Summary

    private var timeSummaryRow: some View {
        HStack(spacing: 12) {
            timeStat(value: totalHours, label: "Total Hours", icon: "clock.fill", color: AppTheme.orange)
            timeStat(value: "\(avgDailyMinutes) min", label: "Daily Average", icon: "chart.bar.fill", color: AppTheme.sky)
        }
    }

    private func timeStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.warmTextPrimary)

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.warmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }

    // MARK: Bar Graph

    private var timeBarGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Time — \(period == .weekly ? "This Week" : "This Month")")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            BarGraphView(
                data: barData
            )
            .frame(height: 180)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: Breakdown

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            // Focus time bar
            breakdownRow(
                icon: "person.fill",
                label: "Focus Sessions",
                time: focusHours,
                minutes: focusMinutes,
                total: totalMinutes,
                color: AppTheme.orange
            )

            // Calm time bar
            breakdownRow(
                icon: "figure.mind.and.body",
                label: "Calm Centre",
                time: calmHours,
                minutes: calmMinutes,
                total: totalMinutes,
                color: AppTheme.sage
            )
        }
        .padding(16)
        .glassCard()
    }

    private func breakdownRow(icon: String, label: String, time: String, minutes: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                    Text("\(time) hrs")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }

                Spacer()

                Text("\(total > 0 ? Int(Double(minutes) / Double(total) * 100) : 0)%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 6)

                    Capsule()
                        .fill(color)
                        .frame(width: total > 0 ? geo.size.width * CGFloat(minutes) / CGFloat(total) : 0, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - 4. Focus Points Detail Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct FocusPointsDetailSheet: View {
    let totalPoints: Int
    let currentLevel: Int
    let periodPoints: Int
    let period: ProgressPeriod
    var dailyPoints: [String: Int] = [:]
    var focusSessionPoints: Int = 0
    var taskCompletionPoints: Int = 0
    var calmCentrePoints: Int = 0

    @Environment(\.dismiss) private var dismiss

    private var pointsForNextLevel: Int {
        (currentLevel + 1) * 500
    }

    private var levelProgress: Double {
        let needed = pointsForNextLevel
        let inLevel = totalPoints - (currentLevel * 500)
        return min(Double(max(inLevel, 0)) / Double(max(needed - currentLevel * 500, 1)), 1.0)
    }

    // Real points bar data from tracked daily points
    private var pointsBarData: [(label: String, value: Int)] {
        let dayCount = period == .weekly ? 7 : 28
        let formatter = DateFormatter()
        formatter.dateFormat = period == .weekly ? "EEE" : "d"
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        keyFormatter.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        let today = Date()

        return (0..<dayCount).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let label = formatter.string(from: date)
            let key = keyFormatter.string(from: date)
            let points = dailyPoints[key] ?? 0
            return (label, points)
        }
    }

    // Real points breakdown from actual sources
    private var breakdown: [(label: String, icon: String, points: Int, color: Color)] {
        return [
            ("Focus Sessions", "person.fill", focusSessionPoints, AppTheme.orange),
            ("Task Completion", "checkmark.circle.fill", taskCompletionPoints, AppTheme.sage),
            ("Calm Centre", "figure.mind.and.body", calmCentrePoints, AppTheme.sky),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Points & Level
                    pointsSummaryRow

                    // Level progress
                    levelProgressSection

                    // Bar graph
                    pointsBarGraphSection

                    // Breakdown
                    pointsBreakdownSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Focus Points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    // MARK: Summary

    private var pointsSummaryRow: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.orange)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.orange.opacity(0.12))
                    .clipShape(Circle())

                Text("\(totalPoints)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)

                Text("Total Points")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()

            VStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.sage)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.sage.opacity(0.12))
                    .clipShape(Circle())

                Text("+\(periodPoints)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.sage)

                Text(period == .weekly ? "This Week" : "This Month")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()
        }
    }

    // MARK: Level Progress

    private var levelProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(currentLevel)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                    Text("\(totalPoints) / \(pointsForNextLevel) pts to Level \(currentLevel + 1)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
                Spacer()
                Text("\(Int(levelProgress * 100))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.orange.opacity(0.12))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.orange, AppTheme.amber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geo.size.width * levelProgress), height: 10)
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 4, y: 0)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: Bar Graph

    private var pointsBarGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points Earned — \(period == .weekly ? "This Week" : "This Month")")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            BarGraphView(
                data: pointsBarData,
                barColor: AppTheme.orange,
                gradientEnd: AppTheme.amber
            )
            .frame(height: 180)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: Points Breakdown

    private var pointsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points Breakdown")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.warmTextPrimary)

            ForEach(breakdown, id: \.label) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(item.color)
                        .frame(width: 32, height: 32)
                        .background(item.color.opacity(0.12))
                        .clipShape(Circle())

                    Text(item.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.warmTextPrimary)

                    Spacer()

                    Text("+\(item.points)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(item.color)
                }
                if item.label != breakdown.last?.label {
                    Divider().opacity(0.3)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Reusable Bar Graph View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct BarGraphView: View {
    let data: [(label: String, value: Int)]
    var barColor: Color = AppTheme.orange
    var gradientEnd: Color = AppTheme.amber

    private var maxValue: Int {
        max(data.map(\.value).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth = max(8, (geo.size.width - CGFloat(data.count - 1) * 4 - 32) / CGFloat(max(data.count, 1)))
            let graphHeight = geo.size.height - 30

            VStack(spacing: 0) {
                // Bars area
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 4) {
                            // Value label on top
                            if item.value > 0 {
                                Text("\(item.value)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(AppTheme.warmTextSecondary)
                            }

                            // Bar
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(
                                    item.value > 0
                                        ? LinearGradient(
                                            colors: [barColor, gradientEnd],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                        : LinearGradient(
                                            colors: [AppTheme.warmTextSecondary.opacity(0.12), AppTheme.warmTextSecondary.opacity(0.12)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                )
                                .frame(
                                    width: barWidth,
                                    height: item.value > 0 ? max(6, graphHeight * CGFloat(item.value) / CGFloat(maxValue)) : 3
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: graphHeight)

                // X-axis labels
                HStack(spacing: 4) {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        Text(item.label)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                    }
                }
                .frame(height: 20)
                .padding(.top, 4)
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Public Circular Progress Ring (reusable from sheets)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CircularProgressRingPublic: View {
    let completed: Int
    let goal: Int

    private var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(completed) / Double(goal), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.orange.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round))

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.orange, AppTheme.amber, AppTheme.sage, AppTheme.orange],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fraction)

            VStack(spacing: 1) {
                Text("\(completed)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.warmTextPrimary)
                Text("/ \(goal)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
    }
}
