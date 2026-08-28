import SwiftUI
import PDFKit
import TarotContent
import TarotCore
import TarotData
import TarotNotifications

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - Color helpers — 100k MXN Luxury Palette — Morado Tarot
// Editorial, nocturno, místico y limpio. Conserva lujo pero en violeta tarot.

extension Color {
    // Fondo terciopelo morado profundo — obsidiana violeta
    static var tarotBackground: Color {
        Color(red: 0.06, green: 0.04, blue: 0.13) // #0F0A22
    }
    static var tarotBackgroundElevated: Color {
        Color(red: 0.09, green: 0.06, blue: 0.18)
    }

    // Panel de vidrio ahumado — translúcido, no opaco
    static var tarotPanel: Color {
        Color.white.opacity(0.055)
    }
    static var tarotPanelStrong: Color {
        Color.white.opacity(0.08)
    }
    static var tarotCardBase: Color {
        Color(red: 0.11, green: 0.08, blue: 0.19)
    }

    // Bordes y sombras con temperatura violeta
    static var tarotBorder: Color {
        Color(red: 0.60, green: 0.52, blue: 1.0).opacity(0.13)
    }
    static var tarotBorderStrong: Color {
        Color(red: 0.60, green: 0.52, blue: 1.0).opacity(0.20)
    }
    static var tarotShadow: Color {
        Color.black.opacity(0.45)
    }
    static var tarotShadowSoft: Color {
        Color.black.opacity(0.28)
    }

    // Violeta tarot — lavanda luminoso, no neón
    static var tarotGold: Color {
        Color(red: 0.60, green: 0.52, blue: 1.0) // #9984FF lavanda tarot
    }
    static var tarotGoldHighlight: Color {
        Color(red: 0.78, green: 0.72, blue: 1.0) // #C7B8FF
    }
    static var tarotGoldDeep: Color {
        Color(red: 0.36, green: 0.28, blue: 0.78) // sombra violeta profunda
    }
    static var tarotIvory: Color {
        Color(red: 0.96, green: 0.94, blue: 0.89)
    }

    // Vino/bugundi editorial — solo acento, nunca fondo pleno
    static var tarotBurgundy: Color {
        Color(red: 0.28, green: 0.08, blue: 0.14)
    }
    static var tarotBurgundyDeep: Color {
        Color(red: 0.18, green: 0.04, blue: 0.08)
    }

    // Gradientes metálicos reutilizables
    static var tarotGoldGradient: LinearGradient {
        LinearGradient(colors: [tarotGoldHighlight, tarotGold, tarotGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var tarotGoldHorizontal: LinearGradient {
        LinearGradient(colors: [tarotGoldDeep, tarotGold, tarotGoldHighlight, tarotGold, tarotGoldDeep], startPoint: .leading, endPoint: .trailing)
    }
    static var tarotBackgroundGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 0.09, green: 0.06, blue: 0.18), Color(red: 0.05, green: 0.03, blue: 0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension CardSuit {
    var displayName: String {
        switch self {
        case .wands: return "Bastos"
        case .cups: return "Copas"
        case .swords: return "Espadas"
        case .pentacles: return "Oros"
        }
    }
}

// MARK: - Image loading

enum PlatformImageLoader {
    private static let cache = NSCache<NSString, PlatformImage>()
    static func image(named name: String) -> PlatformImage? {
        if let cached = cache.object(forKey: name as NSString) { return cached }
        let cleanName = (name as NSString).deletingPathExtension
        let candidates = ["\(cleanName)", cleanName]

        for candidate in candidates {
            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: "png") {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) {
                    cache.setObject(img, forKey: name as NSString)
                    return img
                }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) {
                    cache.setObject(img, forKey: name as NSString)
                    return img
                }
                #endif
            }

            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: nil) {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) {
                    cache.setObject(img, forKey: name as NSString)
                    return img
                }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) {
                    cache.setObject(img, forKey: name as NSString)
                    return img
                }
                #endif
            }

            #if canImport(UIKit)
            if let img = UIImage(named: candidate, in: .tarotContent, compatibleWith: nil) {
                cache.setObject(img, forKey: name as NSString)
                return img
            }
            #elseif canImport(AppKit)
            if let img = Bundle.tarotContent.image(forResource: candidate) {
                cache.setObject(img, forKey: name as NSString)
                return img
            }
            #endif
        }

        return nil
    }
}

// MARK: - PDF rendering

enum PlatformPDFRenderer {
    static func render(page: PDFPage, size: CGSize) -> PlatformImage? {
        let bounds = page.bounds(for: .mediaBox)
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        let renderSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)

        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))
            ctx.cgContext.translateBy(x: 0, y: renderSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return image
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(renderSize.width),
            pixelsHigh: Int(renderSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        guard let rep else { return nil }
        rep.size = renderSize
        NSGraphicsContext.saveGraphicsState()
        if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = ctx
            NSColor.white.setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: renderSize))
            ctx.cgContext.translateBy(x: 0, y: renderSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.flushGraphics()
        }
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: renderSize)
        image.addRepresentation(rep)
        return image
        #else
        return nil
        #endif
    }
}

// MARK: - App-level helpers

enum PlatformApp {
    static func canOpenURL(_ url: URL) -> Bool {
        #if canImport(UIKit)
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }

    static func openURL(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #endif
    }
}
