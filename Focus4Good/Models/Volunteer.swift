import Foundation

// MARK: - Impact Goal (Focus Points Donation Tiers)

struct ImpactGoal: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let pointsCost: Int
    let impactLabel: String

    static let allGoals: [ImpactGoal] = [
        ImpactGoal(
            title: "Stationery Kit",
            description: "Pencils, notebooks, erasers & a geometry box for one child",
            icon: "pencil.and.ruler.fill",
            pointsCost: 500,
            impactLabel: "1 Child"
        ),
        ImpactGoal(
            title: "Textbooks",
            description: "A full set of textbooks for one child for the academic year",
            icon: "text.book.closed.fill",
            pointsCost: 1000,
            impactLabel: "1 Child / Year"
        ),
        ImpactGoal(
            title: "School Kit",
            description: "School bag, books, uniform & shoes — everything to start school",
            icon: "backpack.fill",
            pointsCost: 2500,
            impactLabel: "1 Full Kit"
        ),
        ImpactGoal(
            title: "Library Books",
            description: "Donate 5 inspiring storybooks to the community center library",
            icon: "books.vertical.fill",
            pointsCost: 2000,
            impactLabel: "5 Books"
        ),
        ImpactGoal(
            title: "Art Supplies",
            description: "Colors, sketchbooks, and craft materials for creative learning",
            icon: "paintpalette.fill",
            pointsCost: 750,
            impactLabel: "1 Art Kit"
        )
    ]
}

// MARK: - Donation Record (local tracking)

struct DonationRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    let goalTitle: String
    let pointsSpent: Int
    let date: Date
}

// MARK: - NGO
struct NGO: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var location: String
    var mission: String
    var founderName: String
    var founderPhone: String
    var imageName: String
    var studentCount: Int
    var yearsActive: Int
    var projectCount: Int
    var isVerified: Bool
    var galleryImages: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case mission
        case founderName = "founder_name"
        case founderPhone = "founder_phone"
        case imageName = "image_name"
        case studentCount = "student_count"
        case yearsActive = "years_active"
        case projectCount = "project_count"
        case isVerified = "is_verified"
        case galleryImages = "gallery_images"
    }
}

// MARK: - VolunteerEvent
struct VolunteerEvent: Identifiable, Hashable {
    var id: UUID = UUID()
    var ngoId: UUID
    var title: String
    var location: String
    var eventDate: Date
    var participantCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case ngoId = "ngo_id"
        case title
        case location
        case eventDate = "event_date"
        case participantCount = "participant_count"
    }
}

extension VolunteerEvent: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self, forKey: .id)
        ngoId            = try c.decode(UUID.self, forKey: .ngoId)
        title            = try c.decode(String.self, forKey: .title)
        location         = try c.decode(String.self, forKey: .location)
        participantCount = try c.decode(Int.self, forKey: .participantCount)
        eventDate        = SupabaseDateCoding.flexDecode(from: c, key: .eventDate) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(ngoId, forKey: .ngoId)
        try c.encode(title, forKey: .title)
        try c.encode(location, forKey: .location)
        try c.encode(participantCount, forKey: .participantCount)
        try c.encode(SupabaseDateCoding.encodeDateOnly(eventDate), forKey: .eventDate)
    }
}

// MARK: - VolunteerRegistration
struct VolunteerRegistration: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var ngoId: UUID
    var fullName: String
    var email: String
    var phone: String
    var pastExperience: String
    var registeredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ngoId = "ngo_id"
        case fullName = "full_name"
        case email
        case phone
        case pastExperience = "past_experience"
        case registeredAt = "registered_at"
    }
}

extension VolunteerRegistration: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self, forKey: .id)
        userId         = try c.decode(UUID.self, forKey: .userId)
        ngoId          = try c.decode(UUID.self, forKey: .ngoId)
        fullName       = try c.decode(String.self, forKey: .fullName)
        email          = try c.decode(String.self, forKey: .email)
        phone          = try c.decode(String.self, forKey: .phone)
        pastExperience = try c.decode(String.self, forKey: .pastExperience)
        registeredAt   = SupabaseDateCoding.flexDecode(from: c, key: .registeredAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(ngoId, forKey: .ngoId)
        try c.encode(fullName, forKey: .fullName)
        try c.encode(email, forKey: .email)
        try c.encode(phone, forKey: .phone)
        try c.encode(pastExperience, forKey: .pastExperience)
        try c.encode(SupabaseDateCoding.encodeTimestamp(registeredAt), forKey: .registeredAt)
    }
}
