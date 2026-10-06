import SwiftUI
import PhotosUI

struct AddCommunityView: View {
    @Binding var addCommunity: Bool
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self) private var userStore

    @State private var nameOfCommunity: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var isPrivate: Bool = false

    // Photo state
    @State private var coverImage: Image?
    @State private var coverImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var profileSelectedItem: PhotosPickerItem?
    @State private var showProfileCamera = false
    @State private var showProfilePhotoPicker = false

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack {
                // MARK: Cover Photo Section
                ZStack(alignment: .bottomLeading) {
                    Menu {
                        Button { showCamera = true } label: { Label("Camera", systemImage: "camera") }
                        Button { showPhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                    } label: {
                        ZStack {
                            if let coverImage {
                                coverImage.resizable().scaledToFill().frame(height: 160).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(AppTheme.orange.opacity(0.08)).frame(height: 160).frame(maxWidth: .infinity).overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8])).foregroundColor(AppTheme.orange.opacity(0.5)))
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(AppTheme.orange)
                                    Text(coverImage == nil ? "Add Cover Photo" : "Change Photo").font(.headline).foregroundStyle(AppTheme.orange)
                                }
                            }
                        }
                    }
                    
                    Menu {
                        Button { showProfileCamera = true } label: { Label("Camera", systemImage: "camera") }
                        Button { showProfilePhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                    } label: {
                        ZStack {
                            Circle().fill(AppTheme.cardBg).frame(width: 80, height: 80).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            if let profileImage {
                                profileImage.resizable().scaledToFill().frame(width: 72, height: 72).clipShape(Circle())
                            } else {
                                Image(systemName: "camera.circle.fill").resizable().foregroundStyle(AppTheme.orange, AppTheme.orange.opacity(0.2)).frame(width: 72, height: 72)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .offset(y: 40)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 48)

                // MARK: Form Fields
                VStack(spacing: 0) {
                    HStack {
                        Text("Name")
                            .font(.headline)
                            .foregroundStyle(AppTheme.warmTextPrimary)

                        Spacer()

                        TextField("Community Name", text: $nameOfCommunity)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppTheme.warmTextPrimary)
                    }
                    .padding()
                    Divider()

                    HStack {
                        Text("Category").font(.headline)
                            .foregroundStyle(AppTheme.warmTextPrimary)
                        Spacer()
                        Menu {
                            Button("Hyperactivity") { category = "Hyperactivity" }
                            Button("Focus") { category = "Focus" }
                            Button("Mindfulness") { category = "Mindfulness" }
                            Button("Study Tips") { category = "Study Tips" }
                            Button("Mental Health") { category = "Mental Health" }
                            Button("Volunteering") { category = "Volunteering" }
                            Button("Other") { category = "Other" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.isEmpty ? "Select" : category)
                                    .foregroundStyle(category.isEmpty ? AppTheme.warmTextSecondary : AppTheme.warmTextPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.warmTextSecondary)
                            }
                        }
                    }
                    .padding()
                    Divider()

                    VStack(alignment: .leading) {
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(4...8)
                            .padding(.vertical, 4)
                    }
                    .padding()
                }
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.orange.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(spacing: 0) {
                    HStack {
                        Toggle(isOn: $isPrivate) {
                            Text("Private Community")
                                .font(.headline)
                                .foregroundStyle(AppTheme.warmTextPrimary)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.orange.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)

                Button {
                    Task {
                        let userId = userStore.currentUser?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                        isSubmitting = true
                        
                        // Upload cover image to Supabase Storage if present
                        var uploadedCoverUrl: String?
                        if let imageData = coverImageData {
                            let path = "communities/\(userId.uuidString)/\(UUID().uuidString).jpg"
                            do {
                                uploadedCoverUrl = try await communityStore.uploadImage(data: imageData, path: path)
                            } catch {
                                print("Image upload failed, continuing without cover image: \(error)")
                            }
                        }
                        var uploadedProfileUrl: String?
                        if let profileData = profileImageData {
                            let path = "communities/\(userId.uuidString)/profile_\(UUID().uuidString).jpg"
                            uploadedProfileUrl = try? await communityStore.uploadImage(data: profileData, path: path)
                        }
                        
                        do {
                            try await communityStore.createCommunity(
                                name: nameOfCommunity,
                                description: description.isEmpty ? "A community about \(category.isEmpty ? "various topics" : category)." : description,
                                categoryId: nil,
                                isPrivate: isPrivate,
                                userId: userId,
                                coverImageUrl: uploadedCoverUrl,
                                profileImageUrl: uploadedProfileUrl
                            )
                            isSubmitting = false
                            addCommunity = false
                        } catch {
                            isSubmitting = false
                            errorMessage = "Failed to create community: \(error.localizedDescription)"
                            showErrorAlert = true
                        }
                    }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 8)
                        }
                        Text(isSubmitting ? "Creating..." : "Create Community")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(nameOfCommunity.isEmpty || isSubmitting ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(nameOfCommunity.isEmpty || isSubmitting)
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Add Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        addCommunity = false
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $coverImage, imageData: $coverImageData).ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        coverImageData = data
                        coverImage = Image(uiImage: uiImage)
                    }
                }
            }
            .fullScreenCover(isPresented: $showProfileCamera) {
                CameraPickerView(image: $profileImage, imageData: $profileImageData).ignoresSafeArea()
            }
            .photosPicker(isPresented: $showProfilePhotoPicker, selection: $profileSelectedItem, matching: .images, photoLibrary: .shared())
            .onChange(of: profileSelectedItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        profileImageData = data
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            }
        }
    }
}

// MARK: - Camera Picker (minimal bridge for camera hardware)

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: Image?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                parent.image = Image(uiImage: uiImage)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddCommunityView(addCommunity: .constant(true))
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
