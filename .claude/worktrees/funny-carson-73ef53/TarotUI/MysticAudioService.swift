import Foundation
import AVFoundation
import Combine
import TarotContent
#if os(iOS)
import UIKit
#endif

public final class MysticAudioService: NSObject, ObservableObject {
    public static let shared = MysticAudioService()
    private var audioPlayer: AVAudioPlayer?
    #if os(iOS)
    private var audioSession: AVAudioSession = .sharedInstance()
    #endif
    @Published public var currentTrack: AmbientTrack
    @Published public var isPlaying: Bool = false

    private override init() {
        currentTrack = AmbientTrack.availableTracks.first!
        super.init()
    }

    public func selectTrack(_ track: AmbientTrack) {
        let wasPlaying = isPlaying
        stop()
        currentTrack = track
        preparePlayer()
        if wasPlaying { play() }
    }

    public func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    private func preparePlayer() {
        let extensions = ["wav", "mp3", "m4a"]
        var resolved: URL? = nil
        for ext in extensions {
            if let url = Bundle.tarotContent.url(forResource: currentTrack.audioFileName, withExtension: ext) {
                resolved = url; break
            }
            if let url = Bundle.main.url(forResource: currentTrack.audioFileName, withExtension: ext) {
                resolved = url; break
            }
        }
        guard let url = resolved else {
            print("[MysticAudio] File not found: \(currentTrack.audioFileName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = -1  // loop infinito
            audioPlayer?.prepareToPlay()
        } catch {
            print("[MysticAudio] Error: \(error.localizedDescription)")
        }
    }

    private func play() {
        if audioPlayer == nil { preparePlayer() }
        guard let player = audioPlayer else { return }
        #if os(iOS)
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            player.play()
            isPlaying = true
        } catch {
            print("[MysticAudio] Session error: \(error.localizedDescription)")
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
        audioPlayer = nil
        isPlaying = false
    }

    deinit {
        stop()
        #if os(iOS)
        try? audioSession.setActive(false)
        #endif
    }
}

extension MysticAudioService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // numberOfLoops = -1 ya hace loop — este delegate es por si acaso
        if flag && isPlaying { player.play() }
    }
}
