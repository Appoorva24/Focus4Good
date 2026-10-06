import SwiftUI

struct CommunityMemberRow: Identifiable {
    var id: UUID { memberId }
    let userId: UUID
    let memberId: UUID
    let name: String
    let email: String
    let imageUrl: String?
    let role: String
}

struct CommunityMembersSheet: View {
    let community: Community
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var memberRows: [CommunityMemberRow] = []
    @State private var isLoading = false
    @State private var searchField = ""
    @State private var memberToRemove: CommunityMemberRow?
    @State private var showRemoveAlert = false
    
    var filteredRows: [CommunityMemberRow] {
        if searchField.isEmpty {
            return memberRows
        } else {
            return memberRows.filter { $0.name.localizedCaseInsensitiveContains(searchField) || $0.email.localizedCaseInsensitiveContains(searchField) }
        }
    }
    
    var pendingRows: [CommunityMemberRow] {
        filteredRows.filter { $0.role == "pending" }
    }
    
    var activeRows: [CommunityMemberRow] {
        filteredRows.filter { $0.role == "member" || $0.role == "admin" }
    }
    
    private var isOwner: Bool {
        userStore.currentUser?.id == community.creatorId
    }
    
    private var isAdmin: Bool {
        if isOwner { return true }
        guard let userId = userStore.currentUser?.id else { return false }
        if let member = communityStore.communityMembers.first(where: { $0.communityId == community.id && $0.userId == userId }) {
            return member.role == "admin" || member.role == "owner"
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading members...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if memberRows.isEmpty {
                    ContentUnavailableView(
                        "No Members",
                        systemImage: "person.3.sequence.fill",
                        description: Text("This community doesn't have any members yet.")
                    )
                } else {
                    List {
                        // Pending Requests Section
                        if isAdmin && !pendingRows.isEmpty {
                            Section("Pending Requests") {
                                ForEach(pendingRows) { row in
                                    pendingMemberRow(row)
                                }
                            }
                        }
                        
                        // Active Members Section
                        if !activeRows.isEmpty {
                            Section("Members (\(activeRows.count))") {
                                ForEach(activeRows) { row in
                                    activeMemberRow(row)
                                }
                                .onDelete { indexSet in
                                    guard isOwner else { return }
                                    if let index = indexSet.first {
                                        let row = activeRows[index]
                                        if row.userId != community.creatorId {
                                            memberToRemove = row
                                            showRemoveAlert = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchField, prompt: "Search members")
                }
            }
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if isOwner && !activeRows.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
            .alert("Remove Member", isPresented: $showRemoveAlert) {
                Button("Remove", role: .destructive) {
                    if let row = memberToRemove,
                       let member = communityStore.communityMembers.first(where: { $0.id == row.memberId }) {
                        Task {
                            await communityStore.removeMember(member)
                            await fetchAndBuildMembers()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let row = memberToRemove {
                    Text("Are you sure you want to remove \(row.name) from this community?")
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
            .task {
                isLoading = true
                await fetchAndBuildMembers()
                isLoading = false
            }
        }
    }
    
    // MARK: - Pending Member Row
    @ViewBuilder
    private func pendingMemberRow(_ row: CommunityMemberRow) -> some View {
        HStack(spacing: 12) {
            avatarView(row)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                Text(row.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    if let member = communityStore.communityMembers.first(where: { $0.id == row.memberId }) {
                        Task {
                            await communityStore.acceptJoinRequest(member)
                            await fetchAndBuildMembers()
                        }
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                
                Button {
                    if let member = communityStore.communityMembers.first(where: { $0.id == row.memberId }) {
                        Task {
                            await communityStore.rejectJoinRequest(member)
                            await fetchAndBuildMembers()
                        }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Active Member Row
    @ViewBuilder
    private func activeMemberRow(_ row: CommunityMemberRow) -> some View {
        HStack(spacing: 12) {
            avatarView(row)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                Text(row.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            roleBadge(for: row)
        }
        .deleteDisabled(!isOwner || row.userId == community.creatorId)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func avatarView(_ row: CommunityMemberRow) -> some View {
        Group {
            if let urlStr = row.imageUrl {
                if urlStr.hasPrefix("asset://") {
                    Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                        .resizable().scaledToFill()
                } else if let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            initialsView(row.name)
                        }
                    }
                } else {
                    initialsView(row.name)
                }
            } else {
                initialsView(row.name)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
    
    @ViewBuilder
    private func initialsView(_ name: String) -> some View {
        ZStack {
            Circle().fill(AppTheme.orange.opacity(0.15))
            Text(String(name.prefix(1)).uppercased())
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.orange)
        }
    }
    
    @ViewBuilder
    private func roleBadge(for row: CommunityMemberRow) -> some View {
        let displayRole: String = {
            if row.userId == community.creatorId { return "Owner" }
            return row.role.capitalized
        }()
        
        Text(displayRole)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(displayRole == "Owner" || displayRole == "Admin" ? .white : .secondary)
            .background(
                Capsule()
                    .fill(displayRole == "Owner" || displayRole == "Admin" ? AppTheme.orange : Color(.systemGray5))
            )
    }
    
    // MARK: - Data
    private func fetchAndBuildMembers() async {
        let members = communityStore.communityMembers.filter {
            $0.communityId == community.id && ($0.role == "pending" || $0.role == "member" || $0.role == "admin")
        }
        guard !members.isEmpty else {
            memberRows = []
            return
        }
        
        let ids = members.map { $0.userId }
        let profiles = await communityStore.fetchProfiles(for: ids)
        
        var tempRows: [CommunityMemberRow] = []
        for member in members {
            if let profile = profiles.first(where: { $0.id == member.userId }) {
                tempRows.append(CommunityMemberRow(
                    userId: profile.id,
                    memberId: member.id,
                    name: profile.fullName,
                    email: profile.email,
                    imageUrl: profile.profileImageUrl,
                    role: member.role
                ))
            }
        }
        
        // Sort: Owner -> Admin -> Member by name
        memberRows = tempRows.sorted { r1, r2 in
            let isOwner1 = r1.userId == community.creatorId
            let isOwner2 = r2.userId == community.creatorId
            if isOwner1 != isOwner2 { return isOwner1 }
            
            let isAdmin1 = r1.role == "admin"
            let isAdmin2 = r2.role == "admin"
            if isAdmin1 != isAdmin2 { return isAdmin1 }
            
            return r1.name.localizedCompare(r2.name) == .orderedAscending
        }
    }
}
