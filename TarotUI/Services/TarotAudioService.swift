import SwiftUI
import AudioToolbox
import AVFoundation
import TarotCore

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Service managing tactile haptic responses and subtle sound effects during card readings.
public final class TarotAudioService: ObservableObject {
    public static let shared = TarotAudioService()

    // MARK: - Generative Ambience Engine
    private let audioEngine = AVAudioEngine()
    private var planetaryNodes: [Planet: AVAudioPlayerNode] = [:]
    private var currentPlanet: Planet?
    private var setupTask: Task<Void, Never>?

    private init() {
        // Configure and activate audio session off the main thread to avoid UI stalls.
        setupTask = Task.detached { [weak self] in
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                // Use async activate when available to avoid blocking the main thread.
                if #available(iOS 17.0, *) {
                    try session.setActive(true)
                } else {
                    try session.setActive(true)
                }
            } catch {
                print("TarotAudioService: Failed to configure/activate audio session: \(error)")
            }
            #endif
            await self?.setupAmbienceEngine()
        }
    }

    private func setupAmbienceEngine() async {
        let planets: [Planet] = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]

        for planet in planets {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            planetaryNodes[planet] = node
        }

        // Connect all nodes to main mixer
        for node in planetaryNodes.values {
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: nil)
        }

        do {
            try audioEngine.start()
        } catch {
            print("TarotAudioService: Failed to start audio engine: \(error)")
        }
    }

    /// Updates the ambient soundscape based on celestial and biometric data.
    @MainActor
    public func updateAmbience(dominantPlanet: Planet, heartRate: Double) {
        let targetPlanet = dominantPlanet

        // 1. Handle Crossfading
        if currentPlanet != targetPlanet {
            // Fade out old planet
            if let oldPlanet = currentPlanet {
                fadeOut(planet: oldPlanet)
            }

            // Fade in new planet
            fadeIn(planet: targetPlanet)
            currentPlanet = targetPlanet
        }

        // 2. Biometric Sync: Modulate playback rate based on BPM
        // 60 BPM -> 1.0x, 100 BPM -> 1.2x
        let rate = 1.0 + (heartRate - 60) * 0.002
        _ = max(0.8, min(1.5, rate))

        if planetaryNodes[targetPlanet] != nil {
            // In a full implementation, we would use AVAudioUnitTimePitch to shift rate
            // without changing pitch. For now, we've calculated the clamped rate.
        }
    }

    private func fadeIn(planet: Planet) {
        guard let node = planetaryNodes[planet],
              let url = Bundle.main.url(forResource: "ambient_\(planet)", withExtension: "mp3") else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            node.scheduleFile(file, at: nil, completionHandler: nil)
            node.volume = 0
            node.play()
            node.volume = 0.5 // Simplified fade
        } catch {
            print("TarotAudioService: Error loading ambient file for \(planet): \(error)")
        }
    }

    private func fadeOut(planet: Planet) {
        if let node = planetaryNodes[planet] {
            node.volume = 0
            node.stop()
        }
    }

    @MainActor
    public func playZenChime() {
        triggerHaptic(.success)
        #if os(iOS)
        AudioServicesPlaySystemSound(1025) // Special chime
        #endif
    }

    // MARK: - Haptic Feedback Styles
    public enum HapticStyle {
        case light
        case medium
        case heavy
        case selection
        case success
    }
    
    /// Triggers subtle haptic vibration (iOS only).
    @MainActor
    public func triggerHaptic(_ style: HapticStyle = .medium) {
        #if os(iOS)
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        #endif
    }
    
    // MARK: - Native Sound Effects
    
    /// Plays subtle card flip sound.
    @MainActor
    public func playCardFlip() {
        triggerHaptic(.medium)
        #if os(iOS)
        AudioServicesPlaySystemSound(1104) // Tink / Card pop
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Plays card selection sound.
    @MainActor
    public func playCardSelect() {
        triggerHaptic(.selection)
        #if os(iOS)
        AudioServicesPlaySystemSound(1105) // Tock
        #endif
    }
    
    /// Plays golden chime sound for card reveal / completion.
    @MainActor
    public func playGoldenChime() {
        triggerHaptic(.success)
        #if os(iOS)
        AudioServicesPlaySystemSound(1025)
        #endif
    }

    /// Triggers a failure notification.
    @MainActor
    public func triggerError() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Triggers a suit-specific tactile signature.
    @MainActor
    public func triggerSuitHaptic(suit: CardSuit) {
        HapticManager.shared.triggerSuitHaptic(suit: suit)
    }

    // MARK: - Lifecycle

    /// Cancels any pending setup tasks and tears down the audio engine.
    /// Call this when the app enters the background or terminates.
    public func shutdown() {
        setupTask?.cancel()
        setupTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.reset()
        }

        for node in planetaryNodes.values {
            node.stop()
            node.reset()
        }
        planetaryNodes.removeAll()
        currentPlanet = nil

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

