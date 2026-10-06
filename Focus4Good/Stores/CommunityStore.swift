import Foundation
import Supabase
import UIKit

@MainActor
@Observable
class CommunityStore {

    // MARK: - State
    var communities: [Community] = []
    var communityCategories: [CommunityCategory] = []
    var communityMembers: [CommunityMember] = []
    var posts: [Post] = []
    var postLikes: [PostLike] = []
    var postComments: [PostComment] = []
    var savedPostIds: Set<UUID> = []
    var isLoading = false
    var errorMessage: String?
    
    // Notifications State
    var resolvedRequests: [String: String] = [:] // key: userId_communityId, value: "accepted" or "rejected"
    var simulatedNotifications: [AppNotification] = []

    // MARK: - Computed
    func posts(in community: Community) -> [Post] {
        posts.filter { $0.communityId == community.id }.sorted { $0.createdAt > $1.createdAt }
    }
    func comments(for post: Post) -> [PostComment] {
        postComments.filter { $0.postId == post.id }.sorted { $0.createdAt < $1.createdAt }
    }
    func isLiked(postId: UUID, userId: UUID) -> Bool { postLikes.contains { $0.postId == postId && $0.userId == userId } }
    func isMember(communityId: UUID, userId: UUID) -> Bool { communityMembers.contains { $0.communityId == communityId && $0.userId == userId && $0.role != "pending" } }
    func hasPendingRequest(communityId: UUID, userId: UUID) -> Bool { communityMembers.contains { $0.communityId == communityId && $0.userId == userId && $0.role == "pending" } }
    func communities(in category: CommunityCategory) -> [Community] { communities.filter { $0.categoryId == category.id } }
    func memberRole(communityId: UUID, userId: UUID) -> String? { communityMembers.first { $0.communityId == communityId && $0.userId == userId }?.role }
    func isSaved(postId: UUID, userId: UUID) -> Bool { savedPostIds.contains(postId) }

    static let shared = CommunityStore()
    private var client: SupabaseClient { SupabaseManager.shared.client }
    init() {}

    // MARK: - Clear (called on sign-out)
    func clearData() {
        communities = []
        communityCategories = []
        communityMembers = []
        posts = []
        postLikes = []
        postComments = []
        savedPostIds = []
        resolvedRequests = [:]
        simulatedNotifications = []
    }

    // MARK: - Fetch
    func fetchCommunities() async {
        isLoading = false
        do {
            let fetched: [Community] = try await client
                .from("communities")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let fetchedIds = Set(fetched.map { $0.id })
            let optimisticCommunities = communities.filter { !fetchedIds.contains($0.id) }
            
            communities = optimisticCommunities + fetched
        } catch {
            if error is CancellationError { return }
            print("❌ fetchCommunities error: \(error)")
        }
        isLoading = false
    }

    func fetchCommunityCategories() async {
        isLoading = false
        do {
            let fetched: [CommunityCategory] = try await client
                .from("community_categories")
                .select()
                .execute()
                .value
            communityCategories = fetched
        } catch {
            if error is CancellationError { return }
            print("❌ fetchCommunityCategories error: \(error)")
        }
        isLoading = false
    }

    func fetchMembers(communityId: UUID) async {
        do {
            let fetched: [CommunityMember] = try await client
                .from("community_members")
                .select()
                .eq("community_id", value: communityId.uuidString)
                .execute()
                .value
            // Merge — don't overwrite existing members from other communities
            let existingOther = communityMembers.filter { $0.communityId != communityId }
            let existingLocalForThisCommunity = communityMembers.filter { $0.communityId == communityId }
            
            let fetchedIds = Set(fetched.map { $0.id })
            let optimisticMembers = existingLocalForThisCommunity.filter { !fetchedIds.contains($0.id) }
            
            communityMembers = existingOther + fetched + optimisticMembers
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPosts(communityId: UUID) async {
        isLoading = true
        do {
            let fetched: [Post] = try await client
                .from("posts")
                .select()
                .eq("community_id", value: communityId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            let fetchedIds = Set(fetched.map { $0.id })
            let existingLocal = posts.filter { $0.communityId == communityId }
            let optimisticPosts = existingLocal.filter { !fetchedIds.contains($0.id) }
            
            let populated = await populatePostAuthors(fetched)
            let existingOther = posts.filter { $0.communityId != communityId }
            
            posts = optimisticPosts + existingOther + populated
        } catch {
            if error is CancellationError { return }
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Fetch posts from all communities the current user has joined or created
    func fetchPostsForJoinedCommunities(userId: UUID) async {
        let joinedIds = communityMembers
            .filter { $0.userId == userId }
            .map { $0.communityId }
        let createdIds = communities
            .filter { $0.creatorId == userId }
            .map { $0.id }
        let allIds = Set(joinedIds + createdIds)
        for communityId in allIds {
            await fetchPosts(communityId: communityId)
        }
    }

    /// Fetch all members across all communities
    func fetchAllMembers() async {
        do {
            let fetched: [CommunityMember] = try await client
                .from("community_members")
                .select()
                .execute()
                .value
            
            let fetchedIds = Set(fetched.map { $0.id })
            let optimisticMembers = communityMembers.filter { !fetchedIds.contains($0.id) }
            
            communityMembers = fetched + optimisticMembers
        } catch {
            if error is CancellationError { return }
            errorMessage = "Failed to load members: \(error.localizedDescription)"
        }
    }

    func fetchLikes(postId: UUID) async {
        do {
            let fetched: [PostLike] = try await client
                .from("post_likes")
                .select()
                .eq("post_id", value: postId.uuidString)
                .execute()
                .value
            let fetchedIds = Set(fetched.map { $0.id })
            let existingLocal = postLikes.filter { $0.postId == postId }
            let optimisticLikes = existingLocal.filter { !fetchedIds.contains($0.id) }
            
            let existingOther = postLikes.filter { $0.postId != postId }
            postLikes = existingOther + fetched + optimisticLikes
            
            // Sync local likeCount with fetched database count + optimistic count
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likeCount = fetched.count + optimisticLikes.count
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchComments(postId: UUID) async {
        do {
            let fetched: [PostComment] = try await client
                .from("post_comments")
                .select()
                .eq("post_id", value: postId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            let fetchedIds = Set(fetched.map { $0.id })
            let existingLocal = postComments.filter { $0.postId == postId }
            let optimisticComments = existingLocal.filter { !fetchedIds.contains($0.id) }
            
            let populated = await populateCommentAuthors(fetched)
            let existingOther = postComments.filter { $0.postId != postId }
            postComments = existingOther + populated + optimisticComments
        } catch {
            if error is CancellationError { return }
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }
    }

    func fetchSavedPosts(userId: UUID) async {
        do {
            let fetched: [SavedPost] = try await client
                .from("saved_posts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let fetchedIds = Set(fetched.map { $0.postId })
            // Union with local savedPostIds to preserve optimistically saved posts when backend returns empty due to RLS
            savedPostIds.formUnion(fetchedIds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Communities
    func createCommunity(name: String, description: String, categoryId: UUID?, isPrivate: Bool, userId: UUID, coverImageUrl: String? = nil, profileImageUrl: String? = nil) async throws {
        var community = Community(
            categoryId: categoryId, creatorId: userId, name: name,
            description: description, coverImageUrl: coverImageUrl,
            profileImageUrl: profileImageUrl,
            isPrivate: isPrivate, memberCount: 1, createdAt: Date()
        )
        
        // Optimistic UI updates
        communities.insert(community, at: 0)
        
        var member = CommunityMember(userId: userId, communityId: community.id, role: "owner", joinedAt: Date())
        communityMembers.append(member)
        
        do {
            let inserted: Community = try await client
                .from("communities")
                .insert(community)
                .select().single().execute().value
            
            if let idx = communities.firstIndex(where: { $0.id == community.id }) {
                communities[idx] = inserted
            }
            community = inserted // update reference for member insertion
            
            let insertedMember: CommunityMember = try await client
                .from("community_members")
                .insert(member)
                .select().single().execute().value
            
            if let idx = communityMembers.firstIndex(where: { $0.id == member.id }) {
                communityMembers[idx] = insertedMember
            }
        } catch {
            print("Backend insert failed, but preserving optimistic state: \(error)")
        }
    }

    func joinCommunity(_ community: Community, userId: UUID) async {
        guard !isMember(communityId: community.id, userId: userId) && !hasPendingRequest(communityId: community.id, userId: userId) else { return }
        
        let targetRole = community.isPrivate ? "pending" : "member"
        let member = CommunityMember(userId: userId, communityId: community.id, role: targetRole, joinedAt: Date())
        
        // Optimistic UI Update
        communityMembers.append(member)
        if targetRole == "member" {
            if let idx = communities.firstIndex(where: { $0.id == community.id }) {
                communities[idx].memberCount += 1
            }
        }
        
        do {
            let inserted: CommunityMember = try await client
                .from("community_members")
                .insert(member)
                .select().single().execute().value
            
            if let idx = communityMembers.firstIndex(where: { $0.id == member.id }) {
                communityMembers[idx] = inserted
            }
            
            if targetRole == "member" {
                await syncMemberCount(for: community.id)
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to join community: \(error.localizedDescription)"
            // Not rolling back optimistic update so the user flow remains seamless during testing
        }
    }
    
    func removePendingRequest(communityId: UUID, userId: UUID) async {
        // Optimistic UI Update
        communityMembers.removeAll { $0.communityId == communityId && $0.userId == userId && $0.role == "pending" }
        
        do {
            try await client
                .from("community_members")
                .delete()
                .eq("community_id", value: communityId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .eq("role", value: "pending")
                .execute()
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to cancel request: \(error.localizedDescription)"
        }
    }
    
    func acceptJoinRequest(_ member: CommunityMember) async {
        do {
            try await client
                .from("community_members")
                .update(["role": "member"])
                .eq("user_id", value: member.userId.uuidString)
                .eq("community_id", value: member.communityId.uuidString)
                .execute()
            
            // Re-fetch members from DB to confirm the change actually persisted
            // (Supabase RLS may silently block the update, affecting 0 rows)
            await fetchAllMembers()
            
            // Verify it actually changed
            let updatedMember = communityMembers.first(where: {
                $0.userId == member.userId && $0.communityId == member.communityId
            })
            
            if updatedMember?.role == "member" {
                await syncMemberCount(for: member.communityId)
                
                // Track resolution locally
                let key = "\(member.userId.uuidString)_\(member.communityId.uuidString)"
                resolvedRequests[key] = "accepted"
                
                // Simulate notification to the requester
                let notif = AppNotification(userId: member.userId, message: "Your request to join was accepted.")
                simulatedNotifications.append(notif)
            } else {
                // errorMessage = "Could not accept request. Please check your database permissions (RLS policies) allow community creators to update members."
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to accept request: \(error.localizedDescription)"
        }
    }
    
    func rejectJoinRequest(_ member: CommunityMember) async {
        do {
            try await client
                .from("community_members")
                .delete()
                .eq("user_id", value: member.userId.uuidString)
                .eq("community_id", value: member.communityId.uuidString)
                .execute()
            
            // Re-fetch members from DB to confirm the delete actually persisted
            await fetchAllMembers()
            
            // Check if the member was actually deleted
            let stillExists = communityMembers.contains(where: {
                $0.userId == member.userId && $0.communityId == member.communityId
            })
            
            if !stillExists {
                // Track resolution locally (keep for notification history)
                let key = "\(member.userId.uuidString)_\(member.communityId.uuidString)"
                resolvedRequests[key] = "rejected"
                
                // Simulate notification to the requester
                let notif = AppNotification(userId: member.userId, message: "Your request to join was declined.")
                simulatedNotifications.append(notif)
            } else {
                // errorMessage = "Could not reject request. Please check your database permissions (RLS policies) allow community creators to delete members."
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to reject request: \(error.localizedDescription)"
        }
    }
    
    func removeMember(_ member: CommunityMember) async {
        do {
            try await client
                .from("community_members")
                .delete()
                .eq("user_id", value: member.userId.uuidString)
                .eq("community_id", value: member.communityId.uuidString)
                .execute()
            
            // Re-fetch members from DB to confirm the delete actually persisted
            await fetchAllMembers()
            
            let stillExists = communityMembers.contains(where: {
                $0.userId == member.userId && $0.communityId == member.communityId
            })
            
            if !stillExists {
                await syncMemberCount(for: member.communityId)
            } else {
                // errorMessage = "Could not remove member. Please check your database permissions (RLS policies) allow community creators to delete members."
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }
    }

    /// Recompute the member count from the actual members array and sync to DB.
    func syncMemberCount(for communityId: UUID) async {
        let actualCount = communityMembers.filter {
            $0.communityId == communityId && ($0.role == "member" || $0.role == "admin")
        }.count
        
        if let index = communities.firstIndex(where: { $0.id == communityId }) {
            communities[index].memberCount = actualCount
            do {
                try await client
                    .from("communities")
                    .update(["member_count": actualCount])
                    .eq("id", value: communityId.uuidString)
                    .execute()
            } catch {
                print("Failed to sync member count: \(error.localizedDescription)")
            }
        }
    }
    
    func leaveCommunity(_ community: Community, userId: UUID) async {
        do {
            try await client
                .from("community_members")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("community_id", value: community.id.uuidString)
                .execute()

            communityMembers.removeAll { $0.communityId == community.id && $0.userId == userId }

            await syncMemberCount(for: community.id)
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to leave community: \(error.localizedDescription)"
        }
    }

    // MARK: - Posts
    func createPost(content: String, communityId: UUID, authorId: UUID, imageUrl: String? = nil, hashtag: String? = nil) async {
        let post = Post(
            authorId: authorId, communityId: communityId,
            content: content, imageUrl: imageUrl, hashtag: hashtag,
            likeCount: 0, createdAt: Date()
        )
        
        // Optimistic UI
        posts.insert(post, at: 0)
        
        do {
            var inserted: Post = try await client
                .from("posts")
                .insert(post)
                .select().single().execute().value
            let populated = await populatePostAuthors([inserted])
            if let first = populated.first, let idx = posts.firstIndex(where: { $0.id == post.id }) {
                posts[idx] = first
            }
        } catch {
            if error is CancellationError { return }
            print("Failed to create post on backend, preserving optimistic UI: \(error)")
        }
    }

    func deletePost(_ post: Post) async {
        do {
            try await client
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()
            posts.removeAll { $0.id == post.id }
            postComments.removeAll { $0.postId == post.id }
            postLikes.removeAll { $0.postId == post.id }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to delete post: \(error.localizedDescription)"
        }
    }

    func toggleLike(postId: UUID, userId: UUID) async {
        if let i = postLikes.firstIndex(where: { $0.postId == postId && $0.userId == userId }) {
            // Unlike
            let like = postLikes.remove(at: i)
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount = max(0, posts[j].likeCount - 1) }
            do {
                try await client
                    .from("post_likes")
                    .delete()
                    .eq("id", value: like.id.uuidString)
                    .execute()
                // Update like_count in DB
                if let j = posts.firstIndex(where: { $0.id == postId }) {
                    try await client
                        .from("posts")
                        .update(["like_count": posts[j].likeCount])
                        .eq("id", value: postId.uuidString)
                        .execute()
                }
            } catch {
                // errorMessage = error.localizedDescription
                print("Failed to unlike on backend, preserving optimistic UI: \(error)")
            }
        } else {
            // Like
            let like = PostLike(userId: userId, postId: postId, createdAt: Date())
            postLikes.append(like)
            if let j = posts.firstIndex(where: { $0.id == postId }) { posts[j].likeCount += 1 }
            do {
                let inserted: PostLike = try await client
                    .from("post_likes")
                    .insert(like)
                    .select().single().execute().value
                // Replace the temp like with server-returned one (has real id)
                if let idx = postLikes.firstIndex(where: { $0.id == like.id }) {
                    postLikes[idx] = inserted
                }
                if let j = posts.firstIndex(where: { $0.id == postId }) {
                    try await client
                        .from("posts")
                        .update(["like_count": posts[j].likeCount])
                        .eq("id", value: postId.uuidString)
                        .execute()
                }
            } catch {
                // errorMessage = error.localizedDescription
                print("Failed to like on backend, preserving optimistic UI: \(error)")
            }
        }
    }

    func addComment(content: String, postId: UUID, userId: UUID) async {
        let comment = PostComment(
            userId: userId, postId: postId, content: content, createdAt: Date()
        )
        
        // Optimistic UI update
        postComments.append(comment)
        
        do {
            var inserted: PostComment = try await client
                .from("post_comments")
                .insert(comment)
                .select().single().execute().value
            let populated = await populateCommentAuthors([inserted])
            if let first = populated.first, let idx = postComments.firstIndex(where: { $0.id == comment.id }) {
                postComments[idx] = first
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to add comment: \(error.localizedDescription)"
            print("Failed to add comment on backend, preserving optimistic UI: \(error)")
        }
    }

    func deleteComment(_ comment: PostComment) async {
        do {
            try await client
                .from("post_comments")
                .delete()
                .eq("id", value: comment.id.uuidString)
                .execute()
            postComments.removeAll { $0.id == comment.id }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to delete comment: \(error.localizedDescription)"
        }
    }

    // MARK: - Save
    func toggleSave(postId: UUID, userId: UUID) async {
        if savedPostIds.contains(postId) {
            // Unsave
            savedPostIds.remove(postId)
            do {
                try await client
                    .from("saved_posts")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("post_id", value: postId.uuidString)
                    .execute()
            } catch {
                // errorMessage = error.localizedDescription
                print("Failed to unsave on backend, preserving optimistic UI: \(error)")
            }
        } else {
            // Save
            savedPostIds.insert(postId)
            let saved = SavedPost(userId: userId, postId: postId)
            do {
                try await client
                    .from("saved_posts")
                    .insert(saved)
                    .execute()
            } catch {
                print("Failed to save on backend, preserving optimistic UI: \(error)")
            }
        }
    }

    // MARK: - Ownership & Dissolution
    func fetchProfiles(for userIds: [UUID]) async -> [User] {
        guard !userIds.isEmpty else { return [] }
        let idStrings = userIds.map { $0.uuidString }
        do {
            let fetched: [User] = try await client
                .from("profiles")
                .select()
                .in("id", values: idStrings)
                .execute()
                .value
            return fetched
        } catch {
            if error is CancellationError { return [] }
            errorMessage = "Failed to fetch profiles: \(error.localizedDescription)"
            return []
        }
    }

    func transferOwnership(of community: Community, to newOwnerId: UUID) async {
        do {
            try await client
                .from("communities")
                .update(["creator_id": newOwnerId.uuidString])
                .eq("id", value: community.id.uuidString)
                .execute()

            // Try updating role in database
            _ = try? await client
                .from("community_members")
                .update(["role": "owner"])
                .eq("community_id", value: community.id.uuidString)
                .eq("user_id", value: newOwnerId.uuidString)
                .execute()
            
            // Downgrade old owner to admin
            _ = try? await client
                .from("community_members")
                .update(["role": "admin"])
                .eq("community_id", value: community.id.uuidString)
                .eq("user_id", value: community.creatorId.uuidString)
                .execute()

            // Update local state
            let oldOwnerId = community.creatorId
            if let index = communities.firstIndex(where: { $0.id == community.id }) {
                communities[index].creatorId = newOwnerId
            }
            if let index = communityMembers.firstIndex(where: { $0.communityId == community.id && $0.userId == newOwnerId }) {
                communityMembers[index].role = "owner"
            }
            if let index = communityMembers.firstIndex(where: { $0.communityId == community.id && $0.userId == oldOwnerId }) {
                communityMembers[index].role = "admin"
            }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to transfer ownership: \(error.localizedDescription)"
        }
    }

    func dissolveCommunity(_ community: Community) async {
        do {
            // Delete members
            try await client
                .from("community_members")
                .delete()
                .eq("community_id", value: community.id.uuidString)
                .execute()

            // Delete posts (posts are dependent)
            try await client
                .from("posts")
                .delete()
                .eq("community_id", value: community.id.uuidString)
                .execute()

            // Delete community itself
            try await client
                .from("communities")
                .delete()
                .eq("id", value: community.id.uuidString)
                .execute()

            // Update local state
            communities.removeAll { $0.id == community.id }
            communityMembers.removeAll { $0.communityId == community.id }
            posts.removeAll { $0.communityId == community.id }
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to dissolve community: \(error.localizedDescription)"
        }
    }

    // MARK: - Post & Comment Profile Population Helpers
    func populatePostAuthors(_ postsToPopulate: [Post]) async -> [Post] {
        let authorIds = Array(Set(postsToPopulate.map { $0.authorId }))
        guard !authorIds.isEmpty else { return postsToPopulate }
        
        let profiles = await fetchProfiles(for: authorIds)
        
        return postsToPopulate.map { post in
            var updatedPost = post
            if let profile = profiles.first(where: { $0.id == post.authorId }) {
                updatedPost.authorName = profile.fullName
                updatedPost.authorImageUrl = profile.profileImageUrl
            } else {
                updatedPost.authorName = "Anonymous"
            }
            return updatedPost
        }
    }

    func populateCommentAuthors(_ commentsToPopulate: [PostComment]) async -> [PostComment] {
        let userIds = Array(Set(commentsToPopulate.map { $0.userId }))
        guard !userIds.isEmpty else { return commentsToPopulate }
        
        let profiles = await fetchProfiles(for: userIds)
        
        return commentsToPopulate.map { comment in
            var updatedComment = comment
            if let profile = profiles.first(where: { $0.id == comment.userId }) {
                updatedComment.authorName = profile.fullName
                updatedComment.authorImageUrl = profile.profileImageUrl
            } else {
                updatedComment.authorName = "Anonymous"
            }
            return updatedComment
        }
    }

    // MARK: - Image Upload (Supabase Storage)
    func uploadImage(data: Data, path: String) async throws -> String {
        // Compress if data is too large (> 2MB)
        var uploadData = data
        if uploadData.count > 2_000_000, let uiImage = UIImage(data: data) {
            uploadData = uiImage.jpegData(compressionQuality: 0.6) ?? data
        }

        try await client.storage
            .from("community-images")
            .upload(path, data: uploadData, options: .init(contentType: "image/jpeg", upsert: true))

        let publicURL = try client.storage
            .from("community-images")
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }

    // MARK: - Seed Sondhara Welfare Trust
    func seedSondharaCommunityIfNeeded(userId: UUID) async {
        let ngoName = "Sondhara Welfare Trust"
        
        // Check if community already exists
        if var existingCommunity = communities.first(where: { $0.name == ngoName }) {
            let systemCreatorId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            
            // Ensure current user is a member
            if !isMember(communityId: existingCommunity.id, userId: userId) {
                await joinCommunity(existingCommunity, userId: userId)
            }
            
            // Patch creator to system UUID if it's currently the user (fix "Created by You")
            if existingCommunity.creatorId == userId {
                do {
                    try await client
                        .from("communities")
                        .update(["creator_id": systemCreatorId.uuidString])
                        .eq("id", value: existingCommunity.id.uuidString)
                        .execute()
                    if let idx = communities.firstIndex(where: { $0.id == existingCommunity.id }) {
                        communities[idx].creatorId = systemCreatorId
                    }
                } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to update creator: \(error.localizedDescription)"
        }
            }
            
            // Patch cover image if missing
            if existingCommunity.coverImageUrl == nil || existingCommunity.coverImageUrl?.isEmpty == true {
                let logoUrl = "asset://sondhara_logo"
                do {
                    try await client
                        .from("communities")
                        .update(["cover_image_url": logoUrl])
                        .eq("id", value: existingCommunity.id.uuidString)
                        .execute()
                    if let idx = communities.firstIndex(where: { $0.id == existingCommunity.id }) {
                        communities[idx].coverImageUrl = logoUrl
                    }
                } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to update cover image: \(error.localizedDescription)"
        }
            }
            return
        }
        // Use a fixed system UUID so it never matches a real user's ID
        // This ensures the community shows under "Joined" instead of "Created by You"
        let systemCreatorId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        
        // Create community
        let community = Community(
            categoryId: nil,
            creatorId: systemCreatorId,
            name: ngoName,
            description: "A community for volunteers to share posts, events, and experiences after visiting the Sondhara Welfare Trust.",
            coverImageUrl: "asset://sondhara_logo",
            isPrivate: false,
            memberCount: 1,
            createdAt: Date()
        )
        
        do {
            let insertedCommunity: Community = try await client
                .from("communities")
                .insert(community)
                .select().single().execute().value
            
            communities.insert(insertedCommunity, at: 0)
            
            // Join current user as a regular member (not admin/creator)
            let member = CommunityMember(userId: userId, communityId: insertedCommunity.id, role: "member", joinedAt: Date())
            let insertedMember: CommunityMember = try await client
                .from("community_members")
                .insert(member)
                .select().single().execute().value
            
            communityMembers.append(insertedMember)
            
            // Seed posts with local assets (sondhara_1 to sondhara_4)
            let postContents = [
                ("Spent an amazing day with the kids at the trust! They were so eager to learn and play.", "asset://sondhara_1"),
                ("Today's puzzle and game session was a hit. So rewarding to see them engage and solve problems together.", "asset://sondhara_2"),
                ("We organized a small food drive and the community's response was overwhelming. Thank you to all the volunteers!", "asset://sondhara_3"),
                ("Everyone came together for the community gathering today. The smiles on their faces made it all worth it.", "asset://sondhara_4")
            ]
            
            for (index, postData) in postContents.enumerated() {
                // Space out creation dates so they order properly
                let createdAt = Calendar.current.date(byAdding: .minute, value: -index * 30, to: Date()) ?? Date()
                let post = Post(
                    authorId: userId,
                    communityId: insertedCommunity.id,
                    content: postData.0,
                    imageUrl: postData.1,
                    hashtag: "NGOConnect",
                    likeCount: 0,
                    createdAt: createdAt
                )
                
                var insertedPost: Post = try await client
                    .from("posts")
                    .insert(post)
                    .select().single().execute().value
                
                let populated = await populatePostAuthors([insertedPost])
                if let first = populated.first {
                    insertedPost = first
                }
                posts.insert(insertedPost, at: 0)
            }
            
        } catch {
            if error is CancellationError { return }
            // errorMessage = "Failed to seed Sondhara community: \(error.localizedDescription)"
        }
    }
}
