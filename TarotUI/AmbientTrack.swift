// MARK: - Ambient Tracks — Frecuencias del Tarot
import Foundation

public struct AmbientTrack: Identifiable, Hashable {
    public let id: String  // stable ID (no UUID, persists across launches)
    public let name: String
    public let icon: String
    public let audioFileName: String  // sin extensión — se busca .wav en Bundle.tarotContent
    public let description: String

    public static let availableTracks: [AmbientTrack] = [
        AmbientTrack(id: "432hz",  name: "432 Hz",       icon: "waveform",           audioFileName: "tarot_432hz",  description: "Afinación natural · amor universal"),
        AmbientTrack(id: "528hz",  name: "528 Hz",       icon: "sparkles",           audioFileName: "tarot_528hz",  description: "Transformación · frecuencia del ADN"),
        AmbientTrack(id: "396hz",  name: "396 Hz",       icon: "wind",               audioFileName: "tarot_396hz",  description: "Liberación del miedo · chakra raíz"),
        AmbientTrack(id: "bowl",   name: "Tazón Tibetano", icon: "circle.hexagongrid", audioFileName: "tarot_bowl",   description: "Meditación profunda · D 147 Hz"),
        AmbientTrack(id: "om",     name: "Om Binaural",  icon: "moon.stars",         audioFileName: "tarot_om",     description: "Om cósmico 136 Hz · ondas theta"),
    ]
}
