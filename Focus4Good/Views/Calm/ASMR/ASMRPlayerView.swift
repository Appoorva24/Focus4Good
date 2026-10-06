import SwiftUI

struct ASMRPlayerView: View {

    let sound: AsmrSound

    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var volume: Double = 0.5
    @State private var isSeeking = false
    @State private var isMuted = false

    @Environment(CalmCentreStore.self) private var store
    private var audio: ASMRAudioService { ASMRAudioService.shared }

    var body: some View {
        GeometryReader { geo in
            let artworkSize = geo.size.width - 56

            VStack(spacing: 0) {
                Spacer()

                // Artwork
                Image(sound.imageUrl.isEmpty ? "asmr_rain" : sound.imageUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: artworkSize, height: artworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                Spacer().frame(height: 32)

                // Title + Favourite
                titleRow.padding(.horizontal, 28)

                Spacer().frame(height: 20)

                // Progress
                progressSection.padding(.horizontal, 28)

                Spacer().frame(height: 36)

                // Controls
                playbackControls

                Spacer().frame(height: 36)

                // Volume
                volumeSlider.padding(.horizontal, 28)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.warmTextPrimary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }
        }
        .onAppear {
            store.isASMRPlayerPresented = true
            if audio.isLoaded(soundName: sound.name) {
                // Same sound is already loaded (playing or paused) — resume from current position
                isPlaying = audio.isPlaying
                duration = audio.duration
                currentTime = audio.currentTime
                if isPlaying { startTimer() }
            } else {
                startPlaying()
            }
        }
        .onDisappear { 
            store.isASMRPlayerPresented = false
            stopTimer() 
        }
    }

    // MARK: - Subviews

    private var titleRow: some View {
        HStack {
            Text(sound.name)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Spacer()

            let isFavourite = store.favouriteAsmrSoundIds.contains(sound.id)
            Button { 
                if let userId = userStore.currentUser?.id {
                    store.toggleAsmrFavourite(soundId: sound.id, userId: userId) 
                }
            } label: {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavourite ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { currentTime },
                    set: { newValue in
                        currentTime = newValue
                        audio.seek(to: newValue)
                    }
                ),
                in: 0...max(duration, 1)
            ) { editing in
                isSeeking = editing
                if !editing { audio.seek(to: currentTime) }
            }
            .tint(Color(.systemGray))

            HStack {
                Text(formatTime(currentTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-\(formatTime(max(0, duration - currentTime)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 44) {
            Button {
                isMuted.toggle()
                audio.setVolume(isMuted ? 0 : Float(volume))
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                isPlaying ? pausePlaying() : resumePlaying()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Button {
                currentTime = 0
                audio.seek(to: 0)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var volumeSlider: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $volume, in: 0...1)
                .tint(Color(.systemGray))
                .onChange(of: volume) { _, newValue in
                    audio.setVolume(Float(newValue))
                }

            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Playback Logic

    private func startPlaying() {
        store.playAsmrSound(sound)
        audio.play(soundName: sound.name)
        isPlaying = true
        duration = audio.duration
        currentTime = 0
        startTimer()
    }

    private func pausePlaying() {
        audio.pause()
        isPlaying = false
        stopTimer()
    }

    private func resumePlaying() {
        audio.resume()
        isPlaying = true
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard !isSeeking else { return }
            currentTime = audio.currentTime
            duration = audio.duration
            if currentTime >= duration, duration > 0 { pausePlaying() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        ASMRPlayerView(
            sound: AsmrSound(
                name: "Nature & Calm",
                description: "Recommended for Focus",
                category: "Nature",
                audioUrl: "",
                imageUrl: "asmr_hero",
                durationSeconds: 300
            )
        )
        .environment(CalmCentreStore.shared)
        .environment(UserStore())
    }
}
