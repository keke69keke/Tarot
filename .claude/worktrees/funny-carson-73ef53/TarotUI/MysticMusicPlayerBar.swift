import SwiftUI

// MARK: - Mystic Music Player Bar — Frecuencias del Tarot

public struct MysticMusicPlayerBar: View {
    @StateObject private var audioService = MysticAudioService.shared
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Descripción del track actual
            HStack(spacing: 6) {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.tarotGold.opacity(0.7))
                Text("FRECUENCIAS DEL TAROT")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(1.8)
                    .foregroundStyle(Color.tarotGold.opacity(0.7))
            }

            HStack(spacing: 12) {
                // Selector de frecuencia
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
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color.tarotGold)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.tarotGold.opacity(0.14)))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(audioService.currentTrack.name)
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                                .lineLimit(1)
                            Text(audioService.currentTrack.description)
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.5))
                                .lineLimit(1)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.tarotIvory.opacity(0.4))
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Play / Pause
                Button {
                    TarotAudioService.shared.triggerHaptic(.light)
                    audioService.togglePlay()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.tarotGold)
                        if audioService.isPlaying {
                            WaveformAnimationView()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.tarotGold.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .luxuryGlass(cornerRadius: 18)
        .padding(.horizontal)
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
