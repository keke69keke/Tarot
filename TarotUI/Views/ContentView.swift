import SwiftUI
import TarotCore
import TarotData

public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: TarotViewModel
    @State private var showWelcome = true

    public init(container: AppContainer) { _model = StateObject(wrappedValue: TarotViewModel(container: container)) }

    public var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color.tarotBackground.ignoresSafeArea()

            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.02, blue: 0.14), Color(red: 0.08, green: 0.03, blue: 0.18)]
                    : [Color(red: 0.20, green: 0.12, blue: 0.30), Color(red: 0.16, green: 0.08, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            .ignoresSafeArea()

            // Lavender ambient glow
            Circle()
                .fill(Color(red: 0.72, green: 0.55, blue: 0.95).opacity(colorScheme == .dark ? 0.16 : 0.10))
                .frame(width: 340, height: 340)
                .blur(radius: 68)
                .offset(x: -140, y: -200)

            // Deep violet accent glow
            Circle()
                .fill(Color(red: 0.42, green: 0.12, blue: 0.55).opacity(colorScheme == .dark ? 0.15 : 0.09))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: 160, y: -140)

            // ── Main UI ─────────────────────────────────────────
            // TabView fills the screen fully, respecting safe areas so
            // nothing is clipped on iPhone (no framed/rounded wrapper).
            TabView {
                ForEach(model.settings.activeTabs) { tab in
                    Group {
                        switch tab {
                        case .reading: ReadingView(model: model)
                        case .ask: AskTarotView(repository: model.container.cards)
                        case .horoscope: HoroscopeView(repository: model.container.cards)
                        case .library: LibraryGridView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                        case .reference: RiderReferenceView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                        case .daily: DailyCardView(model: model)
                        case .learn: LearningCenterView()
                        case .journal: JournalView(model: model)
                        case .settings: SettingsView(model: model)
                        case .chat: TarotChatView(apiKey: model.settings.openAIKey, repository: model.container.cards)
                        }
                    }
                    .tabItem { Label(tab.label, systemImage: tab.systemImage) }
                    .tag(tab)
                }
            }
            .opacity(showWelcome ? 0 : 1)

            // ── Welcome Splash ───────────────────────────────────
            if showWelcome {
                WelcomeView(colorScheme: colorScheme, userName: model.settings.userName) {
                    withAnimation(.easeInOut(duration: 0.65)) {
                        showWelcome = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 1.08))
                ))
                .zIndex(10)
            }
        }
        .preferredColorScheme(model.settings.appearance.colorScheme)
        .alert("Error", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Aceptar", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}
