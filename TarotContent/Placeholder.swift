import Foundation

/// Localiza el bundle de recursos del contenido de tarot sin recurrir a
/// `Bundle.module`.
///
/// El accesor `Bundle.module` que genera SwiftPM termina en un
/// `Swift.fatalError` cuando no encuentra el bundle, y esa trampa no se puede
/// capturar con `try?`: al ejecutar el binario de SwiftPM o un `.app` mal
/// empaquetado, la app moría con SIGILL antes de pintar la primera vista.
///
/// Aquí la búsqueda es explícita y siempre devuelve `nil` como último recurso,
/// de modo que el llamante pueda degradar (p. ej. al bundle principal) en vez
/// de abortar el proceso.
/// Ancla de modulo.
///
/// Sirve para localizar el bundle donde vive este codigo con
/// `Bundle(for:)`: al correr `swift test` es el `.xctest` de las pruebas (que
/// tiene el bundle de recursos como hermano), y en el `.app` es el propio
/// bundle de la aplicacion. Sin ella, `Bundle.main` apunta al `xctest` de
/// Xcode y la busqueda no encuentra nada.
final class TarotContentBundleAnchor {}

enum TarotContentBundle {
    /// Nombres con los que SwiftPM y los empaquetados copian el bundle.
    private static let bundleNames = ["TarotApp_TarotContent.bundle", "TarotContent.bundle"]

    /// Candidatos de directorio, en orden de preferencia:
    ///  1. `Contents/Resources` del `.app` (ubicación estándar en macOS).
    ///  2. Raíz del `.app` (donde lo deja `scripts/make-macos-app.sh`, que además
    ///     enlaza `Contents/Resources` al mismo bundle).
    ///  3. Directorio del ejecutable (caso del binario suelto de SwiftPM, que
    ///     tiene el bundle como hermano en `.build/<triple>/<config>`).
    private static var searchDirectories: [URL] {
        let main = Bundle.main
        var dirs: [URL] = []

        // 1. Contents/Resources del propio .app
        if let resources = main.resourceURL {
            dirs.append(resources)
        }
        // 2. Raíz del .app
        dirs.append(main.bundleURL)

        // 3. Junto al ejecutable (binario suelto de SwiftPM)
        let executableDir = main.bundleURL.deletingLastPathComponent()
        if !dirs.contains(executableDir) {
            dirs.append(executableDir)
        }

        // 4. Junto al ejecutable real del proceso, por si Bundle.main apunta a otro sitio.
        if let exe = Bundle.main.executableURL?.resolvingSymlinksInPath() {
            let exeDir = exe.deletingLastPathComponent()
            if !dirs.contains(exeDir) {
                dirs.append(exeDir)
            }
        }

        // 5. Alrededor del bundle que carga este codigo. Es el caso que hacia
        //    falta para `swift test`: ahi `Bundle.main` es el `xctest` de Xcode
        //    (bajo `/usr/bin`), asi que los candidatos 1-4 caen fuera del
        //    arbol de compilacion y no ven el bundle de recursos. Se prueban
        //    el propio bundle de codigo, su directorio padre y su carpeta de
        //    recursos.
        let codeBundle = Bundle(for: TarotContentBundleAnchor.self)
        for candidato in [codeBundle.bundleURL,
                          codeBundle.bundleURL.deletingLastPathComponent(),
                          codeBundle.resourceURL] {
            if let candidato, !dirs.contains(candidato) {
                dirs.append(candidato)
            }
        }

        return dirs
    }

    /// Bundle que contiene `cards.json`, o `nil` si no se encuentra ninguno.
    ///
    /// No se limita a comprobar que el directorio exista: verifica el catálogo,
    /// porque un bundle vacío solo trasladaría el fallo más adelante.
    static func locate() -> Bundle? {
        for dir in searchDirectories {
            for name in bundleNames {
                let candidate = dir.appendingPathComponent(name)
                guard let bundle = Bundle(url: candidate) else { continue }
                if bundle.url(forResource: "cards", withExtension: "json") != nil {
                    return bundle
                }
            }
        }

        // Último recurso: el bundle principal puede llevar los recursos copiados
        // dentro (builds de Xcode que empaquetan el contenido directamente).
        if Bundle.main.url(forResource: "cards", withExtension: "json") != nil {
            return .main
        }

        return nil
    }
}

/// El bundle que contiene el catálogo de cartas y las ilustraciones.
///
/// Si no se localiza ningún bundle válido se devuelve el bundle principal: ahí
/// `BundleCardRepository` fallará con un error lanzable normal, que
/// `AppContainer` puede reportar en la pantalla de error, en lugar de un trap
/// que mata la app.
public extension Bundle {
    static let tarotContent: Bundle = TarotContentBundle.locate() ?? .main
}
