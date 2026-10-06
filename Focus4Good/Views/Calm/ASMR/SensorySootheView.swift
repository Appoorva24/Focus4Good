import SwiftUI

struct SensorySootheView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    @State private var selectedSound: AsmrSound?
    
    // New State for Recents
    @State private var recentPlaylist: ASMRPlaylist?
    @State private var recentSounds: [AsmrSound] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // 1. Top Section: 5 Playlists (Horizontally Scrollable)
                playlistsSection
                
                // 2. Favourites Section
                if !store.favouriteAsmrSounds.isEmpty {
                    favouriteSoundsSection
                }
                
                // 3. Middle Section: Recent Playlist
                if recentPlaylist != nil {
                    recentPlaylistSection
                }
                
                // 4. Bottom Section: Recently Played ASMR Sounds
                if !recentSounds.isEmpty {
                    recentlyPlayedSoundsSection
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle("ASMR Sounds")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { 
            loadRecents()
            if let userId = userStore.currentUser?.id {
                Task { await store.fetchFavouriteAsmrSounds(userId: userId) }
            }
        }
    }

    // MARK: - Data Loading
    
    private func loadRecents() {
        let userId = userStore.currentUser?.id.uuidString ?? "guest"
        let playlistKey = "recent_asmr_playlist_id_\(userId)"
        let soundsKey = "recent_asmr_sounds_\(userId)"
        
        // Load recent playlist
        if let savedIdString = UserDefaults.standard.string(forKey: playlistKey),
           let savedId = UUID(uuidString: savedIdString) {
            recentPlaylist = ASMRData.playlists.first(where: { $0.id == savedId })
        } else {
            recentPlaylist = nil
        }
        
        // Load recent sounds
        if let data = UserDefaults.standard.data(forKey: soundsKey),
           let saved = try? JSONDecoder().decode([AsmrSound].self, from: data) {
            recentSounds = saved
        } else {
            recentSounds = []
        }
    }

    // MARK: - Subviews

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ASMRData.playlists) { playlist in
                        NavigationLink(destination: ASMRPlaylistDetailView(playlist: playlist)) {
                            playlistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16) // Added vertical padding so shadows aren't clipped during scroll
            }

        }
    }

    private func playlistCard(playlist: ASMRPlaylist) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background (Image or Placeholder Color)
            if !playlist.coverImageName.isEmpty {
                Image(playlist.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(hex: playlist.placeholderColorHex).gradient)
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                Text(playlist.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: playlist.placeholderColorHex).opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var recentPlaylistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jump Back In")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let playlist = recentPlaylist {
                NavigationLink(destination: ASMRPlaylistDetailView(playlist: playlist)) {
                    HStack(spacing: 16) {
                        if !playlist.coverImageName.isEmpty {
                            Image(playlist.coverImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: playlist.placeholderColorHex).gradient)
                                .frame(width: 80, height: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Recent Playlist")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var favouriteSoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Your Favourites")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(store.favouriteAsmrSounds) { sound in
                        Button {
                            store.activeAsmrSound = sound
                            store.showGlobalASMRPlayer = true
                        } label: {
                            VStack(spacing: 8) {
                                if !sound.imageUrl.isEmpty {
                                    Image(sound.imageUrl)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "waveform")
                                                .font(.title2)
                                                .foregroundStyle(.secondary)
                                        )
                                }

                                Text(sound.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 120)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentlyPlayedSoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Played Sounds")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(recentSounds, id: \.name) { sound in
                    soundRow(sound)
                }
            }
            .padding(.horizontal)
        }
    }

    private func soundRow(_ sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
            store.activeAsmrSound = sound
            store.showGlobalASMRPlayer = true
        } label: {
            HStack(spacing: 14) {
                if !sound.imageUrl.isEmpty {
                    Image(sound.imageUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "waveform")
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(sound.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SensorySootheView()
            .environment(CalmCentreStore.shared)
            .environment(UserStore())
    }
}
