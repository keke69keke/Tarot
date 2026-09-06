import Foundation
import Combine
#if canImport(MediaPlayer)
import MediaPlayer
#endif

@MainActor
public final class ExternalAudioService: ObservableObject {
    public static let shared = ExternalAudioService()

    @Published public private(set) var appleMusicAuthorized: Bool = false
    @Published public private(set) var spotifyAvailable: Bool = false

    private init() {
        #if os(iOS)
        updateAppleMusicStatus()
        #endif
        updateSpotifyAvailability()
    }

    public func refreshAvailability() {
        #if os(iOS)
        updateAppleMusicStatus()
        #endif
        updateSpotifyAvailability()
    }

    private func updateSpotifyAvailability() {
        if let spotifyURL = URL(string: "spotify:") {
            spotifyAvailable = PlatformApp.canOpenURL(spotifyURL)
        } else {
            spotifyAvailable = false
        }
    }

    public func updateAppleMusicStatus() {
        #if os(iOS)
        let status = MPMediaLibrary.authorizationStatus()
        appleMusicAuthorized = (status == .authorized)
        #else
        appleMusicAuthorized = false
        #endif
    }

    public func requestAppleMusicAuthorization(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async { [weak self = self] in
                self?.appleMusicAuthorized = (status == .authorized)
                completion(status == .authorized)
            }
        }
        #else
        completion(false)
        #endif
    }

    public func playAppleMusicCatalogItem(storeID: String) {
        #if os(iOS)
        let player = MPMusicPlayerController.systemMusicPlayer
        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [storeID])
        player.setQueue(with: descriptor)
        player.play()
        #endif
    }

    public func playAppleMusic() {
        #if os(iOS)
        let player = MPMusicPlayerController.systemMusicPlayer
        player.play()
        #endif
    }

    public func pauseAppleMusic() {
        #if os(iOS)
        let player = MPMusicPlayerController.systemMusicPlayer
        player.pause()
        #endif
    }

    public func openSpotifyURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        PlatformApp.openURL(url)
    }

    public func playSpotifyTrack(uriOrUrl: String) {
        if let appUrl = URL(string: uriOrUrl), PlatformApp.canOpenURL(appUrl) {
            PlatformApp.openURL(appUrl)
            return
        }
        if let webUrl = URL(string: uriOrUrl), PlatformApp.canOpenURL(webUrl) {
            PlatformApp.openURL(webUrl)
        }
    }
}
