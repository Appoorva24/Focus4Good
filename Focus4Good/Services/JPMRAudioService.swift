@preconcurrency import AVFoundation

// MARK: - JPMRAudioService

/// Provides guided voice instructions throughout a JPMR session
/// using AVSpeechSynthesizer with a gentle, calming female voice.

@MainActor
class JPMRAudioService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = JPMRAudioService()

    // MARK: - Private State

    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?

    private override init() {
        super.init()
        synthesizer.delegate = self
        selectedVoice = pickFemaleVoice()
    }

    // MARK: - Voice Selection

    private func pickFemaleVoice() -> AVSpeechSynthesisVoice? {
        let preferred: [String] = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Ava",
            "com.apple.voice.premium.en-GB.Stephanie",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Ava",
            "com.apple.voice.enhanced.en-GB.Stephanie",
            "com.apple.voice.compact.en-US.Samantha",
        ]

        for id in preferred {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                return voice
            }
        }

        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Guided Experience

    /// Welcome message as preparation begins.
    func speakPreparation(groupCount: Int) {
        configureAudioSession()
        let text = "Welcome to your progressive muscle relaxation session. "
            + "We will work through \(groupCount) muscle \(groupCount == 1 ? "group" : "groups") together. "
            + "Find a comfortable position and close your eyes. "
            + "Take a few slow, deep breaths to settle in."
        speakCalm(text)
    }

    func speakTense(muscleName: String, instruction: String) {
        configureAudioSession()
        let text = "\(muscleName). \(instruction)."
        speakCalm(text)
    }

    func speakRest(muscleName: String, releaseNote: String) {
        configureAudioSession()
        let text = "Release. \(releaseNote)."
        speakCalm(text)
    }

    /// Announce the transition to the next muscle group.
    func speakGroupTransition(nextName: String, currentIndex: Int, totalGroups: Int) {
        configureAudioSession()
        let remaining = totalGroups - currentIndex
        let text: String
        if remaining <= 2 {
            text = "Almost there. Let's move to your \(nextName.lowercased())."
        } else {
            text = "Good. Now let's move to your \(nextName.lowercased())."
        }
        speakCalm(text)
    }

    /// Guide the user through ending steps.
    func speakEndingStep(title: String, instruction: String) {
        configureAudioSession()
        // Clean up newlines from instruction text
        let cleaned = instruction.replacingOccurrences(of: "\n", with: ". ")
        let text = "\(title). \(cleaned)"
        speakCalm(text)
    }

    /// Congratulatory closing message.
    func speakCompletion(groupCount: Int) {
        configureAudioSession()
        let text = "Wonderful. You've completed your progressive muscle relaxation session, "
            + "working through \(groupCount) muscle \(groupCount == 1 ? "group" : "groups"). "
            + "Take a moment to notice how calm and relaxed your body feels. "
            + "You've earned your focus points. Well done."
        speakCalm(text)
    }

    /// Stop all speech immediately.
    func stopAll() {
        synthesizer.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    func pauseAll() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resumeAll() {
        synthesizer.continueSpeaking()
    }

    // MARK: - Private Helpers

    private func speakCalm(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
    }
}
