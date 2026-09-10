import SwiftUI
import TarotCore
import TarotContent

/// Biblioteca unificada — fusiona "Biblioteca" (grid) y "Libro Rider" (lista + detalle)
/// en una sola experiencia con dos modos, para aligerar tabs y evitar confusión.
/// Mantiene lujo morado: luxuryGlass, Eyebrow, GoldDivider, texturas.
struct UnifiedLibraryView: View {
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign

    @State private var query = ""
    @State private var mode: Mode = .galeria
    @State private var orientation: CardOrientation = .upright

    enum Mode: String, CaseIterable {
        case galeria = "Galería"
        case libro = "Libro"
        var systemImage: String {
            switch self {
            case .galeria: return "rectangle.grid.2x2"
            case .libro: return "book.closed"
            }
        }
    }

    var filtered: [Card] {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? repository.allCards()
            : repository.search(query: query)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    modePicker
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    if mode == .libro {
                        orientationPicker
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                    }

                    if mode == .galeria {
                        galeriaContent
                    } else {
                        libroContent
                    }
                }
                .padding(.bottom, 24)
            }
            .background(StarfieldBackgroundView(starCount: 80))
            .navigationTitle("Biblioteca")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .searchable(text: $query, prompt: mode == .galeria ? "Buscar carta, palo o número" : "Buscar en el libro Rider")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: "BIBLIOTECA  ·  78 CARTAS")
            Text("Toda la sabiduría en un solo lugar")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Color.tarotIvory)
            Text("Explora en Galería visual o en formato Libro con significados al derecho e invertida, amor, salud, carrera y simbología.")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.58))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Label("78 cartas", systemImage: "rectangle.stack")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.82))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.06)).background(Capsule().fill(.ultraThinMaterial).opacity(0.35)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.7))
                Label("Unificada", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotGold)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.tarotGold.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))
            }
        }
        .padding(16)
        .luxuryGlass(cornerRadius: 20)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var modePicker: some View {
        Picker("Modo", selection: $mode) {
            ForEach(Mode.allCases, id: \.self) { m in
                Label(m.rawValue, systemImage: m.systemImage).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.tarotGold)
    }

    private var orientationPicker: some View {
        Picker("Orientación", selection: $orientation) {
            Text("Al derecho").tag(CardOrientation.upright)
            Text("Invertida").tag(CardOrientation.reversed)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Galería (grid por arcanos)
    private var galeriaContent: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            if query.isEmpty {
                let majors = repository.cards(in: .majorArcana)
                if !majors.isEmpty { gridSection(title: "Arcanos Mayores", subtitle: "\(majors.count) cartas", cards: majors) }
                ForEach(CardSuit.allCases, id: \.self) { suit in
                    let minors = repository.cards(in: .minorArcana(suit: suit))
                    if !minors.isEmpty { gridSection(title: suit.displayName, subtitle: "\(minors.count) cartas", cards: minors) }
                }
            } else {
                if filtered.isEmpty {
                    emptyState(text: "Sin resultados para “\(query)”")
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(filtered.count) resultados").font(.system(size: 11, weight: .medium, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.5)).padding(.horizontal, 16).padding(.top, 12)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                            ForEach(filtered) { card in
                                NavigationLink { CardDetailView(card: card, orientation: .upright, repository: repository, activeDeck: activeDeck, cardBackDesign: cardBackDesign) } label: { LibraryCardCell(card: card, activeDeck: activeDeck, cardBackDesign: cardBackDesign) }
                                    .buttonStyle(.plain)
                            }
                        }.padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    private func gridSection(title: String, subtitle: String, cards: [Card]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 16, weight: .bold, design: .serif)).foregroundStyle(Color.tarotIvory)
                Spacer()
                Text(subtitle).font(.system(size: 11, weight: .medium, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.5))
            }.padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 14) {
                ForEach(cards) { card in
                    NavigationLink { CardDetailView(card: card, orientation: .upright, repository: repository, activeDeck: activeDeck, cardBackDesign: cardBackDesign) } label: { LibraryCardCell(card: card, activeDeck: activeDeck, cardBackDesign: cardBackDesign) }
                        .buttonStyle(.plain)
                }
            }.padding(.horizontal, 16)
        }
    }

    // MARK: - Libro (lista)
    private var libroContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if filtered.isEmpty {
                emptyState(text: query.isEmpty ? "No hay cartas" : "Sin resultados para “\(query)”")
                    .padding(.top, 24)
            } else {
                ForEach(filtered) { card in
                    NavigationLink { ReferenceCardView(card: card, orientation: orientation, repository: repository, activeDeck: activeDeck, cardBackDesign: cardBackDesign) } label: { libroRow(card) }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    private func libroRow(_ card: Card) -> some View {
        HStack(spacing: 14) {
            CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: orientation == .reversed, useTexture: true, size: CGSize(width: 56, height: 82), activeDeck: activeDeck, backDesign: cardBackDesign)
                .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name).font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(Color.tarotIvory)
                Text(card.suit?.displayName ?? "Arcano Mayor").font(.system(size: 11, weight: .regular, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.55))
                HStack(spacing: 6) {
                    Text(card.arcanaType == .major ? "Mayor" : "Menor").font(.system(size: 10, weight: .bold, design: .serif)).tracking(0.6).padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(card.arcanaType == .major ? Color.tarotGold.opacity(0.16) : Color.white.opacity(0.07))).foregroundStyle(card.arcanaType == .major ? Color.tarotGold : Color.tarotIvory.opacity(0.6))
                    if card.bookContent != nil { Image(systemName: "books.vertical").font(.system(size: 10)).foregroundStyle(Color.tarotGold.opacity(0.75)) }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11, weight: .light)).foregroundStyle(Color.tarotIvory.opacity(0.25))
        }
        .padding(.vertical, 10).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.04)).background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial).opacity(0.30)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.7))
        .padding(.bottom, 8)
    }

    private func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 36, weight: .thin)).foregroundStyle(Color.tarotIvory.opacity(0.35))
            Text(text).font(.system(size: 13, weight: .regular, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.55))
        }.frame(maxWidth: .infinity).padding(.top, 40)
    }
}

private struct LibraryCardCell: View {
    let card: Card
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign

    var body: some View {
        VStack(spacing: 8) {
            CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 96, height: 144), activeDeck: activeDeck, backDesign: cardBackDesign)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 5)
            Text(card.name).font(.system(size: 11, weight: .semibold, design: .serif)).foregroundStyle(Color.tarotIvory).lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity).padding(8)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.05)).background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial).opacity(0.30)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(card.arcanaType == .major ? Color.tarotGold.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 0.8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name)")
    }
}
