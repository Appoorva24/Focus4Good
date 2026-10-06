import SwiftUI

// MARK: - Muscle Step Data

private struct MuscleStep {
    let groupNumber: Int
    let name: String
    let icon: String
    let tenseInstruction: String
    let releaseNote: String
}

private let allSteps: [MuscleStep] = [
    .init(groupNumber: 1,  name: "Feet",            icon: "figure.walk",                       tenseInstruction: "Curl your toes downward tightly",                     releaseNote: "Feel the relaxation spread through your feet"),
    .init(groupNumber: 2,  name: "Calves",           icon: "figure.run",                        tenseInstruction: "Pull your toes toward your shins, tensing your calves", releaseNote: "Let the tension flow out of your calves"),
    .init(groupNumber: 3,  name: "Thighs",           icon: "figure.strengthtraining.traditional", tenseInstruction: "Squeeze your thigh muscles tightly together",          releaseNote: "Feel your thighs go heavy and relaxed"),
    .init(groupNumber: 4,  name: "Hips & Buttocks",  icon: "figure.cooldown",                   tenseInstruction: "Clench your gluteal muscles",                          releaseNote: "Let your hips sink and soften"),
    .init(groupNumber: 5,  name: "Abdomen",          icon: "figure.core.training",              tenseInstruction: "Suck your stomach in and tighten your core",            releaseNote: "Let your belly go completely soft"),
    .init(groupNumber: 6,  name: "Chest",            icon: "lungs.fill",                        tenseInstruction: "Take a deep breath and hold, tensing your chest",        releaseNote: "Exhale and feel your breathing slow naturally"),
    .init(groupNumber: 7,  name: "Hands & Forearms", icon: "hand.raised.fill",                  tenseInstruction: "Make tight fists with both hands",                      releaseNote: "Let your fingers go completely limp"),
    .init(groupNumber: 8,  name: "Upper Arms",       icon: "figure.arms.open",                  tenseInstruction: "Bend your elbows and flex your biceps hard",             releaseNote: "Let your arms fall heavy by your sides"),
    .init(groupNumber: 9,  name: "Shoulders",        icon: "figure.stand",                      tenseInstruction: "Shrug your shoulders up toward your ears",               releaseNote: "Let them drop completely"),
    .init(groupNumber: 10, name: "Neck",             icon: "person.crop.circle",                tenseInstruction: "Gently press the back of your head into the surface",    releaseNote: "Release and feel your neck lengthen"),
    .init(groupNumber: 11, name: "Forehead",         icon: "face.smiling",                      tenseInstruction: "Raise your eyebrows as high as possible",                releaseNote: "Let your forehead go smooth"),
    .init(groupNumber: 11, name: "Eyes",             icon: "eye.fill",                          tenseInstruction: "Squeeze your eyes shut tightly",                         releaseNote: "Let your eyelids rest gently"),
    .init(groupNumber: 11, name: "Jaw",              icon: "face.smiling",                      tenseInstruction: "Clench your teeth and tighten your jaw",                 releaseNote: "Let your mouth hang slightly open"),
]

// MARK: - Presets

private enum SessionPreset: CaseIterable {
    case quick, standard, full

    var label: String {
        switch self {
        case .quick:    "Quick"
        case .standard: "Standard"
        case .full:     "Full Body"
        }
    }

    var detail: String {
        switch self {
        case .quick:    "4 key areas"
        case .standard: "7 groups"
        case .full:     "All 11"
        }
    }

    var groups: Set<Int> {
        switch self {
        case .quick:    [5, 7, 9, 11]
        case .standard: [1, 3, 5, 7, 8, 9, 11]
        case .full:     Set(1...11)
        }
    }
}

// MARK: - Session Stage

private enum SessionStage: Equatable {
    case idle, preparation, tensing, resting, ending, complete
}

// MARK: - Ending Step

private enum EndingStep: Int, CaseIterable {
    case deepBreaths = 0, bodyScan = 1, wiggle = 2, openEyes = 3

    var title: String {
        switch self {
        case .deepBreaths: "Deep Breaths"
        case .bodyScan:    "Body Scan"
        case .wiggle:      "Awaken"
        case .openEyes:    "Return"
        }
    }

    var instruction: String {
        switch self {
        case .deepBreaths: "Take 3 slow, deep breaths"
        case .bodyScan:    "Mentally scan your body from head to toe\nNotice the relaxation"
        case .wiggle:      "Gently wiggle your fingers and toes"
        case .openEyes:    "Open your eyes slowly\nSit up gradually"
        }
    }

    var icon: String {
        switch self {
        case .deepBreaths: "wind"
        case .bodyScan:    "figure.mind.and.body"
        case .wiggle:      "hand.raised.fingers.spread"
        case .openEyes:    "eye"
        }
    }

    var duration: Int {
        switch self {
        case .deepBreaths: 15
        case .bodyScan:    10
        case .wiggle:      5
        case .openEyes:    5
        }
    }
}

// MARK: - Timing Constants

private let tenseDuration = 5
private let restDuration  = 10
private let prepDuration  = 20

// MARK: - JPMRSessionView

struct JPMRSessionView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGroups: Set<Int> = [11, 9, 7, 6, 5, 1]
    @State private var stage: SessionStage = .idle
    @State private var countdown      = 0
    @State private var stepIndex      = 0
    @State private var endingIndex    = 0
    @State private var isRunning      = false
    @State private var showCompletion = false
    @State private var showVideoTutorial = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var ringProgress: CGFloat = 0.0
    @State private var phaseStartTime: Date? = nil
    @State private var elapsedPauseTime: TimeInterval = 0.0

    private let userId = UUID()

    private var activeSteps: [MuscleStep] {
        activeGroupsSorted.compactMap { groupNum in
            allSteps.first(where: { $0.groupNumber == groupNum })
        }
    }

    private var activeGroupsSorted: [Int] { selectedGroups.sorted(by: >) }

    private var currentStep: MuscleStep {
        activeSteps[min(stepIndex, max(activeSteps.count - 1, 0))]
    }

    private var currentEnding: EndingStep {
        EndingStep(rawValue: min(endingIndex, EndingStep.allCases.count - 1)) ?? .deepBreaths
    }


    var body: some View {
        ZStack {
            AppTheme.appGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()


                circularImageArea
                
                Spacer()
                progressArea.padding(.bottom, 24)
                actionButton.padding(.bottom, 48)
            }

            if showCompletion {
                completionOverlay
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showCompletion)
        .navigationTitle("Unwind Body")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { groupMenu }
        }
        .onDisappear {
            stopTimer()
            JPMRAudioService.shared.stopAll()
        }
        .navigationDestination(isPresented: $showVideoTutorial) {
            JPMRVideoView()
        }
    }

    // MARK: - Display Helpers

    private var displayIcon: String {
        switch stage {
        case .idle:        "figure.mind.and.body"
        case .preparation: "wind"
        case .tensing:     currentStep.icon
        case .resting:     currentStep.icon
        case .ending:      currentEnding.icon
        case .complete:    "checkmark.seal.fill"
        }
    }

    private var displayTitle: String {
        switch stage {
        case .idle:        "Ready"
        case .preparation: "Settle In"
        case .tensing:     currentStep.name
        case .resting:     currentStep.name
        case .ending:      currentEnding.title
        case .complete:    "Complete"
        }
    }

    private var displayPhaseLabel: String {
        switch stage {
        case .idle:        "Press Start to begin"
        case .preparation: "Close your eyes and breathe deeply"
        case .tensing:     "Inhale & Tense"
        case .resting:     "Release & Rest"
        case .ending:      currentEnding.instruction
        case .complete:    ""
        }
    }

    private var displayDetail: String {
        switch stage {
        case .tensing: currentStep.tenseInstruction
        case .resting: currentStep.releaseNote
        default:       ""
        }
    }

    private var circleScale: CGFloat {
        switch stage {
        case .tensing: 1.2
        case .resting: 0.85
        default:       1.0
        }
    }

    private var circleFillOpacity: Double {
        switch stage {
        case .tensing: 0.28
        case .resting: 0.10
        default:       0.18
        }
    }

    // MARK: - Highlight Data

    private func highlightPositions(for group: Int) -> [CGPoint] {
        switch group {
        case 1: return [CGPoint(x: 0.45, y: 0.92), CGPoint(x: 0.55, y: 0.92)] // Feet
        case 2: return [CGPoint(x: 0.43, y: 0.78), CGPoint(x: 0.57, y: 0.78)] // Calves
        case 3: return [CGPoint(x: 0.41, y: 0.65), CGPoint(x: 0.59, y: 0.65)] // Thighs
        case 4: return [CGPoint(x: 0.5, y: 0.52)] // Hips & Buttocks
        case 5: return [CGPoint(x: 0.5, y: 0.42)] // Abdomen
        case 6: return [CGPoint(x: 0.5, y: 0.32)] // Chest
        case 7: return [CGPoint(x: 0.23, y: 0.58), CGPoint(x: 0.77, y: 0.58)] // Hands & Forearms
        case 8: return [CGPoint(x: 0.3, y: 0.38), CGPoint(x: 0.7, y: 0.38)] // Upper Arms
        case 9: return [CGPoint(x: 0.35, y: 0.25), CGPoint(x: 0.65, y: 0.25)] // Shoulders
        case 10: return [CGPoint(x: 0.5, y: 0.20)] // Neck
        case 11: return [CGPoint(x: 0.5, y: 0.12)] // Face
        default: return []
        }
    }

    private var imageForCurrentStep: String? {
        let isTensing = (stage == .tensing)
        
        if currentStep.name == "Forehead" {
            return isTensing ? "forhead_tense" : "forhead_relax"
        }
        if currentStep.name == "Eyes" {
            return isTensing ? "eyes_tense" : "eyes_relax"
        }
        
        switch currentStep.groupNumber {
        case 1: return isTensing ? "toe_tense" : "toe_release" // Feet/Toes
        case 5: return isTensing ? "stomach_tense" : "stomach_release" // Abdomen
        case 6: return isTensing ? "chest_tense" : "chest_release" // Chest
        case 7: return isTensing ? "fist_tense" : "fist_release" // Hands & Forearms
        case 9: return isTensing ? "shoulder_tense" : "shoulder_release" // Shoulders
        default: return nil
        }
    }

    private var circularImageArea: some View {
        ZStack {
            if stage == .ending {
                Image(systemName: currentEnding.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundStyle(Color.accentColor)
                    .animation(.easeInOut(duration: 0.5), value: currentEnding)
            } else {
                if let imageName = imageForCurrentStep {
                    ZStack {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipShape(Circle())
                            .shadow(color: stage == .tensing ? Color.accentColor.opacity(0.5) : Color.clear, radius: 15)
                            .scaleEffect(stage == .tensing ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.0), value: stage)
                            .animation(.easeInOut(duration: 0.5), value: currentStep.groupNumber)
                        
                        if stage == .tensing || stage == .resting {
                            Circle()
                                .trim(from: 0, to: ringProgress)
                                .stroke(
                                    Color.white.opacity(0.9),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 304, height: 304)
                                .scaleEffect(stage == .tensing ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.0), value: stage)
                                .animation(.linear(duration: 0.02), value: ringProgress)
                        }
                    }
                } else {
                    let isTensing = stage == .tensing
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(isTensing ? 0.3 : 0.1))
                            .frame(width: 220, height: 220)
                        Image(systemName: currentStep.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .foregroundStyle(isTensing ? Color.accentColor : Color.accentColor.opacity(0.7))
                            .scaleEffect(isTensing ? 1.1 : 1.0)
                    }
                    .frame(width: 280, height: 280)
                    .animation(.easeInOut(duration: 0.5), value: currentStep.groupNumber)
                    .animation(.easeInOut(duration: 0.5), value: stage)
                }
            }
        }
        .frame(height: 320)
    }

    private var infoArea: some View {
        VStack(spacing: 8) {
            Text(displayTitle)
                .font(.title3)
                .fontWeight(.bold)

            Text(displayPhaseLabel)
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            Text(displayDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(displayDetail.isEmpty ? 0 : 1)
                .frame(minHeight: 20)
        }
        .animation(.easeInOut(duration: 0.3), value: stage)
        .animation(.easeInOut(duration: 0.3), value: stepIndex)
        .padding(.horizontal, 32)
    }

    private var progressArea: some View {
        VStack(spacing: 12) {
            if stage == .tensing || stage == .resting {
                let groupIndex = (activeGroupsSorted.firstIndex(of: currentStep.groupNumber) ?? 0) + 1
                Text("Group \(groupIndex) of \(selectedGroups.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            } else if stage == .preparation {
                Text("Preparing…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if stage == .ending {
                Text("Closing…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(selectedGroups.count) group\(selectedGroups.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 5) {
                ForEach(activeGroupsSorted, id: \.self) { group in
                    Circle()
                        .fill(groupDotColor(for: group))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(height: 44)
    }

    private func groupDotColor(for group: Int) -> Color {
        guard isRunning || stage == .ending || stage == .complete else {
            return Color(.systemGray4)
        }
        if stage == .ending || stage == .complete { return .accentColor }

        guard let groupIndex = activeGroupsSorted.firstIndex(of: group),
              let currentIndex = activeGroupsSorted.firstIndex(of: currentStep.groupNumber) else {
            return Color(.systemGray4)
        }

        if groupIndex < currentIndex { return .accentColor }
        if groupIndex == currentIndex { return Color.accentColor.opacity(0.5) }
        return Color(.systemGray4)
    }

    private var groupMenu: some View {
        Menu {
            Button {
                // Currently active
            } label: {
                HStack {
                    Text("Full Body Relaxation")
                    Image(systemName: "checkmark")
                }
            }
            
            Divider()
            
            Button {
                showVideoTutorial = true
            } label: {
                Label("Video Tutorial", systemImage: "play.rectangle.fill")
            }
        } label: {
            Image(systemName: "figure.mind.and.body")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
        }
    }

    private var actionButton: some View {
        Button {
            isRunning ? pauseSession() : resumeSession()
        } label: {
            Text(isRunning ? "Pause" : (stage == .idle || stage == .complete ? "Start" : "Resume"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 160, height: 52)
                .background(Capsule().fill(Color.accentColor))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(selectedGroups.isEmpty)
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showCompletion = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("You completed \(selectedGroups.count) muscle group\(selectedGroups.count == 1 ? "" : "s") of progressive relaxation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 30 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showCompletion = false
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color.accentColor))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Session Logic

    private func startSession() {
        guard !selectedGroups.isEmpty else { return }
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
        isRunning = true
        enterTense()
    }

    private func pauseSession() {
        stopTimer()
        JPMRAudioService.shared.pauseAll()
        if let start = phaseStartTime {
            elapsedPauseTime += Date().timeIntervalSince(start)
            phaseStartTime = nil
        }
        isRunning = false
    }

    private func resumeSession() {
        if stage == .idle || stage == .complete {
            startSession()
            return
        }
        isRunning = true
        phaseStartTime = Date()
        JPMRAudioService.shared.resumeAll()
        startTimer()
    }

    private func stopSession() {
        stopTimer()
        JPMRAudioService.shared.stopAll()
        stage = .idle
        countdown = 0
        isRunning = false
        stepIndex = 0
        endingIndex = 0
        elapsedSeconds = 0
        elapsedPauseTime = 0
        phaseStartTime = nil
        ringProgress = 0
    }

    private func resetTiming() {
        phaseStartTime = Date()
        elapsedPauseTime = 0.0
        ringProgress = 0.0
    }

    private func enterPreparation() {
        stage = .preparation
        countdown = prepDuration
        resetTiming()
        JPMRAudioService.shared.speakPreparation(groupCount: selectedGroups.count)
        startTimer()
    }

    private func enterTense() {
        stage = .tensing
        countdown = tenseDuration
        resetTiming()
        JPMRAudioService.shared.speakTense(muscleName: currentStep.name, instruction: currentStep.tenseInstruction)
        startTimer()
    }

    private func enterRest() {
        stage = .resting
        countdown = restDuration
        resetTiming()
        JPMRAudioService.shared.speakRest(muscleName: currentStep.name, releaseNote: currentStep.releaseNote)
        startTimer()
    }

    private func enterEnding() {
        endingIndex = 0
        enterEndingStep()
    }

    private func enterEndingStep() {
        stage = .ending
        countdown = currentEnding.duration
        resetTiming()
        JPMRAudioService.shared.speakEndingStep(title: currentEnding.title, instruction: currentEnding.instruction)
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in tick() }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        var elapsed: TimeInterval = elapsedPauseTime
        if let start = phaseStartTime {
            elapsed += Date().timeIntervalSince(start)
        }
        
        let duration: Double
        if stage == .tensing {
            duration = Double(tenseDuration)
        } else if stage == .resting {
            duration = Double(restDuration)
        } else if stage == .ending {
            duration = Double(currentEnding.duration)
        } else {
            duration = Double(prepDuration)
        }
        
        let remaining = Int(ceil(max(0, duration - elapsed)))
        if remaining != countdown {
            countdown = remaining
        }
        
        if stage == .tensing || stage == .resting {
            ringProgress = CGFloat(min(1.0, elapsed / duration))
        } else {
            ringProgress = 0.0
        }
        
        if elapsed >= duration {
            elapsedSeconds += Int(duration)
            advance()
        }
    }

    private func advance() {
        switch stage {
        case .preparation:
            stepIndex = 0
            enterTense()

        case .tensing:
            enterRest()

        case .resting:
            if stepIndex >= activeSteps.count - 1 {
                completeSession()
            } else {
                stepIndex += 1
                enterTense()
            }

        case .ending:
            if endingIndex >= EndingStep.allCases.count - 1 {
                completeSession()
            } else {
                endingIndex += 1
                enterEndingStep()
            }

        default:
            break
        }
    }

    private func completeSession() {
        stopTimer()
        isRunning = false
        stage = .complete

        // JPMRAudioService.shared.speakCompletion(groupCount: selectedGroups.count)

        Task {
            await store.logJpmrSession(userId: userId, durationSeconds: elapsedSeconds)
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        JPMRSessionView()
            .environment(CalmCentreStore.shared)
    }
}
