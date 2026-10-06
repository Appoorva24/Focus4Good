import SwiftUI

struct ScheduleView: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @State private var showAddTask = false
    @State private var selectedTask: UserTask?

    @State private var selectedDate: Date = Date()



    private var tasksForSelectedDate: [UserTask] {
        taskStore.tasks(for: selectedDate)
            .sorted { task1, task2 in
                let c1 = taskStore.isTaskCompleted(task1, on: selectedDate)
                let c2 = taskStore.isTaskCompleted(task2, on: selectedDate)
                if c1 != c2 {
                    return !c1 && c2
                }
                if let time1 = task1.scheduledTime, let time2 = task2.scheduledTime {
                    return time1 < time2
                } else if task1.scheduledTime != nil {
                    return true
                } else if task2.scheduledTime != nil {
                    return false
                }
                return task1.createdAt < task2.createdAt
            }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.pageGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                calendarView
                
                Group {
                    if tasksForSelectedDate.isEmpty {
                        emptyDayState
                    } else {
                        taskList
                    }
                }
            }

            floatingAddButton
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(initialDate: selectedDate)
        }

        .navigationDestination(item: $selectedTask) { task in
            PomodoroView(task: task)
        }
        .onAppear {
            // Refresh tasks and completions whenever the schedule is opened
            guard let userId = userStore.currentUser?.id else { return }
            Task {
                await taskStore.fetchTasks(userId: userId)
                await taskStore.fetchTaskCompletions(userId: userId)
            }
        }
    }

    // MARK: - Empty Day State

    private var emptyDayState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.orange.opacity(0.6))
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.orange.opacity(0.4))
                    .offset(x: 38, y: -38)
            }
            Text("No tasks for this day")
                .font(.headline)
                .foregroundStyle(AppTheme.warmTextSecondary)
            Text("Tap + to add one")
                .font(.subheadline)
                .foregroundStyle(AppTheme.warmTextSecondary.opacity(0.7))

            Spacer()
        }
    }

    // MARK: - Scrollable Calendar Strip

    private var calendarDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var dates: [Date] = []
        for i in -60...60 {
            if let d = cal.date(byAdding: .day, value: i, to: today) {
                dates.append(d)
            }
        }
        return dates
    }

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Month & Year header
            Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                .font(.title3.bold())
                .foregroundStyle(AppTheme.warmTextPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 10) {
                        ForEach(calendarDates, id: \.self) { date in
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDate(date, inSameDayAs: Date())

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(date.formatted(.dateTime.weekday(.short)).uppercased())
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(isSelected ? .white.opacity(0.85) : AppTheme.warmTextSecondary)

                                    Text(date.formatted(.dateTime.day()))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : (isToday ? AppTheme.orange : AppTheme.warmTextPrimary))
                                }
                                .frame(width: 44, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected ? AppTheme.orange : .clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isToday && !isSelected ? AppTheme.orange.opacity(0.5) : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(date)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .onAppear {
                        proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .center)
                    }
                }
            }

            Divider().padding(.horizontal, 16)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            Section {
                ForEach(tasksForSelectedDate) { task in
                    TaskRowView(task: task, date: selectedDate, selectedTask: $selectedTask)
                        .listRowBackground(AppTheme.cardBg)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let taskToDelete = tasksForSelectedDate[index]
                        Task { await taskStore.deleteTask(taskToDelete) }
                    }
                }
            } header: {
                HStack {
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline).foregroundStyle(AppTheme.warmTextPrimary).textCase(nil)
                    Spacer()
                    let remaining = tasksForSelectedDate.filter { !taskStore.isTaskCompleted($0, on: selectedDate) }.count
                    if remaining > 0 {
                        Text("\(remaining) Remaining").font(.caption.bold()).foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Floating Add Button (only shown when tasks exist)

    private var floatingAddButton: some View {
        Button { showAddTask = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold()).foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(AppTheme.orange))
                .shadow(color: AppTheme.orange.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 24).padding(.bottom, 32)
    }
}

struct TaskRowView: View {
    let task: UserTask
    let date: Date
    @Binding var selectedTask: UserTask?
    @Environment(TaskStore.self) private var taskStore

    private var isCompleted: Bool {
        taskStore.isTaskCompleted(task, on: date)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                Task { await taskStore.toggleCompletion(for: task, on: date) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isCompleted ? AppTheme.orange : Color(.systemGray3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isCompleted {
                        Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(AppTheme.orange)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isCompleted ? AppTheme.warmTextSecondary : AppTheme.warmTextPrimary)
                    .strikethrough(isCompleted)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if task.repeatType != .never {
                        tagView(task.repeatType.displayName, color: .purple)
                    }
                    if let time = task.scheduledTime {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.caption2)
                            Text(time.formatted(.dateTime.hour().minute())).font(.caption)
                        }
                        .foregroundStyle(AppTheme.warmTextSecondary)
                    }
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 3) {
                            Image(systemName: "timer").font(.caption2)
                            Text("\(duration)m").font(.caption)
                        }
                        .foregroundStyle(AppTheme.warmTextSecondary)
                    }
                }
            }

            Spacer()

            if !isCompleted {
                Button { selectedTask = task } label: {
                    Image(systemName: "timer").font(.title3).foregroundStyle(AppTheme.orange)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func tagView(_ text: String, color: Color) -> some View {
        Text(text).font(.caption2.bold()).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}
