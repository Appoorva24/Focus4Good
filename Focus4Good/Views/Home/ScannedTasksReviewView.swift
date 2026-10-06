import SwiftUI

// MARK: - Scanned Tasks Review View
/// Allows user to review recognized tasks from handwritten notes,
/// select/deselect individual tasks, set Pomodoro timer slots for each,
/// and save the entire schedule.

struct ScannedTasksReviewView: View {
    @Binding var scannedTasks: [ScannedTask]
    var onDismissAll: () -> Void

    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var scheduleDate = Date()
    @State private var isSaving = false
    @State private var showSuccess = false

    private var selectedTasks: [ScannedTask] {
        scannedTasks.filter { $0.isSelected }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(scannedTasks.count) tasks found")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(selectedTasks.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()

                // Select/Deselect All
                Button {
                    let allSelected = scannedTasks.allSatisfy { $0.isSelected }
                    for i in scannedTasks.indices {
                        scannedTasks[i].isSelected = !allSelected
                    }
                } label: {
                    Text(scannedTasks.allSatisfy { $0.isSelected } ? "Deselect All" : "Select All")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .padding(16)

            Divider()

            // Date Picker
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.orange)
                Text("Schedule Date")
                    .font(.subheadline.weight(.medium))
                Spacer()
                DatePicker("", selection: $scheduleDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Task List
            List {
                ForEach($scannedTasks) { $task in
                    ScannedTaskRow(task: $task)
                }
            }
            .listStyle(.plain)

            Divider()

            // Save Button
            Button {
                saveTasks()
            } label: {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Add \(selectedTasks.count) Tasks")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if selectedTasks.isEmpty {
                            Capsule().fill(Color(.systemGray4))
                        } else {
                            Capsule().fill(
                                LinearGradient(
                                    colors: [AppTheme.orange, Color(hex: "F4845F")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                )
                .shadow(color: selectedTasks.isEmpty ? .clear : AppTheme.orange.opacity(0.3), radius: 10, y: 4)
            }
            .disabled(selectedTasks.isEmpty || isSaving)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("Review Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Tasks Added!", isPresented: $showSuccess) {
            Button("Done") {
                onDismissAll()
            }
        } message: {
            Text("\(selectedTasks.count) tasks have been added to your schedule.")
        }
    }

    private func saveTasks() {
        guard let userId = userStore.currentUser?.id else { return }
        isSaving = true

        Task {
            for task in selectedTasks {
                let estimatedDuration = task.pomodoroSlots * 25
                let newTask = UserTask(
                    userId: userId,
                    title: task.title,
                    scheduledDate: scheduleDate,
                    scheduledTime: nil,
                    repeatType: .never,
                    priority: .medium,
                    isCompleted: false,
                    estimatedDuration: estimatedDuration,
                    createdAt: Date()
                )
                await taskStore.addTask(newTask)
            }
            isSaving = false
            showSuccess = true
        }
    }
}

// MARK: - Scanned Task Row

struct ScannedTaskRow: View {
    @Binding var task: ScannedTask

    var body: some View {
        HStack(spacing: 14) {
            // Selection toggle
            Button {
                task.isSelected.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(task.isSelected ? AppTheme.orange : Color(.systemGray3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if task.isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
            .buttonStyle(.plain)

            // Task title (editable)
            VStack(alignment: .leading, spacing: 4) {
                TextField("Task name", text: $task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(task.isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

                // Pomodoro slots stepper
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.orange)

                    Text("\(task.pomodoroSlots) × 25 min")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    Stepper("", value: $task.pomodoroSlots, in: 1...8)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(task.isSelected ? 1.0 : 0.5)
    }
}
