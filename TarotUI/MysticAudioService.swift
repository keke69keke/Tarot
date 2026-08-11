import Foundation
import AVFoundation
import Combine
#if os(iOS)
import UIKit
#endif

public final class MysticAudioService: ObservableObject {
    public static let shared = MysticAudioService()

    private var audioPlayer: AVAudioPlayer?
    #if os(iOS)
    private var audioSession: AVAudioSession = .sharedInstance()
    #endif

    @Published public var currentTrack: AmbientTrack
    @Published public var isPlaying: Bool = false

    private init() {
        currentTrack = AmbientTrack.availableTracks.first!
    }

    public func selectTrack(_ track: AmbientTrack) {
        currentTrack = track
        preparePlayer()
    }

    public func togglePlay() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: currentTrack.audioFileName, withExtension: "mp3") else {
            print("Audio file not found: \(currentTrack.audioFileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to prepare audio player: \(error.localizedDescription)")
        }
    }

    private func play() {
        guard let player = audioPlayer else {
            preparePlayer()
            return
        }

        #if os(iOS)
        do {
            try audioSession.setActive(true)
            player.play()
            isPlaying = true
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
        #else
        player.play()
        isPlaying = true
        #endif
    }

    private func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    public func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }

    deinit {
        audioPlayer?.stop()
        #if os(iOS)
        try? audioSession.setActive(false)
        #endif
    }
}
