// Add this to your project
import Foundation

public struct AmbientTrack: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let icon: String
    public let audioFileName: String

    public static let availableTracks: [AmbientTrack] = [
        AmbientTrack(name: "Bosque", icon: "leaf.fill", audioFileName: "forest"),
        AmbientTrack(name: "Océano", icon: "waveform", audioFileName: "ocean"),
        AmbientTrack(name: "Lluvia", icon: "cloud.rain", audioFileName: "rain"),
        AmbientTrack(name: "Fuego", icon: "flame.fill", audioFileName: "fire")
    ]
}
