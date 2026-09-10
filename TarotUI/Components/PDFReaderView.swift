import SwiftUI
import PDFKit
import TarotCore

/// A view for reading imported PDF books from the library.
struct PDFReaderView: View {
    let book: ImportedBook
    let libraryManager: LibraryManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0
    @State private var pdfDocument: PDFDocument?
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showShare = false
    @State private var documentURL: URL?
    
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { searchText },
            set: { searchText = $0 }
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                Color.tarotBackgroundGradient.ignoresSafeArea()
                
                pdfContent
                
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.tarotGold)
                        }
                        
                        Spacer()
                        
                        Text("Leyendo")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.7))
                        
                        Spacer()
                        
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.tarotGold)
                            .opacity(0.5)
                            .onTapGesture {
                                showShare = true
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.tarotBackground.opacity(0.8))
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(book.title)
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 80)
                        
                        if totalPages > 0 {
                            Text("Página \(currentPage)/\(totalPages)")
                                .font(.caption)
                                .foregroundStyle(Color.tarotGold)
                                .padding(.top, 4)
                        }
                    }
                    
                    if totalPages > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Página \(currentPage)/\(totalPages)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.7))
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(currentPage) },
                                    set: { currentPage = Int($0) }
                                ),
                                in: 1.0...Double(totalPages),
                                onEditingChanged: { _ in
                                    loadPage()
                                }
                            )
                            .tint(Color.tarotGold)
                            .accentColor(Color.tarotGold.opacity(0.6))
                        }
                        .padding(16)
                        .background(Color.tarotPanel.opacity(0.4))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarBackButtonHidden()
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.tarotGold)
                    }
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.tarotGold)
                    }
                }
                #endif
            }
            .onAppear {
                loadPDF()
                currentPage = book.lastReadPage
            }
            .sheet(isPresented: $showShare) {
                shareSheet
            }
        }
    }
    
    @ViewBuilder
    private var pdfContent: some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            PDFKitView(
                document: pdfDocument,
                currentPage: $currentPage,
                totalPages: $totalPages,
                searchText: searchTextBinding
            )
            .ignoresSafeArea()
            .searchable(text: searchTextBinding, prompt: "Buscar en el documento")
            .onSubmit(of: .search) {
                showSearch = true
            }
        } else {
            Color.clear.ignoresSafeArea()
        }
        #else
        Text("El lector de PDF solo está disponible en iOS").foregroundStyle(Color.tarotIvory)
        #endif
    }

    @ViewBuilder
    private var shareSheet: some View {
        if let url = documentURL {
            #if os(iOS)
            ActivityView(activityItems: [url], applicationActivities: nil)
            #else
            Text("Compartir no disponible en macOS").foregroundStyle(Color.tarotIvory)
            #endif
        }
    }
    
    private func loadPDF() {
        guard let url = libraryManager.getFileURL(for: book) as URL? else {
            return
        }
        
        documentURL = url
        
        if let document = PDFDocument(url: url) {
            pdfDocument = document
            totalPages = document.pageCount
            currentPage = max(1, min(book.lastReadPage, totalPages))
        }
    }

    private func loadPage() {
        // Page change is handled via PDFKitView's updateUIView
    }
}

#if os(iOS)
import UIKit

/// PDFKit view wrapper for iOS
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    let searchText: Binding<String>
    
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePage
        v.backgroundColor = UIColor(Color.tarotBackground)
        
        if let doc = document {
            v.document = doc
            totalPages = doc.pageCount
            context.coordinator.observe(view: v)
        }
        
        return v
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let doc = document, uiView.document !== doc {
            uiView.document = doc
            totalPages = doc.pageCount
        }
        
        if let p = document?.page(at: min(max(currentPage - 1, 0), (document?.pageCount ?? 0) - 1)),
           uiView.currentPage != p {
            uiView.go(to: p)
        }
        
        if totalPages != document?.pageCount {
            totalPages = document?.pageCount ?? 0
        }
    }
    
    func makeCoordinator() -> PDFKitViewCoordinator {
        PDFKitViewCoordinator(currentPage: $currentPage, totalPages: $totalPages)
    }
}

/// Coordinator to observe PDF view changes
class PDFKitViewCoordinator: NSObject {
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    private var hasObserver = false
    
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
    
    @objc private func pageChanged(notification: Notification) {
        guard let pdfView = notification.object as? PDFView else { return }
        if let current = pdfView.currentPage,
           let pageIndex = pdfView.document?.index(for: current) {
            currentPage = pageIndex + 1
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

/// Activity view for sharing PDF documents
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
