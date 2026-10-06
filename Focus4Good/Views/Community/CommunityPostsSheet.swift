import SwiftUI

struct CommunityPostsSheet: View {
    let community: Community
    @Environment(CommunityStore.self) private var communityStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchField = ""
    
    private var posts: [Post] {
        communityStore.posts(in: community)
    }
    
    var filteredPosts: [Post] {
        if searchField.isEmpty {
            return posts
        } else {
            return posts.filter {
                $0.content.localizedCaseInsensitiveContains(searchField) ||
                ($0.hashtag?.localizedCaseInsensitiveContains(searchField) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredPosts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.4))
                        Text(posts.isEmpty ? "No posts yet" : "No matching posts found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPosts) { post in
                                CommunityPostRowView(post: post)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(AppTheme.appGradient.ignoresSafeArea())
            .navigationTitle("Posts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchField, prompt: "Search posts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
