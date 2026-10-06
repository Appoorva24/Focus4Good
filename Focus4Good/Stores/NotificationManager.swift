import UserNotifications
import Foundation

/// Notification Manager - Handles all task notifications
class NotificationManager {
    
    static let shared = NotificationManager()
    init() {}
    
    // MARK: - Permission Handling
    
    /// Request notification permissions from user
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule notification for a task
    func scheduleNotification(for task: UserTask) async {
        // Cancel any existing notification for this task
        await cancelNotification(for: task.id)
        
        // Only schedule if task has time set
        guard let scheduledTime = task.scheduledTime else { return }
        
        // Check permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1
        
        // Add priority info if high
        if task.priority == .high {
            content.subtitle = "⚠️ High Priority"
        }
        
        // Create date components for trigger
        let taskDate = task.scheduledDate ?? Date()
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: taskDate
        )
        
        // Subtract 5 mins from scheduledTime
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -5, to: scheduledTime) ?? scheduledTime
        let timeComponents = Calendar.current.dateComponents(
            [.hour, .minute],
            from: notificationTime
        )
        
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        // Check if task is for repeat type
        if task.repeatType != .never {
            await scheduleRepeatingNotification(for: task, content: content, dateComponents: dateComponents)
        } else {
            // One-time notification
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: task.id.uuidString,
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    /// Schedule repeating notification for recurring tasks
    private func scheduleRepeatingNotification(
        for task: UserTask,
        content: UNMutableNotificationContent,
        dateComponents: DateComponents
    ) async {
        var triggerComponents = dateComponents
        
        // Configure repeat based on task repeat type
        switch task.repeatType {
        case .daily:
            triggerComponents.year = nil
            triggerComponents.month = nil
            triggerComponents.day = nil
            
        case .weekly:
            triggerComponents.year = nil
            triggerComponents.month = nil
            let weekday = Calendar.current.component(.weekday, from: task.scheduledDate ?? Date())
            triggerComponents.weekday = weekday
            
        case .weekdays:
            // Monday to Friday — schedule 5 separate notifications
            for weekday in 2...6 {
                var weekdayComponents = triggerComponents
                weekdayComponents.year = nil
                weekdayComponents.month = nil
                weekdayComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: weekdayComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "\(task.id.uuidString)-weekday-\(weekday)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
            return
            
        case .weekends:
            // Saturday and Sunday
            for weekday in [1, 7] {
                var weekendComponents = triggerComponents
                weekendComponents.year = nil
                weekendComponents.month = nil
                weekendComponents.weekday = weekday
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: weekendComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "\(task.id.uuidString)-weekend-\(weekday)",
                    content: content,
                    trigger: trigger
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
            return
            
        case .monthly:
            triggerComponents.year = nil
            triggerComponents.month = nil
            
        case .yearly:
            triggerComponents.year = nil
            
        default:
            triggerComponents.year = nil
            triggerComponents.month = nil
            triggerComponents.day = nil
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    /// Cancel notification for a specific task
    func cancelNotification(for taskId: UUID) async {
        let identifiers = [
            taskId.uuidString,
            "\(taskId.uuidString)-weekday-2",
            "\(taskId.uuidString)-weekday-3",
            "\(taskId.uuidString)-weekday-4",
            "\(taskId.uuidString)-weekday-5",
            "\(taskId.uuidString)-weekday-6",
            "\(taskId.uuidString)-weekend-1",
            "\(taskId.uuidString)-weekend-7"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Get count of pending notifications
    func getPendingNotificationsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
    
    // MARK: - Re-engagement Notifications (Zepto / Zomato Style)
    
    /// Notification tiers with escalating delays
    private enum ReengagementTier: CaseIterable {
        case twoHours, oneDay, threeDays, sevenDays
        
        var identifier: String {
            switch self {
            case .twoHours:  return "reengagement-2h"
            case .oneDay:    return "reengagement-1d"
            case .threeDays: return "reengagement-3d"
            case .sevenDays: return "reengagement-7d"
            }
        }
        
        var delaySeconds: TimeInterval {
            switch self {
            case .twoHours:  return 2 * 60 * 60       // 2 hours
            case .oneDay:    return 24 * 60 * 60       // 1 day
            case .threeDays: return 3 * 24 * 60 * 60   // 3 days
            case .sevenDays: return 7 * 24 * 60 * 60   // 7 days
            }
        }
        
        /// Pool of catchy messages — a random one is picked each time
        var messages: [(title: String, body: String)] {
            switch self {
            case .twoHours:
                return [
                    ("🎯 Your tasks are waiting!",
                     "A quick focus session can make all the difference. Let's crush it!"),
                    ("⏰ Time to lock in!",
                     "Your Pomodoro timer is ready. Just 25 minutes can change your whole day."),
                    ("📝 Got a minute?",
                     "Check off one small task — momentum is everything!"),
                    ("💪 You were on a roll!",
                     "Don't stop now. Open the app and keep that energy going."),
                    ("🚀 Ready for a focus sprint?",
                     "Your productivity streak is calling. Let's go!")
                ]
                
            case .oneDay:
                return [
                    ("🔥 Don't break your streak!",
                     "You've been crushing it lately — keep the momentum going!"),
                    ("🌟 Your Focus Points miss you!",
                     "Come back and earn more points to level up your classroom."),
                    ("📋 Tomorrow's tasks won't plan themselves!",
                     "Take 2 minutes to plan ahead. Future you will be grateful."),
                    ("🧘 Need a mental reset?",
                     "A quick breathing session in Calm Centre works wonders."),
                    ("🏆 You're so close to leveling up!",
                     "Just a few more focus sessions and you'll reach the next level.")
                ]
                
            case .threeDays:
                return [
                    ("🧘 Feeling overwhelmed?",
                     "Take 2 minutes in Calm Centre. You deserve a breather."),
                    ("💭 Your Brain Dump journal misses you!",
                     "Clear your mind — write down what's bothering you. It really helps."),
                    ("🎵 Unwind with some ASMR sounds",
                     "Tap in for a calming sensory session. Your brain will thank you."),
                    ("👥 Your community posted new updates!",
                     "See what others are achieving and get inspired."),
                    ("📊 Check your weekly progress!",
                     "See how far you've come. You might surprise yourself.")
                ]
                
            case .sevenDays:
                return [
                    ("🎁 We miss you!",
                     "Your Focus Points are gathering dust. Come back and level up!"),
                    ("💫 It's never too late to restart!",
                     "Even 5 minutes of focus today beats zero. We believe in you!"),
                    ("🌱 Small steps, big changes",
                     "Open the app, set one goal, and watch the magic happen."),
                    ("🤝 Your volunteer community needs you!",
                     "Check out new NGO events and make a real difference."),
                    ("🏠 Your virtual classroom is lonely!",
                     "Come back, earn points, and decorate your space. It's fun!"),
                    ("✨ Fresh start? We've got you!",
                     "No judgment, just good vibes. Let's pick up where you left off.")
                ]
            }
        }
    }
    
    /// Schedule the full re-engagement notification cascade.
    /// Call this when the app moves to the **background**.
    func scheduleReengagementNotifications(
        streak: Int = 0,
        points: Int = 0,
        level: Int = 1
    ) async {
        // Check permission first
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }
        
        // Cancel any existing re-engagement notifications first
        cancelReengagementNotifications()
        
        for tier in ReengagementTier.allCases {
            guard var message = tier.messages.randomElement() else { continue }
            
            // Personalize messages with user data when relevant
            message = personalizeMessage(message, streak: streak, points: points, level: level)
            
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default
            content.categoryIdentifier = "reengagement"
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: tier.delaySeconds,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: tier.identifier,
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        
        print("📲 Scheduled 4 re-engagement notifications")
    }
    
    /// Cancel all pending re-engagement notifications.
    /// Call this when the app becomes **active** again.
    func cancelReengagementNotifications() {
        let identifiers = ReengagementTier.allCases.map { $0.identifier }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
        print("🔕 Cancelled re-engagement notifications")
    }
    
    // MARK: - Personalization
    
    /// Dynamically inject user stats into notification copy for a personal touch
    private func personalizeMessage(
        _ message: (title: String, body: String),
        streak: Int,
        points: Int,
        level: Int
    ) -> (title: String, body: String) {
        var title = message.title
        var body = message.body
        
        // Add streak urgency if user has an active streak
        if streak > 0 && title.contains("streak") {
            body = "Your \(streak)-day streak is about to reset! \(body)"
        }
        
        // Add points info if relevant
        if points > 0 && body.contains("Focus Points") {
            body = body.replacingOccurrences(
                of: "Focus Points",
                with: "\(points) Focus Points"
            )
        }
        
        // Add level info
        if level > 1 && body.contains("level up") {
            body = body.replacingOccurrences(
                of: "level up",
                with: "reach Level \(level + 1)"
            )
        }
        
        return (title, body)
    }
}
