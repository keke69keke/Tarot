import Foundation
import Combine

#if canImport(CoreMotion) && !os(macOS)
import CoreMotion

/// Service that detects somatic gestures (like shaking) and notifies the application.
public final class SomaticService: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published public var isShaking = false

    private var lastAccelerometerData: CMAccelerometerData?
    private let shakeThreshold: Double = 2.0 // Adjust based on testing

    public init() {
        startAccelerometerUpdates()
    }

    public func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.detectShake(data)
        }
    }

    public func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }

    private func detectShake(_ data: CMAccelerometerData) {
        guard let last = lastAccelerometerData else {
            lastAccelerometerData = data
            return
        }

        let deltaX = data.acceleration.x - last.acceleration.x
        let deltaY = data.acceleration.y - last.acceleration.y
        let deltaZ = data.acceleration.z - last.acceleration.z

        let totalDelta = sqrt(deltaX*deltaX + deltaY*deltaY + deltaZ*deltaZ)

        if totalDelta > shakeThreshold {
            // Trigger shake event
            self.isShaking = true
            // Reset quickly so it can trigger again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isShaking = false
            }
        }

        lastAccelerometerData = data
    }
}
#else

/// Fallback stub for platforms without CoreMotion (e.g. macOS).
/// Keeps the same API but performs no motion tracking.
public final class SomaticService: ObservableObject {
    @Published public var isShaking = false

    public init() {}
    public func startAccelerometerUpdates() {}
    public func stopAccelerometerUpdates() {}
}

#endif
