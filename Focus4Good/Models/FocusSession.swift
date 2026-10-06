import Foundation

struct FocusSession: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var taskId: UUID?
    var sessionNumber: Int
    var totalSessions: Int
    var focusDurationMinutes: Int
    var breakDurationMinutes: Int
    var distractionCount: Int
    var pointsEarned: Int
    var status: SessionStatus
    var startedAt: Date
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case sessionNumber = "session_number"
        case totalSessions = "total_sessions"
        case focusDurationMinutes = "focus_duration_minutes"
        case breakDurationMinutes = "break_duration_minutes"
        case distractionCount = "distraction_count"
        case pointsEarned = "points_earned"
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }

    enum SessionStatus: String, Codable {
        case inProgress = "in_progress"
        case completed
        case cancelled
    }
}

extension FocusSession: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(UUID.self, forKey: .id)
        userId               = try c.decode(UUID.self, forKey: .userId)
        taskId               = try c.decodeIfPresent(UUID.self, forKey: .taskId)
        sessionNumber        = try c.decode(Int.self, forKey: .sessionNumber)
        totalSessions        = try c.decode(Int.self, forKey: .totalSessions)
        focusDurationMinutes = try c.decode(Int.self, forKey: .focusDurationMinutes)
        breakDurationMinutes = try c.decode(Int.self, forKey: .breakDurationMinutes)
        distractionCount     = try c.decode(Int.self, forKey: .distractionCount)
        pointsEarned         = try c.decode(Int.self, forKey: .pointsEarned)
        status               = try c.decode(SessionStatus.self, forKey: .status)
        startedAt            = SupabaseDateCoding.flexDecode(from: c, key: .startedAt) ?? Date()
        completedAt          = SupabaseDateCoding.flexDecode(from: c, key: .completedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(taskId, forKey: .taskId)
        try c.encode(sessionNumber, forKey: .sessionNumber)
        try c.encode(totalSessions, forKey: .totalSessions)
        try c.encode(focusDurationMinutes, forKey: .focusDurationMinutes)
        try c.encode(breakDurationMinutes, forKey: .breakDurationMinutes)
        try c.encode(distractionCount, forKey: .distractionCount)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(status, forKey: .status)
        try c.encode(SupabaseDateCoding.encodeTimestamp(startedAt), forKey: .startedAt)
        try c.encodeIfPresent(completedAt.map { SupabaseDateCoding.encodeTimestamp($0) }, forKey: .completedAt)
    }
}
