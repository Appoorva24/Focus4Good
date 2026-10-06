import Foundation
import Supabase

@MainActor
@Observable
class TaskStore {
    
    // MARK: - State
    var tasks: [UserTask] = []
    var categories: [TaskCategory] = []
    var isLoading = false
    var errorMessage: String?
    
    /// Per-day completion tracking for repeating tasks.
    /// Maps task ID → set of date strings ("yyyy-MM-dd") that are completed.
    var taskCompletions: [UUID: Set<String>] = [:]
    
    // MARK: - Computed (UNCHANGED — these still work!)
    var todaysTasks: [UserTask] {
        return tasks(for: Date())
    }
    var completedTasks: [UserTask] { tasks.filter { $0.isCompleted } }
    var pendingTasks: [UserTask] { tasks.filter { !$0.isCompleted } }
    func tasks(for category: TaskCategory) -> [UserTask] {
        tasks.filter { $0.categoryId == category.id }
    }
    
    // MARK: - Filter Tasks for a Specific Date
    func tasks(for date: Date) -> [UserTask] {
        let cal = Calendar.current
        let targetComponents = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        let targetYMD = targetComponents.year! * 10000 + targetComponents.month! * 100 + targetComponents.day!
        
        return tasks.filter { task in
            guard let startDate = task.scheduledDate else { return false }
            
            let startComponents = cal.dateComponents([.year, .month, .day, .weekday], from: startDate)
            let startYMD = startComponents.year! * 10000 + startComponents.month! * 100 + startComponents.day!
            
            // If the target date is before the task's start date, it shouldn't appear
            if targetYMD < startYMD { return false }
            
            // If the task has an end date, and the target date is strictly after it, it shouldn't appear
            if let endDate = task.endDate {
                let endComponents = cal.dateComponents([.year, .month, .day], from: endDate)
                let endYMD = endComponents.year! * 10000 + endComponents.month! * 100 + endComponents.day!
                if targetYMD > endYMD { return false }
            }
            
            if task.repeatType == .never {
                // For non-repeating tasks with an end date: show every day from start to end (inclusive).
                // For non-repeating tasks without an end date: show only on the exact start date.
                if task.endDate != nil {
                    return true // targetDate is already validated to be within [taskStart, taskEnd]
                } else {
                    return targetYMD == startYMD
                }
            }
            
            // Evaluate repetition rules
            let targetDayStart = cal.startOfDay(for: date)
            let taskDayStart = cal.startOfDay(for: startDate)
            let daysDifference = cal.dateComponents([.day], from: taskDayStart, to: targetDayStart).day ?? 0
            
            switch task.repeatType {
            case .never:
                return false
            case .daily:
                return true
            case .weekdays:
                let weekday = cal.component(.weekday, from: date)
                return weekday >= 2 && weekday <= 6 // 2=Mon, 6=Fri
            case .weekends:
                let weekday = cal.component(.weekday, from: date)
                return weekday == 1 || weekday == 7 // 1=Sun, 7=Sat
            case .weekly:
                return startComponents.weekday == targetComponents.weekday
            case .fortnightly:
                return startComponents.weekday == targetComponents.weekday && (daysDifference % 14 == 0)
            case .monthly:
                return startComponents.day == targetComponents.day
            case .every3Months:
                let monthDiff = cal.dateComponents([.month], from: taskDayStart, to: targetDayStart).month ?? 0
                return startComponents.day == targetComponents.day && (monthDiff % 3 == 0)
            case .every6Months:
                let monthDiff = cal.dateComponents([.month], from: taskDayStart, to: targetDayStart).month ?? 0
                return startComponents.day == targetComponents.day && (monthDiff % 6 == 0)
            case .yearly:
                return startComponents.day == targetComponents.day && startComponents.month == targetComponents.month
            case .custom:
                return false
            }
        }
    }
    
    static let shared = TaskStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    // Cache keys are user-scoped to prevent data leaking between accounts
    private func tasksCacheKey(for userId: UUID) -> String { "cached_user_tasks_\(userId.uuidString)" }
    private func completionsCacheKey(for userId: UUID) -> String { "cached_task_completions_\(userId.uuidString)" }
    
    init() {
        // Do NOT load local data on init — data is loaded only after we know which
        // user is authenticated (via fetchTasks(userId:))
    }
    
    // MARK: - Local Persistence
    private func loadLocalData(for userId: UUID) {
        if let data = UserDefaults.standard.data(forKey: tasksCacheKey(for: userId)),
           let cached = try? JSONDecoder().decode([UserTask].self, from: data) {
            self.tasks = cached.map { normalizeTaskDates($0) }
            print("📦 Loaded \(self.tasks.count) tasks from local storage for user \(userId.uuidString.prefix(8))")
        }
        if let data = UserDefaults.standard.data(forKey: completionsCacheKey(for: userId)),
           let rawMap = try? JSONDecoder().decode([String: [String]].self, from: data) {
            var map: [UUID: Set<String>] = [:]
            for (k, v) in rawMap {
                if let uuid = UUID(uuidString: k) {
                    map[uuid] = Set(v)
                }
            }
            self.taskCompletions = map
        }
    }
    
    private func saveTasksLocally(for userId: UUID) {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksCacheKey(for: userId))
        }
        let rawMap = Dictionary(uniqueKeysWithValues: taskCompletions.map { ($0.key.uuidString, Array($0.value)) })
        if let data = try? JSONEncoder().encode(rawMap) {
            UserDefaults.standard.set(data, forKey: completionsCacheKey(for: userId))
        }
    }
    
    // Wipes in-memory state + cached data for a specific user (called on sign-out)
    func clearData(for userId: UUID? = nil) {
        tasks = []
        categories = []
        taskCompletions = [:]
        if let uid = userId {
            UserDefaults.standard.removeObject(forKey: tasksCacheKey(for: uid))
            UserDefaults.standard.removeObject(forKey: completionsCacheKey(for: uid))
        }
    }
    
    // MARK: - Date Normalization
    /// Normalizes scheduledDate and endDate to startOfDay to eliminate timezone drift
    /// from Supabase encode/decode cycles.
    private func normalizeTaskDates(_ task: UserTask) -> UserTask {
        let cal = Calendar.current
        var t = task
        if let date = t.scheduledDate {
            t.scheduledDate = cal.startOfDay(for: date)
        }
        if let date = t.endDate {
            t.endDate = cal.startOfDay(for: date)
        }
        return t
    }
    
    // MARK: - Fetch Tasks from Supabase
    func fetchTasks(userId: UUID) async {
        isLoading = false
        // Clear any stale in-memory data before loading for this user
        tasks = []
        taskCompletions = [:]
        // Load this user's local cache
        loadLocalData(for: userId)
        do {
            let fetched: [UserTask] = try await client
                .from("tasks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let normalizedFetched = fetched.map { normalizeTaskDates($0) }
            // Merge fetched with any local-only tasks (same user) to avoid losing offline-created tasks
            var merged = normalizedFetched
            let fetchedIds = Set(normalizedFetched.map { $0.id })
            for localTask in tasks where !fetchedIds.contains(localTask.id) {
                // Only keep local tasks that belong to this user
                if localTask.userId == userId {
                    merged.append(localTask)
                }
            }
            tasks = merged
            saveTasksLocally(for: userId)
            print("✅ Synced \(tasks.count) tasks from Supabase for user \(userId.uuidString.prefix(8))")
        } catch {
            // Offline — keep the user's local cache that was already loaded
            print("⚠️ fetchTasks: \(error.localizedDescription), using \(tasks.count) local tasks")
        }
        isLoading = false
    }
    
    // MARK: - Add Task
    func addTask(_ task: UserTask) async {
        // 1. Normalize dates
        let taskToAdd = normalizeTaskDates(task)
        print("📝 Adding task: \(taskToAdd.title) | scheduledDate=\(String(describing: taskToAdd.scheduledDate)) | endDate=\(String(describing: taskToAdd.endDate))")
        
        // 2. Insert into local tasks array immediately and persist
        var updatedTasks = tasks
        if let existingIndex = updatedTasks.firstIndex(where: { $0.id == taskToAdd.id }) {
            updatedTasks[existingIndex] = taskToAdd
        } else {
            updatedTasks.insert(taskToAdd, at: 0)
        }
        tasks = updatedTasks // Force trigger SwiftUI observation
        if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
        print("✅ Task inserted locally: \(taskToAdd.title)")
        
        // 3. Schedule notification if time is set
        if taskToAdd.scheduledTime != nil {
            await NotificationManager.shared.scheduleNotification(for: taskToAdd)
        }
        
        // 4. Try syncing to Supabase in the background
        do {
            let inserted: UserTask = try await client
                .from("tasks")
                .insert(taskToAdd)
                .select()
                .single()
                .execute()
                .value
            
            var finalTask = inserted
            if finalTask.scheduledDate == nil && taskToAdd.scheduledDate != nil {
                finalTask.scheduledDate = Calendar.current.startOfDay(for: taskToAdd.scheduledDate!)
            } else {
                finalTask = normalizeTaskDates(finalTask)
            }
            if finalTask.endDate == nil && taskToAdd.endDate != nil {
                finalTask.endDate = Calendar.current.startOfDay(for: taskToAdd.endDate!)
            }
            
            if let idx = tasks.firstIndex(where: { $0.id == taskToAdd.id || $0.id == finalTask.id }) {
                var updated = tasks
                updated[idx] = finalTask
                tasks = updated
                if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
            }
            print("☁️ Task synced to Supabase: \(finalTask.title)")
        } catch {
            print("⚠️ Supabase sync skipped/failed (offline/bypassed): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Add Tasks Batch
    func addTasksBatch(_ taskItems: [UserTask]) async {
        for task in taskItems {
            await addTask(task)
        }
    }
    
    // MARK: - Update Task
    func updateTask(_ task: UserTask) async {
        let normalized = normalizeTaskDates(task)
        if let index = tasks.firstIndex(where: { $0.id == normalized.id }) {
            tasks[index] = normalized
            if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
            await NotificationManager.shared.cancelNotification(for: normalized.id)
            if normalized.scheduledTime != nil {
                await NotificationManager.shared.scheduleNotification(for: normalized)
            }
        }
        
        do {
            try await client
                .from("tasks")
                .update(normalized)
                .eq("id", value: normalized.id.uuidString)
                .execute()
        } catch {
            print("⚠️ updateTask Supabase sync error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Task
    func deleteTask(_ task: UserTask) async {
        tasks.removeAll { $0.id == task.id }
        taskCompletions.removeValue(forKey: task.id)
        if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
        await NotificationManager.shared.cancelNotification(for: task.id)
        
        do {
            try await client
                .from("tasks")
                .delete()
                .eq("id", value: task.id.uuidString)
                .execute()
        } catch {
            print("⚠️ deleteTask Supabase sync error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Toggle Completion (legacy — non-repeating tasks)
    func toggleCompletion(for task: UserTask) async {
        // For repeating tasks, use the per-day version with today's date
        if task.repeatType != .never {
            await toggleCompletion(for: task, on: Date())
            return
        }
        var updated = task
        updated.isCompleted.toggle()
        await updateTask(updated)
        if updated.isCompleted, let userId = UserStore.shared.currentUser?.id {
            await ProgressStore.shared.incrementTasksCompleted(userId: userId)
            await ProgressStore.shared.addPointsEarned(points: 10, userId: userId)
            await UserStore.shared.updateFocusPoints(by: 10)
        }
    }
    
    // MARK: - Per-Day Completion (for repeating tasks)
    
    /// Check if a task is completed on a specific date.
    /// For non-repeating tasks, uses the `isCompleted` flag.
    /// For repeating tasks, checks the `taskCompletions` dictionary.
    func isTaskCompleted(_ task: UserTask, on date: Date) -> Bool {
        if task.repeatType == .never {
            return task.isCompleted
        }
        let dateKey = Self.dateKey(from: date)
        return taskCompletions[task.id]?.contains(dateKey) ?? false
    }
    
    /// Toggle completion for a task on a specific date.
    /// For repeating tasks, inserts/deletes from `task_completions` table.
    /// For non-repeating tasks, falls back to the old toggle.
    func toggleCompletion(for task: UserTask, on date: Date) async {
        if task.repeatType == .never {
            await toggleCompletion(for: task)
            return
        }
        
        let dateKey = Self.dateKey(from: date)
        let isCurrentlyCompleted = taskCompletions[task.id]?.contains(dateKey) ?? false
        
        if isCurrentlyCompleted {
            // Remove completion locally immediately
            taskCompletions[task.id]?.remove(dateKey)
            if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
            print("✅ Removed completion locally for \(task.title) on \(dateKey)")
            
            do {
                try await client
                    .from("task_completions")
                    .delete()
                    .eq("task_id", value: task.id.uuidString)
                    .eq("completed_date", value: dateKey)
                    .execute()
            } catch {
                print("⚠️ Remove completion Supabase error: \(error.localizedDescription)")
            }
        } else {
            // Add completion locally immediately
            if taskCompletions[task.id] == nil {
                taskCompletions[task.id] = []
            }
            taskCompletions[task.id]?.insert(dateKey)
            if let userId = UserStore.shared.currentUser?.id { saveTasksLocally(for: userId) }
            print("✅ Added completion locally for \(task.title) on \(dateKey)")
            
            // Increment progress
            if let userId = UserStore.shared.currentUser?.id {
                await ProgressStore.shared.incrementTasksCompleted(userId: userId)
                await ProgressStore.shared.addPointsEarned(points: 10, userId: userId)
                await UserStore.shared.updateFocusPoints(by: 10)
            }
            
            do {
                let completion = TaskCompletion(
                    taskId: task.id,
                    completedDate: dateKey
                )
                try await client
                    .from("task_completions")
                    .insert(completion)
                    .execute()
            } catch {
                print("⚠️ Add completion Supabase error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Fetch Task Completions
    func fetchTaskCompletions(userId: UUID) async {
        do {
            let fetched: [TaskCompletion] = try await client
                .from("task_completions")
                .select()
                .in("task_id", values: tasks.map { $0.id.uuidString })
                .execute()
                .value
            
            for c in fetched {
                if taskCompletions[c.taskId] == nil {
                    taskCompletions[c.taskId] = []
                }
                taskCompletions[c.taskId]?.insert(c.completedDate)
            }
            saveTasksLocally(for: userId)
            print("✅ Fetched \(fetched.count) task completions")
        } catch {
            print("⚠️ fetchTaskCompletions error: \(error.localizedDescription), using local completions")
        }
    }
    
    // MARK: - Date Key Helper
    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    static func dateKey(from date: Date) -> String {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        return dateKeyFormatter.string(from: day)
    }
    
    // MARK: - Categories
    func fetchCategories() async {
        isLoading = true
        do {
            let fetched: [TaskCategory] = try await client
                .from("task_categories")
                .select()
                .execute()
                .value
            categories = fetched
        } catch {
            // Auth bypassed — suppress user-facing error
        }
        isLoading = false
    }
    
    func addCategory(_ category: TaskCategory) async {
        do {
            let inserted: TaskCategory = try await client
                .from("task_categories")
                .insert(category)
                .select()
                .single()
                .execute()
                .value
            categories.append(inserted)
        } catch {
            // Auth bypassed — suppress user-facing error
        }
    }
    
    func updateCategory(_ category: TaskCategory) async {
        do {
            try await client
                .from("task_categories")
                .update(category)
                .eq("id", value: category.id.uuidString)
                .execute()
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index] = category
            }
        } catch {
            // Auth bypassed — suppress user-facing error
        }
    }
    
    func deleteCategory(_ category: TaskCategory) async {
        do {
            try await client
                .from("task_categories")
                .delete()
                .eq("id", value: category.id.uuidString)
                .execute()
            categories.removeAll { $0.id == category.id }
        } catch {
            // Auth bypassed — suppress user-facing error
        }
    }
}

