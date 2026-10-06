import SwiftUI

struct CommunityRowView: View {
    var community: Community
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @State private var showUnfollowAlert = false
    @State private var showPosts = false
    @State private var showCancelRequestAlert = false
    @State private var showRequestedAlert = false

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }

    private var isJoined: Bool {
        community.creatorId == currentUserId || communityStore.isMember(communityId: community.id, userId: currentUserId)
    }

    /// Posts belonging to this community
    private var communityPosts: [Post] {
        communityStore.posts(in: community)
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            // Tappable area: navigates to detail view unconditionally
            Button {
                updateLastVisited()
                showPosts = true
            } label: {
                communityInfo
            }
            .buttonStyle(.plain)

            Spacer()

            // Join button logic
            if !isJoined {
                let isPending = communityStore.hasPendingRequest(communityId: community.id, userId: currentUserId)
                
                Button {
                    if isPending {
                        showCancelRequestAlert = true
                    } else {
                        Task {
                            await communityStore.joinCommunity(community, userId: currentUserId)
                            if community.isPrivate {
                                showRequestedAlert = true
                            }
                        }
                    }
                } label: {
                    Text(isPending ? "Requested" : "Join")
                        .fontWeight(.semibold)
                        .frame(width: 100)
                        .padding(.vertical, 6)
                        .background(isPending ? Color.gray : AppTheme.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                // Notification Badge for 'Your Communities' tab
                let unreadCount = communityPosts.filter { $0.createdAt.timeIntervalSince1970 > lastVisited }.count
                if unreadCount > 0 {
                    Text(unreadCount > 4 ? "4+" : "\(unreadCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var lastVisitedKey: String { "last_visited_\(community.id.uuidString)" }
    private var lastVisited: Double { UserDefaults.standard.double(forKey: lastVisitedKey) }
    private func updateLastVisited() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastVisitedKey)
    }

    // MARK: - Community Info (icon + name + description)

    private var communityInfo: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                let displayUrlStr = community.profileImageUrl ?? community.coverImageUrl
                if let urlStr = displayUrlStr {
                    if urlStr.hasPrefix("asset://") {
                        Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                            .resizable().scaledToFill()
                    } else if let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image { img.resizable().scaledToFill() }
                            else { Image(systemName: "person.3.fill").font(.title3).foregroundStyle(.secondary) }
                        }
                    } else {
                        Image(systemName: "person.3.fill").font(.title3).foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "person.3.fill").font(.title3).foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .background(Circle().fill(Color(.systemGray5)))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Text(community.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(community.isPrivate ? "Private" : "Public")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemFill))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }

                Text(community.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(community.memberCount)")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble.fill")
                        Text("\(communityPosts.count)")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }

    var body: some View {
        cardContent
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), AppTheme.cardGradientEnd],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .shadow(color: AppTheme.orange.opacity(0.10), radius: 10, y: 3)
            .padding(.horizontal, 10)
            .navigationDestination(isPresented: $showPosts) {
                CommunityDetailView(community: community)
            }
        .alert("Unfollow Community", isPresented: $showUnfollowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    await communityStore.leaveCommunity(community, userId: currentUserId)
                }
            }
        } message: {
            Text("Are you sure you want to unfollow \"\(community.name)\"? You will no longer see its posts in Your Communities.")
        }
        .alert("Cancel Request", isPresented: $showCancelRequestAlert) {
            Button("Remove", role: .destructive) {
                Task {
                    await communityStore.removePendingRequest(communityId: community.id, userId: currentUserId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel your request to join this community?")
        }
        .alert("Request Sent", isPresented: $showRequestedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your request to join this private community has been sent to the admin.")
        }
    }
}

// MARK: - Community Posts Destination View

struct CommunityDetailView: View {
    var community: Community
    
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLeaveAlert = false
    @State private var showDissolveAlert = false
    @State private var showTransferSheet = false
    @State private var showAddPost = false
    @State private var showMembersSheet = false
    @State private var showPostsSheet = false
    @State private var showCancelRequestAlert = false
    @State private var showRequestedAlert = false

    private var posts: [Post] {
        communityStore.posts(in: community)
    }

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }

    private var otherMembers: [CommunityMember] {
        communityStore.communityMembers.filter { $0.communityId == community.id && $0.userId != currentUserId }
    }

    private var isJoined: Bool {
        community.creatorId == currentUserId || communityStore.isMember(communityId: community.id, userId: currentUserId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Native Profile Header
                VStack(alignment: .leading, spacing: 0) {
                    // Cover Banner & Avatar
                    ZStack(alignment: .bottomLeading) {
                        // Cover Banner
                        Group {
                            if let urlStr = community.coverImageUrl {
                                if urlStr.hasPrefix("asset://") {
                                    Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                                        .resizable().scaledToFill()
                                } else if let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image { img.resizable().scaledToFill() }
                                        else { Rectangle().fill(AppTheme.orange.opacity(0.1)) }
                                    }
                                } else {
                                    Rectangle().fill(AppTheme.orange.opacity(0.1))
                                }
                            } else {
                                Rectangle().fill(AppTheme.orange.opacity(0.1))
                            }
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        // Avatar
                        Group {
                            let displayUrlStr = community.profileImageUrl ?? community.coverImageUrl
                            if let urlStr = displayUrlStr {
                                if urlStr.hasPrefix("asset://") {
                                    Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                                        .resizable().scaledToFill()
                                } else if let url = URL(string: urlStr) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image { img.resizable().scaledToFill() }
                                        else { Image(systemName: "person.3.fill").font(.largeTitle).foregroundStyle(.secondary) }
                                    }
                                } else {
                                    Image(systemName: "person.3.fill").font(.largeTitle).foregroundStyle(.secondary)
                                }
                            } else {
                                Image(systemName: "person.3.fill").font(.largeTitle).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .background(Circle().fill(Color(.systemGray6)))
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 4))
                        .offset(y: 40) // Overlap bottom edge
                        .padding(.leading, 16)
                    }
                    .padding(.bottom, 40) // Space for overlapping avatar

                    // Name & Subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(community.name)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.leading)
                        
                        Text(community.isPrivate ? "Private Community" : "Public Community")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Native-style Stats Row
                    HStack(spacing: 16) {
                        Button {
                            showMembersSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("\(community.memberCount)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Members")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            showPostsSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(community.isPrivate && !isJoined ? "—" : "\(posts.count)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("Posts")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(community.isPrivate && !isJoined)
                        
                        Spacer() // Align stats to leading edge
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - About Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("ABOUT")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Text(community.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 16)
                }

                // MARK: - Posts Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("POSTS")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    if community.isPrivate && !isJoined {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("Private Community")
                                .font(.headline)
                            Text("Join this community to see its posts.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            let isPending = communityStore.hasPendingRequest(communityId: community.id, userId: currentUserId)
                            Button {
                                if isPending {
                                    showCancelRequestAlert = true
                                } else {
                                    Task {
                                        await communityStore.joinCommunity(community, userId: currentUserId)
                                        if community.isPrivate {
                                            showRequestedAlert = true
                                        }
                                    }
                                }
                            } label: {
                                Text(isPending ? "Requested" : "Join")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(isPending ? Color.gray : AppTheme.orange.opacity(0.4))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if posts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 36))
                                .foregroundStyle(.tertiary)
                            Text("No posts yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                CommunityPostRowView(post: post)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 18) {
                    if isJoined {
                        Button {
                            showAddPost = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        
                        Button {
                            if community.creatorId == currentUserId {
                                if otherMembers.isEmpty {
                                    showDissolveAlert = true
                                } else {
                                    showTransferSheet = true
                                }
                            } else {
                                showLeaveAlert = true
                            }
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                    } else {
                        let isPending = communityStore.hasPendingRequest(communityId: community.id, userId: currentUserId)
                        Button {
                            if isPending {
                                showCancelRequestAlert = true
                            } else {
                                Task {
                                    await communityStore.joinCommunity(community, userId: currentUserId)
                                    if community.isPrivate {
                                        showRequestedAlert = true
                                    }
                                }
                            }
                        } label: {
                            if isPending {
                                Image(systemName: "person.badge.clock")
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                        }
                    }
                }
            }
        }
        .task {
            await communityStore.fetchMembers(communityId: community.id)
        }
        .alert("Leave Community", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await communityStore.leaveCommunity(community, userId: currentUserId)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to leave \"\(community.name)\"?")
        }
        .alert("Leave & Dissolve Community", isPresented: $showDissolveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave & Dissolve", role: .destructive) {
                Task {
                    await communityStore.dissolveCommunity(community)
                    dismiss()
                }
            }
        } message: {
            Text("You are the only member left. If you leave, this community will be dissolved. Are you sure you want to leave and dissolve \"\(community.name)\"?")
        }
        .alert("Cancel Request", isPresented: $showCancelRequestAlert) {
            Button("Remove", role: .destructive) {
                Task {
                    await communityStore.removePendingRequest(communityId: community.id, userId: currentUserId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel your request to join this community?")
        }
        .alert("Request Sent", isPresented: $showRequestedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your request to join this private community has been sent to the admin.")
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferOwnershipSheet(community: community, otherMembers: otherMembers) {
                dismiss()
            }
        }
        .sheet(isPresented: $showAddPost) {
            AddPostView(isPresented: $showAddPost, community: community)
        }
        .sheet(isPresented: $showMembersSheet) {
            CommunityMembersSheet(community: community)
        }
        .sheet(isPresented: $showPostsSheet) {
            CommunityPostsSheet(community: community)
        }
    }
}

#Preview {
    NavigationStack {
        let communityObject = Community(categoryId: nil, creatorId: UUID(), name: "ADHD Community", description: "This community is for person who having adhd", isPrivate: false, memberCount: 59, createdAt: Date())
        CommunityRowView(community: communityObject)
            .environment(CommunityStore.shared)
            .environment(UserStore.shared)
    }
}
