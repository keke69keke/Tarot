import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct SettingsView: View {
    @ObservedObject var model: TarotViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        bottomMenuSection
                        optionsSection
                        personalizationSection
                        appearanceSection
                        notificationsSection
                        openAISection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle(TarotStrings.settingsTitle.localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
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

    private var optionsSection: some View {
        luxurySection(title: TarotStrings.options.localized, systemImage: "slider.horizontal.3") {
            Toggle(TarotStrings.allowReversed.localized, isOn: $model.settings.allowReversedCards)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .tint(Color.tarotGold)
        }
    }

    private var bottomMenuSection: some View {
        luxurySection(title: TarotStrings.bottomMenu.localized, systemImage: "square.grid.2x2") {
            ForEach(model.settings.activeTabs) { tab in
                HStack(spacing: 12) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 13, weight: .light))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.tarotGold)
                    Text(tab.label)
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.tarotIvory.opacity(0.3))
                }
            }

            if !model.settings.inactiveTabs.isEmpty {
                Divider().overlay(Color.tarotGold.opacity(0.15))
                ForEach(model.settings.inactiveTabs) { tab in
                    HStack(spacing: 12) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 13, weight: .light))
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.tarotIvory.opacity(0.45))
                        Text(tab.label)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.55))
                        Spacer()
                        Button {
                            if let idx = model.settings.inactiveTabs.firstIndex(of: tab) {
                                model.settings.inactiveTabs.remove(at: idx)
                                model.settings.activeTabs.append(tab)
                                model.persistSettings()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(Color.tarotGold)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Arrastra para reordenar · Desliza para ocultar · Toca ＋ para mostrar")
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.4))
                .padding(.top, 4)
        }
    }

    private func luxurySection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.tarotGold)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.6)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                    .textCase(.uppercase)
            }
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .luxuryGlass(cornerRadius: 20)
        }
    }

    private var notificationsSection: some View {
        luxurySection(title: TarotStrings.notifications.localized, systemImage: "bell") {
            Toggle(TarotStrings.dailyReminder.localized, isOn: $model.settings.notificationsEnabled)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .tint(Color.tarotGold)
            if model.settings.notificationsEnabled {
                Stepper(String(format: TarotStrings.notificationHour.localized, model.settings.dailyNotificationHour), value: $model.settings.dailyNotificationHour, in: 6...22)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .tint(Color.tarotGold)
            }
        }
    }

    private var openAISection: some View {
        luxurySection(title: TarotStrings.integration.localized, systemImage: "brain.head.profile") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.tarotGold)
                    Text(TarotStrings.openAIKey.localized)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                }
                Text(TarotStrings.openAIDescription.localized)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.55))
                    .lineSpacing(2)
            }

            SecureField(TarotStrings.openAIKeyPlaceholder.localized, text: $model.settings.openAIKey)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.tarotIvory)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.tarotGold.opacity(0.2), lineWidth: 0.75)
                )
                .onChange(of: model.settings.openAIKey) { _ in model.persistSettings() }

            if !model.settings.openAIKey.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tarotGold)
                    Text(TarotStrings.openAIKeyConfigured.localized)
                        .font(.caption)
                        .foregroundStyle(Color.tarotGold)
                }
            }
        }
    }

    private var personalizationSection: some View {
        luxurySection(title: TarotStrings.personalization.localized, systemImage: "wand.and.stars") {
            deckPicker
            backPicker
            languagePicker
            Text("Personaliza las cartas, el reverso y el idioma para adaptarlo a tu estilo.")
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.4))
        }
    }

    private var deckPicker: some View {
        Picker("Baraja", selection: deckSelectionBinding) {
            ForEach(DeckType.allCases, id: \.rawValue) { deck in
                Text(deck.displayName).tag(deck.rawValue)
            }
        }
        .font(.system(size: 13, design: .serif))
        .foregroundStyle(Color.tarotIvory)
    }

    private var backPicker: some View {
        Picker("Reverso", selection: backDesignSelectionBinding) {
            ForEach(CardBackDesign.allCases, id: \.rawValue) { design in
                Text(design.displayName).tag(design.rawValue)
            }
        }
        .font(.system(size: 13, design: .serif))
        .foregroundStyle(Color.tarotIvory)
    }

    private var languagePicker: some View {
        Picker("Idioma", selection: languageSelectionBinding) {
            Text(Language.spanish.displayName).tag(Language.spanish.rawValue)
            Text(Language.english.displayName).tag(Language.english.rawValue)
        }
        .font(.system(size: 13, design: .serif))
        .foregroundStyle(Color.tarotIvory)
    }

    private var appearanceSection: some View {
        luxurySection(title: TarotStrings.appearance.localized, systemImage: "paintbrush.pointed") {
            Picker(TarotStrings.theme.localized, selection: appearanceSelectionBinding) {
                Text(Appearance.automatic.displayName).tag(Appearance.automatic.rawValue)
                Text(Appearance.light.displayName).tag(Appearance.light.rawValue)
                Text(Appearance.dark.displayName).tag(Appearance.dark.rawValue)
            }
            .font(.system(size: 13, design: .serif))
            .foregroundStyle(Color.tarotIvory)
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
}
