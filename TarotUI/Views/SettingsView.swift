import SwiftUI
import TarotCore
import TarotData

struct SettingsView: View {
    @ObservedObject var model: TarotViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(model.settings.activeTabs) { tab in
                        HStack(spacing: 12) {
                            Image(systemName: tab.systemImage)
                                .frame(width: 26, height: 26)
                                .foregroundStyle(Color.tarotGold)
                            Text(tab.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onMove { source, destination in
                        model.settings.activeTabs.move(fromOffsets: source, toOffset: destination)
                        model.persistSettings()
                    }
                    .onDelete { offsets in
                        let removed = offsets.map { model.settings.activeTabs[$0] }
                        model.settings.activeTabs.remove(atOffsets: offsets)
                        model.settings.inactiveTabs.append(contentsOf: removed)
                        model.persistSettings()
                    }

                    if !model.settings.inactiveTabs.isEmpty {
                        inactiveTabsSection
                    }
                } header: {
                    Label("Menú inferior", systemImage: "square.grid.2x2")
                } footer: {
                    Text("Arrastra para reordenar · Desliza para ocultar · Toca ＋ para mostrar")
                }

                personalizationSection

                Section("Opciones") {
                    Toggle("Permitir cartas invertidas", isOn: $model.settings.allowReversedCards)
                }

                appearanceSection

                notificationsSection

                openAISection
            }
            .formStyle(.grouped)
            .navigationTitle("Ajustes")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            #endif
            .onChange(of: model.settings.allowReversedCards) { _ in model.persistSettings() }
            .onChange(of: model.settings.notificationsEnabled) { value in
                model.persistSettings()
                if value {
                    Task { try? await model.container.notifications.scheduleDailyNotification(hour: model.settings.dailyNotificationHour) }
                } else {
                    Task { await model.container.notifications.cancelDailyNotification() }
                }
            }
            .onChange(of: model.settings.selectedLanguage) { _ in model.persistSettings() }
            .onChange(of: model.settings.activeDeck) { _ in model.persistSettings() }
            .onChange(of: model.settings.cardBackDesign) { _ in model.persistSettings() }
            .onChange(of: model.settings.appearance) { _ in model.persistSettings() }
            .onChange(of: model.settings.dailyNotificationHour) { value in
                model.persistSettings()
                if model.settings.notificationsEnabled {
                    Task { try? await model.container.notifications.scheduleDailyNotification(hour: value) }
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section("Recordatorios") {
            Toggle("Recordatorio diario", isOn: $model.settings.notificationsEnabled)
            if model.settings.notificationsEnabled {
                Stepper("Hora de notificación: \(model.settings.dailyNotificationHour):00", value: $model.settings.dailyNotificationHour, in: 6...22)
            }
        }
    }

    private var openAISection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("API Key de OpenAI", systemImage: "brain.head.profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Opcional. Sin API key, Arcana IA usa el motor local de tarot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            SecureField("sk-...", text: $model.settings.openAIKey)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onChange(of: model.settings.openAIKey) { _ in model.persistSettings() }

            if !model.settings.openAIKey.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("API Key configurada")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text("Integración")
        }
    }

    // MARK: - Computed Properties for Pickers (simplified)

    private var personalizationSection: some View {
        Section(header: Text("Personalización"), footer: Text("Personaliza las cartas, el reverso y el idioma para adaptarlo a tu estilo.")) {
            deckPicker
            backPicker
            languagePicker
        }
    }

    private var deckPicker: some View {
        Picker("Baraja", selection: deckSelectionBinding) {
            ForEach(DeckType.allCases, id: \.rawValue) { deck in
                Text(deck.displayName).tag(deck.rawValue)
            }
        }
    }

    private var backPicker: some View {
        Picker("Reverso", selection: backDesignSelectionBinding) {
            ForEach(CardBackDesign.allCases, id: \.rawValue) { design in
                Text(design.displayName).tag(design.rawValue)
            }
        }
    }

    private var languagePicker: some View {
        Picker("Idioma", selection: languageSelectionBinding) {
            Text(Language.spanish.displayName).tag(Language.spanish.rawValue)
            Text(Language.english.displayName).tag(Language.english.rawValue)
        }
    }

    private var appearanceSection: some View {
        Section(header: Text("Apariencia")) {
            Picker("Tema", selection: appearanceSelectionBinding) {
                Text(Appearance.automatic.displayName).tag(Appearance.automatic.rawValue)
                Text(Appearance.light.displayName).tag(Appearance.light.rawValue)
                Text(Appearance.dark.displayName).tag(Appearance.dark.rawValue)
            }
        }
    }

    private var inactiveTabsSection: some View {
        Section {
            Divider()
                .listRowInsets(EdgeInsets())
            ForEach(model.settings.inactiveTabs) { tab in
                inactiveTabRow(for: tab)
            }
        }
    }

    private func inactiveTabRow(for tab: AppTab) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tab.systemImage)
                .frame(width: 26, height: 26)
                .foregroundStyle(.secondary)
            Text(tab.label)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                if let idx = model.settings.inactiveTabs.firstIndex(of: tab) {
                    model.settings.inactiveTabs.remove(at: idx)
                    model.settings.activeTabs.append(tab)
                    model.persistSettings()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.tarotGold)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private var deckSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.activeDeck.rawValue },
            set: {
                model.settings.activeDeck = DeckType(rawValue: $0) ?? .riderWaite
                model.persistSettings()
            }
        )
    }

    private var backDesignSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.cardBackDesign.rawValue },
            set: {
                model.settings.cardBackDesign = CardBackDesign(rawValue: $0) ?? .classic
                model.persistSettings()
            }
        )
    }

    private var languageSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.selectedLanguage.rawValue },
            set: {
                model.settings.selectedLanguage = Language(rawValue: $0) ?? .spanish
                model.persistSettings()
            }
        )
    }

    private var appearanceSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.appearance.rawValue },
            set: {
                model.settings.appearance = Appearance(rawValue: $0) ?? .automatic
                model.persistSettings()
            }
        )
    }

    // Removed complex Pickers to resolve type-checking issues
    // Settings are still functional with essential toggles
}
