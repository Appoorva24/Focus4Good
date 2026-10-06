import Foundation

struct CommunityCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
}

// MARK: - Community
struct Community: Identifiable, Hashable {
    var id: UUID = UUID()
    var categoryId: UUID?
    var creatorId: UUID
    var name: String
    var description: String
    var coverImageUrl: String?
    var profileImageUrl: String?
    var isPrivate: Bool
    var memberCount: Int
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case creatorId = "creator_id"
        case name
        case description
        case coverImageUrl = "cover_image_url"
        case profileImageUrl = "profile_image_url"
        case isPrivate = "is_private"
        case memberCount = "member_count"
        case createdAt = "created_at"
    }
}

extension Community: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self, forKey: .id)
        categoryId    = try c.decodeIfPresent(UUID.self, forKey: .categoryId)
        creatorId     = try c.decode(UUID.self, forKey: .creatorId)
        name          = try c.decode(String.self, forKey: .name)
        description   = try c.decode(String.self, forKey: .description)
        coverImageUrl = try c.decodeIfPresent(String.self, forKey: .coverImageUrl)
        profileImageUrl = try c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        isPrivate     = try c.decode(Bool.self, forKey: .isPrivate)
        memberCount   = try c.decode(Int.self, forKey: .memberCount)
        createdAt     = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encode(creatorId, forKey: .creatorId)
        try c.encode(name, forKey: .name)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(coverImageUrl, forKey: .coverImageUrl)
        try c.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try c.encode(isPrivate, forKey: .isPrivate)
        try c.encode(memberCount, forKey: .memberCount)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

// MARK: - CommunityMember
struct CommunityMember: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var communityId: UUID
    var role: String
    var joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case communityId = "community_id"
        case role
        case joinedAt = "joined_at"
    }
}

extension CommunityMember: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        userId      = try c.decode(UUID.self, forKey: .userId)
        communityId = try c.decode(UUID.self, forKey: .communityId)
        role        = try c.decode(String.self, forKey: .role)
        joinedAt    = SupabaseDateCoding.flexDecode(from: c, key: .joinedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(communityId, forKey: .communityId)
        try c.encode(role, forKey: .role)
        try c.encode(SupabaseDateCoding.encodeTimestamp(joinedAt), forKey: .joinedAt)
    }
}

// MARK: - Post
struct Post: Identifiable, Hashable {
    var id: UUID = UUID()
    var authorId: UUID
    var communityId: UUID
    var content: String
    var imageUrl: String?
    var hashtag: String?
    var likeCount: Int
    var createdAt: Date

    // Joined fields — populated client-side from profiles, not stored in DB
    var authorName: String?
    var authorImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId = "author_id"
        case communityId = "community_id"
        case content
        case imageUrl = "image_url"
        case hashtag
        case likeCount = "like_count"
        case createdAt = "created_at"
        // authorName and authorImageUrl are NOT in the DB — excluded from CodingKeys
    }
}

extension Post: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        authorId    = try c.decode(UUID.self, forKey: .authorId)
        communityId = try c.decode(UUID.self, forKey: .communityId)
        content     = try c.decode(String.self, forKey: .content)
        imageUrl    = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        hashtag     = try c.decodeIfPresent(String.self, forKey: .hashtag)
        likeCount   = try c.decode(Int.self, forKey: .likeCount)
        createdAt   = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
        // Non-DB fields default to nil
        authorName = nil
        authorImageUrl = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(authorId, forKey: .authorId)
        try c.encode(communityId, forKey: .communityId)
        try c.encode(content, forKey: .content)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(hashtag, forKey: .hashtag)
        try c.encode(likeCount, forKey: .likeCount)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

// MARK: - PostLike
struct PostLike: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case createdAt = "created_at"
    }
}

extension PostLike: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self, forKey: .id)
        userId    = try c.decode(UUID.self, forKey: .userId)
        postId    = try c.decode(UUID.self, forKey: .postId)
        createdAt = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(postId, forKey: .postId)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

// MARK: - PostComment
struct PostComment: Identifiable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID
    var content: String
    var createdAt: Date

    // Joined fields — populated client-side from profiles
    var authorName: String?
    var authorImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
        case content
        case createdAt = "created_at"
        // authorName and authorImageUrl are NOT in the DB
    }
}

extension PostComment: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self, forKey: .id)
        userId    = try c.decode(UUID.self, forKey: .userId)
        postId    = try c.decode(UUID.self, forKey: .postId)
        content   = try c.decode(String.self, forKey: .content)
        createdAt = SupabaseDateCoding.flexDecode(from: c, key: .createdAt) ?? Date()
        authorName = nil
        authorImageUrl = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(postId, forKey: .postId)
        try c.encode(content, forKey: .content)
        try c.encode(SupabaseDateCoding.encodeTimestamp(createdAt), forKey: .createdAt)
    }
}

// MARK: - SavedPost
struct SavedPost: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var postId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
    }
}

// MARK: - AppNotification (Simulated Local Notifications)
struct AppNotification: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var message: String
    var createdAt: Date = Date()
    var isRead: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case message
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}
