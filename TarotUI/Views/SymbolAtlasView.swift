import SwiftUI
import TarotCore
import TarotDI

/// El Atlas de Símbolos: una enciclopedia visual que conecta el conocimiento universal con la historia personal.
struct SymbolAtlasView: View {
    @EnvironmentObject var container: AppContainer
    @State private var selectedSymbol: UniversalSymbol?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                LuxuryPageHeader(
                    eyebrow: "ENCICLOPEDIA SAGRADA",
                    title: "Atlas de Símbolos"
                ) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.tarotGold)
                }
                .padding(.bottom, 8)

                // Grid de Símbolos
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 20)], spacing: 20) {
                    ForEach(container.symbolAtlas.getAllSymbols()) { symbol in
                        SymbolCard(symbol: symbol, isSelected: selectedSymbol == symbol)
                            .onTapGesture {
                                TarotAudioService.shared.triggerHaptic(.light)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedSymbol = symbol
                                }
                            }
                    }
                }

                // Detalle del Símbolo seleccionado
                if let symbol = selectedSymbol {
                    symbolDetail(symbol)
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                }
            }
            .padding(24)
        }
        // Antes terminaba en `.background(Color.clear)`, que no pinta nada: al
        // empujarla con un `NavigationLink` (Referencia > Símbolos) la vista no
        // hereda el fondo del padre y caia al negro del sistema, con siete
        // franjas negras. Verificado midiendo la captura.
        .tarotNightBackground()
    }

    private func symbolDetail(_ symbol: UniversalSymbol) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                // Medallón del símbolo
                if let platformImage = PlatformImageLoader.image(named: "symbol_" + symbol.id) {
                    Image(platformImage: platformImage)
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.tarotGold.opacity(0.45), lineWidth: 1))
                        .shadow(color: Color.tarotGold.opacity(0.25), radius: 10, x: 0, y: 4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol.name)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                    Text("Significado Universal")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .tracking(1.0)
                        .foregroundStyle(Color.tarotIvory.opacity(0.4))
                        .textCase(.uppercase)
                }
                Spacer()
                Button {
                    withAnimation { selectedSymbol = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tarotIvory.opacity(0.3))
                }
            }

            Text(container.symbolAtlas.meaning(for: symbol))
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .lineSpacing(8)
                .italic()
                .multilineTextAlignment(.leading)

            GoldDivider(opacity: 0.2)

            VStack(alignment: .leading, spacing: 12) {
                Text("Tu Historia Personal")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotGold)

                let readings = container.symbolAtlas.findReadings(for: symbol)
                if readings.isEmpty {
                    Text("Este símbolo aún no ha aparecido en tus lecturas.")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.4))
                        .italic()
                } else {
                    VStack(spacing: 10) {
                        ForEach(readings) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.savedAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 11, design: .serif))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.6))
                                    Text(entry.spread.type?.label ?? "Tirada")
                                        .font(.system(size: 12, weight: .semibold, design: .serif))
                                        .foregroundStyle(Color.tarotGold)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundStyle(Color.tarotGold.opacity(0.5))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 0.5))
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(LinearGradient(colors: [Color.tarotGold.opacity(0.4), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    struct SymbolCard: View {
        let symbol: UniversalSymbol
        let isSelected: Bool
        @EnvironmentObject var container: AppContainer

        var body: some View {
            let resonance = container.symbolAtlas.findReadings(for: symbol).count
            let glowIntensity = min(Double(resonance) * 0.1, 0.6)

            VStack(spacing: 14) {
                ZStack {
                    // Soul Resonance Aura
                    Circle()
                        .fill(Color.tarotGold)
                        .frame(width: 72, height: 72)
                        .blur(radius: 14)
                        .opacity(glowIntensity)

                    Circle()
                        .fill(isSelected ? Color.tarotGold : Color.tarotPanel)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle().stroke(Color.tarotGold.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                     // Symbol artwork loaded from symbol_<id>.png in the asset bundle
                     if let platformImage = PlatformImageLoader.image(named: "symbol_" + symbol.id) {
                         Image(platformImage: platformImage)
                             .resizable()
                             .renderingMode(.original)
                             .aspectRatio(contentMode: .fit)
                             .frame(width: 64, height: 64)
                             .clipShape(Circle())
                             .overlay(Circle().stroke(Color.tarotGold.opacity(isSelected ? 0.6 : 0.25), lineWidth: 1))
                     } else {
                         // Fallback: text initial if image not found
                         Text(symbol.name.prefix(1))
                             .font(.system(size: 26, weight: .bold, design: .serif))
                             .foregroundStyle(isSelected ? Color.black : Color.tarotGold)
                     }
                }

                Text(symbol.name)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(isSelected ? Color.tarotGold : Color.tarotIvory.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? Color.tarotGold.opacity(0.12) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(isSelected ? Color.tarotGold.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? Color.tarotGold.opacity(0.15) : .clear, radius: 12, x: 0, y: 6)
        }
    }
}
