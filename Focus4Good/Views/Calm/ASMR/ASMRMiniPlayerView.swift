import SwiftUI

struct ASMRMiniPlayerView: View {
    @Environment(CalmCentreStore.self) private var store
    var audio = ASMRAudioService.shared
    
    var body: some View {
        if let soundName = audio.currentSoundName, !store.isASMRPlayerPresented, !audio.isDeepFocusSound {
            Button {
                store.showGlobalASMRPlayer = true
            } label: {
                HStack(spacing: 16) {
                    // Artwork
                    if let imageName = store.activeAsmrSound?.imageUrl {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "waveform")
                            .font(.title2)
                            .foregroundColor(AppTheme.orange)
                            .frame(width: 48, height: 48)
                            .background(AppTheme.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 2) {
                        Text(soundName)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(audio.isPlaying ? "Playing ASMR" : "Paused")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Play / Pause Button
                    Button {
                        if audio.isPlaying {
                            audio.pause()
                        } else {
                            audio.resume()
                        }
                    } label: {
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain) // Prevent the button highlight from ruining the look
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
