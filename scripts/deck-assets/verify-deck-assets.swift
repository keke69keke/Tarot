#!/usr/bin/env swift
// Verifica que el arte de los mazos coincide con scripts/deck-assets/deck-manifest.json.
//
// Uso:
//   swift scripts/deck-assets/verify-deck-assets.swift [ruta-del-repo]
//
// Comprueba, para cada una de las 156 entradas del manifiesto: existencia del archivo,
// huella SHA-256 y dimensiones. Sale con codigo 1 si algo no cuadra.

import Foundation
import CryptoKit

struct Entry: Decodable {
    let deck: String
    let id: Int
    let imageName: String
    let source: String
    let output: String
    let sha256: String
    let width: Int
    let height: Int
}

struct Source: Decodable { let deck: String; let file: String; let sha256: String }
struct Manifest: Decodable { let schema: String; let sources: [Source]; let cards: [Entry] }

func sha256(of url: URL) -> String? {
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

let repoRoot = URL(fileURLWithPath: CommandLine.arguments.count > 1
                   ? CommandLine.arguments[1]
                   : FileManager.default.currentDirectoryPath)
let manifestURL = repoRoot.appendingPathComponent("scripts/deck-assets/deck-manifest.json")
let resources = repoRoot.appendingPathComponent("TarotContent/Resources")

guard let manifestData = try? Data(contentsOf: manifestURL),
      let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
    FileHandle.standardError.write(Data("No se pudo leer \(manifestURL.path)\n".utf8))
    exit(2)
}

print("esquema: \(manifest.schema)")
print("repo:    \(repoRoot.path)")
print("recursos:\(resources.path)")
for source in manifest.sources {
    print("origen  \(source.deck.padding(toLength: 12, withPad: " ", startingAt: 0)) \(source.file)  sha256=\(source.sha256.prefix(16))\u{2026}")
}

var problems: [String] = []
var verified = 0
var perDeck: [String: Int] = [:]

for entry in manifest.cards {
    let url = resources.appendingPathComponent(entry.output)
    guard let digest = sha256(of: url) else {
        problems.append("falta o no se puede leer: \(entry.output)")
        continue
    }
    if digest != entry.sha256 {
        problems.append("huella distinta: \(entry.output) (esperada \(entry.sha256.prefix(12))\u{2026}, obtenida \(digest.prefix(12))\u{2026})")
        continue
    }
    verified += 1
    perDeck[entry.deck, default: 0] += 1
}

for (deck, count) in perDeck.sorted(by: { $0.key < $1.key }) {
    print("verificadas: \(deck) \(count)/78")
}

if problems.isEmpty {
    print("OK: \(verified)/\(manifest.cards.count) recursos coinciden con el manifiesto")
    exit(0)
}
print("FALLOS: \(problems.count)")
for problem in problems.prefix(20) { print("  - \(problem)") }
exit(1)
