import AVFoundation

//Sound-to-File Mapping

private func getFileName(for soundName: String) -> String {
    let lowerName = soundName.lowercased()
    if lowerName.contains("creating") || lowerName.contains("mental") || lowerName.contains("deep focus") || lowerName.contains("deepfocus") {
        return "creating-mental-space"
    } else if lowerName.contains("rain") || lowerName.contains("water") || lowerName.contains("ocean") || lowerName.contains("stream") {
        return "soft_rain_asmr"
    } else if lowerName.contains("typing") || lowerName.contains("keyboard") || lowerName.contains("mechanical") {
        return "keyboard_typing_asmr"
    } else if lowerName.contains("noise") || lowerName.contains("hum") || lowerName.contains("fan") {
        return "white_noise"
    } else {
        return "nature_and_calm"
    }
}

import Observation

// MARK: - ASMRAudioService

@Observable
class ASMRAudioService: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {

    //prevents two different sounds from playing at the same time
    static let shared = ASMRAudioService()

    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentSoundName: String?

    var isShuffleEnabled = false
    var playlistSounds: [AsmrSound] = []
    var currentSound: AsmrSound?

    private override init() {
        super.init()
    }

    var isDeepFocusSound: Bool {
        guard let name = currentSoundName?.lowercased() else { return false }
        return name.contains("creating") || name.contains("mental") || name.contains("deep focus")
    }

    /// Whether the given sound is already loaded (playing or paused).
    func isLoaded(soundName: String) -> Bool {
        currentSoundName == soundName && audioPlayer != nil
    }

    func shufflePlay(playlist: [AsmrSound]) {
        self.playlistSounds = playlist
        self.isShuffleEnabled = true
        guard !playlist.isEmpty else { return }

        let randomSound = playlist.randomElement() ?? playlist[0]
        self.currentSound = randomSound

        Task { @MainActor in
            CalmCentreStore.shared.activeAsmrSound = randomSound
        }

        play(soundName: randomSound.name)
        saveAsRecentSound(randomSound)
    }

    func play(soundName: String) {
        stop()

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Look up the file name using the dynamic matcher
        let fileName = getFileName(for: soundName)

        // Try to find the audio file in the bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("ASMRAudioService: could not find \(fileName).mp3 in bundle")
            return
        }

        // starting the player
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = 0  // Play once (timer controls end / delegate handles next)
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentSoundName = soundName
            isPlaying = true
        } catch {
            print("ASMRAudioService: failed to play — \(error)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentSoundName = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - AVAudioPlayerDelegate
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if self.isShuffleEnabled && !self.playlistSounds.isEmpty {
                let candidates = self.playlistSounds.count > 1 
                    ? self.playlistSounds.filter { $0.name != self.currentSoundName }
                    : self.playlistSounds
                if let nextSound = candidates.randomElement() {
                    self.currentSound = nextSound
                    CalmCentreStore.shared.activeAsmrSound = nextSound
                    self.play(soundName: nextSound.name)
                    self.saveAsRecentSound(nextSound)
                } else {
                    self.isPlaying = false
                    self.currentSoundName = nil
                }
            } else {
                self.isPlaying = false
                self.currentSoundName = nil
            }
        }
    }

    // MARK: - Save Recent
    func saveAsRecentSound(_ sound: AsmrSound, userId: String? = nil) {
        let key = "recent_asmr_sounds_\(userId ?? "guest")"
        var recents: [AsmrSound] = []
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([AsmrSound].self, from: data) {
            recents = saved
        }
        recents.removeAll { $0.name == sound.name }
        recents.insert(sound, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        if let encoded = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    // Duration & Current Time

    /// Total duration of the loaded audio in seconds.
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }

    /// Current playback position in seconds.
    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }

    // MARK: Seeking

    /// Seek to a specific time in seconds.
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clampedTime = max(0, min(time, player.duration))
        player.currentTime = clampedTime
    }

    // MARK: Volume

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
}
