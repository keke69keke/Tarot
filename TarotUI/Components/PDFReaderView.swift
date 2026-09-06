import SwiftUI
import TarotCore

/// A view for reading imported PDF books from the library.
/// Currently displays book metadata; full PDF rendering requires PDFKit integration.
struct PDFReaderView: View {
    let book: ImportedBook
    let libraryManager: LibraryManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 1
    
    var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
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
                    
                    // Placeholder for additional actions
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.tarotGold)
                        .opacity(0.5)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Spacer()
                
                // Book Info
                VStack(spacing: 16) {
                    Text(book.title)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                        .multilineTextAlignment(.center)
                    
                    Text("Archivo: \(book.fileName)")
                        .font(.caption)
                        .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    
                    if let totalPages = book.totalPages {
                        Text("Páginas: \(totalPages)")
                            .font(.caption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    }
                    
                    Text("Agregado: \(book.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(Color.tarotIvory.opacity(0.5))
                }
                .padding(24)
                .background(Color.tarotPanel.opacity(0.6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                // Placeholder message
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.tarotGold.opacity(0.6))
                    
                    Text("Visualizador de PDF")
                        .font(.headline)
                        .foregroundStyle(Color.tarotIvory)
                    
                    Text("La funcionalidad de lectura de PDF estará disponible próximamente. Puedes gestionar tu biblioteca desde la sección de ajustes.")
                        .font(.caption)
                        .foregroundStyle(Color.tarotIvory.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(24)
                .background(Color.tarotGold.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer: Reading progress (if available)
                if let totalPages = book.totalPages, totalPages > 0 {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Progreso")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.tarotIvory.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(currentPage)/\(totalPages)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.tarotGold)
                        }
                        
                        ProgressView(value: Double(currentPage), total: Double(totalPages))
                            .tint(Color.tarotGold)
                    }
                    .padding(16)
                    .background(Color.tarotPanel.opacity(0.4))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            currentPage = book.lastReadPage
        }
    }
}

#Preview {
    NavigationStack {
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
}
