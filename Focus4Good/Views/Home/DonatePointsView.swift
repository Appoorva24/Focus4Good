import SwiftUI

// MARK: - Donate Points View

struct DonatePointsView: View {
    let ngoName: String
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: ImpactGoal? = nil
    @State private var lastDonatedGoal: ImpactGoal? = nil
    @State private var showConfirm = false
    @State private var showSuccess = false
    @State private var animateCoins = false
    @State private var showInsufficientPoints = false

    private var focusPoints: Int {
        userStore.currentUser?.focusPoints ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Points Balance Header
                        pointsBalanceCard

                        // Impact Goals
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose an Impact")
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.warmTextPrimary)

                            ForEach(ImpactGoal.allGoals) { goal in
                                impactGoalCard(goal)
                            }
                        }

                        // Donation History
                        if !userStore.donationHistory.isEmpty {
                            donationHistorySection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Donate Points")
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
            .alert("Confirm Donation", isPresented: $showConfirm, presenting: selectedGoal) { goal in
                Button("Cancel", role: .cancel) { selectedGoal = nil }
                Button("Donate \(goal.pointsCost) pts") {
                    Task {
                        let success = await userStore.donatePoints(for: goal)
                        if success {
                            lastDonatedGoal = goal
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showSuccess = true
                            }
                        }
                        selectedGoal = nil
                    }
                }
            } message: { goal in
                Text("Donate \(goal.pointsCost) Focus Points to sponsor \"\(goal.title)\" for \(ngoName)?")
            }
            .alert("Amazing! 🎉", isPresented: $showSuccess, presenting: lastDonatedGoal) { _ in
                Button("Continue", role: .cancel) {
                    showSuccess = false
                }
            } message: { goal in
                Text("Your focus just funded \(goal.title). Because of your dedication, \(goal.description.lowercased()). You're making a real difference in their education!")
            }
            .alert("Not Enough Points", isPresented: $showInsufficientPoints) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You don't have enough focus points. Complete daily tasks and earn points to donate.")
            }
        }
    }

    // MARK: - Points Balance Card

    private var pointsBalanceCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.orange)
                Text("Your Balance")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.warmTextSecondary)
            }

            Text("\(focusPoints)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.warmTextPrimary)
                .contentTransition(.numericText())

            Text("Focus Points")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.warmTextSecondary)
                .kerning(1)
                .textCase(.uppercase)

            if userStore.totalPointsDonated > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.rose)
                    Text("\(userStore.totalPointsDonated) pts donated so far")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Impact Goal Card

    private func impactGoalCard(_ goal: ImpactGoal) -> some View {
        let canAfford = focusPoints >= goal.pointsCost

        return Button {
            if canAfford {
                selectedGoal = goal
                showConfirm = true
            } else {
                showInsufficientPoints = true
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canAfford
                              ? AppTheme.orange.opacity(0.12)
                              : Color(.systemGray5))
                        .frame(width: 52, height: 52)
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(canAfford ? AppTheme.orange : Color(.systemGray3))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(canAfford ? AppTheme.warmTextPrimary : AppTheme.warmTextSecondary)
                    Text(goal.description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Cost + Impact
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.pointsCost)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(canAfford ? AppTheme.orange : Color(.systemGray3))
                    Text(goal.impactLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Donation History

    private var donationHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Donation History")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.warmTextPrimary)

            ForEach(userStore.donationHistory.prefix(10)) { record in
                HStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.rose)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.goalTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.warmTextPrimary)
                        Text(record.date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }

                    Spacer()

                    Text("-\(record.pointsSpent) pts")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(14)
                .glassCard(cornerRadius: 12)
            }
        }
    }

}
