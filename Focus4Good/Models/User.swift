import Foundation

// MARK: - User (maps to 'profiles' table)
struct User: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var fullName: String
    var email: String
    var profileImageUrl: String?
    var authProvider: String
    var focusPoints: Int
    var currentLevel: Int
    var bestStreak: Int
    var currentStreak: Int

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case profileImageUrl = "profile_image_url"
        case authProvider = "auth_provider"
        case focusPoints = "focus_points"
        case currentLevel = "current_level"
        case bestStreak = "best_streak"
        case currentStreak = "current_streak"
    }
}

// MARK: - UserSettings
struct UserSettings: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var appNotifications: Bool
    var goalCompletionNotifications: Bool
    var coachingNotifications: Bool
    var timezone: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case appNotifications = "app_notifications"
        case goalCompletionNotifications = "goal_completion_notifications"
        case coachingNotifications = "coaching_notifications"
        case timezone
    }
}

// MARK: - UserProgress
struct UserProgress: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var periodType: String
    var periodStart: Date
    var tasksCompleted: Int
    var focusTimeMinutes: Int
    var calmCentreMinutes: Int
    var focusPointsEarned: Int
    var taskGoal: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case periodType = "period_type"
        case periodStart = "period_start"
        case tasksCompleted = "tasks_completed"
        case focusTimeMinutes = "focus_time_minutes"
        case calmCentreMinutes = "calm_centre_minutes"
        case focusPointsEarned = "focus_points_earned"
        case taskGoal = "task_goal"
    }
}

extension UserProgress: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                = try c.decode(UUID.self, forKey: .id)
        userId            = try c.decode(UUID.self, forKey: .userId)
        periodType        = try c.decode(String.self, forKey: .periodType)
        tasksCompleted    = try c.decode(Int.self, forKey: .tasksCompleted)
        focusTimeMinutes  = try c.decode(Int.self, forKey: .focusTimeMinutes)
        calmCentreMinutes = try c.decode(Int.self, forKey: .calmCentreMinutes)
        focusPointsEarned = try c.decode(Int.self, forKey: .focusPointsEarned)
        taskGoal          = try c.decode(Int.self, forKey: .taskGoal)
        periodStart       = SupabaseDateCoding.flexDecode(from: c, key: .periodStart) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(periodType, forKey: .periodType)
        try c.encode(tasksCompleted, forKey: .tasksCompleted)
        try c.encode(focusTimeMinutes, forKey: .focusTimeMinutes)
        try c.encode(calmCentreMinutes, forKey: .calmCentreMinutes)
        try c.encode(focusPointsEarned, forKey: .focusPointsEarned)
        try c.encode(taskGoal, forKey: .taskGoal)
        try c.encode(SupabaseDateCoding.encodeDateOnly(periodStart), forKey: .periodStart)
    }
}
