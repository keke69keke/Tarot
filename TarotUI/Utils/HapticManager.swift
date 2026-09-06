import SwiftUI
import TarotCore

#if canImport(UIKit) && !os(macOS)
import UIKit

/// Manages tactile feedback for the Tarot app on platforms that support haptics (iOS/tvOS/watchOS).
public final class HapticManager {
    public static let shared = HapticManager()
    private init() {}

    /// Triggers a light impact, suitable for hovering or selecting small elements.
    public func triggerLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Triggers a medium impact, suitable for card flips or significant state changes.
    public func triggerMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Triggers a heavy impact, suitable for completing a reading or major reveals.
    public func triggerHeavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Triggers a selection feedback, suitable for sliders or picker-like interactions.
    public func triggerSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Triggers a success notification.
    public func triggerSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Triggers a failure notification.
    public func triggerError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Triggers a suit-specific tactile signature.
    public func triggerSuitHaptic(suit: CardSuit) {
        switch suit {
        case .wands:
            // Energetic, rapid bursts
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { generator.impactOccurred() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { generator.impactOccurred() }
        case .cups:
            // Soft, undulating wave
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { generator.selectionChanged() }
        case .swords:
            // Sharp, precise, "cutting" impact
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .pentacles:
            // Deep, grounding, slow thump
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
#else

/// Stub implementation for platforms without UIKit (e.g. macOS).
/// Methods are noop to keep API compatible.
public final class HapticManager {
    public static let shared = HapticManager()
    private init() {}

    public func triggerLight() {}
    public func triggerMedium() {}
    public func triggerHeavy() {}
    public func triggerSelection() {}
    public func triggerSuccess() {}
    public func triggerError() {}
    public func triggerSuitHaptic(suit: CardSuit) {}
}

#endif
