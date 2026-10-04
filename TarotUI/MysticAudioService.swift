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
        currentTrack = AmbientTrack.availableTracks.first ?? .defaultTrack
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
        // La activacion de la sesion de audio pasa a un hilo de fondo para no bloquear
        // el principal, como recomienda Apple.
        activateSessionAndPlay(player: player)
        #else
        player.play()
        isPlaying = true
        #endif
    }

    #if os(iOS)
    /// Configura y activa la sesion de audio y, cuando el sistema confirma la
    /// activacion, arranca la reproduccion.
    ///
    /// La version anterior usaba `setActive(_:options:)` con un closure de
    /// finalizacion: esa firma ya no existe en `AVAudioSession`, asi que el
    /// objetivo de iOS no compilaba y el build moria a medias.
    private func activateSessionAndPlay(player: AVAudioPlayer) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                try self.audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try self.audioSession.setActive(true)
                DispatchQueue.main.async {
                    player.play()
                    self.isPlaying = true
                }
            } catch {
                print("[MysticAudio] Session activate error: \(error.localizedDescription)")
            }
        }
    }
    #endif

    private func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        #if os(iOS)
        // Desactivar la sesion tambien fuera del hilo principal: es una llamada que
        // puede tardar y bloquear la interfaz.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("[MysticAudio] Session deactivate error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async { self.isPlaying = false }
        }
        #else
        isPlaying = false
        #endif
    }

    deinit {
        stop()
    }
}

extension MysticAudioService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // numberOfLoops = -1 ya hace loop — este delegate es por si acaso
        if flag && isPlaying { player.play() }
    }
}
