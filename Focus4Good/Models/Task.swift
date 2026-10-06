import Foundation

struct TaskCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var color: String
}

struct UserTask: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var categoryId: UUID?
    var title: String
    var scheduledDate: Date?
    var endDate: Date?
    var scheduledTime: Date?
    var repeatType: RepeatType
    var priority: Priority
    var difficulty: Difficulty
    var isCompleted: Bool
    var estimatedDuration: Int?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case categoryId = "category_id"
        case title
        case scheduledDate = "scheduled_date"
        case endDate = "end_date"
        case scheduledTime = "scheduled_time"
        case repeatType = "repeat_type"
        case priority
        case difficulty
        case isCompleted = "is_completed"
        case estimatedDuration = "estimated_duration"
        case createdAt = "created_at"
    }
    
    enum RepeatType: String, Codable, CaseIterable {
        case never, daily, weekdays, weekends, weekly
        case fortnightly, monthly
        case every3Months = "every_3_months"
        case every6Months = "every_6_months"
        case yearly, custom
    }
    
    enum Priority: String, Codable, CaseIterable {
        case none, low, medium, high
    }
    
    enum Difficulty: String, Codable, CaseIterable {
        case none, easy, medium, hard
    }
    
    // MARK: - Regular init (for creating tasks locally)
    init(
        id: UUID = UUID(),
        userId: UUID,
        categoryId: UUID? = nil,
        title: String,
        scheduledDate: Date? = nil,
        endDate: Date? = nil,
        scheduledTime: Date? = nil,
        repeatType: RepeatType,
        priority: Priority,
        difficulty: Difficulty = .none,
        isCompleted: Bool,
        estimatedDuration: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.categoryId = categoryId
        self.title = title
        self.scheduledDate = scheduledDate
        self.endDate = endDate
        self.scheduledTime = scheduledTime
        self.repeatType = repeatType
        self.priority = priority
        self.difficulty = difficulty
        self.isCompleted = isCompleted
        self.estimatedDuration = estimatedDuration
        self.createdAt = createdAt
    }
}

// MARK: - Custom Codable (uses shared SupabaseDateCoding utility)
extension UserTask: Codable {

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id           = try c.decode(UUID.self, forKey: .id)
        userId       = try c.decode(UUID.self, forKey: .userId)
        categoryId   = try c.decodeIfPresent(UUID.self, forKey: .categoryId)
        title        = try c.decode(String.self, forKey: .title)
        repeatType   = try c.decode(RepeatType.self, forKey: .repeatType)
        priority     = try c.decode(Priority.self, forKey: .priority)
        difficulty   = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .none
        isCompleted  = try c.decode(Bool.self, forKey: .isCompleted)
        estimatedDuration = try c.decodeIfPresent(Int.self, forKey: .estimatedDuration)

        // Flexibly decode dates — Supabase may return "2026-04-25" (date),
        // "14:30:00" (time), or full ISO8601 timestamps
        scheduledDate = SupabaseDateCoding.flexDecode(from: c, key: .scheduledDate)
        endDate       = SupabaseDateCoding.flexDecode(from: c, key: .endDate)
        scheduledTime = SupabaseDateCoding.flexDecode(from: c, key: .scheduledTime)
        createdAt     = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)

        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encode(title, forKey: .title)
        try c.encode(repeatType, forKey: .repeatType)
        try c.encode(priority, forKey: .priority)
        try c.encode(difficulty, forKey: .difficulty)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)

        // Encode dates as strings that match the Supabase column types
        try c.encodeIfPresent(scheduledDate.map { SupabaseDateCoding.encodeDateOnly($0) },
                              forKey: .scheduledDate)
        try c.encodeIfPresent(endDate.map { SupabaseDateCoding.encodeDateOnly($0) },
                              forKey: .endDate)
        try c.encodeIfPresent(scheduledTime.map { SupabaseDateCoding.encodeTimeOnly($0) },
                              forKey: .scheduledTime)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

// MARK: - Task Completion (per-day tracking for repeating tasks)

struct TaskCompletion: Codable {
    var id: UUID
    var taskId: UUID
    var completedDate: String  // "yyyy-MM-dd"
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case completedDate = "completed_date"
    }
    
    init(id: UUID = UUID(), taskId: UUID, completedDate: String) {
        self.id = id
        self.taskId = taskId
        self.completedDate = completedDate
    }
}

