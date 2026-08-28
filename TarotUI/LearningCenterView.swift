import SwiftUI
import TarotCore

// MARK: - Book Cover Colors (deterministic from title hash)
private func bookCoverGradient(for title: String) -> [Color] {
    let palettes: [[Color]] = [
        [Color.tarotGoldDeep, Color.tarotGoldDeep.opacity(0.4)],
        [Color.tarotGold, Color.tarotGoldDeep],
        [Color.tarotGoldHighlight, Color.tarotGold],
        [Color.tarotGold, Color.tarotGoldHighlight],
        [Color.tarotGoldDeep, Color.tarotGold],
        [Color.tarotGoldHighlight, Color.tarotGoldDeep],
        [Color.tarotGold, Color.tarotGold.opacity(0.6)],
        [Color.tarotGoldDeep, Color.tarotGoldHighlight],
        [Color.tarotGoldHighlight, Color.tarotGoldDeep],
    ]
    let idx = abs(title.hashValue) % palettes.count
    return palettes[idx]
}

private func bookCoverIcon(for title: String) -> String {
    let icons = ["books.vertical.fill", "scroll.fill", "moon.stars.fill", "sparkles",
                 "flame.fill", "leaf.fill", "star.fill", "eye.fill", "atom", "wand.and.stars", "sun.max.fill", "moon.fill"]
    return icons[abs(title.hashValue) % icons.count]
}

// MARK: - Premium Book Cover Card
private struct EsotericBookCover: View {
    let title: String
    let subtitle: String
    let size: CGSize
    @State private var hovered = false

    var body: some View {
        let colors = bookCoverGradient(for: title)
        let icon = bookCoverIcon(for: title)

        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            Canvas { context, sz in
                let step: CGFloat = 22
                var p = Path()
                for x in stride(from: -sz.height, to: sz.width + sz.height, by: step) {
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + sz.height, y: sz.height))
                    p.move(to: CGPoint(x: x, y: sz.height))
                    p.addLine(to: CGPoint(x: x + sz.height, y: 0))
                }
                context.stroke(p, with: .color(Color.tarotIvory.opacity(0.06)), lineWidth: 0.75)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.tarotIvory.opacity(0.25))
                        .padding(12)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.60))
                    .lineLimit(1)
            }
            .padding(10)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(colors: [Color.tarotGold.opacity(0.6),
                                             Color.tarotGold.opacity(0.15)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.75
                )
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(hovered ? 1.03 : 1.0)
        .shadow(color: Color.tarotGold.opacity(0.3), radius: hovered ? 18 : 10, x: 0, y: 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .onHover { hovered = $0 }
    }
}

// MARK: - LearningCenterView
@MainActor
public struct LearningCenterView: View {
    @StateObject private var libraryManager = LibraryManager()
    @State private var showingFilePicker = false
    @State private var showingBrowser = false
    @State private var selectedSection: LibrarySection = .books
    @State private var animateIn = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                 Color.tarotBackground
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerView
                            .padding(.bottom, 20)

                        MysticMusicPlayerBar()
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        sectionTabs
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        switch selectedSection {
                        case .books: booksSection
                        case .spreads: spreadsInfoSection
                        case .tools: toolsSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    if case .success(let urls) = result, let url = urls.first {
                        try? libraryManager.importPDF(from: url)
                    }
                }
            }
            .sheet(isPresented: $showingBrowser) {
                NavigationStack {
                    TarotWebBrowserView(libraryManager: libraryManager)
                        .navigationTitle("Navegador Arcano")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
.toolbar {
                            #if os(iOS)
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Cerrar") { showingBrowser = false }
                            }
                            #else
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Cerrar") { showingBrowser = false }
                            }
                            #endif
                        }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                         Text("Biblioteca Arcana")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .tracking(-0.6)
                            .foregroundStyle(Color.tarotIvory)
                        Text("Sabiduría Esotérica · \(libraryManager.importedBooks.count) libros")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.68))
                }
                 Spacer()
                 Image(systemName: "books.vertical.fill")
                     .font(.system(size: 28))
                     .foregroundStyle(Color.tarotGold.opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
    }

    // MARK: - Section Tabs
    private var sectionTabs: some View {
         HStack(spacing: 0) {
            ForEach(LibrarySection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon).font(.caption)
                        Text(section.label).font(.system(size: 13, weight: .semibold, design: .serif))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        selectedSection == section
                            ? Color.tarotGold.opacity(0.20)
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedSection == section
                            ? Color.tarotGold
                            : Color.tarotIvory.opacity(0.45)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedSection == section
                                    ? Color.tarotGold.opacity(0.5)
                                    : Color.clear, lineWidth: 0.75)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.tarotPanel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.13), lineWidth: 0.75)
        )
    }

    // MARK: - Books Section
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            quickActionsBar.padding(.horizontal)

            if !libraryManager.pinnedBookmarks.isEmpty {
                pinnedBookmarksSection.padding(.horizontal)
            }
            if !libraryManager.bookmarks.isEmpty {
                bookmarksSection.padding(.horizontal)
            }

            sectionLabel("📖 Guía Integrada").padding(.horizontal)
            NavigationLink(destination: PDFBookView(book: builtInGuideBook, libraryManager: libraryManager)) {
                builtInBookRow
            }
            .padding(.horizontal)

            sectionLabel("🎓 Escuela de Tarot").padding(.horizontal)
            schoolSection.padding(.horizontal)

            if libraryManager.importedBooks.isEmpty {
                emptyLibraryView.padding(.horizontal)
            } else {
                sectionLabel("📚 Biblioteca Esotérica — \(libraryManager.importedBooks.count) obras").padding(.horizontal)
                bookGrid
            }
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }

    private var quickActionsBar: some View {
        HStack(spacing: 10) {
            quickActionButton(icon: "safari.fill", label: "Navegador", color: Color.tarotGold) {
                showingBrowser = true
            }
            quickActionButton(icon: "doc.badge.plus", label: "Importar PDF", color: Color.tarotGold) {
                showingFilePicker = true
            }
            NavigationLink(destination: SecretVaultView()) {
                VStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 20))
                    Text("Bóveda").font(.system(size: 11, weight: .bold, design: .serif))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.tarotPanel)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.tarotGold.opacity(0.6), lineWidth: 0.75))
                .foregroundStyle(Color.tarotGold)
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: 11, weight: .bold, design: .serif))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.tarotPanel)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.5), lineWidth: 0.75))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    private var pinnedBookmarksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.tarotGold)
                Text("Fijados — acceso rápido").font(.system(size: 11, weight: .bold, design: .serif)).tracking(1.1).foregroundStyle(Color.tarotGold).textCase(.uppercase)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(libraryManager.pinnedBookmarks) { bm in
                        Button { showingBrowser = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(Color.tarotGold)
                                Text(bm.title.isEmpty ? bm.url : bm.title).font(.system(size: 12, weight: .medium, design: .serif)).foregroundStyle(Color.tarotIvory).lineLimit(1)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(Color.tarotGold.opacity(0.12)).background(Capsule().fill(.ultraThinMaterial).opacity(0.35)))
                            .overlay(Capsule().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))
                        }.buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { libraryManager.removeBookmark(bm) } label: { Label("Eliminar", systemImage: "trash") }
                            Button { libraryManager.togglePin(bm) } label: { Label("Desfijar", systemImage: "pin.slash") }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.04)).background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial).opacity(0.28)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tarotGold.opacity(0.14), lineWidth: 0.7))
    }

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.tarotGold.opacity(0.85))
                Text("Favoritos — \(libraryManager.bookmarks.count)").font(.system(size: 11, weight: .bold, design: .serif)).tracking(1.1).foregroundStyle(Color.tarotIvory.opacity(0.7)).textCase(.uppercase)
                Spacer()
            }
            ForEach(libraryManager.bookmarks.prefix(5)) { bm in
                HStack(spacing: 10) {
                    Image(systemName: bm.isPinned ? "pin.fill" : "star").font(.system(size: 11)).foregroundStyle(bm.isPinned ? Color.tarotGold : Color.tarotIvory.opacity(0.45))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bm.title.isEmpty ? bm.url : bm.title).font(.system(size: 12, weight: .medium, design: .serif)).foregroundStyle(Color.tarotIvory).lineLimit(1)
                        Text(bm.url).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.tarotIvory.opacity(0.45)).lineLimit(1)
                    }
                    Spacer()
                    Button { libraryManager.togglePin(bm) } label: {
                        Image(systemName: bm.isPinned ? "pin.slash" : "pin").font(.system(size: 12)).foregroundStyle(Color.tarotGold.opacity(0.85))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.03)))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 0.6))
                .contextMenu { Button(role: .destructive) { libraryManager.removeBookmark(bm) } label: { Label("Eliminar", systemImage: "trash") } }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.6))
    }

    private var builtInGuideBook: ImportedBook {
        ImportedBook(
            title: "Guía Definitiva del Tarot",
            fileName: "rider_waite_guide.pdf"
        )
    }

    private var builtInBookRow: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Color.tarotGoldDeep, Color.tarotGoldDeep.opacity(0.4)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 72)
                Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(Color.tarotGold)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Guía Definitiva del Tarot")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text("Fiebig & Bürger · Rider-Waite · Incluida")
                    .font(.system(size: 11, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.55))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.tarotIvory.opacity(0.3)).font(.caption)
        }
        .padding(14)
        .background(Color.tarotPanel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.75))
    }

    private var bookGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
            ForEach(libraryManager.importedBooks) { book in
                NavigationLink(destination: PDFBookView(book: book, libraryManager: libraryManager)) {
                    EsotericBookCover(title: book.title, subtitle: book.fileName, size: CGSize(width: 160, height: 220))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        libraryManager.deleteBook(book)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Escuela de Tarot
    private var schoolSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(schoolCourses) { course in
                    NavigationLink(destination: SchoolCourseView(course: course)) {
                        EsotericBookCover(title: course.title, subtitle: "Curso · \(course.lessons.count) lecciones", size: CGSize(width: 220, height: 140))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

 private var schoolCourses: [SchoolCourse] {
        [
            SchoolCourse(
                title: "Interpretación de Arcanos",
                icon: "arcade.stick",
                color: Color.tarotGold,
                summary: "Domina los 22 Mayores y 56 Menores: arquetipos, símbolos y lectura contextual profunda.",
                lessons: [
                    SchoolLesson(title: "Los Arcanos Mayores — El Viaje del Héroe", subtitle: "22 arquetipos del alma", icon: "star.fill", content: "Los Mayores narran el Viaje del Héroe (Campbell) desde El Loco (0, potencial puro, Aleph, Urano) hasta El Mundo (21, integración, Saturno). Cada carta es una estación iniciática: El Mago (voluntad, Mercurio), La Papisa (intuición, Luna), La Emperatriz (Venus, creación), El Emperador (Aries, estructura), El Papa (Tauro, tradición), Los Enamorados (Géminis, elección), El Carro (Cáncer, dirección), La Fuerza (Leo, coraje), El Ermitaño (Virgo, introspección), La Rueda (Júpiter, ciclos), La Justicia (Libra, equilibrio), El Colgado (Neptuno, sacrificio), La Muerte (Escorpio, transmutación), La Templanza (Sagitario, alquimia), El Diablo (Capricornio, sombra), La Torre (Marte, ruptura), La Estrella (Acuario, esperanza), La Luna (Piscis, inconsciente), El Sol (Sol, vitalidad), El Juicio (Plutón, renacimiento) y El Mundo (Saturno, culminación).\n\nPráctica: Elige un Mayor que represente tu momento actual y escribe 3 palabras clave, su sombra y su consejo. Medita 5 minutos con la carta frente a ti."),
                    SchoolLesson(title: "Arcanos Menores — La Vida Cotidiana", subtitle: "4 palos × 14 cartas", icon: "suit.club.fill", content: "Los Menores son la vida concreta. Bastos (Fuego, Wands) = acción, creatividad, impulso; Copas (Agua) = emociones, vínculos, intuición; Espadas (Aire) = mente, verdad, conflicto; Oros/Pentáculos (Tierra) = cuerpo, trabajo, dinero. Cada palo va del As (semilla, potencial puro) al 10 (culminación) y luego las cortes: Paje (aprendiz, mensaje), Caballero (acción, movimiento), Reina (maestría receptiva), Rey (maestría activa).\n\nNumerología: As= inicio, 2= dualidad/decisión, 3= expansión, 4= estabilidad, 5= crisis/cambio, 6= armonía, 7= reflexión/desafío, 8= poder/movimiento, 9= culminación interior, 10= final/completitud.\n\nEjercicio: Para cada palo, ordena del As al Rey y cuenta una historia continua; notarás el arco narrativo."),
                    SchoolLesson(title: "Símbolos, Colores y Numerología", subtitle: "El lenguaje oculto", icon: "number", content: "Cada detalle es un código. Colores: rojo (pasión/voluntad), azul (intuición/inconsciente), amarillo (consciencia), verde (crecimiento), gris (neutralidad). Posturas: figura de pie (acción), sentado (reflexión), de espaldas (inconsciente). Objetos: espadas = mente, bastos = fuego, copas = corazón, oros = materia. Números + palo = matiz: 5 de Espadas es crisis mental, 5 de Copas es pérdida emocional, 5 de Oros es carencia material.\n\nSímbolos recurrentes: Sol blanco (consciencia pura), Luna (ciclo), Montaña (obstáculo/meta), Río (inconsciente), Muralla (protección/límite). Aprende a leerlos como un sueño: ¿qué te provoca cada símbolo?"),
                    SchoolLesson(title: "Lectura Contextual y Combinaciones", subtitle: "De carta aislada a relato", icon: "link", content: "Una carta sola es una palabra; tres cartas son una frase. La clave es la sintaxis posicional. Ejemplo: En pasado-presente-futuro, El Loco (pasado) + La Torre (presente) + La Estrella (futuro) = un inicio ingenuo que hoy se derrumba para abrir esperanza. Las combinaciones modifican: El Diablo + La Estrella = atadura que se libera; La Luna + El Sol = confusión que se aclara.\n\nMétodo: 1) Lee cada carta en su posición (contextual del Deck), 2) Busca el hilo narrativo (¿qué elemento domina? ¿qué palo falta?), 3) Síntesis en una frase oracular que puedas recordar."),
                ]
            ),
            SchoolCourse(
                title: "Tiradas Prácticas",
                icon: "rectangle.stack.fill",
                color: Color.tarotGold,
                summary: "De 1 a 12 cartas: cuándo usar cada tirada y cómo interpretar posiciones con precisión.",
                lessons: [
                    SchoolLesson(title: "Tirada de 3 Cartas — Pasado/Presente/Futuro", subtitle: "La más versátil", icon: "3.circle.fill", content: "Tres cartas, infinitas historias. Posiciones: 1 Pasado (raíz, influencia que te trae aquí), 2 Presente (corazón de la cuestión, energía dominante), 3 Futuro (probabilidad si mantienes el rumbo). No es destino fatal, es tendencia.\n\nVariantes: Mente-Cuerpo-Espíritu; Situación-Acción-Resultado; Tú-Otro-Vínculo. Cada variante reencuadra la misma tríada.\n\nLectura profunda: Mira el elemento dominante. ¿Tres Espadas = mente saturada? ¿Tres Copas = emociones desbordadas? Usa los vacíos: si no hay Oros, falta tierra/acción concreta."),
                    SchoolLesson(title: "Cruz Celta — 10 Cartas", subtitle: "La tirada reina", icon: "xmark.circle.fill", content: "10 posiciones que mapean psique y destino: 1 Presente, 2 Desafío (lo que cruza), 3 Pasado reciente, 4 Futuro próximo, 5 Encima (consciencia/meta), 6 Debajo (inconsciente/base), 7 Consejo (actitud recomendada), 8 Entorno (otros, influencias externas), 9 Esperanzas/Temores, 10 Resultado.\n\nCómo leerla sin abrumarte: Lee primero el eje central (1-2), luego la línea temporal (3-4-10), luego el eje vertical (5-6), finalmente el entorno (7-8-9). La síntesis es la historia que conecta estos cuatro ejes.\n\nPista morada: Las posiciones 1-6 son el diagrama en cruz, 7-10 el bastón lateral — visualiza la cruz, no solo la lista."),
                    SchoolLesson(title: "Herradura, Relaciones y 12 Meses", subtitle: "Panorámicas", icon: "7.circle.fill", content: "Herradura (7): Pasado lejano, Presente, Oculto, Consejo, Futuro cercano, Futuro lejano, Resultado — ideal para visión completa sin la densidad de la Cruz.\n\nRelaciones (7): Tú, Pareja, Fortalezas, Desafíos, Camino mutuo, Consejo, Resultado — lee Tú vs Pareja como polaridad (¿Fuego vs Agua?). Si Fortalezas es 3 de Copas y Desafíos es 5 de Espadas, la amistad sostiene pero la comunicación hiere.\n\n12 Meses: Una carta por mes, de Enero a Diciembre. Úsala en Ano Nuevo o cumpleaños. Busca el arco anual: ¿dónde cae La Muerte? Ese mes pide transformación."),
                    SchoolLesson(title: "Tiradas Libres y Esotéricas", subtitle: "Árbol, Estrella, Luna, Pirámide", icon: "sparkles", content: "Esotéricas: Templanza (6, equilibrio de opuestos), Árbol de la Vida (10 sefirot, de Kether a Malkuth), Estrella de David (7, integración de 6 elementos + centro), Espejo del Alma (9, sombra junguiana), Alquimia (4 fases Nigredo→Rubedo), Ciclo Lunar (4 fases), Pirámide (6, base→vértice).\n\nClave: Cada tirada esotérica tiene una narrativa mítica. No memorices posiciones, entiende el mito: En Alquimia, Nigredo es putrefacción (qué debe morir), Albedo purificación, Citrinitas iluminación, Rubedo perfección. La tirada te inicia, no solo te informa."),
                ]
            ),
            SchoolCourse(
                title: "Cábala y Árbol de la Vida",
                icon: "tree.fill",
                color: Color.tarotGold,
                summary: "Las 22 letras, 10 sefirot y 32 senderos: el mapa hermético que une Tarot y creación.",
                lessons: [
                    SchoolLesson(title: "Las 10 Sefirot", subtitle: "De Kether a Malkuth", icon: "tree", content: "Kether (Corona, unidad), Chokmah (Sabiduría, fuerza paterna), Binah (Comprensión, matriz), Chesed (Misericordia, expansión), Geburah (Rigor, disciplina), Tiphareth (Belleza, corazón/Sol), Netzach (Victoria, emociones/Venus), Hod (Esplendor, intelecto/Mercurio), Yesod (Fundamento, Luna/inconsciente), Malkuth (Reino, materia). El Árbol es el cuerpo de Dios y tu psique.\n\nPráctica: Coloca 10 cartas (una por sefirá) y lee tu Árbol personal: ¿dónde hay cartas difíciles? Esa sefirá pide atención."),
                    SchoolLesson(title: "22 Senderos y Letras Hebreas", subtitle: "Cada Mayor es una letra", icon: "arrow.right.circle.fill", content: "Aleph (El Loco, aire), Beth (El Mago, Mercurio), Gimel (La Papisa, Luna), Daleth (La Emperatriz, Venus), Heh (El Emperador, Aries), Vav (El Papa, Tauro), Zayin (Los Enamorados, Géminis), Cheth (El Carro, Cáncer), Teth (La Fuerza, Leo), Yod (El Ermitaño, Virgo), Kaph (La Rueda, Júpiter), Lamed (La Justicia, Libra), Mem (El Colgado, Agua), Nun (La Muerte, Escorpio), Samekh (La Templanza, Sagitario), Ayin (El Diablo, Capricornio), Peh (La Torre, Marte), Tzaddi (La Estrella, Acuario), Qoph (La Luna, Piscis), Resh (El Sol, Sol), Shin (El Juicio, Fuego), Tav (El Mundo, Saturno/Tierra).\n\nMeditación: Recorre el alfabeto hebreo con los Mayores como flashcards místicas."),
                    SchoolLesson(title: "Meditación Cabalística", subtitle: "Ascenso por el Árbol", icon: "sparkles", content: "Meditación guiada: Visualiza Malkuth (tus pies en tierra) con 10 de Oros, sube a Yesod (Luna, sueños) con La Luna, a Tiphareth (corazón solar) con El Sol, a Kether (corona) con El Mundo. En cada sefirá, respira 4 tiempos y pregunta: ¿qué me enseña esta esfera hoy? Anota sincronicidades.\n\nTip lujo: Usa la textura 'sacredGeometry' del mazo Thoth para este ascenso; la geometría sagrada resuena con la Cábala."),
                    SchoolLesson(title: "Cábala Práctica — Cuatro Mundos", subtitle: "Atziluth, Briah, Yetzirah, Assiah", icon: "atom", content: "Cuatro mundos: Atziluth (Fuego, arquetipos, Bastos), Briah (Agua, creación, Copas), Yetzirah (Aire, formación, Espadas), Assiah (Tierra, manifestación, Oros). Los Mayores cruzan todos los mundos; los Menores viven en uno.\n\nLectura: Si en una tirada hay muchos Bastos, estás en Atziluth (idea); muchos Oros, en Assiah (materia). El equilibrio de mundos revela dónde está tu energía y dónde falta."),
                ]
            ),
            SchoolCourse(
                title: "Astrología Aplicada",
                icon: "moon.stars.fill",
                color: Color.tarotGold,
                summary: "Signos, planetas, casas y elementos: tarot como espejo del cielo natal.",
                lessons: [
                    SchoolLesson(title: "Signos y Mayores — Correspondencias", subtitle: "Zodiaco en 22 cartas", icon: "star.fill", content: "Aries–El Emperador (liderazgo), Tauro–El Papa (tradición), Géminis–Los Enamorados (dualidad), Cáncer–El Carro (dirección emocional), Leo–La Fuerza (coraje), Virgo–El Ermitaño (análisis), Libra–La Justicia (equilibrio), Escorpio–La Muerte (transmutación), Sagitario–La Templanza (alquimia), Capricornio–El Diablo (ambición/sombra), Acuario–La Estrella (esperanza), Piscis–La Luna (inconsciente). Planetas: Mercurio–El Mago, Venus–La Emperatriz, Luna–La Papisa, Sol–El Sol, Marte–La Torre, Júpiter–La Rueda, Saturno–El Mundo.\n\nUsa esto para fechar eventos: Si sale La Torre (Marte) con 3 de Bastos (Aries), el evento es ariano/marcial y rápido."),
                    SchoolLesson(title: "Elementos y Casas Astrológicas", subtitle: "Fuego, Tierra, Aire, Agua + 12 casas", icon: "flame.fill", content: "Bastos=Fuego (Aries, Leo, Sagitario), Oros=Tierra (Tauro, Virgo, Capricornio), Espadas=Aire (Géminis, Libra, Acuario), Copas=Agua (Cáncer, Escorpio, Piscis). En una lectura, cuenta elementos: ¿falta Agua? Falta empatía. ¿Exceso de Aire? Parálisis por análisis.\n\n12 casas (tirada astrológica): 1 Yo, 2 Recursos, 3 Comunicación, 4 Hogar, 5 Creatividad, 6 Salud/Trabajo, 7 Pareja, 8 Transformación, 9 Filosofía, 10 Carrera, 11 Amigos, 12 Inconsciente. Cada posición es una casa; la carta es el planeta huésped."),
                    SchoolLesson(title: "Decanatos y Timing", subtitle: "Cuándo sucede", icon: "clock.fill", content: "Cada signo tiene 3 decanatos de 10° (36 decanatos = 36 cartas numeradas del 2 al 10). Ejemplo: 2 de Bastos es Marte en Aries (primer decanato de Aries), 5 de Copas es Marte en Escorpio. Esto permite afinar timing: Bastos rápido (días), Copas medio (semanas), Espadas variable, Oros lento (meses).\n\nPráctica: Cuando preguntes '¿cuándo?', mira el palo y el decanato de la carta de Futuro/Resultado para estimar tempo."),
                    SchoolLesson(title: "Carta Natal y Tarot — Hoja Natal", subtitle: "Sol, Luna, Ascendente", icon: "star.circle.fill", content: "Tu Sol es tu esencia (Mayores solares), Luna tu mundo emocional (Copas/Luna), Ascendente tu máscara (cómo te ven). En la app, Hoja Natal calcula Sol/Luna/Asc aproximados y puedes meditar con esas tres cartas como tirada personal.\n\nEjercicio: Saca tu Sol (ej. Leo–La Fuerza), Luna (ej. Escorpio–Muerte) y Asc (Géminis–Los Enamorados) y lee la historia: ¿cómo tu Fuerza se transforma (Muerte) para elegir con amor (Enamorados)?"),
                ]
            ),
            SchoolCourse(
                title: "Trabajo con la Sombra",
                icon: "moon.fill",
                color: Color.tarotGold,
                summary: "Jung + Tarot: integra tu sombra, sana heridas y transforma patrones kármicos.",
                lessons: [
                    SchoolLesson(title: "La Sombra en el Tarot — Arcanos Incómodos", subtitle: "Torre, Diablo, Luna, Muerte", icon: "moon.haze.fill", content: "La Sombra no es maldad, es lo no mirado. La Torre (Marte) derrumba estructuras falsas (ego, relación, trabajo) para liberar verdad. El Diablo (Capricornio) muestra ataduras: adicciones, dinero, poder, miedo. La Luna (Piscis) revela inconsciente, sueños, confusión fértil. La Muerte (Escorpio) no es muerte física, es poda necesaria.\n\nReencuadre: Pregunta no '¿qué me pasa?' sino '¿qué me libera esta carta incómoda?' La incomodidad es la brújula."),
                    SchoolLesson(title: "Espejo del Alma — 9 Posiciones Junguianas", subtitle: "Tirada sanadora", icon: "camera.macro", content: "Máscara (cómo te muestras), Sombra (lo negado), Anima/Animus (polaridad interna), Herida de Infancia, Don Oculto (perla en la herida), Patrón Kármico (bucle), Llamado del Alma (vocación), Obstáculo, Sí-Mismo (integración).\n\nLectura profunda: Si Sombra es 9 de Espadas (ansiedad) y Don Oculto es 9 de Copas (deseo cumplido), tu ansiedad esconde un deseo de plenitud. Si Patrón es 5 de Oros (carencia) y Llamado es 6 de Oros (dar/recibir), sanas al aprender a pedir y dar."),
                    SchoolLesson(title: "Integración — Diario y Ritual", subtitle: "De herida a don", icon: "heart.fill", content: "Ritual: 1) Saca una carta sombra al día (pregunta: ¿qué parte de mí necesita luz hoy?), 2) Escribe 5 líneas sin censura, 3) Responde con una carta consejo (¿cómo la integro?). En 21 días verás tu patrón.\n\nIntegración no es eliminar la sombra, es darle asiento a tu mesa interna. Cuando La Torre cae, no reconstruyas igual; cuando El Diablo aprieta, pregunta qué poder cedes."),
                    SchoolLesson(title: "Linaje y Propósito — Tirada del Linaje", subtitle: "7 posiciones ancestrales", icon: "person.3.fill", content: "Posiciones: Linaje, Abuelos, Padres, Infancia, Patrón Kármico, Propósito, Liberación. El Tarot puede leer herencias emocionales: Si Abuelos es 10 de Espadas (derrota) y Liberación es As de Bastos (nuevo fuego), honras al linaje no repitiendo, sino iniciando tu propio fuego.\n\nTip: Usa el Diario para anotar patrones familiares que se repiten en tiradas distintas; el tarot es espejo genealógico."),
                ]
            ),
            SchoolCourse(
                title: "Historia Viva del Tarot",
                icon: "book.closed.fill",
                color: Color.tarotGold,
                summary: "De los Visconti al Rider-Waite: cómo el juego se volvió oráculo y por qué importa hoy.",
                lessons: [
                    SchoolLesson(title: "Orígenes — Visconti, Marsella, Etteilla", subtitle: "Del juego al espejo", icon: "scroll.fill", content: "1441: Filippo Visconti encarga a Bonifacio Bembo los Tarocchi dorados para la corte de Milán (oro, amor cortés). Siglo XVI: el Tarot de Marsella fija el canon iconográfico que Waite heredará. 1781: Court de Gébelin inventa origen egipcio; Etteilla crea el primer mazo adivinatorio y la tirada. 1888: Golden Dawn sistematiza correspondencias cabalísticas/astrológicas. 1909: Waite-Smith publican el Rider-Waite (Pamela Colman Smith ilustra 78 cartas narrativas, no solo pips). Comprender esta historia te libera de dogma: el tarot es un lenguaje vivo, no una reliquia."),
                    SchoolLesson(title: "Iconografía — Leer como Renacimiento", subtitle: "Cada detalle cuenta", icon: "eye.fill", content: "Smith pintó teatros simbólicos: en 3 de Espadas, corazón atravesado bajo nubes de tormenta; en 6 de Copas, niños intercambian flores (nostalgia). Waite añadió detalles dorados de la Golden Dawn: el velo de la Papisa (Boaz/Jachin), el infinito del Mago (lemniscata), los girasoles de la Reina de Bastos (vitalidad). Leer es iconología: ¿qué mira el personaje? ¿qué oculta? ¿qué elemento domina el paisaje?"),
                    SchoolLesson(title: "Ética del Tarotista", subtitle: "Poder y responsabilidad", icon: "hand.raised.fill", content: "El tarot no predice fatalidad; revela probabilidades y agencia. Principios: 1) No leer sin permiso, 2) No diagnosticar salud/legal/financiero como profesional, 3) Lenguaje empoderador ('¿qué puedes hacer?' vs 'qué te pasará'), 4) Confidencialidad, 5) Derivación cuando hay riesgo. La carta no es veredicto, es espejo para elegir mejor."),
                ]
            ),
            SchoolCourse(
                title: "Numerología y Destino",
                icon: "number",
                color: Color.tarotGold,
                summary: "Del 1 al 10, Maestros 11/22, año personal y sinergia carta-número.",
                lessons: [
                    SchoolLesson(title: "1 al 10 — Ciclo de Manifestación", subtitle: "La escalera del 1 al 10", icon: "number.circle.fill", content: "1 Inicio (As), 2 Dualidad, 3 Creación, 4 Estructura, 5 Crisis, 6 Armonía, 7 Evaluación, 8 Poder, 9 Culminación interior, 10 Plenitud/fin de ciclo. En Mayores, reduce: La Rueda (10) = 1 (nuevo ciclo), El Mundo (21=3) = creación. Tu número de vida (fecha reducida) resuena con un Mayor: si eres Life Path 7, tu maestro es El Carro (7) y El Ermitaño (7)."),
                    SchoolLesson(title: "Maestros 11 y 22 — Justicia y Loco", subtitle: "Números que no se reducen", icon: "star.circle.fill", content: "11 (La Fuerza/La Justicia según mazo) es intuición elevada, canal; 22 (El Loco/El Mundo) es maestro constructor. Si tu carta de año es 11 o 22, es año bisagra: no pidas normalidad, pide propósito. En lecturas, 11 y 22 como suma de cartas señalan tema kármico mayor."),
                    SchoolLesson(title: "Año Personal y Carta del Año", subtitle: "Tu carta anual", icon: "calendar", content: "Suma día+mes+año en curso, reduce a 1-22 y mapea a Mayor. Ejemplo: 14/06/2026 = 1+4+6+2+0+2+6=21 → El Mundo (año de culminación). Saca esa carta y medita el año con ella. Combina con tirada de 12 meses para timing mensual."),
                ]
            ),
        ]
    }

    private struct SchoolCourseView: View {
        let course: SchoolCourse
        @State private var expandedLesson: UUID?

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(course.color.opacity(0.18))
                                    .frame(width: 56, height: 56)
                                Image(systemName: course.icon)
                                    .font(.system(size: 26))
                                    .foregroundStyle(course.color)
                            }
                            Text(course.title)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .tracking(-0.3)
                                .foregroundStyle(Color.tarotIvory)
                        }
                        Text(course.summary)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(Color.tarotIvory.opacity(0.6))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.tarotPanel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(course.color.opacity(0.4), lineWidth: 0.75)
                    )

                    // Lessons
                    Text("\(course.lessons.count) LECCIONES")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundStyle(course.color)
                        .tracking(1.6)
                        .padding(.horizontal, 4)

                    ForEach(course.lessons) { lesson in
                        lessonRow(lesson)
                    }
                }
                .padding()
            }
            .navigationTitle(course.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }

        private func lessonRow(_ lesson: SchoolLesson) -> some View {
            let isExpanded = expandedLesson == lesson.id
            return VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        expandedLesson = isExpanded ? nil : lesson.id
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(course.color.opacity(0.15))
                                .frame(width: 42, height: 42)
                            Image(systemName: lesson.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(course.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lesson.title)
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundStyle(Color.tarotIvory)
                                .multilineTextAlignment(.leading)
                            Text(lesson.subtitle)
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(Color.tarotIvory.opacity(0.5))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.4))
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Text(lesson.content)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.75))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.tarotPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isExpanded ? course.color.opacity(0.4) : Color.tarotGold.opacity(0.08), lineWidth: 0.75)
            )
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical").font(.system(size: 48)).foregroundStyle(Color.tarotIvory.opacity(0.2))
            Text("Biblioteca vacía")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.5))
            Text("Importa PDFs o espera a que los libros precargados se carguen automáticamente.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.tarotIvory.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.tarotPanel)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.13), lineWidth: 0.75)
        )
    }

    // MARK: - Spreads Info Section
    private var spreadsInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("🔮 Catálogo de Tiradas").padding(.horizontal)

            ForEach(SpreadType.allCases, id: \.self) { spread in
                spreadInfoRow(spread: spread)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private func spreadInfoRow(spread: SpreadType) -> some View {
        let isEsoteric = [SpreadType.temperance, .treeOfLife, .starDavid, .soulMirror, .alchemyPath, .moonCycle].contains(spread)
        return HStack(spacing: 14) {
            Text(spread.symbol)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(isEsoteric ? Color.tarotGoldDeep.opacity(0.4)
                            : Color.tarotPanel)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(spread.label)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotIvory)
                    if isEsoteric {
                        Text("ESOTÉRICO").font(.system(size: 9, weight: .black, design: .serif)).foregroundStyle(Color.tarotGold)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.tarotGold.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(spread.esotericDescription)
                    .font(.system(size: 11, design: .serif)).foregroundStyle(Color.tarotIvory.opacity(0.5)).lineLimit(2)
                Text("\(spread.positions.count) cartas")
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.tarotPanel.opacity(isEsoteric ? 0.95 : 0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isEsoteric ? Color.tarotGold.opacity(0.35) : Color.tarotGold.opacity(0.08), lineWidth: 0.75))
        .padding(.horizontal)
    }

    // MARK: - Tools Section
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("🛠 Herramientas Arcanas").padding(.horizontal)

            Button {
                showingBrowser = true
            } label: {
                toolRowContent(icon: "safari.fill", title: "Navegador Arcano", subtitle: "Explora recursos esotéricos en internet",
                               color: Color.tarotGold)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Button {
                showingFilePicker = true
            } label: {
                toolRowContent(icon: "doc.badge.plus", title: "Importar PDF", subtitle: "Añade libros desde tus archivos",
                               color: Color.tarotGold)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            NavigationLink(destination: SecretVaultView()) {
                toolRowContent(icon: "lock.shield.fill", title: "Bóveda Secreta",
                               subtitle: "Notas privadas protegidas con PIN y cámara",
                               color: Color.tarotGold)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private func toolRowContent(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text(subtitle)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.5))
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.tarotIvory.opacity(0.3))
        }
        .padding(14)
        .background(Color.tarotPanel)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.2), lineWidth: 0.75))
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .serif))
            .foregroundStyle(Color.tarotGold.opacity(0.8))
            .textCase(.uppercase)
            .tracking(1.4)
    }
}

// MARK: - School Models
private struct SchoolCourse: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let summary: String
    let lessons: [SchoolLesson]
}

private struct SchoolLesson: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let content: String
}

// MARK: - Section Enum
private enum LibrarySection: CaseIterable, Hashable {
    case books, spreads, tools

    var label: String {
        switch self {
        case .books: return "Libros"
        case .spreads: return "Tiradas"
        case .tools: return "Herramientas"
        }
    }

    var icon: String {
        switch self {
        case .books: return "books.vertical"
        case .spreads: return "sparkles"
        case .tools: return "wrench.and.screwdriver"
        }
    }
}
