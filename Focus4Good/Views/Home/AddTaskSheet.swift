import SwiftUI

struct AddTaskSheet: View {
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    var initialDate: Date?

    @State private var title = ""
    @State private var isDateEnabled = true
    @State private var selectedDate = Date()
    @State private var isEndDateEnabled = false
    @State private var endDate = Date()
    @State private var isTimeEnabled = false
    @State private var selectedTime = Date()
    @State private var repeatType: UserTask.RepeatType = .never
    @State private var difficulty: UserTask.Difficulty = .none
    @State private var estimatedDuration = 25

    init(initialDate: Date? = nil) {
        self.initialDate = initialDate
        let date = initialDate ?? Date()
        _selectedDate = State(initialValue: date)
        _isDateEnabled = State(initialValue: true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                
                List {
                    Section {
                        TextField("Task Name", text: $title).font(.body).foregroundStyle(AppTheme.warmTextPrimary)
                    } header: { Text("Task Name").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                    .listRowBackground(AppTheme.cardBg)

                Section {
                    Toggle(isOn: $isDateEnabled.animation()) {
                        Label("Start Date", systemImage: "calendar")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isDateEnabled {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.orange)
                    }

                    Toggle(isOn: $isEndDateEnabled.animation()) {
                        Label("End Date", systemImage: "calendar.badge.clock")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isEndDateEnabled {
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(AppTheme.orange)
                    }

                    Toggle(isOn: $isTimeEnabled.animation()) {
                        Label("Time", systemImage: "clock")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .tint(AppTheme.orange)

                    if isTimeEnabled {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .tint(AppTheme.orange)
                    }
                } header: { Text("Date & Time").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                Section {
                    Menu {
                        ForEach(UserTask.RepeatType.allCases, id: \.self) { type in
                            Button(type.displayName) { repeatType = type }
                        }
                    } label: {
                        HStack {
                            Label("Repeat", systemImage: "arrow.2.circlepath").foregroundStyle(AppTheme.warmTextPrimary)
                            Spacer()
                            Text(repeatType.displayName).foregroundStyle(AppTheme.warmTextPrimary)
                            Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
                        }
                    }
                    
                    Menu {
                        ForEach(UserTask.Difficulty.allCases, id: \.self) { diff in
                            Button(diff.displayName) { difficulty = diff }
                        }
                    } label: {
                        HStack {
                            Label("Difficulty", systemImage: "flame").foregroundStyle(AppTheme.warmTextPrimary)
                            Spacer()
                            Text(difficulty.displayName).foregroundStyle(AppTheme.warmTextPrimary)
                            Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
                        }
                    }
                } header: { Text("Repeat & Priority").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)

                Section {
                    HStack {
                        Label("Duration", systemImage: "timer")
                            .foregroundStyle(AppTheme.warmTextPrimary)
                        Spacer()
                        Stepper("\(estimatedDuration) min", value: $estimatedDuration, in: 5...240, step: 5)
                            .fixedSize()
                    }
                } header: { Text("More Options").foregroundStyle(AppTheme.warmTextPrimary).textCase(nil) }
                .listRowBackground(AppTheme.cardBg)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveTask() } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(title.isEmpty ? AppTheme.warmTextSecondary : AppTheme.orange)
                    }
                    .disabled(title.isEmpty)
                }
            }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .alert("Error Saving Task",
               isPresented: Binding(
                   get: { taskStore.errorMessage != nil },
                   set: { if !$0 { taskStore.errorMessage = nil } }
               ),
               presenting: taskStore.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func pickerRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon).foregroundStyle(AppTheme.warmTextPrimary)
                Spacer()
                Text(value).foregroundStyle(AppTheme.warmTextPrimary)
                Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(AppTheme.warmTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let userId = userStore.currentUser?.id ?? DummyData.currentUser.id
        
        let task = UserTask(
            userId: userId,
            categoryId: nil,
            title: trimmedTitle,
            scheduledDate: isDateEnabled ? selectedDate : (initialDate ?? Date()),
            endDate: isEndDateEnabled ? endDate : nil,
            scheduledTime: isTimeEnabled ? selectedTime : nil,
            repeatType: repeatType,
            priority: .none,
            difficulty: difficulty,
            isCompleted: false,
            estimatedDuration: estimatedDuration,
            createdAt: Date()
        )
        
        Task {
            taskStore.errorMessage = nil
            await taskStore.addTask(task)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

extension UserTask.RepeatType {
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .fortnightly: return "Fortnightly"
        case .monthly: return "Monthly"
        case .every3Months: return "Every 3 Months"
        case .every6Months: return "Every 6 Months"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

extension UserTask.Priority {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

extension UserTask.Difficulty {
    var displayName: String {
        switch self {
        case .none: return "None"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}
