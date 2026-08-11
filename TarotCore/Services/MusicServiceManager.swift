import Foundation
import StoreKit // Para Apple Music

class MusicServiceManager: ObservableObject {
    enum MusicService {
        case appleMusic
        case spotify
    }

    @Published var selectedService: MusicService = .appleMusic
    @Published var isAuthorized = false

    func authorize(service: MusicService) {
        selectedService = service
        switch service {
        case .appleMusic:
            authorizeAppleMusic()
        case .spotify:
            authorizeSpotify()
        }
    }

    private func authorizeAppleMusic() {
        SKCloudServiceController.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isAuthorized = status == .authorized
            }
        }
    }

    private func authorizeSpotify() {
        // Implementar autorización de Spotify usando su SDK
    }

    func searchTracks(query: String, completion: @escaping ([String]) -> Void) {
        switch selectedService {
        case .appleMusic:
            searchAppleMusic(query: query, completion: completion)
        case .spotify:
            searchSpotify(query: query, completion: completion)
        }
    }

    private func searchAppleMusic(query: String, completion: @escaping ([String]) -> Void) {
        // Implementar búsqueda en Apple Music
    }

    private func searchSpotify(query: String, completion: @escaping ([String]) -> Void) {
        // Implementar búsqueda en Spotify
    }
}
