import SwiftUI

// MARK: - Navigation Destinations

enum HomeDestination: Hashable {
    case schedule
    case ngoList
    case pomodoro(UserTask)
}

// MARK: - HomeView

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(TaskStore.self) private var taskStore
    @Environment(VolunteerStore.self) private var volunteerStore
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    @State private var appeared = false
    @State private var profileImage: UIImage? = nil
    @State private var showRescueMe = false
    @State private var rescueTask: UserTask? = nil

    private var profileImageKey: String {
        "profileImage_\(userStore.currentUser?.id.uuidString ?? "default")"
    }

    private var todayGoalProgress: Double {
        let today = Date()
        let todayTasks = taskStore.todaysTasks
        let total = todayTasks.count
        guard total > 0 else { return 0 }
        return Double(todayTasks.filter { taskStore.isTaskCompleted($0, on: today) }.count) / Double(total)
    }

    private var focusPoints: Int {
        userStore.currentUser?.focusPoints ?? 0
    }

    private var greetingEmoji: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "🌅"
        case 12..<17: return "☀️"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                let hPad: CGFloat = 20
                let topPad: CGFloat = 12
                let bottomPad: CGFloat = 12
                let spacing: CGFloat = 16
                let cardW = geo.size.width - hPad * 2
                let usable = geo.size.height - topPad - bottomPad - spacing * 2

                // Slightly reduce sizes for cards as requested by user
                let rescueH = cardW * 0.45
                let remainingH = max(usable - rescueH, 200)
                let plannerH = remainingH * 0.52
                let statsH   = remainingH * 0.44

                let ngoH = remainingH * 0.62

                ScrollView(showsIndicators: false) {
                    VStack(spacing: spacing) {
                        plannerCard(height: plannerH, width: cardW)
                        statsRow(height: statsH)
                        rescueMeCard(height: rescueH, width: cardW)
                        ngoConnectCard(height: ngoH, width: cardW)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, topPad)
                    .padding(.bottom, bottomPad)
                }
            }
            .background(homeBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        if let uiImage = profileImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .onChange(of: showProfile) { _, isShowing in
                if !isShowing {
                    loadProfileImage()
                }
            }
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .schedule:       ScheduleView()
                case .ngoList:        NGOListView()
                case .pomodoro(let t): PomodoroView(task: t)
                }
            }
            .sheet(isPresented: $showRescueMe) {
                RescueMeView { task in
                    rescueTask = task
                    navigationPath.append(HomeDestination.pomodoro(task))
                }
            }
            .onAppear {
                loadProfileImage()
                if !UserDefaults.standard.bool(forKey: "didResetPoints") {
                    Task {
                        if let pts = userStore.currentUser?.focusPoints, pts > 0 {
                            await userStore.updateFocusPoints(by: -pts)
                        }
                        UserDefaults.standard.set(true, forKey: "didResetPoints")
                    }
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Subviews
    
    private func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: profileImageKey),
           let image = UIImage(data: data) {
            profileImage = image
        } else {
            profileImage = nil
        }
    }

    // MARK: - Background

    private var homeBackground: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(AppTheme.orange.opacity(0.06))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 60, y: -40)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(AppTheme.sage.opacity(0.05))
                        .frame(width: 180, height: 180)
                        .blur(radius: 50)
                        .offset(x: -40, y: 40)
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Planner Hero Card
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func plannerCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            navigationPath.append(HomeDestination.schedule)
        } label: {
            ZStack {
                // Warm gradient background
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "FFF7ED"))

                // Decorative blob
                Circle()
                    .fill(AppTheme.orange.opacity(0.08))
                    .frame(width: height * 0.7, height: height * 0.7)
                    .blur(radius: 20)
                    .offset(x: width * 0.15, y: -height * 0.1)

                HStack(spacing: 0) {
                    // Left: Text content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Let's plan\nyour day")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.warmTextPrimary)
                            .lineSpacing(2)

                        Text("Create a plan, stay focused\nand get things done.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .lineSpacing(2)

                        Spacer(minLength: 8)

                        // CTA Button
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Let's plan")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(AppTheme.orange)
                                .shadow(color: AppTheme.orange.opacity(0.3), radius: 8, y: 4)
                        )
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 18)
                    .frame(width: width * 0.52, alignment: .leading)

                    // Right: Notebook illustration
                    Image("plannercard")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.42)
                        .padding(.trailing, 8)
                        .padding(.vertical, 8)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: AppTheme.orange.opacity(0.12), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(HomeCardButtonStyle())
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Stats Row
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func statsRow(height: CGFloat) -> some View {
        HStack(spacing: 12) {
            focusPointsCard(height: height)
            todaysGoalCard(height: height)
        }
    }

    // MARK: Focus Points

    @ViewBuilder
    private func focusPointsCard(height: CGFloat) -> some View {
        let pointsGoal = 500
        let progress = min(Double(focusPoints) / Double(pointsGoal), 1.0)

        VStack(spacing: 10) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.orange)
                Text("Focus Points")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
            }
            .padding(.top, 14)

            Spacer(minLength: 0)

            // Circular gauge
            ZStack {
                // Track
                Circle()
                    .stroke(AppTheme.orange.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.orange, AppTheme.amber, AppTheme.orange],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Value
                VStack(spacing: 1) {
                    Text("\(focusPoints)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("pts")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
            }
            .frame(width: height * 0.42, height: height * 0.42)

            Spacer(minLength: 0)

            Text("Keep going!")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.warmTextSecondary)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .glassCard(cornerRadius: 18)
    }

    // MARK: Today's Goal

    @ViewBuilder
    private func todaysGoalCard(height: CGFloat) -> some View {
        let progress = todayGoalProgress

        VStack(spacing: 10) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.sage)
                Text("Today's Goal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.warmTextPrimary)
            }
            .padding(.top, 14)

            Spacer(minLength: 0)

            // Circular gauge
            ZStack {
                // Track
                Circle()
                    .stroke(AppTheme.sage.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round))

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.sage, Color(hex: "6EE7B7"), AppTheme.sage],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Value
                VStack(spacing: 1) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }
            }
            .frame(width: height * 0.42, height: height * 0.42)

            Spacer(minLength: 0)

            Text(progress >= 1.0 ? "Completed!" : (progress > 0 ? "On track!" : "Start today!"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(progress >= 1.0 ? AppTheme.sage : AppTheme.warmTextSecondary)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .glassCard(cornerRadius: 18)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Rescue Me Card
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func rescueMeCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            showRescueMe = true
        } label: {
            Image("rescuemecard")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: AppTheme.orange.opacity(0.14), radius: 14, x: 0, y: 6)
        }
        .buttonStyle(HomeCardButtonStyle())
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - NGO Connect Card
    // ─────────────────────────────────────────────────────────────────

    @ViewBuilder
    private func ngoConnectCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            navigationPath.append(HomeDestination.ngoList)
        } label: {
            ZStack(alignment: .bottom) {
                // Full-bleed hero image
                Image("ngo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()

                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.65),
                        Color.black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content overlay
                VStack(alignment: .leading, spacing: 10) {
                    Spacer()

                    // Title & subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NGO Connect")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Every focus point you earn helps fund a child's education")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }

                    // Progress bar
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            let progressWidth = geo.size.width * CGFloat(min(Double(focusPoints) / 10000.0, 1.0))
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.orange, AppTheme.amber],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(5, progressWidth), height: 5)
                                    .shadow(color: AppTheme.orange.opacity(0.5), radius: 4, y: 0)
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            Text("\(focusPoints) / 10,000 points")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Learn More")
                                    .font(.system(size: 11, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(AppTheme.orange)
                        }
                    }
                }
                .padding(16)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            // Points badge pinned to top-right corner
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(focusPoints) pts")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(16)
            }
        }
        .buttonStyle(HomeCardButtonStyle())
    }
}

// ═════════════════════════════════════════════════════════════════════
// MARK: - Leaf Decoration (Focus Points card)
// ═════════════════════════════════════════════════════════════════════

struct LeafDecoration: View {
    var body: some View {
        ZStack {
            // Main stem
            LeafStem()
                .stroke(AppTheme.orange.opacity(0.5), lineWidth: 1.5)
                .frame(width: 40, height: 60)

            // Leaves
            Ellipse()
                .fill(AppTheme.orange.opacity(0.2))
                .frame(width: 14, height: 24)
                .rotationEffect(.degrees(-30))
                .offset(x: -8, y: -10)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.15))
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(25))
                .offset(x: 8, y: -18)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.18))
                .frame(width: 10, height: 18)
                .rotationEffect(.degrees(-15))
                .offset(x: -4, y: 6)

            Ellipse()
                .fill(AppTheme.orange.opacity(0.12))
                .frame(width: 12, height: 20)
                .rotationEffect(.degrees(35))
                .offset(x: 10, y: 0)
        }
    }
}

struct LeafStem: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - 5, y: rect.minY + 10),
            control: CGPoint(x: rect.midX + 8, y: rect.midY)
        )
        return path
    }
}


struct HomeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
