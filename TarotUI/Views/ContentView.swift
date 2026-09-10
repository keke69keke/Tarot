import SwiftUI
import TarotCore
import TarotData
import TarotDI

public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: TarotViewModel
    private let container: AppContainer
    /// Welcome solo en el primer arranque — persistido entre sesiones.
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var selectedTab: AppTab = .reading
    /// Sheet de ajustes — siempre accesible desde el toolbar aunque Settings no esté en activeTabs
    @State private var showSettings = false

    public init(container: AppContainer) {
        self.container = container
        _model = StateObject(wrappedValue: TarotViewModel(container: container))
    }

    private var safeTabSelection: Binding<AppTab> {
        Binding<AppTab>(
            get: {
                selectedTab
            },
            set: { selectedTab = $0 }
        )
    }

    public var body: some View {
        Group {
            #if os(macOS)
            // macOS layout: Sidebar + Content
            HStack(spacing: 0) {
                MacSidebarView(selectedTab: safeTabSelection, activeTabs: AppTab.allCases)
                
                ZStack {
                    StarfieldBackgroundView(starCount: 110)
                    
                    if !hasSeenWelcome {
                        WelcomeView(colorScheme: colorScheme, userName: model.settings.userName) {
                            withAnimation(.easeInOut(duration: 0.72)) {
                                hasSeenWelcome = true
                            }
                        }
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 1.04))))
                        .zIndex(10)
                    } else {
                        tabContent(for: selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                    }
                }
            }
            #else
            // iOS layout: ZStack with SlidingTabBar
            ZStack {
                StarfieldBackgroundView(starCount: 110)

                TabView(selection: safeTabSelection) {
                    ForEach(AppTab.allCases) { tab in
                        tabContent(for: tab)
                            .ignoresSafeArea(edges: .top)
                            .tag(tab)
                    }
                }
                #if os(iOS)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        #endif
                .tint(Color.tarotGold)
                #if os(iOS)
                        .ignoresSafeArea(edges: .bottom)
                        #endif
                .onChange(of: selectedTab) { _ in
                    TarotAudioService.shared.triggerHaptic(.light)
                }
                .allowsHitTesting(hasSeenWelcome)

                if hasSeenWelcome {
                    VStack(spacing: 0) {
                        Spacer()
                        SlidingTabBar(
                            selectedTab: safeTabSelection,
                            activeTabs: AppTab.allCases
                        )
                        Color.clear
                            .frame(height: 0)
                            #if os(iOS)
                        .ignoresSafeArea(edges: .bottom)
                        #endif
                    }
                    #if os(iOS)
                        .ignoresSafeArea(edges: .bottom)
                        #endif
                    .zIndex(3)
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
            #endif
        }
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
                #if os(iOS)
                .presentationDetents([.large])
                #endif
                #if os(iOS)
                .presentationDragIndicator(.visible)
                #endif
                .preferredColorScheme(.dark)
            }
            .environmentObject(model.container.cosmicBackground)
            .environmentObject(container)
            .preferredColorScheme(.dark)
            .alert(TarotStrings.errorTitle.localized, isPresented: Binding(get: { model.errorMessage != nil }, set: { _ in model.errorMessage = nil })) {
                Button(TarotStrings.ok.localized, role: .cancel) {}
            } message: { Text(model.errorMessage ?? "") }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .reading:          ReadingView(model: model)
        case .ask:              AskTarotView(repository: model.container.cards)
        case .horoscope:        HoroscopeView(repository: model.container.cards)
        case .library:          UnifiedLibraryView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
        case .reference:        Text("Referencia en desarrollo").foregroundStyle(Color.tarotIvory).navigationTitle("Referencia")
        case .daily:            DailyCardView(model: model)
        case .learn:            LearningCenterView()
        case .journal:          JournalView(model: model)
        case .settings:         SettingsView(model: model)
        case .chat:             TarotChatView(apiKey: model.settings.openAIKey, repository: model.container.cards)
        case .biorhythm:        BiorhythmView(model: model)
        case .natal:            NatalChartView(model: model)
        case .soulLink:         SharedDestinyView(soulLinks: model.container.soulLinks)
        }
    }
}
