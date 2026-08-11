import SwiftUI
import PDFKit
import TarotCore
import TarotData

@MainActor
class BookCoverService: ObservableObject {
    @Published var coverImage: PlatformImage? = nil

    func loadCover(from url: URL, size: CGSize) {
        Task {
            if let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) {
                coverImage = PlatformPDFRenderer.render(page: page, size: size)
            }
        }
    }
}
