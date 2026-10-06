import SwiftUI

// MARK: - Badge Model

struct ImpactBadge: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let requirement: String

    /// Check if the user has unlocked this badge
    func isUnlocked(
        totalDonated: Int,
        donationCount: Int,
        bestStreak: Int,
        eventsRegistered: Int
    ) -> Bool {
        switch id {
        case "first_lesson":    return donationCount >= 1
        case "bookworm":        return donationCount >= 5
        case "guru":            return totalDonated >= 10000
        case "streak_for_good": return bestStreak >= 30
        case "volunteer_hero":  return eventsRegistered >= 3
        case "generous_heart":  return totalDonated >= 5000
        default:                return false
        }
    }

    static let allBadges: [ImpactBadge] = [
        ImpactBadge(
            id: "first_lesson",
            title: "First Lesson",
            description: "Made your very first donation",
            icon: "pencil.circle.fill",
            color: Color(hex: "F59E0B"),
            requirement: "Donate points once"
        ),
        ImpactBadge(
            id: "bookworm",
            title: "Bookworm",
            description: "Sponsored textbooks for 5 children",
            icon: "text.book.closed.fill",
            color: Color(hex: "6366F1"),
            requirement: "Make 5 donations"
        ),
        ImpactBadge(
            id: "generous_heart",
            title: "Generous Heart",
            description: "Donated 5,000 Focus Points total",
            icon: "heart.circle.fill",
            color: AppTheme.rose,
            requirement: "Donate 5,000 total pts"
        ),
        ImpactBadge(
            id: "guru",
            title: "Guru",
            description: "Donated 10,000 Focus Points total",
            icon: "star.circle.fill",
            color: AppTheme.orange,
            requirement: "Donate 10,000 total pts"
        ),
        ImpactBadge(
            id: "streak_for_good",
            title: "Streak for Good",
            description: "Maintained a 30-day focus streak",
            icon: "flame.circle.fill",
            color: Color(hex: "EF4444"),
            requirement: "30-day streak"
        ),
        ImpactBadge(
            id: "volunteer_hero",
            title: "Volunteer Hero",
            description: "Registered for 3 teaching events",
            icon: "hand.raised.circle.fill",
            color: AppTheme.sage,
            requirement: "Register for 3 events"
        )
    ]
}

// MARK: - Badges View

struct BadgesView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(\.dismiss) private var dismiss

    private var totalDonated: Int { userStore.totalPointsDonated }
    private var donationCount: Int { userStore.donationHistory.count }
    private var bestStreak: Int { userStore.currentUser?.bestStreak ?? 0 }
    private var eventsRegistered: Int { volunteerStore.volunteerRegistrations.count }

    private var unlockedCount: Int {
        ImpactBadge.allBadges.filter {
            $0.isUnlocked(totalDonated: totalDonated, donationCount: donationCount, bestStreak: bestStreak, eventsRegistered: eventsRegistered)
        }.count
    }

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("\(unlockedCount) / \(ImpactBadge.allBadges.count)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.warmTextPrimary)
                            Text("Badges Unlocked")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.warmTextSecondary)
                        }
                        .padding(.top, 8)

                        // Badge Grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(ImpactBadge.allBadges) { badge in
                                let unlocked = badge.isUnlocked(
                                    totalDonated: totalDonated,
                                    donationCount: donationCount,
                                    bestStreak: bestStreak,
                                    eventsRegistered: eventsRegistered
                                )
                                badgeCell(badge: badge, unlocked: unlocked)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                }
            }
        }
    }

    private func badgeCell(badge: ImpactBadge, unlocked: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                // Background shape (Gradient gem)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        unlocked
                        ? LinearGradient(colors: [badge.color.opacity(0.7), badge.color], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: unlocked ? badge.color.opacity(0.4) : .clear, radius: 10, x: 0, y: 6)
                
                // Glossy inner rim
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    .frame(width: 56, height: 56)

                // The SF Symbol icon
                Image(systemName: badge.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(unlocked ? .white : Color(.systemGray3))
                    .symbolEffect(.bounce, value: unlocked)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            }

            VStack(spacing: 3) {
                Text(badge.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(unlocked ? AppTheme.warmTextPrimary : AppTheme.warmTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(unlocked ? badge.description : badge.requirement)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 24)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(unlocked ? 0.7 : 0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(unlocked ? 0.8 : 0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .opacity(unlocked ? 1.0 : 0.7)
    }
}
