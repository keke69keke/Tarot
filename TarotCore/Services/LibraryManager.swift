import Foundation
import Combine

public struct WebBookmark: Codable, Identifiable, Hashable {
    public let id: UUID
    public var url: String
    public var title: String
    public var isPinned: Bool
    public var dateAdded: Date
    public init(id: UUID = UUID(), url: String, title: String, isPinned: Bool = false, dateAdded: Date = Date()) {
        self.id = id; self.url = url; self.title = title; self.isPinned = isPinned; self.dateAdded = dateAdded
    }
}

@MainActor
public class LibraryManager: ObservableObject {
    @Published public private(set) var importedBooks: [ImportedBook] = []
    @Published public private(set) var bookmarks: [WebBookmark] = []

    private let userDefaultsKey = "TarotLibrary_ImportedBooks"
    private let bookmarksKey = "TarotLibrary_WebBookmarks"
    /// Minimum size (in bytes) a PDF must be to be considered a real, non-stub file.
    private let minimumRealPDFSize: Int = 5_000

    public init() {
        loadBooks()
        loadBookmarks()
        preloadBundledBooksIfNeeded()
    }

    public var pinnedBookmarks: [WebBookmark] { bookmarks.filter { $0.isPinned }.sorted { $0.dateAdded > $1.dateAdded } }

    public func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let libraryFolder = documentsDirectory.appendingPathComponent("TarotLibrary", isDirectory: true)

        if !FileManager.default.fileExists(atPath: libraryFolder.path) {
            try? FileManager.default.createDirectory(at: libraryFolder, withIntermediateDirectories: true, attributes: nil)
        }

        return libraryFolder
    }

    public func importPDF(from url: URL) throws {
        // Access security scoped resource if coming from document picker
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let libraryFolder = getDocumentsDirectory()
        let fileName = url.lastPathComponent
        let destinationURL = libraryFolder.appendingPathComponent(fileName)

        // If file already exists, check if it's a valid (non-stub) size.
        // If it's too small, remove it and re-copy the real version from bundle.
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
            if existingSize >= minimumRealPDFSize {
                // File is already good, just ensure record exists
                if !importedBooks.contains(where: { $0.fileName == fileName }) {
                    addBookRecord(title: titleFromFileName(url.lastPathComponent), fileName: fileName)
                }
                return
            }
            // Stub file found – delete and re-copy
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: url, to: destinationURL)

        // Remove stale record if present (from stub era)
        importedBooks.removeAll { $0.fileName == fileName }
        addBookRecord(title: titleFromFileName(url.lastPathComponent), fileName: fileName)
    }

    /// Converts a raw file name (with broken UTF-8 and separators) into a clean,
    /// human-readable display title.
    ///
    /// The bundled PDFs were originally named with accented characters that got
    /// stripped to ASCII (e.g. `Brujer-a` → `Brujería`, `aproximaci-n` →
    /// `aproximación`). This method restores those accents and formats the title
    /// nicely (title case, no leading numbers/dashes, etc.).
    ///
    /// - Parameter fileName: The raw file name (e.g. `02.-Brujer-a-en-la-Edad-Moderna.pdf`).
    /// - Returns: A clean display title (e.g. `Brujería en la Edad Moderna`).
    private func titleFromFileName(_ fileName: String) -> String {
        let baseName = (fileName as NSString).deletingPathExtension

        // 1) Exact known mapping for the 42 preloaded books (most reliable).
        if let mapped = Self.preloadedBookTitles[baseName] {
            return mapped
        }

        // 2) Fallback heuristic for arbitrary imported files.
        var cleaned = baseName

        // Strip leading numbers/dashes: "02.-", "1.-", "04.-", "13.-" etc.
        cleaned = cleaned.replacingOccurrences(
            of: #"^\s*\d+\.?-?\s*"#,
            with: "",
            options: .regularExpression
        )

        // Replace separators with spaces.
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")
        cleaned = cleaned.replacingOccurrences(of: ".", with: " ")

        // Restore common broken accents (X-a → Xía, X-n → Xón, X-c → Xíc, etc.).
        let accentMap: [(String, String)] = [
            ("Brujer", "Brujer"),
            ("aproximaci", "aproximaci"),
            ("Introducci", "Introducci"),
            ("Presentaci", "Presentaci"),
            ("Combinaci", "Combinaci"),
            ("Sanaci", "Sanaci"),
            ("acumulacion", "acumulaci"),
            ("explicacion", "explicaci"),
            ("Simbolog", "Simbolog"),
            ("Clav", "Clav"),
            ("Salom", "Salom"),
            ("Avenda", "Avenda"),
            ("V-ctor", "Víctor"),
            ("l-gica", "lógica"),
            ("m-gicos", "mágicos"),
            ("B-sicos", "Básicos"),
            ("b-o-t-a", "B.O.T.A.")
        ]
        for (broken, fixed) in accentMap {
            cleaned = cleaned.replacingOccurrences(of: broken, with: fixed)
        }
        // Generic accent restoration for the common `-a`/`-n` broken patterns.
        cleaned = cleaned
            .replacingOccurrences(of: #"([aeiou])-([aeiou])"#, with: "$1í$2", options: .regularExpression)
            .replacingOccurrences(of: #"-n\b"#, with: "ón", options: .regularExpression)
            .replacingOccurrences(of: #"-a\b"#, with: "ía", options: .regularExpression)

        // Collapse multiple spaces and trim.
        cleaned = cleaned.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Title case (capitalize first letter of each word, lowercase the rest).
        let words = cleaned.split(separator: " ").map { word -> String in
            let lower = word.lowercased()
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }
        return words.joined(separator: " ").isEmpty ? baseName : words.joined(separator: " ")
    }

    /// Mapping from the exact bundled resource base-name to a clean, human-readable
    /// display title. This guarantees properly formatted titles for the 42 books.
    private static let preloadedBookTitles: [String: String] = [
        "02.-Brujer-a-en-la-Edad-Moderna.-Una-aproximaci-n-autor-V-ctor-Jos-Ortega-Mu-oz": "Brujería en la Edad Moderna — Una Aproximación (Víctor José Ortega Muñoz)",
        "02.-Libro-XLII-Ejercicios-m-gicos-Autor-Libro-esot-rico": "Libro XLII — Ejercicios Mágicos (Libro Esotérico)",
        "04.-Clav-culas-de-Salom-n-Autor-Salom-n": "Clavículas de Salomón (Salomón)",
        "05.-La-magia-de-Arbatel-Autor-Cornelius-Agrippa": "La Magia de Arbatel (Cornelius Agrippa)",
        "09.-La-l-gica-de-la-ciencia-y-de-la-brujer-a-africanas-autor-Max-Gluckman": "La Lógica de la Ciencia y de la Brujería Africanas (Max Gluckman)",
        "1.-El-tarot-de-los-bohemios-autor-Papus": "El Tarot de los Bohemios (Papus)",
        "11.-Introducci-n-al-Tarot.-Arcanos-Menores-Presentaci-n-autor-Academia-Kinexia": "Introducción al Tarot — Arcanos Menores (Academia Kinexia)",
        "13.-Tarot.-Las-tiradas-del-Tarot-autor-Educate": "Tarot — Las Tiradas del Tarot (Educate)",
        "4.-Tarot.-Arcanos-Mayores-autor-Educate": "Tarot — Arcanos Mayores (Educate)",
        "5.-El-Simbolismo-del-Tarot-autor-P.D.-Ouspensky": "El Simbolismo del Tarot (P.D. Ouspensky)",
        "9.-Simbolog-a-del-ojo-y-la-mirada-en-el-Tarot-Presentaci-n-autor-Jos-Luis-Cotallo": "Simbología del Ojo y la Mirada en el Tarot (José Luis Cotallo)",
        "Combinaci-n-entre-los-Arcanos-Mayores-Educate": "Combinación entre los Arcanos Mayores (Educate)",
        "Conceptos-B-sicos-de-Tarot-Evelyne-y-Terry-Donaldson": "Conceptos Básicos de Tarot (Evelyne y Terry Donaldson)",
        "Curso-Tarot-Completo-Hija-de-Marte": "Curso de Tarot Completo (Hija de Marte)",
        "Curso-de-Tarot-Tarot-de-los-Hechizos": "Curso de Tarot — Tarot de los Hechizos",
        "El-Tarot-Santiago-Bovisio": "El Tarot (Santiago Bovisio)",
        "El-manual-del-tarotista-principiante-Autores-Varios": "El Manual del Tarotista Principiante (Autores Varios)",
        "Gu-a-para-aprender-Tarot-Chantico": "Guía para Aprender Tarot (Chantico)",
"Hechiceras-Brujas-Chamanas-y-Sanadoras-Las-Mujeres-y-sus-Caminos-de-Sanaci-n-Agua-y-Vida": "Hechiceras, Brujas, Chamanas y Sanadoras — Las Mujeres y sus Caminos de Sanación (Agua y Vida)",
        "Mi-Tarot-Carolina-Lastra-Avenda-o": "Mi Tarot (Carolina Lastra Avendaño)",
        "brujas-caza-de-brujas-y-mujeres-silvia-federici-11131": "Brujas — Caza de Brujas y Mujeres (Silvia Federici)",
        "caliban-y-la-bruja-mujeres-cuerpo-y-acumulacion-originaria-silvia-federici-11130": "Calibán y la Bruja — Mujeres, Cuerpo y Acumulación Originaria (Silvia Federici)",
        "el-libro-de-san-cipriano-jonas-sufurino-17341": "El Libro de San Cipriano (Jonás Sufurino)",
        "el-libro-negro-o-la-magia-alberto-el-grande-17343": "El Libro Negro o la Magia (Alberto el Grande)",
        "el-tarot-de-marsella-restaurado-alejandro-jodorowsky-4502": "El Tarot de Marsella Restaurado (Alejandro Jodorowsky)",
        "fundamentos-del-tarot-b-o-t-a-4498": "Fundamentos del Tarot (B.O.T.A.)",
        "guia-practica-del-tarot-fernanda-nosenzo-spagnolo-4500": "Guía Práctica del Tarot (Fernanda Nosenzo Spagnolo)",
        "historia-de-la-brujeria-francesc-lluis-cardona-11132": "Historia de la Brujería (Francesc Lluís Cardona)",
        "historia-del-satanismo-y-la-brujeria-jules-michelet": "Historia del Satanismo y la Brujería (Jules Michelet)",
        "la-bruja-y-la-embrujada-un-caso-de-brujeria-en-bogota-mario-h-carvajal-martinez-17339": "La Bruja y la Embrujada — Un Caso de Brujería en Bogotá (Mario H. Carvajal Martínez)",
        "la-clavicula-de-salomon-eduardo-a-kerr-17342": "La Clavícula de Salomón (Eduardo A. Kerr)",
        "la-magia-en-el-satanismo-moderno-religioso-miguel-pastor-perez-minayo": "La Magia en el Satanismo Moderno Religioso (Miguel Pastor Pérez Minayo)",
        "magia-blanca-y-magia-negra-franz-hartmann": "Magia Blanca y Magia Negra (Franz Hartmann)",
        "magia-un-tratado-sobre-ocultismo-natural-manly-palmer-hall": "Magia — Un Tratado sobre Ocultismo Natural (Manly Palmer Hall)",
        "mal-de-ojo-y-otras-hechicerias-margarita-paz-torres-17340": "Mal de Ojo y Otras Hechicerías (Margarita Paz Torres)",
        "manual-del-hechicero-explicacion-de-espiritismo-magia-y-ritos-ivan-trujillo-gonzalez-11129": "Manual del Hechicero — Explicación de Espiritismo, Magia y Ritos (Iván Trujillo González)",
        "manual-practico-de-magia-ritual-dolores-ashcroft-nowicki-11128": "Manual Práctico de Magia Ritual (Dolores Ashcroft-Nowicki)",
        "significados-psicologicos-de-los-arcanos-mayores-arcoiris-holistica-4501": "Significados Psicológicos de los Arcanos Mayores (Arcoíris Holística)",
"tarot-de-marsella-curso-basico-nivel-i-autores-varios-4504": "Tarot de Marsella — Curso Básico Nivel I (Autores Varios)",
        "tarot-egipcio-ernesto-marquez-4499": "Tarot Egipcio (Ernesto Márquez)",
        "wicca-guia-para-el-practicante-solitario-scott-cunningham-11127": "Wicca — Guía para el Practicante Solitario (Scott Cunningham)",

        "La_Clave_Ilustrada_del_Tarot": "La Clave Ilustrada del Tarot (A.E. Waite)",
        "Guia_Tiradas_Avanzadas": "Guía de Tiradas Avanzadas y Simbología",
        "Tarot_de_los_Bohemios_Papus": "El Tarot de los Bohemios (Papus)",
        "Libro_de_Thoth_y_Alquimia": "El Libro de Thoth y Simbología Alquímica (Crowley)",
        "Astrologia_y_Decanatos_Zodiacales": "Guía de Astrología y Decanatos Zodiacales",
        "Simbologia_Arcanos_Menores": "Simbología Secreta de los Arcanos Menores",
        "Arbol_de_la_Vida_y_Cabala": "El Árbol de la Vida y la Cábala del Tarot",
        "Manual_Tiradas_de_Amor": "Manual Práctico de Tiradas de Amor y Relaciones",
        "Tarot_e_Intuicion_Psiquica": "Tarot e Intuición Psíquica y Canalización",
        "El_Tarot_de_Marsella": "El Tarot de Marsella",
        "Numerologia_y_Destino": "Numerología y Destino",
        "Runas_y_Or_da_culos": "Runas y Oráculos",
        "I_Ching_sabiduria_antigua": "I Ching: Sabiduría Antigua",
        "Alquimia_avanzada": "Alquimia Avanzada",
        "Meditacion_y_Espiritualidad": "Meditación y Espiritualidad",
        "Astrologia_clasica": "Astrología Clásica",
        "Historia_del_Tarot": "Historia del Tarot",
        "Cabala_practica": "Cábala Práctica",
        "Tarot_y_Arquetipos_Junguianos": "Tarot y Arquetipos Junguianos",
        "Simbolos_Sagrados": "Símbolos Sagrados",
        "El_Zodiaco_y_tus_Relaciones": "El Zodíaco y tus Relaciones",
        "Magia_Ceremonial_basica": "Magia Ceremonial Básica",
        "Sue_nos_y_Pl_anico": "Sueños y Plano Astral",
        "Oracle_de_las_Estrellas": "El Oráculo de las Estrellas"
    ]

    private func addBookRecord(title: String, fileName: String) {
        let newBook = ImportedBook(title: title, fileName: fileName)
        importedBooks.append(newBook)
        saveBooks()
    }

        public func deleteBook(_ book: ImportedBook) {
        importedBooks.removeAll { $0.id == book.id }
        let libraryFolder = getDocumentsDirectory()
        let fileURL = libraryFolder.appendingPathComponent(book.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        saveBooks()
    }

    /// Persists the last-read page for a book so the next session resumes here.
    public func updateReadingProgress(for book: ImportedBook, to page: Int) {
        if let idx = importedBooks.firstIndex(of: book) {
            importedBooks[idx].lastReadPage = page
            saveBooks()
        }
    }


    public func getFileURL(for book: ImportedBook) -> URL {
        let documentsURL = getDocumentsDirectory().appendingPathComponent(book.fileName)
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            return documentsURL
        }

        // If not found in Documents, attempt to locate the PDF directly inside available bundles
        for b in availableSearchBundles() {
            let resourceName = (book.fileName as NSString).deletingPathExtension
            if let url = b.url(forResource: resourceName, withExtension: "pdf") {
                return url
            }
            if let url = b.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Books") {
                return url
            }
            if let url = b.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Resources/Books") {
                return url
            }
        }

        return documentsURL
    }

    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let books = try? JSONDecoder().decode([ImportedBook].self, from: data) {
            self.importedBooks = books
        }
    }

    private func saveBooks() {
        if let data = try? JSONEncoder().encode(importedBooks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - Web Bookmarks (navegador)

    public func addBookmark(url: String, title: String) {
        let cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty, !bookmarks.contains(where: { $0.url == cleanURL }) else { return }
        let bm = WebBookmark(url: cleanURL, title: title.isEmpty ? cleanURL : title)
        bookmarks.append(bm); saveBookmarks()
    }

    public func togglePin(_ bookmark: WebBookmark) {
        guard let idx = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
        bookmarks[idx].isPinned.toggle(); saveBookmarks()
    }

    public func togglePin(url: String) {
        if let idx = bookmarks.firstIndex(where: { $0.url == url }) {
            bookmarks[idx].isPinned.toggle()
        } else {
            let bm = WebBookmark(url: url, title: url, isPinned: true)
            bookmarks.append(bm)
        }
        saveBookmarks()
    }

    public func isPinned(url: String) -> Bool { bookmarks.first(where: { $0.url == url })?.isPinned ?? false }

    public func removeBookmark(_ bookmark: WebBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }; saveBookmarks()
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let bms = try? JSONDecoder().decode([WebBookmark].self, from: data) {
            self.bookmarks = bms
        }
    }

    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarksKey)
        }
    }

// MARK: - Preload Bundled Books

private func preloadBundledBooksIfNeeded() {
        let preloadedBookNames = [
            "02.-Brujer-a-en-la-Edad-Moderna.-Una-aproximaci-n-autor-V-ctor-Jos-Ortega-Mu-oz",
            "02.-Libro-XLII-Ejercicios-m-gicos-Autor-Libro-esot-rico",
            "04.-Clav-culas-de-Salom-n-Autor-Salom-n",
            "05.-La-magia-de-Arbatel-Autor-Cornelius-Agrippa",
            "09.-La-l-gica-de-la-ciencia-y-de-la-brujer-a-africanas-autor-Max-Gluckman",
            "1.-El-tarot-de-los-bohemios-autor-Papus",
            "11.-Introducci-n-al-Tarot.-Arcanos-Menores-Presentaci-n-autor-Academia-Kinexia",
            "13.-Tarot.-Las-tiradas-del-Tarot-autor-Educate",
            "4.-Tarot.-Arcanos-Mayores-autor-Educate",
            "5.-El-Simbolismo-del-Tarot-autor-P.D.-Ouspensky",
            "9.-Simbolog-a-del-ojo-y-la-mirada-en-el-Tarot-Presentaci-n-autor-Jos-Luis-Cotallo",
            "Combinaci-n-entre-los-Arcanos-Mayores-Educate",
            "Conceptos-B-sicos-de-Tarot-Evelyne-y-Terry-Donaldson",
            "Curso-Tarot-Completo-Hija-de-Marte",
            "Curso-de-Tarot-Tarot-de-los-Hechizos",
            "El-Tarot-Santiago-Bovisio",
            "El-manual-del-tarotista-principiante-Autores-Varios",
            "Gu-a-para-aprender-Tarot-Chantico",
"Hechiceras-Brujas-Chamanas-y-Sanadoras-Las-Mujeres-y-sus-Caminos-de-Sanaci-n-Agua-y-Vida",
            "Mi-Tarot-Carolina-Lastra-Avenda-o",
            "brujas-caza-de-brujas-y-mujeres-silvia-federici-11131",
            "caliban-y-la-bruja-mujeres-cuerpo-y-acumulacion-originaria-silvia-federici-11130",
            "el-libro-de-san-cipriano-jonas-sufurino-17341",
            "el-libro-negro-o-la-magia-alberto-el-grande-17343",
            "el-tarot-de-marsella-restaurado-alejandro-jodorowsky-4502",
            "fundamentos-del-tarot-b-o-t-a-4498",
            "guia-practica-del-tarot-fernanda-nosenzo-spagnolo-4500",
            "historia-de-la-brujeria-francesc-lluis-cardona-11132",
            "historia-del-satanismo-y-la-brujeria-jules-michelet",
            "la-bruja-y-la-embrujada-un-caso-de-brujeria-en-bogota-mario-h-carvajal-martinez-17339",
            "la-clavicula-de-salomon-eduardo-a-kerr-17342",
            "la-magia-en-el-satanismo-moderno-religioso-miguel-pastor-perez-minayo",
            "magia-blanca-y-magia-negra-franz-hartmann",
            "magia-un-tratado-sobre-ocultismo-natural-manly-palmer-hall",
            "mal-de-ojo-y-otras-hechicerias-margarita-paz-torres-17340",
            "manual-del-hechicero-explicacion-de-espiritismo-magia-y-ritos-ivan-trujillo-gonzalez-11129",
            "manual-practico-de-magia-ritual-dolores-ashcroft-nowicki-11128",
            "significados-psicologicos-de-los-arcanos-mayores-arcoiris-holistica-4501",
"tarot-de-marsella-curso-basico-nivel-i-autores-varios-4504",
            "tarot-egipcio-ernesto-marquez-4499",
            "wicca-guia-para-el-practicante-solitario-scott-cunningham-11127",

            // Nuevos libros generados con create_pdf.py
            "La_Clave_Ilustrada_del_Tarot",
            "Guia_Tiradas_Avanzadas",
            "Tarot_de_los_Bohemios_Papus",
            "Libro_de_Thoth_y_Alquimia",
            "Astrologia_y_Decanatos_Zodiacales",
            "Simbologia_Arcanos_Menores",
            "Arbol_de_la_Vida_y_Cabala",
            "Manual_Tiradas_de_Amor",
            "Tarot_e_Intuicion_Psiquica",
            "El_Tarot_de_Marsella",
            "Numerologia_y_Destino",
            "Runas_y_Or_da_culos",
            "I_Ching_sabiduria_antigua",
            "Alquimia_avanzada",
            "Meditacion_y_Espiritualidad",
            "Astrologia_clasica",
            "Historia_del_Tarot",
            "Cabala_practica",
            "Tarot_y_Arquetipos_Junguianos",
            "Simbolos_Sagrados",
            "El_Zodiaco_y_tus_Relaciones",
            "Magia_Ceremonial_basica",
            "Sue_nos_y_Pl_anico",
            "Oracle_de_las_Estrellas"
        ]

        let searchBundles = availableSearchBundles()

        for name in preloadedBookNames {
            let fileName = "\(name).pdf"
            let destinationURL = getDocumentsDirectory().appendingPathComponent(fileName)

            // Check if destination already exists AND is a real (non-stub) file
            var destinationExistsAndGood = false
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
                if existingSize >= minimumRealPDFSize {
                    // Tentatively good — but we may still want to replace if bundle has a larger, richer file
                    destinationExistsAndGood = true
                } else {
                    // Stub file – remove so we can decide to copy a better bundle version
                    try? FileManager.default.removeItem(at: destinationURL)
                    importedBooks.removeAll { $0.fileName == fileName }
                }
            }

            // Find the PDF in any available bundle
            var foundURL: URL?
            for b in searchBundles {
                if let url = b.url(forResource: name, withExtension: "pdf") {
                    foundURL = url; break
                }
                if let url = b.url(forResource: name, withExtension: "pdf", subdirectory: "Books") {
                    foundURL = url; break
                }
                if let url = b.url(forResource: name, withExtension: "pdf", subdirectory: "Resources/Books") {
                    foundURL = url; break
                }
            }

            if let sourceURL = foundURL {
                // Verify source is real (not a stub)
                let sourceSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? Int) ?? 0
                if sourceSize >= minimumRealPDFSize {
                    // If Documents contains a smaller file than the bundle, prefer replacing it.
                    if destinationExistsAndGood {
                        let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
                        if existingSize < sourceSize {
                            try? FileManager.default.removeItem(at: destinationURL)
                            // Copy the richer bundle PDF to Documents so user can annotate/copy
                            try? FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        }
                        // Ensure record exists
                        if !importedBooks.contains(where: { $0.fileName == fileName }) {
                            addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                        }
                    } else {
                        // Prefer to keep preloaded books in the bundle and reference them directly
                        if !importedBooks.contains(where: { $0.fileName == fileName }) {
                            addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                        }
                    }
                } else {
                    // Source is also a stub — add as bundle-reference record so it appears in UI
                    if !importedBooks.contains(where: { $0.fileName == fileName }) {
                        addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                    }
                }
            } else {
                // Book not found in bundle — add record anyway so UI shows it (opens stub)
                if !importedBooks.contains(where: { $0.fileName == fileName }) {
                    addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                }
            }
        }
    }

private func availableSearchBundles() -> [Bundle] {
        var bundles: [Bundle] = [Bundle.main, Bundle(for: LibraryManager.self)]

        // 1) The canonical, most reliable reference: the TarotContent bundle's own
        //    Bundle.module (defined in TarotContent/Placeholder.swift). Prefer it first.
        let canonical = Bundle(identifier: "tarot.TarotContent.resources")
            ?? Bundle(identifier: "com.tarot.TarotContent")
            ?? Bundle(path: Bundle.main.bundlePath + "/TarotContent.bundle")
            ?? Bundle(path: Bundle.main.bundlePath + "/TarotApp_TarotContent.bundle")
        if let c = canonical, !bundles.contains(where: { $0.bundleURL == c.bundleURL }) {
            bundles.append(c)
        }

        // 2) Scan all already-loaded bundles for any whose identifier or path
        //    contains "TarotContent" (robust against naming changes).
        for b in Bundle.allBundles {
            let id = b.bundleIdentifier ?? ""
            let path = b.bundlePath
            guard id.contains("TarotContent") || path.contains("TarotContent") else { continue }
            if !bundles.contains(where: { $0.bundleURL == b.bundleURL }) {
                bundles.append(b)
            }
        }

        // 3) Fallback: look for the bundle by its known file names on disk.
        let candidates = [
            "TarotApp_TarotContent.bundle",
            "TarotContent.bundle"
        ]
        for name in candidates {
            guard let url = Bundle.main.url(forResource: name, withExtension: nil) else { continue }
            if let b = Bundle(url: url), !bundles.contains(where: { $0.bundleURL == b.bundleURL }) {
                bundles.append(b)
            }
        }

        return bundles
    }
}
