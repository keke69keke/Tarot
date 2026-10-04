#!/usr/bin/env swift
// Compone TarotContent/Resources/Books/El_Tarot_de_Marsella.pdf con el arte actual del mazo.
//
// Equivalente en PDFKit de scripts/make_marseille_pdf.py (que requiere PIL y reportlab, no
// instalados en este entorno). Mismo tamano A4, mismo fondo crema y mismo marco, y las mismas
// proporciones de cada imagen. Dos correcciones respecto al script original:
//   1. las miniaturas de las paginas de palo usan las cuatro figuras de corte del palo
//      (el original pedia card_112.., ids que no existen, asi que salian sin imagen);
//   2. el parrafo de simbolismo se situa debajo de la carta, no encima.
//
// Uso: swift scripts/deck-assets/build-marseille-book.swift [ruta-del-repo]

import Foundation
import CoreGraphics
import CoreText
import ImageIO

struct Card: Decodable { let id: Int; let imageName: String }
struct Catalog: Decodable { let cards: [Card] }

let repoRoot = URL(fileURLWithPath: CommandLine.arguments.count > 1
                   ? CommandLine.arguments[1]
                   : FileManager.default.currentDirectoryPath)
let resources = repoRoot.appendingPathComponent("TarotContent/Resources")
let outURL = resources.appendingPathComponent("Books/El_Tarot_de_Marsella.pdf")

let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: resources.appendingPathComponent("cards.json")))
let nameById = Dictionary(uniqueKeysWithValues: catalog.cards.map { ($0.id, $0.imageName) })

let W = 595.2756, H = 841.8898
let mediaBox = CGRect(x: 0, y: 0, width: W, height: H)
let cream = CGColor(red: 0.95, green: 0.93, blue: 0.87, alpha: 1)
let darkInk = CGColor(red: 0.12, green: 0.08, blue: 0.03, alpha: 1)
let frameInk = CGColor(red: 0.23, green: 0.15, blue: 0.06, alpha: 1)

guard let consumer = CGDataConsumer(url: outURL as CFURL),
      var box = Optional(mediaBox),
      let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else {
    FileHandle.standardError.write(Data("no se pudo crear el PDF\n".utf8)); exit(1)
}

var assetsFound = 0, assetsMissing: [String] = []

func assetURL(fragment: String) -> URL? {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: resources.path)) ?? []
    // El mazo puede estar en HEIC (ligero) o en PNG heredado; se prefiere HEIC.
    let match = names.filter { $0.hasPrefix("marseille_\(fragment)") && ($0.hasSuffix(".heic") || $0.hasSuffix(".png")) }
        .sorted { ($0.hasSuffix(".heic") ? 0 : 1, $0) < ($1.hasSuffix(".heic") ? 0 : 1, $1) }
        .first
    return match.map { resources.appendingPathComponent($0) }
}

func textLine(_ text: String, fontName: String, size: CGFloat, color: CGColor) -> CTLine {
    let font = CTFontCreateWithName(fontName as CFString, size, nil)
    let attributes: [CFString: Any] = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: color]
    let attributed = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
    return CTLineCreateWithAttributedString(attributed)
}

func drawCentered(_ text: String, fontName: String, size: CGFloat, y: CGFloat, color: CGColor) {
    let line = textLine(text, fontName: fontName, size: size, color: color)
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    ctx.textPosition = CGPoint(x: W / 2 - CGFloat(width) / 2, y: y)
    CTLineDraw(line, ctx)
}

func drawLeft(_ lines: [String], fontName: String, size: CGFloat, x: CGFloat, topY: CGFloat, leading: CGFloat, color: CGColor) {
    for (index, text) in lines.enumerated() {
        let line = textLine(text, fontName: fontName, size: size, color: color)
        ctx.textPosition = CGPoint(x: x, y: topY - CGFloat(index) * leading)
        CTLineDraw(line, ctx)
    }
}

func putImage(_ fragment: String, targetHeight: CGFloat, y: CGFloat) {
    guard let url = assetURL(fragment: fragment) else { assetsMissing.append(fragment); return }
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { assetsMissing.append(fragment); return }
    assetsFound += 1
    // Resolucion incrustada limitada a 2x el tamano de presentacion: suficiente en pantallas
    // retina y evita embeber el escaneo completo (el PDF llegaba a 20 MB sin detalle visible extra).
    let capPixels = Int((targetHeight * 2).rounded())
    var toDraw = image
    if image.height > capPixels {
        let cappedWidth = max(1, Int((CGFloat(image.width) * CGFloat(capPixels) / CGFloat(image.height)).rounded()))
        if let small = CGContext(data: nil, width: cappedWidth, height: capPixels, bitsPerComponent: 8,
                                 bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            small.interpolationQuality = .high
            small.draw(image, in: CGRect(x: 0, y: 0, width: cappedWidth, height: capPixels))
            if let out = small.makeImage() { toDraw = out }
        }
    }
    // Sin transformacion: comprobado con un marcador asimetrico que CGContext.draw sobre un
    // contexto PDF ya coloca la imagen en la misma orientacion que el archivo de origen.
    let scale = targetHeight / CGFloat(toDraw.height)
    let width = CGFloat(toDraw.width) * scale
    let rect = CGRect(x: (W - width) / 2, y: y, width: width, height: targetHeight)
    ctx.interpolationQuality = .high
    ctx.draw(toDraw, in: rect)
}

func cardFrame() {
    ctx.setFillColor(cream); ctx.fill(mediaBox)
    ctx.setStrokeColor(frameInk); ctx.setLineWidth(3)
    ctx.stroke(mediaBox.insetBy(dx: 20, dy: 20))
}

func page(_ body: () -> Void) {
    ctx.beginPDFPage(nil)
    cardFrame()
    body()
    ctx.endPDFPage()
}

let majorNames = ["El Loco", "El Mago", "La Sacerdotisa", "La Emperatriz", "El Emperador",
                  "El Papa", "Los Enamorados", "El Carro", "La Fuerza", "El Ermitaño",
                  "La Rueda de la Fortuna", "La Justicia", "El Colgado", "La Muerte",
                  "La Templanza", "El Diablo", "La Torre", "La Estrella", "La Luna",
                  "El Sol", "El Juicio", "El Mundo"]
let suits: [(title: String, ids: [Int])] = [
    ("Cups", [46, 47, 48, 49]),
    ("Wands", [32, 33, 34, 35]),
    ("Swords", [60, 61, 62, 63]),
    ("Pentacles", [74, 75, 76, 77]),
]

// Portada
page {
    drawCentered("El Tarot de Marsella", fontName: "Helvetica-Bold", size: 28, y: H - 150, color: darkInk)
    drawCentered("Curso de Estudio del Mazo Clásico", fontName: "Helvetica", size: 16, y: H - 190, color: darkInk)
    drawCentered("Arte xilográfico — Siglo XVII", fontName: "Helvetica-Oblique", size: 13, y: H - 230, color: darkInk)
    putImage("card_00", targetHeight: 220, y: H - 520)
}

// 22 arcanos mayores
for index in 0..<22 {
    page {
        putImage(String(format: "card_%02d", index), targetHeight: 290, y: H / 2 - 60)
        drawCentered("Arcano \(index): \(majorNames[index])", fontName: "Helvetica-Bold", size: 18, y: H - 80, color: darkInk)
        drawLeft(["Simbolismo escuela Marsella:", "",
                  "• Número \(index) — observa la composición geométrica.",
                  "• Color dominante: rojo y azul sobre fondo crema.",
                  "• La figura central transmite la energía del arcano.",
                  "• Estudia también boca abajo (inversión) y su contrario."],
                 fontName: "Helvetica", size: 10, x: W / 2 - 240, topY: H / 2 - 250, leading: 12, color: darkInk)
    }
}

// Un palo por pagina, con las cuatro figuras de corte
for suit in suits {
    page {
        drawCentered("Palo — \(suit.title)", fontName: "Helvetica-Bold", size: 20, y: H / 2 + 170, color: darkInk)
        drawCentered("As → 10 + 4 figuras cortes", fontName: "Helvetica", size: 12, y: H / 2 + 140, color: darkInk)
        for (k, id) in suit.ids.enumerated() {
            if let name = nameById[id] {
                putImage("card_\(String(format: "%02d", id))", targetHeight: 96, y: H / 2 + 20 - CGFloat(k * 110))
            }
        }
        drawCentered("Cada palo se mapea a un elemento y una esfera de la vida.", fontName: "Helvetica", size: 10, y: H / 2 - 400, color: darkInk)
        drawCentered("Observa cómo las formas se repiten y se combinan.", fontName: "Helvetica", size: 10, y: H / 2 - 420, color: darkInk)
    }
}

// Cierre
page {
    drawCentered("Gracias por estudiar el Tarot de Marsella.", fontName: "Helvetica-Oblique", size: 15, y: H / 2 + 60, color: darkInk)
    drawCentered("Las cartas son espejos del alma.", fontName: "Helvetica", size: 12, y: H / 2, color: darkInk)
    drawCentered("Confía en tu intuición y la sabiduría antigua.", fontName: "Helvetica", size: 12, y: H / 2 - 20, color: darkInk)
}

ctx.closePDF()
let size = ((try? FileManager.default.attributesOfItem(atPath: outURL.path))?[.size] as? Int).map { $0 } ?? 0
print("PDF escrito: \(outURL.path)")
print("imagenes incrustadas: \(assetsFound) | sin imagen: \(assetsMissing.isEmpty ? "ninguna" : assetsMissing.joined(separator: ", ")) | \(size ?? 0) bytes")
