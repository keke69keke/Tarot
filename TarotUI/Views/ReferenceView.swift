import SwiftUI
import UniformTypeIdentifiers
import TarotCore
import TarotDI

/// Centro de referencia: biblioteca esotérica (PDFs), guía integrada,
/// atlas de símbolos y navegador sagrado — todo funcional.
struct ReferenceView: View {
    let container: AppContainer

    @State private var showingImporter = false
    @State private var showingBrowser = false
    @State private var importError: String?
    /// QA: `-pdf` abre la guía integrada al instante para revisar el lector.
    @State private var qaPDF: ImportedBook?
    /// QA: `-atlas` abre el Atlas de Símbolos al instante.
    @State private var qaAtlas = false

    private var library: LibraryManager { container.library }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LuxuryPage(maxWidth: 860) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        quickActions
                        integratedGuides
                        symbolsLink
                        booksSection
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Referencia")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .tarotNightBackground()
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try library.importPDF(from: url)
                    HapticManager.shared.triggerSuccess()
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .sheet(isPresented: $showingBrowser) {
            TarotWebBrowserView(libraryManager: library)
        }
        .sheet(item: $qaPDF) { book in
            PDFReaderView(book: book, libraryManager: library)
        }
        .sheet(isPresented: $qaAtlas) {
            NavigationStack { SymbolAtlasView() }
                .environmentObject(container)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-pdf"), qaPDF == nil {
                qaPDF = ImportedBook(title: "Guía Definitiva del Tarot", fileName: "rider_waite_guide.pdf")
            }
            if args.contains("-atlas"), !qaAtlas {
                qaAtlas = true
            }
        }
        .alert("No se pudo importar", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        LuxuryPageHeader(
            eyebrow: "Biblioteca sagrada",
            title: "Referencia",
            subtitle: "Libros, símbolos y fuentes para profundizar tu práctica. Todo vive aquí, siempre a mano."
        )
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionButton(icon: "doc.badge.plus", label: "Importar PDF") {
                showingImporter = true
            }
            actionButton(icon: "safari.fill", label: "Navegador") {
                showingBrowser = true
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold, design: .serif))
            }
            .foregroundStyle(Color.tarotGold)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.28), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Integrated guides

    private var integratedGuides: some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Guías integradas")
            HStack(spacing: 14) {
                guideCard(
                    title: "Guía Definitiva del Tarot",
                    subtitle: "Rider-Waite · ilustrada",
                    icon: "book.closed.fill",
                    book: ImportedBook(title: "Guía Definitiva del Tarot", fileName: "rider_waite_guide.pdf")
                )
                guideCard(
                    title: "El Tarot de Marsella",
                    subtitle: "Mensaje clásico",
                    icon: "scroll.fill",
                    book: ImportedBook(title: "El Tarot de Marsella", fileName: "El_Tarot_de_Marsella.pdf", lastReadPage: 1, totalPages: 27)
                )
            }
        }
    }

    private func guideCard(title: String, subtitle: String, icon: String, book: ImportedBook) -> some View {
        NavigationLink {
            PDFReaderView(book: book, libraryManager: library)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.tarotGoldGradient)
                        .frame(width: 52, height: 68)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.tarotBackground)
                }
                .shadow(color: Color.tarotGoldDeep.opacity(0.4), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .light, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.5))
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        Text("Leer")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .tracking(1.0)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(Color.tarotGold)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.18), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Symbols

    private var symbolsLink: some View {
        NavigationLink {
            SymbolAtlasView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color.tarotGold)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color.tarotGold.opacity(0.12)))
                    .overlay(Circle().stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Atlas de Símbolos")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Text("Enciclopedia visual de arquetipos universales")
                        .font(.system(size: 11, weight: .light, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.tarotIvory.opacity(0.35))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.18), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Esoteric books

    @ViewBuilder
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Biblioteca esotérica")
                Spacer()
                Text("\(library.importedBooks.count) obras")
                    .font(.system(size: 10.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
            }

            if library.importedBooks.isEmpty {
                LuxuryPanel(padding: 22) {
                    VStack(spacing: 10) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 26, weight: .thin))
                            .foregroundStyle(Color.tarotGold.opacity(0.6))
                        Text("Tu estantería está vacía")
                            .font(.system(size: 13.5, weight: .medium, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.tarotIvory.opacity(0.8))
                        Text("Importa tus propios PDF para construir tu biblioteca personal.")
                            .font(.system(size: 11.5, weight: .light, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 210), spacing: 14)], spacing: 14) {
                    ForEach(library.importedBooks) { book in
                        NavigationLink {
                            PDFReaderView(book: book, libraryManager: library)
                        } label: {
                            BookCoverCard(book: book)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                library.deleteBook(book)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Book cover card

private struct BookCoverCard: View {
    let book: ImportedBook

    private var initials: String {
        book.title.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.tarotGoldDeep.opacity(0.85), Color.tarotGoldDeep.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 92)
                Text(initials)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.85))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.75)
            )

            Text(book.title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.9))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            let last = book.lastReadPage
            if last > 1 {
                Label("Página \(last)", systemImage: "bookmark.fill")
                    .font(.system(size: 9.5, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.8))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.14), lineWidth: 0.7)
        )
    }
}
