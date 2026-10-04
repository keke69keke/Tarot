import SwiftUI
import TarotCore
import TarotData

/// Sincronía de Almas — vínculos reales con resonancia calculada y persistida.
struct SharedDestinyView: View {
    @ObservedObject var soulLinks: SoulLinkService

    @State private var selectedID: String?
    @State private var showingAdd = false
    @State private var isSyncing = false
    /// El aro de resonancia se llena al entrar y queda latiendo despacio.
    @State private var barrido: Double = 0
    @State private var pulso = false

    private var selected: SoulLink? {
        if let selectedID, let match = soulLinks.activeLinks.first(where: { $0.partnerID == selectedID }) {
            return match
        }
        return soulLinks.activeLinks.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LuxuryVignette()

                if soulLinks.activeLinks.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Almas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.tarotGold)
                    }
                    .accessibilityLabel("Vincular un alma")
                }
            }
            .onAppear {
                // QA: `-soul-demo` crea un vínculo de ejemplo para revisar la sección.
                if ProcessInfo.processInfo.arguments.contains("-soul-demo"), soulLinks.activeLinks.isEmpty {
                    let link = soulLinks.addLink(partnerName: "Alma Espejo")
                    selectedID = link.partnerID
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSoulSheet { name, birthDate in
                    let link = soulLinks.addLink(partnerName: name, birthDate: birthDate)
                    selectedID = link.partnerID
                    HapticManager.shared.triggerSuccess()
                }
            }
            .tarotNightBackground()
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.tarotGold.opacity(0.10)).frame(width: 120, height: 120).blur(radius: 16)
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Color.tarotGold)
            }
            Text("Aún no hay almas vinculadas")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotIvory)
            Text("Vincula a alguien para calcular la resonancia energética entre ustedes: sinergia, atracción y karma.")
                .font(.system(size: 13, weight: .light, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 36)

            Button {
                showingAdd = true
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "link")
                    Text("Vincular un alma")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                }
            }
            .buttonStyle(LuxuryPrimaryButtonStyle())
            .frame(maxWidth: 320)
            .padding(.top, 6)
        }
        .padding(24)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LuxuryPage(maxWidth: 720) {
                VStack(alignment: .leading, spacing: 22) {
                    if soulLinks.activeLinks.count > 1 {
                        soulPicker
                    }

                    if let link = selected {
                        gauge(for: link)
                        insights(for: link)
                        actions(for: link)
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }

    private var soulPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(soulLinks.activeLinks) { link in
                    LuxuryChip(
                        title: link.partnerName,
                        systemImage: "person.fill",
                        isSelected: (selected?.partnerID ?? "") == link.partnerID
                    ) {
                        withAnimation(LuxuryAnimation.softSpring) {
                            selectedID = link.partnerID
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func gauge(for link: SoulLink) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.tarotGold.opacity(0.15), lineWidth: 12)
                    .frame(width: 190, height: 190)
                Circle()
                    .fill(Color.tarotGold.opacity(0.12))
                    .frame(width: 190, height: 190)
                    .blur(radius: 26)
                    .scaleEffect(pulso ? 1.07 : 0.95)
                    .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: pulso)
                Circle()
                    .trim(from: 0, to: max(0.02, link.resonanceScore) * barrido)
                    .stroke(
                        Color.tarotGoldGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(-90))
                    .animation(LuxuryAnimation.slowSpring, value: link.resonanceScore)
                    .onAppear {
                        barrido = 0
                        withAnimation(LuxuryAnimation.slowSpring) { barrido = 1 }
                        pulso = true
                    }

                VStack(spacing: 2) {
                    Text("\(Int(link.resonanceScore * 100))%")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)
                        .contentTransition(.numericText())
                    Text("Resonancia")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .tracking(1.4)
                        .foregroundStyle(Color.tarotIvory.opacity(0.55))
                }
            }

            VStack(spacing: 4) {
                Text("Vínculo Energético con \(link.partnerName)")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.tarotIvory)
                    .fixedSize(horizontal: false, vertical: true)
                Text("El flujo entre ustedes indica una conexión \(soulLinks.description(for: link.resonanceScore))")
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LuxurySpacing.lg)
        .luxuryGlass(cornerRadius: LuxuryRadius.lg)
    }

    private func insights(for link: SoulLink) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Perspectivas del destino")
            VStack(spacing: 14) {
                ForEach(SoulInsights.forLink(link)) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: insight.icon)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color.tarotGold)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(insight.title)
                                .font(.system(size: 13.5, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                            Text(insight.detail)
                                .font(.system(size: 12, weight: .light, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.62))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LuxuryRadius.md, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.16), lineWidth: 0.75)
            )
        }
    }

    private func actions(for link: SoulLink) -> some View {
        VStack(spacing: 12) {
            Button {
                isSyncing = true
                HapticManager.shared.triggerMedium()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    soulLinks.synchronize(link)
                    isSyncing = false
                }
            } label: {
                HStack(spacing: 9) {
                    if isSyncing {
                        ProgressView().progressViewStyle(.circular).tint(Color.tarotIvory)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isSyncing ? "Sincronizando…" : "Sincronizar energías")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                }
            }
            .buttonStyle(LuxuryPrimaryButtonStyle(isEnabled: !isSyncing))
            .disabled(isSyncing)

            Button(role: .destructive) {
                withAnimation(LuxuryAnimation.softSpring) {
                    soulLinks.unlinkSoul(partnerID: link.partnerID)
                    selectedID = soulLinks.activeLinks.first?.partnerID
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "person.badge.minus")
                    Text("Desvincular")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                }
                .foregroundStyle(Color.tarotIvory.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(LuxurySecondaryButtonStyle())
        }
    }
}

// MARK: - Alta de un alma

private struct AddSoulSheet: View {
    let onAdd: (String, Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var includeBirthDate = false
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @FocusState private var nameFocused: Bool

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                LuxuryPage(maxWidth: 520) {
                    VStack(alignment: .leading, spacing: 20) {
                        LuxurySectionHeader(
                            eyebrow: "Nuevo vínculo",
                            title: "Vincular un alma",
                            subtitle: "El nombre basta. Si añades la fecha de nacimiento, la resonancia será más precisa."
                        )
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            EyebrowLabel(text: "Nombre")
                            TextField("¿Cómo se llama?", text: $name)
                                .font(.system(size: 15, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                                .padding(14)
                                .luxuryGlass(cornerRadius: 14)
                                .focused($nameFocused)
                                .submitLabel(.done)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $includeBirthDate) {
                                Text("Añadir fecha de nacimiento")
                                    .font(.system(size: 13.5, weight: .medium, design: .serif))
                                    .foregroundStyle(Color.tarotIvory)
                            }
                            .toggleStyle(LuxuryToggleStyle())

                            if includeBirthDate {
                                DatePicker("", selection: $birthDate, in: Date(timeIntervalSince1970: 0)...Date(), displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Color.tarotGold)
                                    .padding(12)
                                    .luxuryGlass(cornerRadius: 14)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Vincular")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Vincular") {
                        onAdd(name, includeBirthDate ? birthDate : nil)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { nameFocused = true }
        }
        .preferredColorScheme(.dark)
    }
}


// MARK: - Lecturas derivadas (capa de presentación)

struct SoulInsight: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

enum SoulInsights {
    static func forLink(_ link: SoulLink) -> [SoulInsight] {
        let score = link.resonanceScore
        let seed = SoulLinkService.stableHash(link.partnerName)

        func pick(_ options: [String], _ mod: Int) -> String {
            options[abs(seed + mod) % options.count]
        }

        if score > 0.85 {
            return [
                SoulInsight(icon: "sparkles", title: "Sinergia", detail: pick(["Sintonicidad excepcional: se potencian en casi todos los planos.", "Vuestros ritmos internos se alinean y se refuerzan."], 1)),
                SoulInsight(icon: "heart.fill", title: "Atracción", detail: pick(["Magnetismo profundo: complementáis luces y sombras.", "Atracción estable que crece con la intimidad."], 2)),
                SoulInsight(icon: "arrow.triangle.2.circlepath", title: "Karma", detail: pick(["Vínculo antiguo orientado a la expansión compartida.", "Almas que se reconocen: propósito común de crecimiento."], 3))
            ]
        } else if score > 0.7 {
            return [
                SoulInsight(icon: "sparkles", title: "Sinergia", detail: pick(["Buena compatibilidad emocional y espiritual.", "Colaboración fluida con espacios propios bien definidos."], 1)),
                SoulInsight(icon: "heart.fill", title: "Atracción", detail: pick(["Tensión creativa que mantiene vivo el interés.", "Química sólida basada en la complementariedad."], 2)),
                SoulInsight(icon: "arrow.triangle.2.circlepath", title: "Karma", detail: pick(["Vínculo que pide paciencia y presencia.", "Aprendizaje mutuo sobre límites y confianza."], 3))
            ]
        } else if score > 0.5 {
            return [
                SoulInsight(icon: "sparkles", title: "Sinergia", detail: pick(["Conexión en crecimiento: requiere tiempo y escucha.", "Base amable; el vínculo se fortalece con constancia."], 1)),
                SoulInsight(icon: "heart.fill", title: "Atracción", detail: pick(["Atracción intermitente, sensible al contexto.", "Interés sincero que madura despacio."], 2)),
                SoulInsight(icon: "arrow.triangle.2.circlepath", title: "Karma", detail: pick(["Vínculo de aprendizaje sobre autonomía.", "Espejo de patrones propios por sanar."], 3))
            ]
        } else {
            return [
                SoulInsight(icon: "sparkles", title: "Sinergia", detail: pick(["Energías muy distintas: exige trabajo consciente.", "Ritmos dispares; el equilibrio es la tarea."], 1)),
                SoulInsight(icon: "heart.fill", title: "Atracción", detail: pick(["Fascinación con fricción: claridad ante todo.", "Atracción intensa pero inestable."], 2)),
                SoulInsight(icon: "arrow.triangle.2.circlepath", title: "Karma", detail: pick(["Vínculo de espejo: muestra lo que toca transformar.", "Encuentro kármico orientado a soltar y aprender."], 3))
            ]
        }
    }
}
