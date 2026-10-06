import SwiftUI

struct TransferOwnershipSheet: View {
    let community: Community
    let otherMembers: [CommunityMember]
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var memberProfiles: [User] = []
    @State private var selectedMemberId: UUID?
    @State private var isLoading = false
    @State private var searchField = ""
    
    var onTransferAndLeave: () -> Void
    
    var filteredProfiles: [User] {
        if searchField.isEmpty {
            return memberProfiles
        } else {
            return memberProfiles.filter { $0.fullName.localizedCaseInsensitiveContains(searchField) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading community members...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if memberProfiles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text("No members to transfer ownership to")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text("Select a member to transfer ownership to")) {
                            ForEach(filteredProfiles) { profile in
                                Button {
                                    selectedMemberId = profile.id
                                } label: {
                                    HStack {
                                        Group {
                                            if let urlStr = profile.profileImageUrl {
                                                if urlStr.hasPrefix("asset://") {
                                                    Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                                                        .resizable().scaledToFill()
                                                } else if let url = URL(string: urlStr) {
                                                    AsyncImage(url: url) { phase in
                                                        if let img = phase.image { img.resizable().scaledToFill() }
                                                        else { Image(systemName: "person.crop.circle.fill").foregroundStyle(.secondary) }
                                                    }
                                                } else {
                                                    Image(systemName: "person.crop.circle.fill").foregroundStyle(.secondary)
                                                }
                                            } else {
                                                Image(systemName: "person.crop.circle.fill").foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                        .background(Circle().fill(Color(.systemGray5)))
                                        
                                        VStack(alignment: .leading) {
                                            Text(profile.fullName)
                                                .font(.body.bold())
                                                .foregroundStyle(.primary)
                                            Text(profile.email)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedMemberId == profile.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(AppTheme.orange)
                                                .font(.title3)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundStyle(.secondary)
                                                .font(.title3)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchField, prompt: "Search members")
                }
                
                Button {
                    guard let targetId = selectedMemberId, let currentUserId = userStore.currentUser?.id else { return }
                    Task {
                        isLoading = true
                        await communityStore.transferOwnership(of: community, to: targetId)
                        await communityStore.leaveCommunity(community, userId: currentUserId)
                        isLoading = false
                        dismiss()
                        onTransferAndLeave()
                    }
                } label: {
                    Text("Transfer & Leave")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedMemberId == nil ? Color.gray.opacity(0.4) : AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(selectedMemberId == nil || isLoading)
                .padding()
            }
            .navigationTitle("Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                isLoading = true
                let ids = otherMembers.map { $0.userId }
                memberProfiles = await communityStore.fetchProfiles(for: ids)
                isLoading = false
            }
        }
    }
}
