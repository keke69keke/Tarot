import Foundation
import Combine
#if canImport(MediaPlayer)
import MediaPlayer
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class ExternalAudioService: ObservableObject {
    public static let shared = ExternalAudioService()

    @Published public private(set) var appleMusicAuthorized: Bool = false
    @Published public private(set) var spotifyAvailable: Bool = false

    private init() {
        #if canImport(MediaPlayer)
        updateAppleMusicStatus()
        #endif
        updateSpotifyAvailability()
    }

    public func refreshAvailability() {
        #if canImport(MediaPlayer)
        updateAppleMusicStatus()
        #endif
        updateSpotifyAvailability()
    }

    private func updateSpotifyAvailability() {
        #if canImport(UIKit)
        if let spotifyURL = URL(string: "spotify:") {
            spotifyAvailable = UIApplication.shared.canOpenURL(spotifyURL)
        } else {
            spotifyAvailable = false
        }
        #else
        spotifyAvailable = false
        #endif
    }

    #if canImport(MediaPlayer)
    public func updateAppleMusicStatus() {
        let status = MPMediaLibrary.authorizationStatus()
        appleMusicAuthorized = (status == .authorized)
    }

    public func requestAppleMusicAuthorization(completion: @escaping (Bool) -> Void) {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async { [weak self] in
                self?.appleMusicAuthorized = (status == .authorized)
                completion(status == .authorized)
            }
        }
    }

    /// Try to play a catalog item (Apple Music store ID). Requires the user to have Music access and/or an active Apple Music subscription for catalog playback.
    public func playAppleMusicCatalogItem(storeID: String) {
        #if canImport(MediaPlayer)
        let player = MPMusicPlayerController.systemMusicPlayer
        let descriptor = MPMusicPlayerStoreQueueDescriptor(storeIDs: [storeID])
        player.setQueue(with: descriptor)
        player.play()
        #endif
    }

    public func playAppleMusic() {
        #if canImport(MediaPlayer)
        let player = MPMusicPlayerController.systemMusicPlayer
        player.play()
        #endif
    }

    public func pauseAppleMusic() {
        #if canImport(MediaPlayer)
        let player = MPMusicPlayerController.systemMusicPlayer
        player.pause()
        #endif
    }
    #endif

    /// Open a Spotify URL (track/album/playlist). If Spotify is installed this will hand off playback to the Spotify app.
    public func openSpotifyURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #endif
    }

    /// Convenience: try to play a Spotify track by opening its spotify:track:... URI or https URL.
    public func playSpotifyTrack(uriOrUrl: String) {
        #if canImport(UIKit)
        if let appUrl = URL(string: uriOrUrl), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl, options: [:], completionHandler: nil)
            return
        }
        if let webUrl = URL(string: uriOrUrl), UIApplication.shared.canOpenURL(webUrl) {
            UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
        }
        #endif
    }
}
