import SwiftUI
import PDFKit
import TarotCore

/// Visor de PDF editorial: chrome mínimo que se auto-oculta, PDF a pantalla
/// completa, progreso persistente y búsqueda funcional dentro del documento.
struct PDFReaderView: View {
    let book: ImportedBook
    let libraryManager: LibraryManager

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0
    @State private var pdfDocument: PDFDocument?
    @State private var documentURL: URL?

    // Chrome (barra superior + controles inferiores)
    @State private var chromeVisible = true

    // Búsqueda
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var highlightQuery = ""
    @State private var matches: [PDFSearchMatch] = []
    @FocusState private var searchFocused: Bool

    // Share
    @State private var showShare = false

    // Persistencia de progreso (debounce)
    @State private var lastPersistedPage = 0
    @State private var persistTask: Task<Void, Never>?

    struct PDFSearchMatch: Identifiable, Hashable {
        let id = UUID()
        let pageIndex: Int
        let snippet: String
        var pageNumber: Int { pageIndex + 1 }
    }

    var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()

            pdfContent
                .ignoresSafeArea()
                .onTapGesture { toggleChrome() }

            chrome
        }
        .navigationBarBackButtonHidden(true)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .statusBarHidden(!chromeVisible)
        #endif
        .onAppear(perform: loadPDF)
        .onDisappear(perform: persistProgressNow)
        .onChange(of: currentPage) { page in schedulePersist(page) }
        .sheet(isPresented: $showShare) { shareSheet }
    }

    // MARK: - Chrome

    private var chrome: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            if showSearch { searchPanel }
            bottomBar
        }
        .opacity(chromeVisible ? 1 : 0)
        .allowsHitTesting(chromeVisible)
        .animation(.easeInOut(duration: 0.22), value: chromeVisible)
        .animation(.easeInOut(duration: 0.22), value: showSearch)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            chromeButton(icon: "chevron.left", label: "Volver") { dismiss() }

            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(totalPages > 0 ? "Página \(currentPage) de \(totalPages)" : "Documento")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.9))
            }

            Spacer(minLength: 0)

            chromeButton(icon: showSearch ? "xmark" : "magnifyingglass", label: "Buscar") {
                withAnimation { showSearch.toggle() }
                if showSearch {
                    searchFocused = true
                } else {
                    searchText = ""
                    matches = []
                    highlightQuery = ""
                }
            }

            chromeButton(icon: "square.and.arrow.up", label: "Compartir") { showShare = true }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.tarotBorder.opacity(0.45))
                .frame(height: 0.5)
        }
    }

    private func chromeButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { action(); HapticManager.shared.triggerLight() }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.tarotGold)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if totalPages > 0 {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // El Slider solo es preciso en libros cortos: con 400 paginas cuesta
                    // clavar la pagina contigua, y estos dos botones la dan de un toque.
                    chromeButton(icon: "chevron.left", label: "Pagina anterior") {
                        currentPage = max(1, currentPage - 1)
                    }
                    .opacity(currentPage <= 1 ? 0.35 : 1)
                    .disabled(currentPage <= 1)

                    Text("\(currentPage)")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .trailing)

                    Slider(
                        value: Binding(
                            get: { Double(currentPage) },
                            set: { currentPage = Int($0.rounded()) }
                        ),
                        in: 1.0...Double(max(totalPages, 1)),
                        step: 1
                    )
                    .tint(Color.tarotGold)

                    Text("\(totalPages)")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.55))
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .leading)

                    chromeButton(icon: "chevron.right", label: "Pagina siguiente") {
                        currentPage = min(totalPages, currentPage + 1)
                    }
                    .opacity(currentPage >= totalPages ? 0.35 : 1)
                    .disabled(currentPage >= totalPages)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: 560)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.6))
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Búsqueda

    @ViewBuilder
    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tarotGold)
                TextField("Buscar en el documento", text: $searchText)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit(performSearch)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""; matches = []; highlightQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.tarotIvory.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))

            if !matches.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(matches) { match in
                            Button {
                                currentPage = match.pageNumber
                                highlightQuery = searchText
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    Text("p.\(match.pageNumber)")
                                        .font(.system(size: 10, weight: .bold, design: .serif))
                                        .foregroundStyle(Color.tarotGold)
                                        .frame(minWidth: 34, alignment: .leading)
                                    Text(match.snippet)
                                        .font(.system(size: 11.5, design: .serif))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.78))
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Color.tarotGold.opacity(0.12))
                        }
                    }
                }
                .frame(maxHeight: 220)
            } else if !searchText.isEmpty {
                Text("Sin coincidencias")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.45))
            }
        }
        .padding(14)
        .frame(maxWidth: 560)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tarotBorder.opacity(0.5), lineWidth: 0.6))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func performSearch() {
        guard let doc = pdfDocument else { return }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { matches = []; return }

        let found = doc.findString(query, withOptions: [.caseInsensitive, .diacriticInsensitive])
        matches = found.prefix(40).compactMap { selection in
            guard let page = selection.pages.first else { return nil }
            let index = doc.index(for: page)
            let snippet = selection.string?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
            return PDFSearchMatch(pageIndex: index, snippet: snippet ?? query)
        }
        highlightQuery = query
        if let first = matches.first { currentPage = first.pageNumber }
        HapticManager.shared.triggerSelection()
    }

    // MARK: - PDF

    @ViewBuilder
    private var pdfContent: some View {
        #if os(iOS)
        PDFKitView(
            document: pdfDocument,
            currentPage: $currentPage,
            totalPages: $totalPages,
            highlightQuery: highlightQuery
        )
        #else
        PDFKitViewMac(
            document: pdfDocument,
            currentPage: $currentPage,
            totalPages: $totalPages,
            highlightQuery: highlightQuery
        )
        #endif
    }

    @ViewBuilder
    private var shareSheet: some View {
        if let url = documentURL {
            #if os(iOS)
            ActivityView(activityItems: [url], applicationActivities: nil)
            #else
            ShareSheetMac(items: [url])
                .frame(width: 1, height: 1)
            #endif
        }
    }

    // MARK: - Estado

    private func toggleChrome() {
        withAnimation(.easeInOut(duration: 0.22)) {
            chromeVisible.toggle()
            if !chromeVisible { showSearch = false; searchFocused = false }
        }
    }

    private func loadPDF() {
        let url = libraryManager.getFileURL(for: book)
        documentURL = url
        if let document = PDFDocument(url: url) {
            pdfDocument = document
            totalPages = document.pageCount
            currentPage = max(1, min(book.lastReadPage, max(document.pageCount, 1)))
            lastPersistedPage = currentPage
        }
    }

    /// Guarda la página actual (con debounce) para reanudar la lectura después.
    private func schedulePersist(_ page: Int) {
        guard page != lastPersistedPage, page > 0 else { return }
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            lastPersistedPage = page
            libraryManager.updateReadingProgress(for: book, to: page)
        }
    }

    private func persistProgressNow() {
        persistTask?.cancel()
        persistTask = nil
        guard currentPage > 0, currentPage != lastPersistedPage else { return }
        lastPersistedPage = currentPage
        libraryManager.updateReadingProgress(for: book, to: currentPage)
    }
}

// MARK: - iOS representable

#if os(iOS)
import UIKit

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let highlightQuery: String

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.backgroundColor = UIColor(Color.tarotBackground)
        view.document = document
        if let doc = document {
            DispatchQueue.main.async { totalPages = doc.pageCount }
        }
        context.coordinator.observe(view: view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let doc = document, uiView.document !== doc {
            uiView.document = doc
            DispatchQueue.main.async { totalPages = doc.pageCount }
            context.coordinator.observe(view: uiView)
        }

        if let doc = document, doc.pageCount > 0 {
            let index = min(max(currentPage - 1, 0), doc.pageCount - 1)
            if let page = doc.page(at: index), uiView.currentPage != page {
                uiView.go(to: page)
            }
            if totalPages != doc.pageCount {
                DispatchQueue.main.async { totalPages = doc.pageCount }
            }
            context.coordinator.applyHighlight(query: highlightQuery, in: uiView, document: doc)
        }
    }

    func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(currentPage: $currentPage, totalPages: $totalPages)
    }
}

final class PDFKitViewCoordinator: NSObject {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    private var hasObserver = false
    private var lastHighlightQuery: String = ""

    init(currentPage: Binding<Int>, totalPages: Binding<Int>) {
        self._currentPage = currentPage
        self._totalPages = totalPages
    }

    func observe(view: PDFView) {
        guard !hasObserver else { return }
        hasObserver = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged),
            name: .PDFViewPageChanged,
            object: view
        )
    }

    /// Resalta todas las coincidencias del texto buscado en el documento.
    func applyHighlight(query: String, in view: PDFView, document: PDFDocument) {
        guard query != lastHighlightQuery else { return }
        lastHighlightQuery = query
        if query.isEmpty {
            view.highlightedSelections = nil
            return
        }
        let selections = document.findString(query, withOptions: [.caseInsensitive, .diacriticInsensitive])
        view.highlightedSelections = selections.isEmpty ? nil : selections
    }

    @objc private func pageChanged(notification: Notification) {
        guard let pdfView = notification.object as? PDFView else { return }
        if let current = pdfView.currentPage,
           let index = pdfView.document?.index(for: current),
           currentPage != index + 1 {
            currentPage = index + 1
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - macOS representable

#if os(macOS)
import AppKit

struct PDFKitViewMac: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let highlightQuery: String

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = NSColor(Color.tarotBackground)
        view.document = document
        if let doc = document {
            DispatchQueue.main.async { totalPages = doc.pageCount }
        }
        context.coordinator.observe(view: view)
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if let doc = document, nsView.document !== doc {
            nsView.document = doc
            DispatchQueue.main.async { totalPages = doc.pageCount }
            context.coordinator.observe(view: nsView)
        }
        guard let doc = document, doc.pageCount > 0 else { return }
        let index = min(max(currentPage - 1, 0), doc.pageCount - 1)
        if let page = doc.page(at: index), nsView.currentPage != page {
            nsView.go(to: page)
        }
        context.coordinator.applyHighlight(query: highlightQuery, in: nsView, document: doc)
    }

    func makeCoordinator() -> PDFKitViewMacCoordinator {
        PDFKitViewMacCoordinator(currentPage: $currentPage, totalPages: $totalPages)
    }
}

final class PDFKitViewMacCoordinator: NSObject {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    private var observer: NSObjectProtocol?
    private var lastHighlightQuery: String = ""

    init(currentPage: Binding<Int>, totalPages: Binding<Int>) {
        self._currentPage = currentPage
        self._totalPages = totalPages
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    func observe(view: PDFView) {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: view,
            queue: .main
        ) { [weak self, weak view] _ in
            guard let self, let view,
                  let doc = view.document,
                  let page = view.currentPage else { return }
            let index = doc.index(for: page) + 1
            if self.currentPage != index { self.currentPage = index }
            if self.totalPages != doc.pageCount { self.totalPages = doc.pageCount }
        }
    }

    func applyHighlight(query: String, in view: PDFView, document: PDFDocument) {
        guard query != lastHighlightQuery else { return }
        lastHighlightQuery = query
        if query.isEmpty {
            view.highlightedSelections = nil
            return
        }
        let selections = document.findString(query, withOptions: [.caseInsensitive, .diacriticInsensitive])
        view.highlightedSelections = selections.isEmpty ? nil : selections
    }
}

struct ShareSheetMac: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            _ = window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif

#Preview {
    PDFReaderView(
        book: ImportedBook(
            title: "El Tarot Hermético",
            fileName: "hermetic_tarot.pdf",
            lastReadPage: 15,
            totalPages: 200
        ),
        libraryManager: LibraryManager()
    )
}
