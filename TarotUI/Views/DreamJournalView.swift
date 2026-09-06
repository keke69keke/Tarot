import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct DreamJournalView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var viewModel = DreamViewModel()
    @State private var isShowingEntrySheet = false
    @State private var selectedDream: DreamEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                AmbientBackgroundView().opacity(0.4)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            EyebrowLabel(text: "MEMORIAS ONÍRICAS")
                            Text("El Oráculo de los Sueños")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                            Text("Donde el inconsciente habla en símbolos y el tarot traduce su misterio.")
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.55))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 12)

                        // Dream List
                        if viewModel.entries.isEmpty {
                            emptyDreamState
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.entries) { dream in
                                    DreamEntryCard(dream: dream)
                                        .onTapGesture {
                                            selectedDream = dream
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Diario Onírico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isShowingEntrySheet = true } label: {
                        Image(systemName: "moon.stars.fill").foregroundStyle(Color.tarotGold)
                    }
                }
            }
            .sheet(isPresented: $isShowingEntrySheet) {
                DreamEntrySheet(repository: container.dreams, oracle: container.dreamOracle) {
                    viewModel.reload(using: container.dreams)
                }
            }
            .sheet(item: $selectedDream) { dream in
                DreamDetailView(dream: dream, oracle: container.dreamOracle)
            }
            .onAppear {
                viewModel.reload(using: container.dreams)
            }
        }
    }

    private var emptyDreamState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.tarotGold.opacity(0.1)).frame(width: 100, height: 100).blur(radius: 20)
                Image(systemName: "sparkles").font(.system(size: 40, weight: .thin)).foregroundStyle(Color.tarotGold.opacity(0.6))
            }
            Text("Tu mapa onírico está vacío")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.7))
            Text("Registra tus sueños para descubrir los hilos que los unen con tu destino.")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct DreamEntryCard: View {
    let dream: DreamEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dream.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.4))
                Spacer()
                if !dream.identifiedSymbols.isEmpty {
                    Text("\(dream.identifiedSymbols.count) símbolos")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.tarotGold.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.5))
                }
            }

            Text(dream.dreamText)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.85))
                .lineLimit(3)
                .italic()

            if let tone = dream.emotionalTone {
                Text("Tono: \(tone)").font(.system(size: 11, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.4))
            }
        }
        .padding(16)
        .luxuryGlass(cornerRadius: 20)
    }
}

class DreamViewModel: ObservableObject {
    @Published var entries: [DreamEntry] = []

    func reload(using repository: DreamRepositoryProtocol) {
        entries = repository.fetchAll()
    }
}

struct DreamEntrySheet: View {
    let repository: DreamRepositoryProtocol
    let oracle: DreamOracleProtocol
    var onSave: () -> Void
    @State private var text = ""
    @State private var tone = ""
    @State private var isAnalyzing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("El Relato del Sueño") {
                    TextEditor(text: $text)
                        .frame(minHeight: 200)
                        .foregroundStyle(Color.tarotIvory)
                }
                Section("Análisis del Oráculo") {
                    Button {
                        analyze()
                    } label: {
                        if isAnalyzing {
                            ProgressView().tint(Color.tarotGold)
                        } else {
                            Label("Analizar Símbolos", systemImage: "sparkles")
                        }
                    }
                    .disabled(text.isEmpty || isAnalyzing)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Nuevo Sueño")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { save() } }
            }
        }
    }

    @Environment(\.dismiss) var dismiss

    private func analyze() {
        isAnalyzing = true
        Task {
            do {
                let analysis = try await oracle.analyzeDream(text: text)
                tone = analysis.emotionalTone
            } catch {
                print("Error analyzing dream")
            }
            isAnalyzing = false
        }
    }

    private func save() {
        let entry = DreamEntry(dreamText: text, emotionalTone: tone)
        try? repository.save(entry: entry)
        onSave()
        dismiss()
    }
}

struct DreamDetailView: View {
    let dream: DreamEntry
    let oracle: DreamOracleProtocol
    @State private var analysis: DreamAnalysis?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(dream.dreamText)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .italic()
                    .padding()
                    .luxuryGlass()

                if let analysis = analysis {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Revelación del Oráculo").font(.system(size: 18, weight: .bold, design: .serif)).foregroundStyle(Color.tarotGold)
                        Text(analysis.summary).font(.system(size: 16, design: .serif)).foregroundStyle(Color.tarotIvory)

                        HStack {
                            ForEach(analysis.identifiedSymbols, id: \.self) { symbol in
                                Text(symbol).font(.system(size: 12, design: .serif)).padding(6).background(Capsule().fill(Color.tarotGold.opacity(0.2))).foregroundStyle(Color.tarotGold)
                            }
                        }

                        if let spread = analysis.recommendedSpread {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sugerencia de Lectura").font(.system(size: 14, weight: .bold, design: .serif)).foregroundStyle(Color.tarotGold)
                                Text("Recomendamos una tirada de \(spread.label) para profundizar en este sueño.").font(.system(size: 13, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.7))
                                Text(analysis.reasoning).font(.system(size: 12, design: .serif)).italic().foregroundStyle(Color.tarotIvory.opacity(0.5))
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.tarotGold.opacity(0.05)))
                        }
                    }
                    .padding()
                    .luxuryGlass()
                } else {
                    Button {
                        analyze()
                    } label: {
                        Label("Consultar al Oráculo", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Capsule().fill(Color.tarotGoldGradient))
                            .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("El Espejo Onírico")
    }

    private func analyze() {
        isLoading = true
        Task {
            if let result = try? await oracle.analyzeDream(text: dream.dreamText) {
                analysis = result
            }
            isLoading = false
        }
    }
}
