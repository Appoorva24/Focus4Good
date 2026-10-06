import SwiftUI

// MARK: - Data & Privacy View
struct DataPrivacyView: View {
    var body: some View {
        List {
            Section {
                Text("Focus4Good collects only the data necessary to provide you with the best focus and volunteer experience. Your data is stored securely and is never sold to third parties.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Personal Data").textCase(nil)) {
                PrivacyRow(
                    icon: "person.text.rectangle.fill",
                    title: "Profile Information",
                    description: "Name, email, and profile photo are used to personalize your experience and community interactions."
                )
            }
            
            Section(header: Text("App Data").textCase(nil)) {
                PrivacyRow(
                    icon: "checklist",
                    title: "Tasks & Goals",
                    description: "Your tasks, schedules, and focus sessions are stored to track your progress and award Focus Points."
                )
                PrivacyRow(
                    icon: "brain.head.profile",
                    title: "Calm Centre",
                    description: "Brain dump entries and meditation history are kept private to you to help your mental wellbeing."
                )
            }
            
            Section(header: Text("Community & Volunteering").textCase(nil)) {
                PrivacyRow(
                    icon: "person.3.fill",
                    title: "Social Interactions",
                    description: "Posts, comments, and volunteer event registrations are shared with the relevant communities and NGOs."
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    var body: some View {
        List {
            Section {
                Text("Focus4Good uses the following device capabilities to enhance your experience. You can manage these at any time in your device Settings.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 4)
            }
            
            Section(header: Text("Requested Permissions").textCase(nil)) {
                PermissionRow(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "Used to send task reminders, Pomodoro timer alerts, and daily motivation."
                )
                PermissionRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Photo Library",
                    description: "Used to let you upload a profile picture and share images in community posts."
                )
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Used to scan your handwritten notes and convert them into digital tasks using Vision AI."
                )
            }
            
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Device Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(AppTheme.orange)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Row Components

struct PrivacyRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.orange)
                    .font(.title3)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 36)
        }
        .padding(.vertical, 6)
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.orange)
                    .font(.title3)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.leading, 36)
        }
        .padding(.vertical, 6)
    }
}
