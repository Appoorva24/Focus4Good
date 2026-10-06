import SwiftUI

// MARK: - NGO Connect View

struct NGOListView: View {
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    
    private var ngo: NGO? {
        volunteerStore.ngos.first ?? VolunteerStore.dummyNGOs.first
    }
    
    private var currentLevel: Int {
        // Temporarily hardcoded to 5 to unlock all levels for testing
        // userStore.currentUser?.currentLevel ?? 1
        5
    }

    var body: some View {
        Group {
            if let ngo = ngo {
                NGOConnectDetailView(ngo: ngo, currentLevel: currentLevel)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading NGO data...")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .background(AppTheme.pageGradient)
        .navigationTitle("NGO Connect")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if volunteerStore.ngos.isEmpty {
                await volunteerStore.fetchNGOs()
            }
            if volunteerStore.volunteerEvents.isEmpty {
                await volunteerStore.fetchVolunteerEvents()
            }
        }
    }
}

// MARK: - Details View

struct NGOConnectDetailView: View {
    let ngo: NGO
    let currentLevel: Int
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    @State private var showingRegistration = false
    @State private var showingDonation = false
    
    private var events: [VolunteerEvent] {
        let fetched = volunteerStore.events(for: ngo)
        return fetched.isEmpty ? VolunteerStore.dummyEvents(for: ngo.id) : fetched
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                if let image = UIImage(named: ngo.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(ngo.name)
                                .font(.title.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            if ngo.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.green)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.north.fill")
                                .font(.caption)
                                .rotationEffect(.degrees(45))
                                .foregroundStyle(AppTheme.orange)
                            Text(ngo.location)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    
                    // Stats
                    NGOStatsView(ngo: ngo)
                    
                    // Mission (Level 1)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Our Mission")
                            .font(.title3.bold())
                        Text(ngo.mission)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Donate Points Section (always visible — core feature)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Donate Your Focus")
                                .font(.title3.bold())
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("\(userStore.currentUser?.focusPoints ?? 0) pts")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(AppTheme.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.orange.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Text("Convert your Focus Points into real educational resources for underprivileged children.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Quick preview of top 3 goals
                        HStack(spacing: 12) {
                            ForEach(ImpactGoal.allGoals.prefix(3)) { goal in
                                VStack(spacing: 8) {
                                    Image(systemName: goal.icon)
                                        .font(.system(size: 22))
                                        .foregroundStyle(AppTheme.orange)
                                        .frame(width: 48, height: 48)
                                        .background(AppTheme.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(goal.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AppTheme.warmTextPrimary)
                                        .lineLimit(1)
                                    Text("\(goal.pointsCost) pts")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(AppTheme.warmTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        Button {
                            showingDonation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                Text("Donate Points")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.orange)
                            .clipShape(Capsule())
                        }
                    }

                    
                    // Level 3: Volunteer
                    LevelLockedSection(title: "Volunteer & Visit", requiredLevel: 3, currentLevel: currentLevel, lockedIcon: "hand.raised.fill", description: "Join our next event and make a direct impact.") {
                        VStack(alignment: .leading, spacing: 16) {
                            if events.isEmpty {
                                Text("No upcoming events")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            } else {
                                ForEach(events) { event in
                                    EventCardView(event: event)
                                }
                            }
                            Button {
                                showingRegistration = true
                            } label: {
                                Text("Register as Volunteer")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    

                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.pageGradient)
        .navigationDestination(isPresented: $showingRegistration) {
            VolunteerRegistrationView(ngo: ngo)
        }
        .sheet(isPresented: $showingDonation) {
            DonatePointsView(ngoName: ngo.name)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Level Locked Section

struct LevelLockedSection<Content: View>: View {
    let title: String
    let requiredLevel: Int
    let currentLevel: Int
    let lockedIcon: String
    let description: String
    @ViewBuilder let content: Content
    
    var isUnlocked: Bool {
        currentLevel >= requiredLevel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                Spacer()
                if !isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                        Text("Lvl \(requiredLevel)")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color(.systemGray3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
            
            if isUnlocked {
                content
            } else {
                VStack(spacing: 12) {
                    Image(systemName: lockedIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(.systemGray3))
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        
                    Text("Unlock at Level \(requiredLevel)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Components

struct NGOStatsView: View {
    let ngo: NGO
    var body: some View {
        HStack {
            Spacer()
            statItem(value: "\(String(format: "%.0f", Double(ngo.studentCount)/1000.0))K+", label: "People")
            Spacer()
            Divider()
            Spacer()
            statItem(value: "\(ngo.yearsActive)", label: "Years Active")
            Spacer()
            Divider()
            Spacer()
            statItem(value: "\(ngo.projectCount)", label: "Projects")
            Spacer()
        }
        .padding(.vertical, 16)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.orange)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct NGOGalleryView: View {
    let images: [String]
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(images.indices, id: \.self) { index in
                if let uiImage = UIImage(named: images[index]) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: VolunteerEvent

    var body: some View {
        HStack(spacing: 16) {
            // Date Badge
            VStack(spacing: 4) {
                Text(event.eventDate.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.orange)
                Text(event.eventDate.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 56, height: 64)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 5)

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "location.north.fill")
                        .font(.caption2)
                        .rotationEffect(.degrees(45))
                        .foregroundStyle(AppTheme.orange)
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(event.participantCount) participants")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Volunteer Registration View
struct VolunteerRegistrationView: View {
    let ngo: NGO
    @Environment(\.dismiss) private var dismiss
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    
    // Form fields
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var pastExperience: String = ""
    
    @State private var showSuccessAlert = false
    
    // Check if user is already registered
    private var isRegistered: Bool {
        guard let user = userStore.currentUser else { return false }
        return volunteerStore.isRegistered(ngoId: ngo.id, userId: user.id)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Personal Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Details")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            RegistrationTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                            Divider().padding(.leading, 40)
                            RegistrationTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                                .keyboardType(.emailAddress)
                            Divider().padding(.leading, 40)
                            RegistrationTextField(icon: "phone.fill", placeholder: "Phone", text: $phone)
                                .keyboardType(.phonePad)
                        }
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    }
                    
                    // Experience Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Experience")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.top, 8)
                                
                                ZStack(alignment: .topLeading) {
                                    if pastExperience.isEmpty {
                                        Text("Past Experience")
                                            .foregroundStyle(Color(.systemGray3))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $pastExperience)
                                        .frame(minHeight: 120)
                                        .scrollContentBackground(.hidden)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(AppTheme.pageGradient)
            .navigationTitle("Volunteer Registration")
            .navigationBarTitleDisplayMode(.inline)
            
            // Fixed Submit Button
            VStack {
                Spacer()
                Button {
                    Task {
                        if let user = userStore.currentUser {
                            await volunteerStore.registerForNGO(
                                userId: user.id,
                                ngoId: ngo.id,
                                fullName: fullName,
                                email: email,
                                phone: phone,
                                pastExperience: pastExperience
                            )
                            showSuccessAlert = true
                        }
                    }
                } label: {
                    Text(isRegistered ? "Already Registered" : "Submit Registration")
                        .font(.headline)
                        .foregroundStyle(isRegistered ? AppTheme.textSecondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isRegistered ? Color(.systemGray4) : AppTheme.orange)
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .disabled(isRegistered || fullName.isEmpty || email.isEmpty || phone.isEmpty)
            }
            
            // Custom Success Overlay
            if showSuccessAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                
                VStack(spacing: 16) {
                    Text("Registration Submitted!")
                        .font(.headline)
                    Text("Thank you for registering with \(ngo.name). They will contact you soon.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    Button {
                        showSuccessAlert = false
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(AppTheme.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .padding(24)
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                .shadow(radius: 20)
                .zIndex(2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSuccessAlert)
    }
}

struct RegistrationTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
