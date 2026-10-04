// Feature: tarot-iphone-app
// Smoke test: los audios ambientales deben existir en el bundle en alguno de los formatos que
// busca MysticAudioService (["wav", "mp3", "m4a"]).
//
// Contexto: los cinco WAV originales sumaban 15 MB dentro del bundle; se convirtieron a AAC
// (m4a, 2.7 MB) con la misma duracion exacta (30,000000 s). Este test evita que un cambio de
// nombre o de formato deje la app sin audio ambiental, y que los WAV sin comprimir vuelvan.

import XCTest
@testable import TarotCore
@testable import TarotContent

final class AmbientAudioResourcesTests: XCTestCase {

    /// Nombres de archivo de `TarotUI/AmbientTrack.swift` (AmbientTrack.allCases).
    private let trackFileNames = [
        "tarot_om", "tarot_396hz", "tarot_432hz", "tarot_528hz", "tarot_bowl"
    ]

    func testEveryAmbientTrackFileExistsInBundle() {
        let supported = ["m4a", "wav", "mp3"]
        for name in trackFileNames {
            let found = supported.first { Bundle.tarotContent.url(forResource: name, withExtension: $0) != nil }
            XCTAssertNotNil(found,
                "Falta el audio ambiental \(name) en el bundle TarotContent (se admite .m4a/.wav/.mp3)")
        }
    }

    func testAmbientAudioIsNotShippedAsUncompressedWav() {
        for name in trackFileNames {
            XCTAssertNil(Bundle.tarotContent.url(forResource: name, withExtension: "wav"),
                "\(name).wav volvio al bundle: los cinco WAV sumaban 15 MB; usar .m4a (AAC) sigue dando 2.7 MB")
        }
    }
}
