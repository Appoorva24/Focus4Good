import SwiftUI
import PhotosUI

enum PostHashtag: String, CaseIterable, Identifiable {
    case none = "None"
    case adhd = "ADHD"
    case focusTips = "FocusTips"
    case mindfulness = "Mindfulness"
    case studying = "Studying"
    case sleepHygiene = "SleepHygiene"
    case diagnosis = "Diagnosis"
    case motivation = "Motivation"
    case question = "Question"
    case custom = "Custom..."
    
    var id: String { self.rawValue }
}

struct AddPostView: View {
    @Binding var isPresented: Bool
    var community: Community
    @Environment(CommunityStore.self) private var store
    @Environment(UserStore.self) private var userStore

    @State private var postDescription: String = ""
    @State private var selectedHashtag: PostHashtag = .none
    @State private var showCustomHashtagAlert = false
    @State private var customHashtagInput = ""
    @State private var customHashtagText = ""

    // Photo state
    @State private var coverImage: Image?
    @State private var coverImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private var currentUser: User? {
        userStore.currentUser
    }

    private var isPostDisabled: Bool {
        postDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && coverImageData == nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - Author & Hashtag Header
                        HStack(alignment: .top, spacing: 12) {
                            Group {
                                if let urlStr = currentUser?.profileImageUrl {
                                    if urlStr.hasPrefix("asset://") {
                                        Image(urlStr.replacingOccurrences(of: "asset://", with: ""))
                                            .resizable().scaledToFill()
                                    } else if let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { phase in
                                            if let img = phase.image { img.resizable().scaledToFill() }
                                            else { Image(systemName: "person.crop.circle.fill").font(.title).foregroundStyle(.secondary) }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.circle.fill").font(.title).foregroundStyle(.secondary)
                                    }
                                } else {
                                    Image(systemName: "person.crop.circle.fill").font(.title).foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .background(Circle().fill(Color(.systemGray5)))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentUser?.fullName ?? "Anonymous")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                if selectedHashtag != .none {
                                    Text("#\(selectedHashtag == .custom ? customHashtagText : selectedHashtag.rawValue)")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .foregroundStyle(AppTheme.orange)
                                        .background(AppTheme.orange.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Post Input Field
                        TextField("What's on your mind?", text: $postDescription, axis: .vertical)
                            .font(.body)
                            .textFieldStyle(.plain)
                            .padding(.horizontal)
                            .focused(FocusedField.description)
                        
                        // MARK: - Photo Preview
                        if let coverImage {
                            ZStack(alignment: .topTrailing) {
                                coverImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .clipped()
                                    .padding(.horizontal)
                                
                                Button {
                                    self.coverImage = nil
                                    self.coverImageData = nil
                                    self.selectedItem = nil
                                } label: {
                                    ZStack {
                                        Circle().fill(.white)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: .black.opacity(0.15), radius: 4)
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppTheme.warmTextPrimary)
                                    }
                                }
                                .padding(.trailing, 24)
                                .padding(.top, 8)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
                
                // MARK: - Bottom Actions Bar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 24) {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(AppTheme.orange)
                        }
                        
                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera")
                                .font(.title3)
                                .foregroundStyle(AppTheme.orange)
                        }
                        
                        // Hashtag Selector
                        Menu {
                            ForEach(PostHashtag.allCases) { tag in
                                Button {
                                    if tag == .custom {
                                        showCustomHashtagAlert = true
                                    } else {
                                        selectedHashtag = tag
                                    }
                                } label: {
                                    Text(tag == .none ? "No Hashtag" : (tag == .custom ? "Custom..." : "#\(tag.rawValue)"))
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "number")
                                    .font(.title3)
                                Text(selectedHashtag == .none ? "Hashtag" : "#\(selectedHashtag == .custom ? customHashtagText : selectedHashtag.rawValue)")
                                    .font(.subheadline.bold())
                            }
                            .foregroundStyle(AppTheme.orange)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        submitPost()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .tint(AppTheme.orange)
                        } else {
                            Text("Post")
                                .fontWeight(.bold)
                                .foregroundStyle(isPostDisabled ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                        }
                    }
                    .disabled(isPostDisabled || isSubmitting)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $coverImage, imageData: $coverImageData)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $selectedItem,
                          matching: .images,
                          photoLibrary: .shared())
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        coverImageData = data
                        coverImage = Image(uiImage: uiImage)
                    }
                }
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .alert("Custom Hashtag", isPresented: $showCustomHashtagAlert) {
                TextField("Enter hashtag (e.g. SelfCare)", text: $customHashtagInput)
                Button("OK") {
                    let cleaned = customHashtagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "#", with: "")
                    if !cleaned.isEmpty {
                        customHashtagText = cleaned
                        selectedHashtag = .custom
                    } else {
                        selectedHashtag = .none
                    }
                }
                Button("Cancel", role: .cancel) {
                    if customHashtagText.isEmpty {
                        selectedHashtag = .none
                    }
                }
            } message: {
                Text("Enter a custom hashtag without spaces or '#' symbol.")
            }
        }
    }
    
    private func submitPost() {
        Task {
            let authorId = currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            isSubmitting = true
            let tag = selectedHashtag == .none ? nil : (selectedHashtag == .custom ? customHashtagText : selectedHashtag.rawValue)
            
            var uploadedImageUrl: String?
            if let imageData = coverImageData {
                let path = "posts/\(authorId.uuidString)/\(UUID().uuidString).jpg"
                do {
                    uploadedImageUrl = try await store.uploadImage(data: imageData, path: path)
                } catch {
                    isSubmitting = false
                    errorMessage = "Failed to upload image. Please verify that the 'community-images' storage bucket is created in your Supabase dashboard and set to public.\n\nError: \(error.localizedDescription)"
                    showErrorAlert = true
                    return
                }
            }
            
            await store.createPost(
                content: postDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                communityId: community.id,
                authorId: authorId,
                imageUrl: uploadedImageUrl,
                hashtag: tag
            )
            isSubmitting = false
            isPresented = false
        }
    }
}

// Focus state helper
private enum FocusedField: Hashable {
    case description
}

extension View {
    fileprivate func focused(_ field: FocusedField) -> some View {
        self // Stub for focused modifier
    }
}
