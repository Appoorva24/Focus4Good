@preconcurrency import AVFoundation

// MARK: - MeditationAudioService

/// Provides AI-generated guided meditation voice using AVSpeechSynthesizer
/// with a calm, gentle delivery — similar to BreatheAudioService.

@MainActor
class MeditationAudioService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = MeditationAudioService()

    // MARK: - Private State

    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?
    private(set) var isSpeaking = false

    private override init() {
        super.init()
        synthesizer.delegate = self
        selectedVoice = pickCalmVoice()
    }

    // MARK: - Voice Selection

    private func pickCalmVoice() -> AVSpeechSynthesisVoice? {
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

    // MARK: - Guided Meditation Phrases

    /// Welcome message at the start of the session.
    func speakWelcome(meditationName: String, durationMinutes: Int) {
        configureAudioSession()
        let text = "Welcome to your \(meditationName) meditation. "
            + "This session will last \(durationMinutes) minutes. "
            + "Find a comfortable position. Close your eyes if you'd like. "
            + "Take a deep breath in, and slowly release. "
            + "Let's begin."
        speakCalm(text)
    }

    /// Speak a phase title and instruction.
    func speakPhase(title: String, instruction: String) {
        configureAudioSession()
        // Clean up instruction for speech: remove newlines
        let cleanInstruction = instruction.replacingOccurrences(of: "\n", with: ". ")
        let text = "\(title). \(cleanInstruction)"
        speakCalm(text)
    }

    /// Transition between phases.
    func speakTransition(nextPhase: String) {
        configureAudioSession()
        let phrases = [
            "Gently shift your awareness now. \(nextPhase).",
            "Beautiful. Let's move to the next part. \(nextPhase).",
            "Take a soft breath. \(nextPhase).",
            "Wonderful. Slowly transition now. \(nextPhase).",
        ]
        let text = phrases.randomElement() ?? phrases[0]
        speakCalm(text)
    }

    /// Completion message.
    func speakCompletion(meditationName: String, durationMinutes: Int) {
        configureAudioSession()
        let text = "Your \(meditationName) meditation is complete. "
            + "You spent \(durationMinutes) minutes nurturing your mind. "
            + "Take a moment to notice how you feel. "
            + "Slowly open your eyes. "
            + "You've earned your focus points. Namaste."
        speakCalm(text)
    }

    /// Stop immediately.
    func stopAll() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    // MARK: - Delegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in isSpeaking = false }
    }

    // MARK: - Private Helpers

    private func speakCalm(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.36              // Very slow, meditative pace
        utterance.pitchMultiplier = 1.05   // Slightly higher for softer feel
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.5
        utterance.postUtteranceDelay = 0.8 // Longer pause for meditation

        synthesizer.speak(utterance)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
    }
}
