import SwiftUI
import TarotCore
import TarotData
import TarotDI

public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: TarotViewModel
    /// Welcome solo en el primer arranque — persistido entre sesiones.
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var selectedTab: AppTab?
    /// Sheet de ajustes — siempre accesible desde el toolbar aunque Settings no esté en activeTabs
    @State private var showSettings = false

    public init(container: any AppContainerProtocol) { _model = StateObject(wrappedValue: TarotViewModel(container: container)) }

    public var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()
            AmbientBackgroundView()

            TabView(selection: $selectedTab) {
                ForEach(model.settings.activeTabs) { tab in
                    tabContent(for: tab)
                        .tabItem {
                            Label {
                                Text(tab.label)
                                    .font(.system(size: 10, weight: .medium, design: .serif))
                                    .tracking(0.2)
                            } icon: {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 15, weight: .light))
                            }
                        }
                        .tag(tab)
                }
            }
            .tint(Color.tarotGold)
            // Haptic sutil al cambiar de tab — feedback táctil consistente
            .onChange(of: selectedTab) { _ in
                TarotAudioService.shared.triggerHaptic(.light)
            }
            .opacity(hasSeenWelcome ? 1 : 0)
            // Sheet ajustes — acceso garantizado independiente del tab bar
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView(model: model)
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button {
                                    showSettings = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundStyle(Color.tarotIvory.opacity(0.55))
                                }
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
            }
            // Hairline joya sobre tab bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GoldDivider(opacity: 0.11)
                    .opacity(hasSeenWelcome ? 1 : 0)
            }

            // Botón flotante ⚙ — solo visible cuando Settings NO está en activeTabs
            if hasSeenWelcome && !model.settings.activeTabs.contains(.settings) {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            TarotAudioService.shared.triggerHaptic(.light)
                            showSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Color.tarotGold)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial.opacity(0.85))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.tarotGold.opacity(0.25), lineWidth: 0.75))
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .accessibilityLabel("Ajustes")
                        .padding(.trailing, 16)
                        .padding(.top, 56)
                    }
                    Spacer()
                }
                .zIndex(5)
            }

            if !hasSeenWelcome {
                WelcomeView(colorScheme: colorScheme, userName: model.settings.userName) {
                    withAnimation(.easeInOut(duration: 0.72)) {
                        hasSeenWelcome = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 1.04))
                ))
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .alert(TarotStrings.errorTitle.localized, isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button(TarotStrings.ok.localized, role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .reading:          ReadingView(model: model)
        case .ask:              AskTarotView(repository: model.container.cards)
        case .horoscope:        HoroscopeView(repository: model.container.cards)
        case .library, .reference: UnifiedLibraryView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
        case .daily:            DailyCardView(model: model)
        case .learn:            LearningCenterView()
        case .journal:          JournalView(model: model)
        case .settings:         SettingsView(model: model)
        case .chat:             TarotChatView(apiKey: model.settings.openAIKey, repository: model.container.cards)
        case .biorhythm:        BiorhythmView(model: model)
        case .natal:            NatalChartView(model: model)
        }
    }
}
