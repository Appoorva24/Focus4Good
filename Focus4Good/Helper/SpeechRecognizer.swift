import Foundation
import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechRecognizer {
    
    // MARK: - State
    var transcript: String = ""
    var isListening: Bool = false
    var errorMessage: String? = nil
    
    // MARK: - Private
    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
    }
    
    // MARK: - Public API
    
    /// Request permission then start recording.
    func startListening() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }
            Task { @MainActor in
                switch status {
                case .authorized:
                    AVAudioApplication.requestRecordPermission { granted in
                        Task { @MainActor in
                            if granted {
                                self.beginRecording()
                            } else {
                                self.errorMessage = "Microphone access denied."
                            }
                        }
                    }
                case .denied, .restricted:
                    self.errorMessage = "Speech recognition permission denied. Please enable it in Settings."
                default:
                    self.errorMessage = "Speech recognition not available."
                }
            }
        }
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        audioEngine = nil
        request = nil
        task = nil
        isListening = false
    }
    
    // MARK: - Private
    
    private func beginRecording() {
        stopListening() // reset any existing session
        
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available right now."
            return
        }
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req
        
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            req.append(buffer)
        }
        
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal == true) {
                    self.stopListening()
                }
            }
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try engine.start()
            isListening = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not start audio engine: \(error.localizedDescription)"
            stopListening()
        }
    }
}
