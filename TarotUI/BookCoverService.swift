import SwiftUI
import PDFKit

#if canImport(UIKit)
import UIKit
typealias BookCoverPlatformImage = UIImage
#else
import AppKit
typealias BookCoverPlatformImage = NSImage
#endif

@MainActor
class BookCoverService: ObservableObject {
    @Published var coverImage: BookCoverPlatformImage? = nil

    func loadCover(from url: URL, size: CGSize) {
        Task {
            if let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) {
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
                coverImage = image
                #else
                // macOS: render the PDF page into an NSImage via a bitmap context.
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
                if let rep {
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
                    coverImage = image
                }
                #endif
            }
        }
    }
}
