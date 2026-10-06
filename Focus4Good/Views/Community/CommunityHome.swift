import SwiftUI

struct CommunityHome: View {
    @State private var addCommunity: Bool = false
    @State private var showRecentPosts: Bool = false
    @State private var showSavedPosts: Bool = false
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var selectedSavedPostCategory: String? = nil
    @State private var selectedRecentPostCategory: String? = nil
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var showMicError: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showNotificationsView: Bool = false
    
    @Environment(CommunityStore.self) private var communities
    @Environment(UserStore.self) private var userStore
    
    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    
    private var totalUnreadNotifications: Int {
        let lastChecked = UserDefaults.standard.double(forKey: "last_checked_notifications_\(currentUserId.uuidString)")
        
        let unreadRecentPostsCount = visibleRecentPosts.filter { post in
            if post.createdAt.timeIntervalSince1970 <= lastChecked { return false }
            let key = "last_visited_\(post.communityId.uuidString)"
            return post.createdAt.timeIntervalSince1970 > UserDefaults.standard.double(forKey: key)
        }.count
        
        let pendingRequestsCount = communities.communityMembers.filter { member in
            if member.role == "pending", member.joinedAt.timeIntervalSince1970 > lastChecked {
                if let community = communities.communities.first(where: { $0.id == member.communityId }) {
                    return community.creatorId == currentUserId
                }
            }
            return false
        }.count
        
        let alertsCount = communities.simulatedNotifications.filter { 
            $0.userId == currentUserId && !$0.isRead && $0.createdAt.timeIntervalSince1970 > lastChecked 
        }.count
        
        return unreadRecentPostsCount + pendingRequestsCount + alertsCount
    }
    
    private var createdCommunities: [Community] {
        communities.communities.filter { $0.creatorId == currentUserId }
    }
    
    private var visibleRecentPosts: [Post] {
        communities.posts.filter { post in
            guard let community = communities.communities.first(where: { $0.id == post.communityId }) else {
                return false
            }
            return community.creatorId == currentUserId || communities.isMember(communityId: community.id, userId: currentUserId)
        }
    }
    
    private var recentPostCategories: [String] {
        let tags = visibleRecentPosts.compactMap { $0.hashtag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }
    
    private var savedPostsList: [Post] {
        communities.posts.filter { communities.isSaved(postId: $0.id, userId: currentUserId) }
    }
    
    private var savedPostCategories: [String] {
        let tags = savedPostsList.compactMap { $0.hashtag }.filter { !$0.isEmpty }
        return Array(Set(tags)).sorted()
    }
    
    private var joinedCommunities: [Community] {
        communities.communities.filter {
            $0.creatorId != currentUserId && communities.isMember(communityId: $0.id, userId: currentUserId)
        }
    }
    
    @State private var joinedIdsSnapshot: Set<UUID> = []
    @State private var hasInitializedSnapshot = false
    
    private func updateSnapshot() {
        joinedIdsSnapshot = Set(communities.communities.filter {
            communities.isMember(communityId: $0.id, userId: currentUserId) || $0.creatorId == currentUserId
        }.map { $0.id })
    }
    
    private var forYouCommunities: [Community] {
        communities.communities.filter {
            !joinedIdsSnapshot.contains($0.id)
        }
    }
    
    private var filteredCommunities: [Community] {
        if searchText.isEmpty {
            return []
        } else {
            return communities.communities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Community List ──
                ScrollView {
                    // Custom Native-style Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color(.secondaryLabel))
                            .font(.system(size: 17))
                        
                        TextField("Search", text: $searchText)
                            .font(.system(size: 17))
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color(.label))
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(UIColor.tertiaryLabel))
                                    .font(.system(size: 17))
                            }
                        } else {
                            // Mic button — tappable, animates when active
                            Button {
                                if speechRecognizer.isListening {
                                    speechRecognizer.stopListening()
                                } else {
                                    speechRecognizer.transcript = ""
                                    speechRecognizer.startListening()
                                }
                            } label: {
                                Image(systemName: speechRecognizer.isListening ? "waveform" : "mic.fill")
                                    .foregroundStyle(speechRecognizer.isListening ? AppTheme.orange : Color(.secondaryLabel))
                                    .font(.system(size: 17))
                                    .symbolEffect(.pulse, isActive: speechRecognizer.isListening)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 36)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .onChange(of: speechRecognizer.transcript) { _, newValue in
                        if !newValue.isEmpty {
                            searchText = newValue
                        }
                    }
                    .onChange(of: speechRecognizer.errorMessage) { _, error in
                        if error != nil { showMicError = true }
                    }
                    .alert("Microphone Error", isPresented: $showMicError) {
                        Button("OK", role: .cancel) { speechRecognizer.errorMessage = nil }
                    } message: {
                        Text(speechRecognizer.errorMessage ?? "")
                    }
                    
                    LazyVStack(spacing: 16) {
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            yourCommunitiesTab
                        }
                    }
                    .padding(.bottom, 80) // space for FAB
                    .animation(.default, value: forYouCommunities)
                    .animation(.default, value: joinedCommunities)
                    .scrollContentBackground(.hidden) // Make scroll view transparent
                }
                .background(progressBackground)
                .navigationTitle("Community")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                showNotificationsView = true
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "bell")
                                        .foregroundStyle(AppTheme.orange)
                                        .padding(.trailing, 4)
                                    
                                    let totalUnread = totalUnreadNotifications
                                    
                                    if totalUnread > 0 {
                                        Text(totalUnread > 9 ? "9+" : "\(totalUnread)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.red)
                                            .clipShape(Capsule())
                                            .offset(x: 4, y: -4)
                                    }
                                }
                            }
                            
                            Button {
                                let now = Date().timeIntervalSince1970
                                let joined = communities.communities.filter {
                                    $0.creatorId == currentUserId || communities.isMember(communityId: $0.id, userId: currentUserId)
                                }
                                for community in joined {
                                    UserDefaults.standard.set(now, forKey: "last_visited_\(community.id.uuidString)")
                                }
                                showRecentPosts = true
                            } label: {
                                Image(systemName: "newspaper")
                                    .foregroundStyle(AppTheme.orange)
                            }
                            
                        }
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        addCommunity = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(AppTheme.buttonGradient)
                                    .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 6)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 10)
                }
                .sheet(isPresented: $addCommunity) {
                    AddCommunityView(addCommunity: $addCommunity)
                }
                .navigationDestination(isPresented: $showNotificationsView) {
                    CommunityNotificationsView()
                }
                .navigationDestination(isPresented: $showRecentPosts) {
                    VStack(spacing: 0) {
                        let filtered = selectedRecentPostCategory == nil ? visibleRecentPosts : visibleRecentPosts.filter { $0.hashtag == selectedRecentPostCategory }
                        if filtered.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray.opacity(0.4))
                                Text("No posts available")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filtered) { post in
                                        CommunityPostRowView(post: post)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    .background(progressBackground)
                    .navigationTitle("Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 16) {
                                Menu {
                                    Button {
                                        selectedRecentPostCategory = nil
                                    } label: {
                                        HStack {
                                            Text("All")
                                            if selectedRecentPostCategory == nil {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                    
                                    ForEach(recentPostCategories, id: \.self) { category in
                                        Button {
                                            selectedRecentPostCategory = category
                                        } label: {
                                            HStack {
                                                Text(category)
                                                if selectedRecentPostCategory == category {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .foregroundStyle(AppTheme.orange)
                                }
                                
                                Button {
                                    showSavedPosts = true
                                } label: {
                                    Image(systemName: "bookmark")
                                        .foregroundStyle(AppTheme.orange)
                                }
                            }
                        }
                    }
                }
                .navigationDestination(isPresented: $showSavedPosts) {
                    VStack(spacing: 0) {
                        let filtered = selectedSavedPostCategory == nil ? savedPostsList : savedPostsList.filter { $0.hashtag == selectedSavedPostCategory }
                        if filtered.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bookmark.slash")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray.opacity(0.4))
                                Text("No saved posts")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filtered) { post in
                                        CommunityPostRowView(post: post)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    .background(progressBackground)
                    .navigationTitle("Saved Posts")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    selectedSavedPostCategory = nil
                                } label: {
                                    HStack {
                                        Text("All")
                                        if selectedSavedPostCategory == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                ForEach(savedPostCategories, id: \.self) { category in
                                    Button {
                                        selectedSavedPostCategory = category
                                    } label: {
                                        HStack {
                                            Text(category)
                                            if selectedSavedPostCategory == category {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(AppTheme.orange)
                            }
                        }
                    }
                }
                .task {
                    await communities.fetchCommunities()
                    await communities.fetchAllMembers()
                    await communities.fetchSavedPosts(userId: currentUserId)
                    for community in communities.communities {
                        await communities.fetchPosts(communityId: community.id)
                    }
                    updateSnapshot()
                }

                .onChange(of: communities.communities) { _, _ in
                    updateSnapshot()
                }
                .onChange(of: communities.communityMembers) { _, _ in
                    updateSnapshot()
                }
                .onAppear {
                    let key = "hasSeenCommunityOnboarding_\(currentUserId.uuidString)"
                    if !UserDefaults.standard.bool(forKey: key) {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    emptyStateView
                        .background(Color(.systemGroupedBackground).ignoresSafeArea())
                }
            }
        }
    }

    private var searchResultsView: some View {
        Group {
            if filteredCommunities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray.opacity(0.4))
                        .padding(.top, 40)
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(filteredCommunities) { community in
                    CommunityRowView(community: community)
                }
            }
        }
    }

    private var yourCommunitiesTab: some View {
        Group {
            if createdCommunities.isEmpty && joinedCommunities.isEmpty && forYouCommunities.isEmpty {
                simpleEmptyStateView
            } else {
                if !createdCommunities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Created by You")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        ForEach(createdCommunities) { community in
                            CommunityRowView(community: community)
                        }
                    }
                }
                
                if !joinedCommunities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Joined Communities")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, createdCommunities.isEmpty ? 0 : 8)
                        
                        ForEach(joinedCommunities) { community in
                            CommunityRowView(community: community)
                        }
                    }
                }
                
                if !forYouCommunities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for you")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, (createdCommunities.isEmpty && joinedCommunities.isEmpty) ? 0 : 8)
                        
                        ForEach(forYouCommunities) { community in
                            CommunityRowView(community: community)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                if showOnboarding {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            UserDefaults.standard.set(true, forKey: "hasSeenCommunityOnboarding_\(currentUserId.uuidString)")
                            showOnboarding = false
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                }
                
                // ── Floating Illustration ──
                ZStack {
                    // Background glow
                    Circle()
                        .fill(AppTheme.orange.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                    
                    // Central large icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.orange, AppTheme.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.orange.opacity(0.4), radius: 20, y: 8)
                        
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    
                    // Top-left floating badge
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.orange)
                    }
                    .offset(x: -85, y: -55)
                    
                    // Top-right floating badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.indigo.opacity(0.3), radius: 8, y: 4)
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 90, y: -60)
                    
                    // Bottom-left floating badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.85), Color.teal],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 52, height: 52)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    .offset(x: -100, y: 50)
                    
                    // Bottom-right concentric rings (like Activity rings)
                    ZStack {
                        Circle()
                            .stroke(AppTheme.orange.opacity(0.3), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        Circle()
                            .stroke(Color.pink.opacity(0.5), lineWidth: 6)
                            .frame(width: 42, height: 42)
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 6)
                            .frame(width: 28, height: 28)
                    }
                    .offset(x: 92, y: 55)
                }
                .frame(height: 260)
                .padding(.top, 40)
                
                // ── Title & Description ──
                VStack(spacing: 16) {
                    Text("Create Your Community")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with others on the same journey. Share progress, find motivation, and grow together — all in one place.")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 32)
                .padding(.horizontal, 32)
                
                // ── Privacy Note ──
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.2.shield.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.orange)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safe & Supportive Space")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Communities are moderated and designed to be welcoming. You control what you share and who sees it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                // ── CTA Button ──
                Button {
                    UserDefaults.standard.set(true, forKey: "hasSeenCommunityOnboarding_\(currentUserId.uuidString)")
                    showOnboarding = false
                } label: {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.orange, AppTheme.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.orange.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }

    }
        
    private var simpleEmptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.4))
                .padding(.top, 40)
            Text("No communities found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
        // MARK: - For You Empty State (shows recent posts feed)
        private var forYouEmptyState: some View {
            VStack(spacing: 20) {

                // Recent posts from joined communities
                if !visibleRecentPosts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Posts")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        ForEach(visibleRecentPosts.prefix(5)) { post in
                            CommunityPostRowView(post: post)
                        }
                    }
                }
            }
        }
        
        // MARK: - Background
        private var progressBackground: some View {
            AppTheme.appGradient.ignoresSafeArea()
        }
    }
    
    #Preview {
        CommunityHome()
            .environment(CommunityStore.shared)
            .environment(UserStore.shared)
    }

// MARK: - CommunityNotificationsView
struct CommunityNotificationsView: View {
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    
    // For navigating to a post when tapped
    @State private var selectedPost: Post?
    @State private var showPostDetail = false
    
    // User Profiles State
    @State private var requesterNames: [UUID: String] = [:]
    @State private var selectedUserIdForProfile: UUID?
    
    // Time grouping
    @State private var lastCheckedAtAppear: Double? = nil
    
    private var currentUserId: UUID {
        userStore.currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    
    private var actualLastChecked: Double {
        lastCheckedAtAppear ?? UserDefaults.standard.double(forKey: "last_checked_notifications_\(currentUserId.uuidString)")
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    enum UnifiedNotification: Identifiable {
        case alert(AppNotification)
        case request(CommunityMember)
        case post(Post)
        
        var id: String {
            switch self {
            case .alert(let n): return "alert_\(n.id.uuidString)"
            case .request(let m): return "request_\(m.id.uuidString)"
            case .post(let p): return "post_\(p.id.uuidString)"
            }
        }
        
        var date: Date {
            switch self {
            case .alert(let n): return n.createdAt
            case .request(let m): return m.joinedAt
            case .post(let p): return p.createdAt
            }
        }
    }
    
    private var allNotifications: [UnifiedNotification] {
        var items: [UnifiedNotification] = []
        
        // Alerts
        let alerts = communityStore.simulatedNotifications.filter { $0.userId == currentUserId }
        items.append(contentsOf: alerts.map { .alert($0) })
        
        // Requests
        let myCommunitiyIds = Set(communityStore.communities.filter { $0.creatorId == currentUserId }.map { $0.id })
        let requests = communityStore.communityMembers.filter { member in
            guard myCommunitiyIds.contains(member.communityId) else { return false }
            if member.role == "pending" { return true }
            if member.role == "rejected" { return true }
            let key = "\(member.userId.uuidString)_\(member.communityId.uuidString)"
            if communityStore.resolvedRequests[key] == "accepted" { return true }
            return false
        }
        items.append(contentsOf: requests.map { .request($0) })
        
        // Posts
        let joined = communityStore.communities.filter { community in
            community.creatorId == currentUserId || communityStore.isMember(communityId: community.id, userId: currentUserId)
        }
        let joinedIds = Set(joined.map { $0.id })
        let posts = communityStore.posts.filter { joinedIds.contains($0.communityId) }
        items.append(contentsOf: posts.map { .post($0) })
        
        // Sort newest first, limit to 50
        return items.sorted(by: { $0.date > $1.date }).prefix(50).map { $0 }
    }
    
    private var recentNotifications: [UnifiedNotification] {
        allNotifications.filter { $0.date.timeIntervalSince1970 > actualLastChecked }
    }
    
    private var pastNotifications: [UnifiedNotification] {
        allNotifications.filter { $0.date.timeIntervalSince1970 <= actualLastChecked }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.appGradient.ignoresSafeArea()
                
                if allNotifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            if !recentNotifications.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("New")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(recentNotifications) { notif in
                                        notificationRow(for: notif, isRecent: true)
                                    }
                                }
                            }
                            
                            if !pastNotifications.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Earlier")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(pastNotifications) { notif in
                                        notificationRow(for: notif, isRecent: false)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .task {
                        let requests = allNotifications.compactMap { notif -> CommunityMember? in
                            if case .request(let member) = notif { return member }
                            return nil
                        }
                        let userIds = requests.map { $0.userId }
                        guard !userIds.isEmpty else { return }
                        let profiles = await communityStore.fetchProfiles(for: userIds)
                        var names: [UUID: String] = [:]
                        for profile in profiles {
                            names[profile.id] = profile.fullName
                        }
                        requesterNames = names
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showPostDetail) {
                if let post = selectedPost {
                    ScrollView {
                        CommunityPostRowView(post: post)
                            .padding()
                    }
                    .navigationTitle("Post")
                    .navigationBarTitleDisplayMode(.inline)
                    .background(AppTheme.appGradient.ignoresSafeArea())
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedUserIdForProfile != nil },
                set: { if !$0 { selectedUserIdForProfile = nil } }
            )) {
                if let userId = selectedUserIdForProfile {
                    OtherUserProfileView(userId: userId)
                }
            }
            .onAppear {
                if lastCheckedAtAppear == nil {
                    lastCheckedAtAppear = UserDefaults.standard.double(forKey: "last_checked_notifications_\(currentUserId.uuidString)")
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_checked_notifications_\(currentUserId.uuidString)")
                }
            }
            .alert("Error", isPresented: Binding(
                get: { communityStore.errorMessage != nil },
                set: { if !$0 { communityStore.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = communityStore.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func notificationRow(for notif: UnifiedNotification, isRecent: Bool) -> some View {
        switch notif {
        case .alert(let alert):
            alertRow(for: alert, isRecent: isRecent)
        case .request(let member):
            requestRow(for: member, isRecent: isRecent)
        case .post(let post):
            postRow(for: post, isRecent: isRecent)
        }
    }
    
    private func alertRow(for notif: AppNotification, isRecent: Bool) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppTheme.orange.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.orange)
                }
            
            Text(notif.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if isRecent {
                Circle()
                    .fill(AppTheme.orange)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
            
            Button {
                if let idx = communityStore.simulatedNotifications.firstIndex(where: { $0.id == notif.id }) {
                    communityStore.simulatedNotifications.remove(at: idx)
                }
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func requestRow(for member: CommunityMember, isRecent: Bool) -> some View {
        let communityName = communityStore.communities.first(where: { $0.id == member.communityId })?.name ?? "Unknown Community"
        let key = "\(member.userId.uuidString)_\(member.communityId.uuidString)"
        let requesterName = requesterNames[member.userId] ?? "Someone"
        
        // Determine resolved status from role or resolvedRequests
        let resolvedStatus: String? = {
            if member.role == "rejected" { return "rejected" }
            if member.role == "member", communityStore.resolvedRequests[key] == "accepted" { return "accepted" }
            if let status = communityStore.resolvedRequests[key] { return status }
            return nil
        }()
        
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                selectedUserIdForProfile = member.userId
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Avatar with initials
                    avatarInitials(requesterName, isOrange: true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("**\(requesterName)** wants to join")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(communityName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isRecent {
                        Circle()
                            .fill(AppTheme.orange)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }
                    
                    Text(timeAgo(from: member.joinedAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(.plain)
            
            if let resolvedStatus {
                HStack(spacing: 6) {
                    Image(systemName: resolvedStatus == "accepted" ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(resolvedStatus == "accepted" ? "Accepted" : "Rejected")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(resolvedStatus == "accepted" ? .green : .red)
                .padding(.top, 2)
            } else {
                HStack(spacing: 12) {
                    Button {
                        Task { await communityStore.rejectJoinRequest(member) }
                    } label: {
                        Text("Reject")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        Task { await communityStore.acceptJoinRequest(member) }
                    } label: {
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(AppTheme.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func postRow(for post: Post, isRecent: Bool) -> some View {
        let communityName = communityStore.communities.first(where: { $0.id == post.communityId })?.name ?? "Unknown Community"
        
        return Button {
            // Navigate to post
            selectedPost = post
            showPostDetail = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if let urlStr = post.authorImageUrl {
                    if urlStr.hasPrefix("asset://") {
                        Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                            .resizable().scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image { img.resizable().scaledToFill() }
                            else { avatarInitials(post.authorName) }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        avatarInitials(post.authorName)
                    }
                } else {
                    avatarInitials(post.authorName)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("**\(post.authorName ?? "Someone")** posted in **\(communityName)**")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !post.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(post.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if isRecent {
                    Circle()
                        .fill(AppTheme.orange)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
                
                Text(timeAgo(from: post.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func avatarInitials(_ name: String?, isOrange: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(isOrange ? AppTheme.orange.opacity(0.15) : Color(.systemGray5))
                .frame(width: 40, height: 40)
            
            if let firstChar = name?.first(where: { $0.isLetter }) {
                Text(String(firstChar).uppercased())
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(isOrange ? AppTheme.orange : .secondary)
            } else {
                Image(systemName: "person.fill")
                    .foregroundStyle(isOrange ? AppTheme.orange : .secondary)
            }
        }
    }
}

// MARK: - OtherUserProfileView
struct OtherUserProfileView: View {
    let userId: UUID
    @Environment(CommunityStore.self) private var communityStore
    @Environment(\.dismiss) private var dismiss
    @State private var profile: User?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let profile = profile {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [AppTheme.orange, AppTheme.orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                                .shadow(color: AppTheme.orange.opacity(0.3), radius: 10, y: 5)
                            
                            if let firstChar = profile.fullName.first, firstChar.isLetter {
                                Text(String(firstChar).uppercased())
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 8) {
                            Text(profile.fullName)
                                .font(.title.bold())
                                .foregroundStyle(AppTheme.warmTextPrimary)
                            
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.warmTextSecondary)
                        }
                        
                        Spacer()
                    } else {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.orange)
                }
            }
            .task {
                let profiles = await communityStore.fetchProfiles(for: [userId])
                profile = profiles.first
            }
        }
    }
}
