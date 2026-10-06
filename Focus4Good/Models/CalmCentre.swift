import Foundation

//BreathingSession
struct BreathingSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cyclesCompleted = "cycles_completed"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//JpmrSession
struct JpmrSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//JpmrVideo
struct JpmrVideo: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var videoUrl: String

    enum CodingKeys: String, CodingKey {
        case id, title
        case videoUrl = "video_url"
    }
}

//GuidedMeditationSession
struct GuidedMeditationSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var meditationName: String
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case meditationName = "meditation_name"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//AsmrSound
struct AsmrSound: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var category: String
    var audioUrl: String
    var imageUrl: String
    var durationSeconds: Int

    init(name: String, description: String, category: String, audioUrl: String, imageUrl: String, durationSeconds: Int) {
        self.id = AsmrSound.stableId(for: name)
        self.name = name
        self.description = description
        self.category = category
        self.audioUrl = audioUrl
        self.imageUrl = imageUrl
        self.durationSeconds = durationSeconds
    }

    /// Produces the same UUID for the same name on every launch.
    private static func stableId(for name: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (i, byte) in name.utf8.enumerated() {
            bytes[i % 16] = bytes[i % 16] &+ byte
        }
        // Mark as UUID v5 (name-based) for spec correctness
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0],  bytes[1],  bytes[2],  bytes[3],
                           bytes[4],  bytes[5],  bytes[6],  bytes[7],
                           bytes[8],  bytes[9],  bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

//UserFavouriteAsmrSound
struct UserFavouriteAsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var soundId: UUID
    var savedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case soundId = "sound_id"
        case savedAt = "saved_at"
    }
}

//BrainDumpFolder
struct BrainDumpFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var entryCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case entryCount = "entry_count"
    }
}

//BrainDumpEntry
struct BrainDumpEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var folderId: UUID?
    var title: String?
    var content: String
    var drawingData: Data?
    var pointsEarned: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case title, content
        case drawingData = "drawing_data"
        case pointsEarned = "points_earned"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), userId: UUID, folderId: UUID? = nil, title: String? = nil, content: String, drawingData: Data? = nil, pointsEarned: Int = 10, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.folderId = folderId
        self.title = title
        self.content = content
        self.drawingData = drawingData
        self.pointsEarned = pointsEarned
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        folderId = try c.decodeIfPresent(UUID.self, forKey: .folderId)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        content = try c.decode(String.self, forKey: .content)
        drawingData = try c.decodeIfPresent(Data.self, forKey: .drawingData)
        pointsEarned = try c.decodeIfPresent(Int.self, forKey: .pointsEarned) ?? 10
        createdAt = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encodeIfPresent(folderId, forKey: .folderId)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(drawingData, forKey: .drawingData)
        try c.encode(pointsEarned, forKey: .pointsEarned)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

//ASMRPlaylist
struct ASMRPlaylist: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var purpose: String
    var coverImageName: String
    var placeholderColorHex: String
    var sounds: [AsmrSound]
}
