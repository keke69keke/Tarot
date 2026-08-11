import Foundation

#if os(iOS)
import PDFKit
import Vision
import UIKit
#endif

public enum EPUBExporterError: Error {
    case unsupportedPlatform
    case pdfLoadFailed
    case noPages
}

public struct EPUBExporter {
    #if os(iOS)
    // Export PDF to EPUB with optional progress callback (0.0 ... 1.0)
    public static func export(pdfURL: URL, title: String, author: String, progress: ((Double) -> Void)? = nil) async throws -> URL {
        guard let doc = PDFDocument(url: pdfURL) else { throw EPUBExporterError.pdfLoadFailed }
        let pageCount = doc.pageCount
        guard pageCount > 0 else { throw EPUBExporterError.noPages }

        // Extract text per page (with OCR fallback) and detect chapters heuristically
        var xhtmlItems: [(fileName: String, xhtml: String)] = []
        var chapters: [(title: String, href: String)] = []

        func detectChapter(in text: String) -> String? {
            let lines = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.count >= 5 }
            for line in lines {
                let letters = line.filter { $0.isLetter }
                if !letters.isEmpty && line == line.uppercased() && !line.contains("PÁGINA") && !line.contains("PAGINA") {
                    return line
                }
            }
            return nil
        }

        for index in 0..<pageCount {
            guard let page = doc.page(at: index) else { continue }
            var text = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                if let image = renderImage(from: page, scale: 2.0) {
                    text = await recognizeText(in: image)
                }
            }
            let fileName = String(format: "page-%03d.xhtml", index + 1)
            if let chapterTitle = detectChapter(in: text) {
                chapters.append((title: chapterTitle, href: fileName))
            }
            let xhtml = makeXHTML(for: text, pageIndex: index, title: title)
            xhtmlItems.append((fileName, xhtml))
            progress?(Double(index + 1) / Double(pageCount))
        }

        // Prepare common resources
        let dateStr = ISO8601DateFormatter().string(from: Date())
        let uuid = UUID().uuidString
        let mimetype = Data("application/epub+zip".utf8)
        let containerXML = makeContainerXML()
        let stylesheet = makeStylesheetCSS()

        // Build navigation (use chapter titles if detected, otherwise list pages)
        let navXHTML: String
        if chapters.isEmpty {
            navXHTML = makeNavXHTML(title: title, items: xhtmlItems.map { $0.fileName })
        } else {
            navXHTML = makeNavXHTML(title: title, items: chapters.map { $0.href }, titles: chapters.map { $0.title })
        }

        // Cover image from first page
        var coverImageData: Data? = nil
        if let first = doc.page(at: 0), let cover = renderImage(from: first, scale: 1.5) {
            coverImageData = cover.jpegData(compressionQuality: 0.9)
        }
        let coverXHTML = makeCoverXHTML(title: title)

        // Package into EPUB (ZIP)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("epub-export-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let epubURL = tempDir.appendingPathComponent(sanitizedFileName("\(title).epub"))

        let zip = ZipWriter(fileURL: epubURL)
        try zip.begin()
        // Per EPUB spec, mimetype must be first and uncompressed
        try zip.addFile(path: "mimetype", data: mimetype, compress: false)
        try zip.addFile(path: "META-INF/container.xml", data: Data(containerXML.utf8))
        try zip.addFile(path: "OEBPS/stylesheet.css", data: Data(stylesheet.utf8))
        if let coverData = coverImageData {
            try zip.addFile(path: "OEBPS/cover.jpg", data: coverData)
            try zip.addFile(path: "OEBPS/cover.xhtml", data: Data(coverXHTML.utf8))
        }
        // Build OPF now that we know which items exist
        let xhtmlNames = xhtmlItems.map { $0.fileName }
        let contentOPF = makeContentOPF(title: title, author: author, uuid: uuid, date: dateStr, pageItems: xhtmlNames, hasCover: coverImageData != nil)
        try zip.addFile(path: "OEBPS/content.opf", data: Data(contentOPF.utf8))
        try zip.addFile(path: "OEBPS/nav.xhtml", data: Data(navXHTML.utf8))
        for item in xhtmlItems {
            try zip.addFile(path: "OEBPS/\(item.fileName)", data: Data(item.xhtml.utf8))
        }
        try zip.finish()

        return epubURL
    }

    // MARK: - PDF Rendering & OCR (iOS)
    private static func renderImage(from page: PDFPage, scale: CGFloat) -> UIImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return img
    }

    private static func recognizeText(in image: UIImage) async -> String {
        guard let cgImage = image.cgImage else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLanguages = ["es-ES", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request])
            let observations = request.results ?? []
            let lines: [String] = observations.compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        } catch {
            return ""
        }
    }

    // MARK: - XHTML & OPF Builders
    private static func makeXHTML(for text: String, pageIndex: Int, title: String) -> String {
        let paragraphs = text
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { "<p>\(escapeHTML($0))</p>" }
            .joined(separator: "\n                ")
        return """
        <?xml version=\"1.0\" encoding=\"utf-8\"?>
        <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"es\" lang=\"es\">
          <head>
            <meta charset=\"utf-8\" />
            <title>\(escapeHTML(title)) – Página \(pageIndex + 1)</title>
            <link rel=\"stylesheet\" type=\"text/css\" href=\"stylesheet.css\" />
          </head>
          <body>
            <section>
                \(paragraphs)
            </section>
          </body>
        </html>
        """
    }

    private static func makeContentOPF(title: String, author: String, uuid: String, date: String, pageItems: [String], hasCover: Bool) -> String {
        var manifest = "<item id=\"nav\" href=\"nav.xhtml\" properties=\"nav\" media-type=\"application/xhtml+xml\"/>\n        <item id=\"css\" href=\"stylesheet.css\" media-type=\"text/css\"/>\n        "
        var spine = "<itemref idref=\"nav\"/>\n        "
        if hasCover {
            manifest += "<item id=\"cover-image\" href=\"cover.jpg\" properties=\"cover-image\" media-type=\"image/jpeg\"/>\n        <item id=\"cover\" href=\"cover.xhtml\" media-type=\"application/xhtml+xml\"/>\n        "
            spine = "<itemref idref=\"cover\"/>\n        " + spine
        }
        for (idx, name) in pageItems.enumerated() {
            manifest += "<item id=\"item\(idx+1)\" href=\"\(name)\" media-type=\"application/xhtml+xml\"/>\n        "
            spine += "<itemref idref=\"item\(idx+1)\"/>\n        "
        }
        return """
        <?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <package xmlns=\"http://www.idpf.org/2007/opf\" version=\"3.0\" unique-identifier=\"pub-id\">
          <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">
            <dc:identifier id=\"pub-id\">urn:uuid:\(uuid)</dc:identifier>
            <dc:title>\(escapeHTML(title))</dc:title>
            <dc:language>es</dc:language>
            <dc:creator>\(escapeHTML(author))</dc:creator>
            <dc:date>\(date)</dc:date>
          </metadata>
          <manifest>
            \(manifest)
          </manifest>
          <spine>
            \(spine)
          </spine>
        </package>
        """
    }

    private static func makeNavXHTML(title: String, items: [String], titles: [String]? = nil) -> String {
        let list: String
        if let titles = titles, titles.count == items.count {
            list = zip(items, titles).enumerated().map { idx, pair in
                let (href, t) = pair
                return "<li><a href=\"\(href)\">\(escapeHTML(t))</a></li>"
            }.joined(separator: "\n                ")
        } else {
            list = items.enumerated().map { idx, name in
                "<li><a href=\"\(name)\">Página \(idx+1)</a></li>"
            }.joined(separator: "\n                ")
        }
        return """
        <?xml version=\"1.0\" encoding=\"utf-8\"?>
        <html xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:epub=\"http://www.idpf.org/2007/ops\">
          <head>
            <meta charset=\"utf-8\" />
            <title>\(escapeHTML(title))</title>
            <link rel=\"stylesheet\" type=\"text/css\" href=\"stylesheet.css\" />
          </head>
          <body>
            <nav epub:type=\"toc\" id=\"toc\">
              <h1>\(escapeHTML(title))</h1>
              <ol>
                \(list)
              </ol>
            </nav>
          </body>
        </html>
        """
    }

    private static func makeCoverXHTML(title: String) -> String {
        return """
        <?xml version=\"1.0\" encoding=\"utf-8\"?>
        <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"es\" lang=\"es\">
          <head>
            <meta charset=\"utf-8\" />
            <title>\(escapeHTML(title)) – Portada</title>
            <link rel=\"stylesheet\" type=\"text/css\" href=\"stylesheet.css\" />
          </head>
          <body>
            <section>
              <img src=\"cover.jpg\" alt=\"Portada\" style=\"max-width: 100%; height: auto; display: block; margin: 0 auto;\" />
            </section>
          </body>
        </html>
        """
    }

    private static func makeContainerXML() -> String {
        return """
        <?xml version=\"1.0\"?>
        <container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">
          <rootfiles>
            <rootfile full-path=\"OEBPS/content.opf\" media-type=\"application/oebps-package+xml\"/>
          </rootfiles>
        </container>
        """
    }

    private static func makeStylesheetCSS() -> String {
        return """
        body { font-family: -apple-system, system-ui, \"Helvetica Neue\", Helvetica, Arial, sans-serif; line-height: 1.45; color: #111; padding: 1.1rem; }
        h1, h2, h3 { font-weight: 700; color: #222; }
        p { margin: 0 0 0.75rem 0; }
        section { max-width: 42rem; margin: 0 auto; }
        """
    }

    private static func escapeHTML(_ s: String) -> String {
        var r = s
        r = r.replacingOccurrences(of: "&", with: "&amp;")
        r = r.replacingOccurrences(of: "<", with: "&lt;")
        r = r.replacingOccurrences(of: ">", with: "&gt;")
        r = r.replacingOccurrences(of: "\"", with: "&quot;")
        r = r.replacingOccurrences(of: "'", with: "&#39;")
        return r
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return cleaned
    }
    #else
    public static func export(pdfURL: URL, title: String, author: String, progress: ((Double) -> Void)? = nil) async throws -> URL {
        throw EPUBExporterError.unsupportedPlatform
    }
    #endif
}

// MARK: - Minimal ZIP Writer (Stored entries only)
fileprivate final class ZipWriter {
    private let fileURL: URL
    private var handle: FileHandle?
    private var entries: [CentralDirectoryEntry] = []
    private var offset: UInt32 = 0

    init(fileURL: URL) { self.fileURL = fileURL }

    func begin() throws {
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        handle = try FileHandle(forWritingTo: fileURL)
        offset = 0
    }

    func addFile(path: String, data: Data, compress: Bool = true) throws {
        guard let handle = handle else { throw NSError(domain: "ZipWriter", code: -1) }
        let localHeaderOffset = offset
        let timeDate = dosDateTime(Date())
        let crc = crc32(data)
        // Always store uncompressed for simplicity and compatibility
        let method: UInt16 = 0
        let compressedData: Data = data

        // Local file header
        var header = Data()
        header.append(uint32LE(0x04034b50)) // signature
        header.append(uint16LE(20)) // version needed
        header.append(uint16LE(0)) // flags
        header.append(uint16LE(method)) // compression method
        header.append(uint16LE(timeDate.time))
        header.append(uint16LE(timeDate.date))
        header.append(uint32LE(crc))
        header.append(uint32LE(UInt32(compressedData.count)))
        header.append(uint32LE(UInt32(data.count)))
        let nameData = Data(path.utf8)
        header.append(uint16LE(UInt16(nameData.count)))
        header.append(uint16LE(0)) // extra len
        header.append(nameData)
        try handle.write(contentsOf: header)
        offset += UInt32(header.count)

        // File data
        try handle.write(contentsOf: compressedData)
        offset += UInt32(compressedData.count)

        // Track entry for central directory
        let entry = CentralDirectoryEntry(path: path,
                                          crc32: crc,
                                          compressedSize: UInt32(compressedData.count),
                                          uncompressedSize: UInt32(data.count),
                                          method: method,
                                          time: timeDate.time,
                                          date: timeDate.date,
                                          localHeaderOffset: localHeaderOffset)
        entries.append(entry)
    }

    func finish() throws {
        guard let handle = handle else { return }
        let startOfCD = offset
        // Central directory
        for e in entries {
            var cd = Data()
            cd.append(uint32LE(0x02014b50)) // signature
            cd.append(uint16LE(20)) // version made by
            cd.append(uint16LE(20)) // version needed
            cd.append(uint16LE(0)) // flags
            cd.append(uint16LE(e.method))
            cd.append(uint16LE(e.time))
            cd.append(uint16LE(e.date))
            cd.append(uint32LE(e.crc32))
            cd.append(uint32LE(e.compressedSize))
            cd.append(uint32LE(e.uncompressedSize))
            let nameData = Data(e.path.utf8)
            cd.append(uint16LE(UInt16(nameData.count)))
            cd.append(uint16LE(0)) // extra len
            cd.append(uint16LE(0)) // comment len
            cd.append(uint16LE(0)) // disk number
            cd.append(uint16LE(0)) // internal attrs
            cd.append(uint32LE(0)) // external attrs
            cd.append(uint32LE(e.localHeaderOffset))
            cd.append(nameData)
            try handle.write(contentsOf: cd)
            offset += UInt32(cd.count)
        }
        let endOfCD = offset
        let cdSize = endOfCD - startOfCD
        let cdOffset = startOfCD
        // End of central directory record
        var end = Data()
        end.append(uint32LE(0x06054b50))
        end.append(uint16LE(0)) // disk number
        end.append(uint16LE(0)) // start disk
        end.append(uint16LE(UInt16(entries.count)))
        end.append(uint16LE(UInt16(entries.count)))
        end.append(uint32LE(cdSize))
        end.append(uint32LE(cdOffset))
        end.append(uint16LE(0)) // comment len
        try handle.write(contentsOf: end)
        try handle.close()
    }

    // MARK: - Helpers
    private func uint16LE(_ v: UInt16) -> Data { withUnsafeBytes(of: v.littleEndian, { Data($0) }) }
    private func uint32LE(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian, { Data($0) }) }

    private func dosDateTime(_ date: Date) -> (time: UInt16, date: UInt16) {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        let year = UInt16(max(0, (comps.year ?? 1980) - 1980))
        let month = UInt16(comps.month ?? 1)
        let day = UInt16(comps.day ?? 1)
        let hour = UInt16(comps.hour ?? 0)
        let minute = UInt16(comps.minute ?? 0)
        let second = UInt16(comps.second ?? 0) / 2
        let time = (hour << 11) | (minute << 5) | second
        let date = (year << 9) | (month << 5) | day
        return (time, date)
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for b in data { crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(b)) & 0xFF)] }
        return crc ^ 0xFFFF_FFFF
    }

    private struct CentralDirectoryEntry {
        let path: String
        let crc32: UInt32
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let method: UInt16
        let time: UInt16
        let date: UInt16
        let localHeaderOffset: UInt32
    }

    private let crcTable: [UInt32] = {
        (0..<(256)).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
            return c
        }
    }()
}
