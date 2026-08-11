import SwiftUI
import TarotCore
import TarotData

struct ReadingView: View {
    @ObservedObject var model: TarotViewModel
    @State private var notes = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var selectedDrawnCard: DrawnCard? = nil
    @State private var replacementIndex: Int? = nil
    @State private var cardPickerQuery = ""
    @State private var isShowingPositionChooser = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tu ritual de tarot")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        Text("Elige una tirada, baraja con intención y descubre lo que las cartas te quieren revelar hoy.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.tarotShadow, radius: 12, x: 0, y: 6)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selecciona tu tirada")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SpreadType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            model.selectedSpread = type
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(type.label)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(model.selectedSpread == type ? .primary : .secondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                            Text("\(type.positions.count) cartas")
                                                .font(.caption2)
                                                .foregroundStyle(model.selectedSpread == type ? .secondary : Color.secondary.opacity(0.85))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .frame(width: 150)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(model.selectedSpread == type ? Color.tarotGold.opacity(0.22) : Color.tarotPanel.opacity(0.88))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(model.selectedSpread == type ? Color.tarotGold.opacity(0.70) : Color.tarotBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.90))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .stroke(Color.tarotBorder, lineWidth: 1)
                                )
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.selectedSpread.label)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("""
                        \(model.selectedSpread.positions.count) cartas · \(model.selectedSpread.positions.map { $0.displayName }.joined(separator: " · "))
                        """)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )

                    // ── Intención de lectura ─────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Intención de la lectura", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Opcional: escribe tu pregunta o el tema que quieres explorar. Se integrará en tu lectura.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Ej: ¿Qué energía me acompaña esta semana?", text: $model.readingIntention)
                            .font(.system(size: 15, design: .serif))
                            .padding(14)
                            .background(Color.tarotPanel.opacity(0.95))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.tarotGold.opacity(0.30), lineWidth: 1)
                            )
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )

                    // ── Carta significadora opcional ────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Usar carta significadora", isOn: $model.useSignificator)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if model.useSignificator {
                            Text("La carta significadora te representa. Se elige al azar del mazo y se coloca como primera carta de la tirada.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 14) {
                                if let sig = model.significatorCard {
                                    VStack(spacing: 6) {
                                        CardFace(name: sig.name, imageName: sig.imageName, textureName: sig.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 70, height: 104), activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign)
                                            .shadow(color: Color.tarotShadow.opacity(0.6), radius: 8, x: 0, y: 4)
                                        Text(sig.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.tarotGold)
                                            .multilineTextAlignment(.center)
                                    }
                                } else {
                                    VStack(spacing: 6) {
                                        CardFace(name: "Sin carta", imageName: nil, textureName: nil, reversed: false, back: true, size: CGSize(width: 70, height: 104), activeDeck: model.settings.activeDeck, backDesign: model.settings.cardBackDesign)
                                        Text("Sin elegir")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    TarotAudioService.shared.triggerHaptic(.medium)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        model.drawRandomSignificator()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "dice.fill")
                                        Text("Elegir al azar")
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    )
                                    .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                                    .shadow(color: Color.tarotGold.opacity(0.35), radius: 10, x: 0, y: 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )

Button {
                        TarotAudioService.shared.triggerHaptic(.medium)
                        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75)) {
                            model.draw()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: model.isShuffling ? "sparkles" : "shuffle")
                            Text(model.isShuffling ? "Barajando…" : "Iniciar tirada")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.78, green: 0.62, blue: 0.98), Color(red: 0.42, green: 0.20, blue: 0.60)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                        .shadow(color: Color(red: 0.42, green: 0.20, blue: 0.60).opacity(0.45), radius: 16, x: 0, y: 10)
                    }
                    .disabled(model.isShuffling)
                    .opacity(model.isShuffling ? 0.75 : 1)

                    if model.isShuffling {
                        CardFace(name: "Barajando", imageName: nil, textureName: nil, reversed: false, back: true, size: CGSize(width: 160, height: 240), backDesign: model.settings.cardBackDesign)
                            .rotationEffect(.degrees(15))
                            .transition(.opacity)
                    }

                    if model.spread != nil {
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75)) {
                                    model.reshuffleCurrentSpread()
                                    revealedIndices.removeAll()
                                }
                            } label: {
                                Text("Barajar mazo")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.tarotPanel.opacity(0.92)))
                                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.isShuffling)

                            Button {
                                isShowingPositionChooser = true
                            } label: {
                                Text("Elegir cartas")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.tarotPanel.opacity(0.92)))
                                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.isShuffling)
                        }
                        .padding(.top, 4)
                        .foregroundStyle(.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.clear)
                        )
                        Text("Mantén pulsada una carta para reemplazarla o usa 'Elegir cartas'.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    if let spread = model.spread {
                        SpreadDiagramView(
                            spread: spread,
                            repository: model.container.cards,
                            revealedIndices: revealedIndices,
                            activeDeck: model.settings.activeDeck,
                            cardBackDesign: model.settings.cardBackDesign,
                            onSelectCard: { drawn in
                                selectedDrawnCard = drawn
                            },
                            onReplaceCard: { index, _ in
                                replacementIndex = index
                            }
                        )
                        .onReceive(model.$spread) { spread in
                            guard let spread = spread else {
                                revealedIndices.removeAll()
                                return
                            }
                            revealedIndices.removeAll()
                            for i in 0..<spread.drawnCards.count {
                                let delay = Double(i) * 0.18 + 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.spring(response: 0.52, dampingFraction: 0.68, blendDuration: 0)) {
                                        _ = revealedIndices.insert(i)
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(spread.drawnCards.count) * 0.18 + 0.5) {
                                withAnimation {
                                    model.isShuffling = false
                                }
                            }
                        }

// Narrative synthesis of the whole reading
                        if let spread = model.spread, !spread.drawnCards.isEmpty {
                            SpreadNarrativeCard(spread: spread, repository: model.container.cards, intention: model.readingIntention)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Notas del diario")
                                .font(.headline)
                            .foregroundStyle(.primary)
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Escribe tus impresiones después de la lectura...")
                                        .foregroundStyle(.secondary)
                                        .padding(14)
                                }
                                TextEditor(text: $notes)
                                    .padding(12)
                                    .background(Color.tarotPanel.opacity(0.92))
                                    .cornerRadius(22)
                                    .frame(minHeight: 120)
                                    .foregroundStyle(.primary)
                            }
Button {
                                TarotAudioService.shared.triggerHaptic(.success)
                                model.saveSpread(notes: notes)
                                notes = ""
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Guardar en diario")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [Color.tarotGold, Color.tarotBurgundy],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                )
                                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                                .shadow(color: Color.tarotGold.opacity(0.30), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.90))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.tarotBorder, lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Tirada")
            .sheet(isPresented: $isShowingPositionChooser) {
                NavigationStack {
                    VStack {
                        Text("Selecciona la posición para reemplazar")
                            .font(.headline)
                            .padding(.top, 16)

                        if let spread = model.spread {
                            List(spread.drawnCards.indices, id: \.self) { idx in
                                let drawn = spread.drawnCards[idx]
                                Button {
                                    replacementIndex = idx
                                    isShowingPositionChooser = false
                                } label: {
                                    HStack(spacing: 12) {
                                        CardFace(name: drawn.card.name, imageName: drawn.card.imageName, textureName: drawn.card.textureImageName, reversed: drawn.orientation == .reversed, useTexture: true, size: CGSize(width: 58, height: 88), activeDeck: model.settings.activeDeck)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(drawn.position.displayName)
                                                .font(.headline)
                                            Text(drawn.card.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.plain)
                        }
                        Spacer()
                    }
                    .navigationTitle("Elegir carta")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { isShowingPositionChooser = false }
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(get: { replacementIndex != nil }, set: { if !$0 { replacementIndex = nil } })) {
                if let selectedIndex = replacementIndex, let spread = model.spread, spread.drawnCards.indices.contains(selectedIndex) {
                    NavigationStack {
                        VStack {
                            Text("Elige una carta para \(spread.drawnCards[selectedIndex].position.displayName)")
                                .font(.headline)
                                .padding(.top, 16)

                            TextField("Buscar carta", text: $cardPickerQuery)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                .padding(.bottom, 6)

                            List(filteredCards(query: cardPickerQuery, repository: model.container.cards), id: \.self) { card in
                                Button {
                                    model.replaceCard(at: selectedIndex, with: card)
                                    replacementIndex = nil
                                    cardPickerQuery = ""
                                } label: {
                                    HStack(spacing: 12) {
                                        CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 58, height: 88), activeDeck: model.settings.activeDeck)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(card.name)
                                                .font(.headline)
                                            Text(card.suit?.displayName ?? "Arcano Mayor")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.plain)
                        }
                        .navigationTitle("Reemplazar carta")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancelar") {
                                    replacementIndex = nil
                                    cardPickerQuery = ""
                                }
                            }
                        }
                    }
                } else {
                    Text("No hay posición seleccionada.")
                }
            }
            .sheet(item: $selectedDrawnCard) { drawn in
                NavigationStack {
                    CardDetailView(drawn: drawn, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                }
            }
        }
    }

    private func filteredCards(query: String, repository: any CardRepository) -> [Card] {
        let allCards = repository.allCards()
        guard !query.isEmpty else { return allCards }
        return repository.search(query: query)
    }
}
