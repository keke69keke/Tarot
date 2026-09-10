import SwiftUI

public struct MysticMusicPlayerBar: View {
    @StateObject private var audioService = MysticAudioService.shared
    @StateObject private var externalAudio = ExternalAudioService.shared
    @State private var showingTrackSelector = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // Track Info / Selector button
            Menu {
                ForEach(AmbientTrack.availableTracks) { track in
                    Button {
                        audioService.selectTrack(track)
                    } label: {
                        Label(track.name, systemImage: track.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: audioService.currentTrack.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.tarotGold)
                    
                    Text(audioService.currentTrack.name)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // External Source Menu (Apple Music / Spotify)
            Menu {
                Button {
                    if externalAudio.appleMusicAuthorized {
                        externalAudio.playAppleMusic()
                    } else {
                        externalAudio.requestAppleMusicAuthorization { granted in
                            if granted {
                                externalAudio.playAppleMusic()
                            }
                        }
                    }
                } label: {
                    Label(
                        externalAudio.appleMusicAuthorized ? "Reproducir en Apple Music" : "Autorizar Apple Music",
                        systemImage: "music.note.house.fill"
                    )
                }

                Button {
                    externalAudio.openSpotifyURL("spotify:")
                } label: {
                    Label(
                        externalAudio.spotifyAvailable ? "Abrir en Spotify" : "Spotify no instalado",
                        systemImage: "music.note.list"
                    )
                }
                .disabled(!externalAudio.spotifyAvailable)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Fuente")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(externalAudio.appleMusicAuthorized ? "Apple Music autorizado" : "Apple Music no autorizado")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.75))
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()
            
            // Play / Pause Button
            Button {
                TarotAudioService.shared.playCardSelect()
                audioService.togglePlay()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.tarotGold)
                    
                    if audioService.isPlaying {
                        WaveformAnimationView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.tarotGold.opacity(0.18)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.92))
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.8)
        )
        .padding(.horizontal)
        .onAppear {
            externalAudio.refreshAvailability()
        }
    }
}

private struct WaveformAnimationView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.tarotGold)
                    .frame(width: 2, height: animating ? CGFloat(6 + (i * 4)) : 4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}
