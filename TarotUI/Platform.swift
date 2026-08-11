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

// MARK: - Color helpers

extension Color {
    static var tarotBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(red: 0.05, green: 0.02, blue: 0.12)
        #endif
    }

    static var tarotPanel: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.22, green: 0.10, blue: 0.34).opacity(0.16)
        #endif
    }

    static var tarotCardBase: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.20, green: 0.10, blue: 0.30)
        #endif
    }

    static var tarotBorder: Color {
        Color(red: 0.72, green: 0.55, blue: 0.95).opacity(0.28)
    }

    static var tarotShadow: Color {
        Color(red: 0.12, green: 0.02, blue: 0.28).opacity(0.30)
    }

    static var tarotGold: Color {
        Color(red: 0.78, green: 0.62, blue: 0.98)
    }

    static var tarotBurgundy: Color {
        Color(red: 0.42, green: 0.12, blue: 0.42)
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
    static func image(named name: String) -> PlatformImage? {
        let cleanName = (name as NSString).deletingPathExtension
        let candidates = ["\(cleanName)", cleanName]

        for candidate in candidates {
            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: "png") {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: nil) {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            #if canImport(UIKit)
            if let img = UIImage(named: candidate, in: .tarotContent, compatibleWith: nil) { return img }
            #elseif canImport(AppKit)
            if let img = Bundle.tarotContent.image(forResource: candidate) { return img }
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
