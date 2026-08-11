import MusicKit
import SwiftUI // Add this import

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
        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run {
                isAuthorized = (status == .authorized)
            }
        }
    }

    private func authorizeSpotify() {
        // Implement Spotify authorization
    }
}
