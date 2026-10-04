// Genera el icono de macOS (TarotApp/TarotMac.iconset + TarotMac.icns) a partir
// del PNG maestro de la app, aplicando la malla de macOS: el dibujo ocupa el
// 80 % del lienzo (824 de 1024) con esquinas redondeadas, y el resto queda
// transparente. Asi el icono se comporta como los demas iconos de macOS en el
// Dock y en Finder, en vez de verse como un cuadrado opaco.
//
// El PNG de iOS (Assets.xcassets/AppIcon.appiconset) NO se toca: iOS usa su
// propia malla y no lleva transparencia.
//
// Uso:  swift scripts/make-macos-icon.swift
import Foundation
import CoreGraphics
import ImageIO

let raiz = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let origen = raiz.appendingPathComponent("TarotApp/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
let destino = raiz.appendingPathComponent("TarotApp/TarotMac.iconset")

guard let fuente = CGImageSourceCreateWithURL(origen as CFURL, nil),
      let imagen = CGImageSourceCreateImageAtIndex(fuente, 0, nil) else {
    fatalError("No se pudo leer \(origen.path)")
}
try? FileManager.default.createDirectory(at: destino, withIntermediateDirectories: true)

// Proporcion de la malla de macOS (medidas de la plantilla oficial de Apple).
let cuerpo = 0.92
let radio = 0.2237  // esquina proporcional al cuerpo (proporcion de Apple)

let tamanos: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

func escribir(_ px: Int, en url: URL) {
    guard let ctx = CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("No se pudo crear el lienzo de \(px) px") }
    ctx.interpolationQuality = .high
    ctx.clear(CGRect(x: 0, y: 0, width: px, height: px))
    let lado = Double(px) * cuerpo
    let esquina = lado * radio
    let marco = CGRect(x: (Double(px) - lado) / 2, y: (Double(px) - lado) / 2, width: lado, height: lado)
    ctx.addPath(CGPath(roundedRect: marco, cornerWidth: esquina, cornerHeight: esquina, transform: nil))
    ctx.clip()
    ctx.draw(imagen, in: marco)
    // Filo interior claro: el dibujo es muy oscuro y sobre el Dock (tambien
    // oscuro) la silueta redondeada se perdia y el icono parecia un cuadrado.
    // Con este contorno la forma se lee como icono de macOS a cualquier tamano.
    let grosor = Double(px) * 0.018  // grueso suficiente para sobrevivir a la reduccion del Dock
    let interior = marco.insetBy(dx: grosor, dy: grosor)
    let rInterior = interior.width * radio
    ctx.addPath(CGPath(roundedRect: interior, cornerWidth: rInterior, cornerHeight: rInterior, transform: nil))
    ctx.setStrokeColor(CGColor(red: 0.85, green: 0.82, blue: 0.98, alpha: 0.45))
    ctx.setLineWidth(grosor * 2)
    ctx.strokePath()
    guard let salida = ctx.makeImage(),
          let fichero = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fatalError("No se pudo preparar \(url.lastPathComponent)") }
    CGImageDestinationAddImage(fichero, salida, nil)
    guard CGImageDestinationFinalize(fichero) else { fatalError("No se pudo escribir \(url.lastPathComponent)") }
}

for (nombre, px) in tamanos {
    escribir(px, en: destino.appendingPathComponent(nombre))
}
print("iconset regenerado: \(destino.path) (\(tamanos.count) tamanos)")
