@MainActor
public protocol CosmicBackgroundEngineProtocol {
    var isZenMode: Bool { get }
    func setZenMode(_ enabled: Bool)
    func updateCosmicState()
    func updateForBiometrics(heartRate: Double, state: SoulState)
    // Additional properties can be added if needed for UI
    // For now, UI uses concrete engine for color access
}
