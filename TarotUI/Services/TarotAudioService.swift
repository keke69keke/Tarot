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
@MainActor
public final class TarotAudioService: ObservableObject {
    public static let shared = TarotAudioService()

    // MARK: - Generative Ambience Engine
    private let audioEngine = AVAudioEngine()
    private var planetaryNodes: [Planet: AVAudioPlayerNode] = [:]
    private var currentPlanet: Planet?

    private init() {
        setupAmbienceEngine()
    }

    private func setupAmbienceEngine() {
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
        let clampedRate = max(0.8, min(1.5, rate))

        if let currentNode = planetaryNodes[targetPlanet] {
            // In a full implementation, we would use AVAudioUnitTimePitch to shift rate
            // without changing pitch. For now, we've calculated the clampedRate.
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
    public func playCardFlip() {
        triggerHaptic(.medium)
        #if os(iOS)
        AudioServicesPlaySystemSound(1104) // Tink / Card pop
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Plays card selection sound.
    public func playCardSelect() {
        triggerHaptic(.selection)
        #if os(iOS)
        AudioServicesPlaySystemSound(1105) // Tock
        #endif
    }
    
    /// Plays golden chime sound for card reveal / completion.
    public func playGoldenChime() {
        triggerHaptic(.success)
        #if os(iOS)
        AudioServicesPlaySystemSound(1025)
        #endif
    }

    /// Triggers a failure notification.
    public func triggerError() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Triggers a suit-specific tactile signature.
    public func triggerSuitHaptic(suit: CardSuit) {
        HapticManager.shared.triggerSuitHaptic(suit: suit)
    }
}
