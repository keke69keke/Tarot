import Foundation

/// The bundle containing the app's bundled tarot catalogue and artwork.
public extension Bundle {
    static let tarotContent: Bundle = {
        // First try Bundle.module (SPM resource bundle).
        let moduleBundle = Bundle.module
        // Verify the bundle actually contains expected resources.
        if moduleBundle.url(forResource: "cards", withExtension: "json") != nil {
            return moduleBundle
        }

        // Fallback: look for the embedded TarotContent bundle in the host app.
        let candidates = [
            "TarotApp_TarotContent",
            "TarotContent"
        ]
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "bundle"),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }

        // Last resort: return the module bundle even if empty.
        return moduleBundle
    }()
}
