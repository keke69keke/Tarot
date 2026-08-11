import SwiftUI
import TarotCore

// MARK: - Book Cover Colors (deterministic from title hash)
private func bookCoverGradient(for title: String) -> [Color] {
    let palettes: [[Color]] = [
        [Color(red: 0.42, green: 0.10, blue: 0.35), Color(red: 0.18, green: 0.05, blue: 0.28)],
        [Color(red: 0.55, green: 0.30, blue: 0.05), Color(red: 0.28, green: 0.12, blue: 0.02)],
        [Color(red: 0.08, green: 0.22, blue: 0.42), Color(red: 0.04, green: 0.08, blue: 0.22)],
        [Color(red: 0.35, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.04, blue: 0.04)],
        [Color(red: 0.05, green: 0.28, blue: 0.22), Color(red: 0.02, green: 0.12, blue: 0.10)],
        [Color(red: 0.40, green: 0.35, blue: 0.05), Color(red: 0.18, green: 0.14, blue: 0.02)],
        [Color(red: 0.22, green: 0.05, blue: 0.40), Color(red: 0.10, green: 0.02, blue: 0.20)],
        [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.10, blue: 0.22)],
        [Color(red: 0.38, green: 0.18, blue: 0.02), Color(red: 0.18, green: 0.08, blue: 0.01)],
    ]
    let idx = abs(title.hashValue) % palettes.count
    return palettes[idx]
}

private func bookCoverIcon(for title: String) -> String {
    let icons = ["books.vertical.fill", "scroll.fill", "moon.stars.fill", "sparkles",
                 "flame.fill", "leaf.fill", "star.fill", "eye.fill", "atom"]
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
                context.stroke(p, with: .color(Color.white.opacity(0.06)), lineWidth: 0.75)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .padding(12)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .lineLimit(1)
            }
            .padding(10)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(colors: [Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.6),
                                             Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.15)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(hovered ? 1.03 : 1.0)
        .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: hovered ? 18 : 10, x: 0, y: 6)
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
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.08, green: 0.04, blue: 0.16)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
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
                    TarotWebBrowserView()
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
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 0.95, green: 0.85, blue: 0.50),
                                                     Color(red: 0.78, green: 0.58, blue: 0.22)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Sabiduría Esotérica · \(libraryManager.importedBooks.count) libros")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.7))
                }
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.5))
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
                        Text(section.label).font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        selectedSection == section
                            ? Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.20)
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedSection == section
                            ? Color(red: 0.95, green: 0.85, blue: 0.50)
                            : Color.white.opacity(0.45)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedSection == section
                                    ? Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.5)
                                    : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Books Section
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            quickActionsBar.padding(.horizontal)

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
            quickActionButton(icon: "safari.fill", label: "Navegador", color: Color(red: 0.3, green: 0.6, blue: 1.0)) {
                showingBrowser = true
            }
            quickActionButton(icon: "doc.badge.plus", label: "Importar PDF", color: Color(red: 0.85, green: 0.72, blue: 0.38)) {
                showingFilePicker = true
            }
            NavigationLink(destination: SecretVaultView()) {
                VStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 20))
                    Text("Bóveda").font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.42, green: 0.25, blue: 0.65).opacity(0.6), lineWidth: 1))
                .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 1.0))
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.5), lineWidth: 1))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
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
                    .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.28, blue: 0.05),
                                                   Color(red: 0.20, green: 0.12, blue: 0.02)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 72)
                Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.45))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Guía Definitiva del Tarot")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("Fiebig & Bürger · Rider-Waite · Incluida")
                    .font(.caption).foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.white.opacity(0.3)).font(.caption)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.3), lineWidth: 1))
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
                color: Color(red: 0.78, green: 0.62, blue: 0.98),
                summary: "Domina el significado de los 22 Arcanos Mayores y los 56 Menores, con sus símbolos, arquetipos y mensajes.",
                lessons: [
                    SchoolLesson(title: "Los Arcanos Mayores", subtitle: "22 arquetipos que narran el viaje del alma", icon: "star.fill", content: "Los Arcanos Mayores representan el camino de la vida: desde El Loco (0) que inicia el viaje con fe y espontaneidad, hasta El Mundo (21) que alcanza la plenitud. Cada carta es un arquetipo universal que refleja una etapa de tu evolución. Aprende a identificar cuál de estos arquetipos resuena con tu situación actual y cómo integrar su energía."),
                    SchoolLesson(title: "Los Arcanos Menores", subtitle: "La vida cotidiana en 4 palos y 56 cartas", icon: "suit.club.fill", content: "Los Arcanos Menores se dividen en cuatro palos que corresponden a los elementos: Bastos (fuego, acción), Copas (agua, emociones), Espadas (aire, mente) y Oros (tierra, materia). Cada palo narra la evolución de un área de tu vida, desde el As (el comienzo) hasta el Rey (la maestría). Aprende a leerlos en contexto."),
                    SchoolLesson(title: "Símbolos y numerología", subtitle: "El lenguaje oculto de cada carta", icon: "number", content: "Cada carta esconde múltiples capas de significado: los números (del 1 al 10 y las figuras de corte), los colores, los objetos y las posturas de los personajes. El número indica el nivel de desarrollo de la energía, mientras que los símbolos aportan matices. El Sol, la luna, la estrella y la torre son arquetipos universales que se repiten."),
                ]
            ),
            SchoolCourse(
                title: "Tiradas Prácticas",
                icon: "rectangle.stack.fill",
                color: Color(red: 0.95, green: 0.72, blue: 0.38),
                summary: "Aprende a realizar las tiradas más usadas y a interpretar las posiciones de cada carta.",
                lessons: [
                    SchoolLesson(title: "Tirada de 3 cartas", subtitle: "Pasado, presente y futuro", icon: "3.circle.fill", content: "La tirada más versátil y sencilla. La primera carta revela el pasado que te trajo hasta aquí, la segunda describe el presente o el corazón de la cuestión, y la tercera apunta al futuro probable. Es ideal para preguntas rápidas y consultas diarias. Cada posición se lee en relación con las demás para formar una historia coherente."),
                    SchoolLesson(title: "La Cruz Celta", subtitle: "La tirada más completa del tarot", icon: "xmark.circle.fill", content: "Con 10 cartas, es la tirada reina del tarot. Analiza el corazón de la cuestión, el desafío, el pasado, el futuro, tu objetivo consciente, la base inconsciente, el consejo, el entorno, tus esperanzas y temores, y el resultado final. Cada posición ilumina una faceta distinta de tu situación."),
                    SchoolLesson(title: "Tirada de la Herradura", subtitle: "7 cartas para visión de conjunto", icon: "7.circle.fill", content: "La herradura despliega 7 cartas en arco: pasado lejano, presente, fuerzas ocultas, consejo, futuro cercano, futuro lejano y resultado. Es excelente para obtener una panorámica general de una situación compleja y entender cómo se desarrollarán los acontecimientos."),
                ]
            ),
            SchoolCourse(
                title: "Cábala y Tarot",
                icon: "tree.fill",
                color: Color(red: 0.55, green: 0.78, blue: 0.42),
                summary: "Conecta las cartas con el Árbol de la Vida y la sabiduría hermética.",
                lessons: [
                    SchoolLesson(title: "El Árbol de la Vida", subtitle: "Las 10 sefirot y sus correspondencias", icon: "tree", content: "La Cábala estructura el universo en 10 esferas (sefirot) conectadas por 22 senderos, los mismos que los 22 Arcanos Mayores. Cada sefirá es una emanación divina: desde Kether (la corona) hasta Malkuth (el reino). El tarot y la cábala comparten este mapa sagrado de la creación."),
                    SchoolLesson(title: "Los Arcanos y los senderos", subtitle: "El camino del iniciado", icon: "arrow.right.circle.fill", content: "Cada Arcano Mayor corresponde a un sendero del Árbol de la Vida y a una letra hebrea. El Loco es Aleph, el aire primordial; El Mundo es Tav, la culminación. Estudiar estas correspondencias te permite leer el tarot como un mapa de iniciación espiritual y de desarrollo personal."),
                    SchoolLesson(title: "Visiertoes y prácticas", subtitle: "Meditaciones con el Árbol", icon: "sparkles", content: "Una práctica poderosa es meditar ascendiendo por el Árbol de la Vida mientras contemplas los Arcanos. Coloca las cartas en la posición de las sefirot y observa cómo cada energía se conecta. Esta práctica integra cuerpo, mente y espíritu revelando bloqueos y dones ocultos."),
                ]
            ),
            SchoolCourse(
                title: "Astrología Aplicada",
                icon: "moon.stars.fill",
                color: Color(red: 0.40, green: 0.72, blue: 1.0),
                summary: "Integra los 12 signos, planetas y casas con las cartas del tarot.",
                lessons: [
                    SchoolLesson(title: "Signos y Arcanos Mayores", subtitle: "Correspondencias zodiacales", icon: "star.fill", content: "Varios Arcanos Mayores se asocian a signos zodiacales: El Emperador es Aries, La Templanza es Sagitario, La Estrella es Acuario, La Rueda es Júpiter. Conocer estas correspondencias enriquece tus lecturas y te permite usar el tarot como una herramienta astrológica."),
                    SchoolLesson(title: "Los palos y los elementos", subtitle: "Fuego, tierra, aire y agua", icon: "flame.fill", content: "Los cuatro palos del tarot corresponden a los cuatro elementos: Bastos = Fuego, Oros = Tierra, Espadas = Aire y Copas = Agua. Estos elementos se relacionan con los signos zodiacales según su naturaleza. Esta correspondencia te ayuda a equilibrar las energías en una lectura."),
                    SchoolLesson(title: "La rueda de 12 casas", subtitle: "La tirada astrológica", icon: "circle.grid.cross.fill", content: "La tirada astrológica coloca 12 cartas en las 12 casas. Cada casa rige un área de la vida: la 1ª tu identidad, la 2ª tus recursos, la 7ª tus relaciones, la 10ª tu carrera. Es una herramienta poderosa para una lectura anual o para entender tu cielo natal con el tarot."),
                ]
            ),
            SchoolCourse(
                title: "Trabajo con la Sombra",
                icon: "moon.fill",
                color: Color(red: 0.72, green: 0.42, blue: 1.0),
                summary: "Explora el inconsciente, integra tu sombra y sana heridas profundas.",
                lessons: [
                    SchoolLesson(title: "La sombra en el tarot", subtitle: "Los arcanos que nos confrontan", icon: "moon.haze.fill", content: "Cartas como La Torre, La Luna, El Diablo o La Muerte suelen asustar, pero son las más sanadoras. La Torre derrumba lo falso, La Luna ilumina lo inconsciente, El Diablo revela tus ataduras, y La Muerte abre paso a la transformación. Trabajarlas conscientemente integra tu sombra."),
                    SchoolLesson(title: "El Espejo del Alma", subtitle: "Sanación con la tirada de 9 cartas", icon: "camera.macro", content: "La tirada del Espejo del Alma explora tu máscara, tu sombra, tu herida de infancia, tu don oculto, tus patrones kármicos y tu llamado del alma. Es una herramienta de autoindagación profunda inspirada en Carl Jung. Cada carta te invita a mirar dentro sin juicio."),
                    SchoolLesson(title: "Integración y práctica", subtitle: "Transformar la herida en don", icon: "heart.fill", content: "No se trata de eliminar la sombra, sino de integrarla. Lleva un diario de tus lecturas, pregunta a las cartas qué patrón repites y cómo transformarlo. La oscuridad no es enemiga de la luz: es su complemento. Cuando integras tu sombra, recuperas una energía vital preciosa."),
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
                                .foregroundStyle(.white)
                        }
                        Text(course.summary)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(course.color.opacity(0.4), lineWidth: 1)
                    )

                    // Lessons
                    Text("\(course.lessons.count) LECCIONES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(course.color)
                        .tracking(1.4)
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
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                            Text(lesson.subtitle)
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.5))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Text(lesson.content)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isExpanded ? course.color.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical").font(.system(size: 48)).foregroundStyle(Color.white.opacity(0.2))
            Text("Biblioteca vacía").font(.headline).foregroundStyle(Color.white.opacity(0.5))
            Text("Importa PDFs o espera a que los libros precargados se carguen automáticamente.")
                .font(.subheadline).foregroundStyle(Color.white.opacity(0.35)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .background(isEsoteric ? Color(red: 0.42, green: 0.10, blue: 0.35).opacity(0.4)
                            : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(spread.label)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    if isEsoteric {
                        Text("ESOTÉRICO").font(.system(size: 9, weight: .black)).foregroundStyle(Color(red: 0.95, green: 0.72, blue: 0.38))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(spread.esotericDescription)
                    .font(.caption).foregroundStyle(Color.white.opacity(0.5)).lineLimit(2)
                Text("\(spread.positions.count) cartas")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(isEsoteric ? 0.07 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isEsoteric ? Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1))
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
                               color: Color(red: 0.3, green: 0.6, blue: 1.0))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Button {
                showingFilePicker = true
            } label: {
                toolRowContent(icon: "doc.badge.plus", title: "Importar PDF", subtitle: "Añade libros desde tus archivos",
                               color: Color(red: 0.85, green: 0.72, blue: 0.38))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            NavigationLink(destination: SecretVaultView()) {
                toolRowContent(icon: "lock.shield.fill", title: "Bóveda Secreta",
                               subtitle: "Notas privadas protegidas con PIN y cámara",
                               color: Color(red: 0.72, green: 0.42, blue: 1.0))
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
                Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(Color.white.opacity(0.5)).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.8))
            .textCase(.uppercase)
            .tracking(1.2)
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
