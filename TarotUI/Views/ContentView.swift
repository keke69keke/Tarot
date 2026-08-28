import SwiftUI
import TarotCore
import TarotData
import TarotDI

public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: TarotViewModel
    @State private var showWelcome = true

    public init(container: any AppContainerProtocol) { _model = StateObject(wrappedValue: TarotViewModel(container: container)) }

    public var body: some View {
        ZStack {
            Color.tarotBackground.ignoresSafeArea()
            Color.tarotBackgroundGradient.ignoresSafeArea()
            AmbientBackgroundView()

            TabView {
                ForEach(model.settings.activeTabs) { tab in
                    Group {
                        switch tab {
                        case .reading: ReadingView(model: model)
                        case .ask: AskTarotView(repository: model.container.cards)
                        case .horoscope: HoroscopeView(repository: model.container.cards)
                        case .library, .reference: UnifiedLibraryView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                        case .daily: DailyCardView(model: model)
                        case .learn: LearningCenterView()
                        case .journal: JournalView(model: model)
                        case .settings: SettingsView(model: model)
                        case .chat: TarotChatView(apiKey: model.settings.openAIKey, repository: model.container.cards)
                        case .biorhythm: BiorhythmView()
                        case .natal: NatalChartView()
                        }
                    }
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
            .opacity(showWelcome ? 0 : 1)
            // Hairline joya sobre tab bar
            .safeAreaInset(edge: .bottom, spacing: 0) {
                GoldDivider(opacity: 0.11)
                    .opacity(showWelcome ? 0 : 1)
            }

            if showWelcome {
                WelcomeView(colorScheme: colorScheme, userName: model.settings.userName) {
                    withAnimation(.easeInOut(duration: 0.72)) {
                        showWelcome = false
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
}
