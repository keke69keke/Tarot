import Foundation

/// Protocol for an engine capable of synthesizing spiritual meanings from tarot spreads.
public protocol NeuralSynthesisEngineProtocol {
    /// Synthesizes a coherent narrative from a provided prompt.
    func synthesize(prompt: String) async throws -> String

    /// Synthesizes a high-level summary for a specific spread and celestial context.
    func synthesizeSummary(for spread: Spread, moonPhase: String) async throws -> String
}
