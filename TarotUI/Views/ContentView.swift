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
    /// Tutorial de secciones — se muestra una vez tras el Welcome.
    @AppStorage("hasSeenSectionsTutorial") private var hasSeenSectionsTutorial = false
    @State private var showTutorial = false
    @State private var selectedTab: AppTab = .reading
    /// Sheet de ajustes — siempre accesible desde el toolbar aunque Settings no esté en activeTabs
    @State private var showSettings = false

    public init(container: AppContainer) {
        self.container = container
        _model = StateObject(wrappedValue: TarotViewModel(container: container))

        // Dev/QA (ambas plataformas): `-tab library` abre directamente en una pestaña;
        // `-tutorial` fuerza el tutorial de secciones; `-fresh` reinicia el primer arranque.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let tab = AppTab(rawValue: args[i + 1]) {
            _selectedTab = State(initialValue: tab)
        }
        if args.contains("-fresh") {
            UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
            UserDefaults.standard.set(false, forKey: "hasSeenSectionsTutorial")
        }
        if args.contains("-tutorial") {
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            _showTutorial = State(initialValue: true)
        }
    }

    /// Tabs visibles según la configuración del usuario (Ajustes → Barra inferior).
    /// Garantiza una lista no vacía y que Ajustes siga siendo alcanzable.
    private var visibleTabs: [AppTab] {
        // «Referencia» ya no es una pestana suelta: vive dentro de «Aprender y Referencia».
        var tabs = model.settings.activeTabs.filter { $0 != .reference }
        if tabs.isEmpty { tabs = AppTab.allCases }
        if !tabs.contains(.settings) { tabs.append(.settings) }
        return tabs
    }

    /// Si el tab seleccionado ya no está visible (se ocultó en Ajustes), salta al primero.
    private func ensureValidSelection() {
        if !visibleTabs.contains(selectedTab) {
            selectedTab = visibleTabs.first ?? .reading
        }
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
                MacSidebarView(selectedTab: safeTabSelection, activeTabs: visibleTabs)
                
                ZStack {
                    if showTutorial {
                        SectionsTutorialView {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showTutorial = false
                                hasSeenSectionsTutorial = true
                            }
                        }
                        .transition(.opacity)
                        .zIndex(11)
                    }
                    
                    if !hasSeenWelcome {
                        WelcomeView(colorScheme: colorScheme, userName: model.settings.userName) {
                            withAnimation(.easeInOut(duration: 0.72)) {
                                hasSeenWelcome = true
                            }
                            if !hasSeenSectionsTutorial {
                                showTutorial = true
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
            .tarotNightBackground()
            #else
            // iOS layout: ZStack with SlidingTabBar
            // Base nocturna en la raiz, SIN el cielo animado. Cada pestana pinta su
            // cielo completo dentro de su NavigationStack (ahi si se ve), pero el
            // stack no cubre el area segura superior: sin esta capa quedaba una
            // franja negra de 62 pt bajo la barra de estado (medido en captura).
            // El `ignoresSafeArea` es imprescindible: sin el, un `Color` suelto no
            // se extiende bajo la barra de estado y la franja vuelve a salir.
            // Se usa la base solida y no `tarotNightBackground()` para no montar un
            // segundo `TimelineView` a 30 fps que quedaria tapado.
            ZStack {
                ZStack {
                    Color.tarotBackground
                    Color.tarotBackgroundGradient
                }
                .ignoresSafeArea()

                TabView(selection: safeTabSelection) {
                    ForEach(visibleTabs) { tab in
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
                .onChange(of: model.settings.activeTabs) { tabs in
                    // Si el tab actual fue ocultado en Ajustes, salta al primero visible.
                    if !tabs.contains(selectedTab) {
                        selectedTab = tabs.first ?? .reading
                    }
                }
                // Reserva espacio para la barra de pestañas flotante.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: hasSeenWelcome ? 86 : 0)
                }
                .allowsHitTesting(hasSeenWelcome)

                if hasSeenWelcome {
                    VStack(spacing: 0) {
                        Spacer()
                        SlidingTabBar(
                            selectedTab: safeTabSelection,
                            activeTabs: visibleTabs
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
                        if !hasSeenSectionsTutorial {
                            showTutorial = true
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    ))
                    .zIndex(10)
                }

                if showTutorial {
                    SectionsTutorialView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showTutorial = false
                            hasSeenSectionsTutorial = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(11)
                }
            }
            #endif
        }
        .onAppear(perform: ensureValidSelection)
        // La app es nocturna por diseño (fondo fijo oscuro, sheets ya en dark).
        // Fijarla evita que en modo claro aparezcan tarjetas crema con texto ámbar.
        .preferredColorScheme(.dark)
        #if os(macOS)
        .navigationTitle("ARCANA · Tarot Studio")
        #endif
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
                .tarotSheetBackground()
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
        case .reference:        LearnAndReferenceView(container: container, inicial: .referencia)
        case .daily:            DailyCardView(model: model)
        case .learn:            LearnAndReferenceView(container: container)
        case .journal:          JournalView(model: model)
        case .settings:         SettingsView(model: model)
        case .chat:             TarotChatView(
                                    apiKey: model.settings.aiApiKey.isEmpty ? model.settings.openAIKey : model.settings.aiApiKey,
                                    repository: model.container.cards,
                                    provider: model.settings.aiProvider,
                                    baseURL: model.settings.aiBaseURL,
                                    modelName: model.settings.aiModelName,
                                    currentSpread: model.spread
                                )
        case .biorhythm:        BiorhythmView(model: model)
        case .lunar:            LunarPhasesView()
        case .natal:            NatalChartView(model: model)
        case .soulLink:         SharedDestinyView(soulLinks: model.container.soulLinks)
        }
    }
}
