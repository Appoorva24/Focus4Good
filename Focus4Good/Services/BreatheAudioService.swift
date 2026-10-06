@preconcurrency import AVFoundation

// MARK: - BreatheAudioService

/// Provides a full guided breathing experience using AVSpeechSynthesizer
/// with a gentle, calming female voice.

@MainActor
class BreatheAudioService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = BreatheAudioService()

    // MARK: - Private State


    //synthesizer - takes any text and convert that into speech
    private let synthesizer = AVSpeechSynthesizer()
    private var selectedVoice: AVSpeechSynthesisVoice?
    private var onSpeechFinished: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
        selectedVoice = pickFemaleVoice()
    }

    // MARK: - Voice Selection

    /// Pick the best available female voice for a calm, gentle experience.
    private func pickFemaleVoice() -> AVSpeechSynthesisVoice? {
        // Preferred female voices in priority order (premium → enhanced → default)
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

        // Fallback: pick any English female voice, or default English
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Full Guided Experience

    /// Welcome and settle the user before the session begins.
    func speakIntro(cycles: Int, completion: @escaping () -> Void) {
        configureAudioSession()
        onSpeechFinished = completion
        let text = "Welcome. Let's begin \(cycles) rounds of the 4, 7, 8 breathing technique."
        speakCalm(text)
    }

    /// Guide the user through each breathing phase.
    func speakPhase(_ phaseName: String, cycle: Int, totalCycles: Int) {
        configureAudioSession()
        onSpeechFinished = nil // Clear any pending completion
        let text: String
        switch phaseName {
        case "Breathe In":
            text = cycle == 1 ? "Breathe in." : "Round \(cycle). Breathe in."
        case "Hold":
            text = "Hold."
        case "Breathe Out":
            text = "Breathe out."
        default:
            text = phaseName
        }
        speakCalm(text)
    }

    // speakCycleTransition removed to prevent overlapping, transition handled in speakPhase.

    /// Speak a calming completion message.
    func speakCompletion(cycles: Int) {
        configureAudioSession()
        let text = "You did it. \(cycles) \(cycles == 1 ? "round" : "rounds") complete. "
            + "Take a moment to notice how your body feels. "
            + "Gently open your eyes when you are ready. "
            + "You've earned your focus points. Well done."
        speakCalm(text)
    }

    func stopAll() {
        onSpeechFinished = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func pauseAll() {
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resumeAll() {
        synthesizer.continueSpeaking()
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onSpeechFinished?()
        onSpeechFinished = nil
    }

    // MARK: - Private Helpers

    /// Speak with a gentle, calming delivery.
    private func speakCalm(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = selectedVoice
        utterance.rate = 0.38              // Very slow, meditative pace
        utterance.pitchMultiplier = 1.05   // Slightly higher for a softer feel
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.5 // Pause after each phrase

        synthesizer.speak(utterance)
    }


    // managing phone's volume
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? session.setActive(true)
    }
}
