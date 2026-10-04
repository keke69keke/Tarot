import Foundation
import Quartz
import PDFKit
import CoreGraphics

// Uso: bookcompact <in.pdf> <out.pdf> [force]
let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let force = CommandLine.arguments.count > 3 && CommandLine.arguments[3] == "force"

let all = (QuartzFilterManager.filters(inDomains: nil) as? [QuartzFilter]) ?? []
guard let filter = all.first(where: { ((($0.properties()?["Name"] as? String) ?? "").contains("Reduce File Size")) }) else {
    print("sin filtro"); exit(2)
}
guard let src = PDFDocument(url: URL(fileURLWithPath: inPath)) else { print("no abre"); exit(1) }

var rotated = 0
for i in 0..<src.pageCount where (src.page(at: i)?.rotation ?? 0) != 0 { rotated += 1 }
if rotated > 0 && !force {
    print("SKIP\t\(inPath)\tpaginas rotadas: \(rotated)")
    exit(3)
}

// palabras de muestra para verificar que el texto sobrevive
var words: [String] = []
for i in stride(from: 0, to: src.pageCount, by: max(1, src.pageCount / 12)) {
    let text = (src.page(at: i)?.string ?? "")
    for w in text.split(separator: " ") where w.count > 7 {
        let clean = w.trimmingCharacters(in: .punctuationCharacters)
        if clean.count > 7, !words.contains(clean) { words.append(clean) }
        if words.count >= 8 { break }
    }
    if words.count >= 8 { break }
}

let data = NSMutableData()
guard let consumer = CGDataConsumer(data: data) else { exit(1) }
var box = src.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 612, height: 792)
guard let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { exit(1) }
filter.apply(to: ctx)
for i in 0..<src.pageCount {
    guard let page = src.page(at: i) else { continue }
    let b = page.bounds(for: .mediaBox)
    let info = [kCGPDFContextMediaBox: CGRect(x: 0, y: 0, width: b.width, height: b.height)] as CFDictionary
    ctx.beginPDFPage(info)
    ctx.saveGState()
    page.draw(with: .mediaBox, to: ctx)
    ctx.restoreGState()
    ctx.endPDFPage()
}
ctx.closePDF()
try? (data as Data).write(to: URL(fileURLWithPath: outPath))

guard let out = PDFDocument(url: URL(fileURLWithPath: outPath)) else { print("no reabre"); exit(1) }
let inSize = ((try? FileManager.default.attributesOfItem(atPath: inPath))?[.size] as? Int) ?? 0
let outSize = ((try? FileManager.default.attributesOfItem(atPath: outPath))?[.size] as? Int) ?? 0
var missing = 0
for w in words {
    let a = src.findString(w, withOptions: []).count
    let b = out.findString(w, withOptions: []).count
    if b < a { missing += 1 }
}
let ok = out.pageCount == src.pageCount && missing == 0 && outSize < inSize
print(String(format: "%@\t%d pag\t%.1f -> %.1f MB (%.0f%% menos)\tpalabras ok: %d/%d\t%@",
             (inPath as NSString).lastPathComponent, src.pageCount,
             Double(inSize)/1_048_576, Double(outSize)/1_048_576,
             100*(1 - Double(outSize)/Double(max(inSize,1))), words.count - missing, words.count,
             ok ? "OK" : "REVISAR"))
exit(ok ? 0 : 4)
