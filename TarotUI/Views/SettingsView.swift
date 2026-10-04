import SwiftUI
import TarotCore
import TarotData
import TarotDI

struct SettingsView: View {
    @ObservedObject var model: TarotViewModel
    @State private var showSectionsTutorial = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        optionsSection
                        personalizationSection
                        appearanceSection
                        notificationsSection
                        openAISection
                        bottomMenuSection
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
            .onChange(of: model.settings.activeDeck) { _ in model.persistSettings(); PlatformImageLoader.clearCache() }
            .onChange(of: model.settings.cardBackDesign) { _ in model.persistSettings() }
            .onChange(of: model.settings.appearance) { _ in model.persistSettings() }
            .onChange(of: model.settings.dailyNotificationHour) { value in
                model.persistSettings()
                if model.settings.notificationsEnabled {
                    Task { try? await model.container.notifications.scheduleDailyNotification(hour: value) }
                }
            }
            .tarotNightBackground()
        }
    }

    private var optionsSection: some View {
        luxurySection(title: TarotStrings.options.localized, systemImage: "slider.horizontal.3") {
            Toggle(TarotStrings.allowReversed.localized, isOn: $model.settings.allowReversedCards)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .tint(Color.tarotGold)

            Button {
                showSectionsTutorial = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color.tarotGold)
                    Text("Repetir tutorial de secciones")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.tarotIvory.opacity(0.35))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSectionsTutorial) {
            SectionsTutorialView {
                showSectionsTutorial = false
            }
            .preferredColorScheme(.dark)
        }
    }

    private var bottomMenuSection: some View {
        luxurySection(title: TarotStrings.bottomMenu.localized, systemImage: "square.grid.2x2") {
            // Activos — ordenables
            // Capturamos una copia estable del array para que el ForEach no vea
            // el array mutado a mitad de render y crashee.
            let activeTabs = model.settings.activeTabs
            ForEach(activeTabs, id: \.self) { tab in
                HStack(spacing: 12) {
                    Image(systemName: tab.systemImage)
                        .font(.system(size: 13, weight: .light))
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.tarotGold)
                    Text(tab.label)
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    Spacer()
                    HStack(spacing: 10) {
                        // Subir: re-buscamos el índice en el momento del tap (no en render)
                        Button {
                            guard let liveIdx = model.settings.activeTabs.firstIndex(of: tab),
                                  liveIdx > 0 else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                model.settings.activeTabs.move(
                                    fromOffsets: IndexSet(integer: liveIdx),
                                    toOffset: liveIdx - 1
                                )
                                model.persistSettings()
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(
                                    (activeTabs.firstIndex(of: tab) ?? 0) > 0
                                        ? Color.tarotIvory.opacity(0.55)
                                        : Color.clear
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled((activeTabs.firstIndex(of: tab) ?? 0) == 0)

                        // Bajar
                        Button {
                            guard let liveIdx = model.settings.activeTabs.firstIndex(of: tab),
                                  liveIdx < model.settings.activeTabs.count - 1 else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                model.settings.activeTabs.move(
                                    fromOffsets: IndexSet(integer: liveIdx),
                                    toOffset: liveIdx + 2   // move(fromOffsets:toOffset:) usa índice post-remove
                                )
                                model.persistSettings()
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(
                                    (activeTabs.firstIndex(of: tab) ?? 0) < activeTabs.count - 1
                                        ? Color.tarotIvory.opacity(0.55)
                                        : Color.clear
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled((activeTabs.firstIndex(of: tab) ?? 0) >= activeTabs.count - 1)

                        // Tabs obligatorios: siempre visibles (la app los restaura al guardar).
                        if tab == .settings || TarotViewModel.mandatoryTabs.contains(tab) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Color.tarotIvory.opacity(0.55))
                                .accessibilityLabel("Obligatorio")
                        } else {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    model.settings.activeTabs.removeAll { $0 == tab }
                                    if !model.settings.inactiveTabs.contains(tab) {
                                        model.settings.inactiveTabs.append(tab)
                                    }
                                    model.persistSettings()
                                }
                            } label: {
                                Image(systemName: "eye.slash")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundStyle(Color.tarotIvory.opacity(0.35))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }

            let visibleInactive = model.settings.inactiveTabs.filter { $0 != .settings }
            if !visibleInactive.isEmpty {
                Divider().overlay(Color.tarotGold.opacity(0.15)).padding(.vertical, 4)
                Text(TarotStrings.hiddenTabsHint.localized)
                    .font(.system(size: 10, weight: .semibold, design: .serif)).tracking(0.8)
                    .foregroundStyle(Color.tarotIvory.opacity(0.35)).textCase(.uppercase)
                ForEach(visibleInactive, id: \.self) { tab in
                    HStack(spacing: 12) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 13, weight: .light))
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.tarotIvory.opacity(0.45))
                        Text(tab.label)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.55))
                        Spacer()

                        // Indicador de límite (8 tabs activos)
                        let atLimit = model.settings.activeTabs.count >= 8
                        if atLimit {
                            Text("Límite 8")
                                .font(.system(size: 9, weight: .semibold, design: .serif))
                                .tracking(0.5)
                                .foregroundStyle(Color.tarotGold.opacity(0.55))
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Capsule().fill(Color.tarotGold.opacity(0.10)))
                                .overlay(Capsule().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.5))
                        } else {
                            Button {
                                // Re-buscamos el índice en el momento del tap para evitar
                                // índices obsoletos si el array cambió desde el render.
                                guard let liveIdx = model.settings.inactiveTabs.firstIndex(of: tab) else { return }
                                guard model.settings.activeTabs.count < 8 else { return }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    model.settings.inactiveTabs.remove(at: liveIdx)
                                    if !model.settings.activeTabs.contains(tab) {
                                        model.settings.activeTabs.append(tab)
                                    }
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
                    .padding(.vertical, 4)
                }
            }

            Text("Toca ↑↓ para reordenar · Toca el ojo para ocultar · Toca ＋ para mostrar. Máximo 8 tabs activos. Los tabs con candado son obligatorios.")
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.35))
                .padding(.top, 6)
                .lineSpacing(2)
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
        luxurySection(title: "Inteligencia Artificial", systemImage: "brain.head.profile") {

            // --- Motor activo: una sola eleccion, plegada ---
            // Antes se listaban los seis proveedores a la vez, cada uno con su
            // descripcion, modelo, URL y clave: la seccion era un muro de ajustes.
            // Ahora se muestra solo el motor elegido y se cambia desde un
            // desplegable; el resto de campos vive en "Opciones avanzadas".
            VStack(alignment: .leading, spacing: 10) {
                Text("Motor")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                    .textCase(.uppercase)

                Menu {
                    ForEach(AIProvider.allCases) { p in
                        Button {
                            model.settings.aiProvider = p
                            if model.settings.aiModelName.isEmpty || !isCustomModel {
                                model.settings.aiModelName = ""
                            }
                            model.persistSettings()
                        } label: {
                            if model.settings.aiProvider == p {
                                Label(p.displayName, systemImage: "checkmark")
                            } else {
                                Text(p.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: model.settings.aiProvider.systemImage)
                            .font(.system(size: 14, weight: .light))
                            .frame(width: 22)
                            .foregroundStyle(Color.tarotGold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.settings.aiProvider.displayName)
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                            Text(model.settings.aiProvider.hint)
                                .font(.system(size: 10, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.45))
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(Color.tarotIvory.opacity(0.45))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            // --- Estado del motor elegido: por que responde o por que no ---
            estadoDelMotor

            // --- Seguridad: donde vive la clave ---
            if !model.settings.aiProvider.isLocal {
                seguridadDeLaClave
            }

            // --- Opciones avanzadas, plegadas ---
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 16) {
                    campoAvanzado(
                        titulo: "Modelo",
                        ayuda: "por defecto: \(model.settings.aiProvider.defaultModel)",
                        texto: $model.settings.aiModelName,
                        placeholder: model.settings.aiProvider.defaultModel,
                        esURL: false
                    )
                    campoAvanzado(
                        titulo: "URL base",
                        ayuda: model.settings.aiProvider.defaultBaseURL.isEmpty
                            ? "sin valor por defecto"
                            : "por defecto: \(model.settings.aiProvider.defaultBaseURL)",
                        texto: $model.settings.aiBaseURL,
                        placeholder: model.settings.aiProvider.defaultBaseURL.isEmpty ? "https://…" : model.settings.aiProvider.defaultBaseURL,
                        esURL: true
                    )
                    Text("Se añade /v1/chat/completions automaticamente.")
                        .font(.system(size: 9, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.30))
                }
                .padding(.top, 10)
            } label: {
                Text("Opciones avanzadas")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.85))
            }
            .tint(Color.tarotGold)
        }
    }

    /// Explica en una linea por que el motor elegido responde o no.
    @ViewBuilder
    private var estadoDelMotor: some View {
        let p = model.settings.aiProvider
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: p == .apple ? "lock.shield.fill" : (p.isLocal ? "house.circle.fill" : "lock.circle.fill"))
                .font(.caption)
                .foregroundStyle(Color.tarotGold.opacity(0.85))
            VStack(alignment: .leading, spacing: 2) {
                if p == .apple {
                    Text("Apple Intelligence se ejecuta en este dispositivo.")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.80))
                    Text(estadoAppleTexto)
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(ArcanaIntelligenceRouter.appleAvailable ? Color.tarotGold : Color.tarotIvory.opacity(0.50))
                } else if p.isLocal {
                    Text("Proveedor local — sin clave y sin salir del equipo. Asegurate de tener \(p.displayName) corriendo.")
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.50))
                } else {
                    Text("La clave se guarda cifrada en el Llavero del dispositivo, nunca en texto plano.")
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.50))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tarotGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// Estado real de Apple Intelligence, para que se pueda diagnosticar.
    private var estadoAppleTexto: String {
        if ArcanaIntelligenceRouter.appleAvailable {
            return "Disponible y listo."
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let motivo = AppleArcanaModel.unavailableReason {
                return "No disponible: \(motivo)."
            }
        }
        return "No disponible en este dispositivo o version del sistema."
        #else
        return "No disponible: el sistema no expone Foundation Models."
        #endif
    }

    /// Seguridad de la clave: estado visible y borrado explicito.
    private var seguridadDeLaClave: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clave de API")
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tarotIvory)

            SecureField("sk-… / gsk_… / tu clave", text: $model.settings.aiApiKey)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.tarotIvory)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.75))
                .onChange(of: model.settings.aiApiKey) { _ in model.persistSettings() }

            HStack(spacing: 6) {
                Image(systemName: model.settings.aiApiKey.isEmpty ? "key.slash" : "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(model.settings.aiApiKey.isEmpty ? Color.tarotIvory.opacity(0.40) : Color.tarotGold)
                Text(model.settings.aiApiKey.isEmpty
                     ? "Sin clave guardada."
                     : "Clave guardada cifrada en el Llavero del dispositivo.")
                    .font(.system(size: 10, design: .serif))
                    .foregroundStyle(model.settings.aiApiKey.isEmpty ? Color.tarotIvory.opacity(0.40) : Color.tarotGold)

                Spacer()

                if !model.settings.aiApiKey.isEmpty {
                    Button {
                        model.settings.aiApiKey = ""
                        model.persistSettings()
                    } label: {
                        Text("Borrar")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.tarotBurgundy)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Campo de las opciones avanzadas, con estilo coherente.
    private func campoAvanzado(titulo: String, ayuda: String, texto: Binding<String>, placeholder: String, esURL: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(titulo)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text("· \(ayuda)")
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.35))
                    .lineLimit(1)
            }
            TextField(placeholder, text: texto)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.tarotIvory)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .keyboardType(esURL ? .URL : .default)
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.75))
                .onChange(of: texto.wrappedValue) { _ in model.persistSettings() }
        }
    }

    private var isCustomModel: Bool {
        let raw = model.settings.aiModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !raw.isEmpty && raw != model.settings.aiProvider.defaultModel
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Baraja")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                    .textCase(.uppercase)
                Text("· \(DeckType.allCases.count) disponibles")
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.35))
            }
            ForEach(DeckType.allCases, id: \.rawValue) { deck in
                DeckRow(deck: deck, isSelected: model.settings.activeDeck == deck) {
                    model.settings.activeDeck = deck
                    model.persistSettings()
                }
            }
        }
        .onAppear {
            // We no longer force Rider-Waite if current deck lacks dedicated artwork,
            // as we now support tinted generic decks.
        }
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

private struct DeckRow: View {
    let deck: DeckType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini texture preview
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.tarotCardBase)
                    CardTextureOverlayView(cardSize: CGSize(width: 36, height: 48), textureStyle: deck.textureStyle)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    if let tint = deck.tintColor {
                        Color(red: tint.r, green: tint.g, blue: tint.b)
                            .opacity(tint.opacity * 1.8)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .blendMode(.multiply)
                    }
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                }
                .frame(width: 36, height: 48)
                .overlay(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.tarotGold.opacity(0.55), lineWidth: 1.1)
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(deck.displayName)
                            .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium, design: .serif))
                            .foregroundStyle(isSelected ? Color.tarotIvory : Color.tarotIvory.opacity(0.86))
                            .lineLimit(2)
                        if !deck.hasDedicatedArtwork {
                            Text("TEXTURA")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundStyle(Color.tarotGold.opacity(0.9))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Capsule().fill(Color.tarotGold.opacity(0.12)))
                                .overlay(Capsule().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.5))
                        }
                    }
                    Text(deck.description)
                        .font(.system(size: 10.5, weight: .regular, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.52))
                        .lineSpacing(1.5)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color.tarotGold)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.18))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.tarotGold.opacity(0.08) : Color.white.opacity(0.04))
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial).opacity(isSelected ? 0.45 : 0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.tarotGold.opacity(0.28) : Color.white.opacity(0.07), lineWidth: isSelected ? 0.9 : 0.6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deck.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
