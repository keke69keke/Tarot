import SwiftUI
import TarotCore

/// Sección de fases lunares: dónde está la luna hoy, qué ritual toca y el mapa
/// completo del ciclo.
///
/// La luna se dibuja de verdad (fracción iluminada y lado según crezca o mengüe),
/// y el ciclo se calcula con `LunarCycle`, que es puro y determinista.
public struct LunarPhasesView: View {
    @State private var seleccion: LunarPhaseKind?
    @State private var hoy = Date()
    @State private var aparecido = false

    public init() {}

    private var posicion: LunarPosition { LunarCycle.position(for: hoy) }
    private var activa: LunarPhaseKind { seleccion ?? posicion.kind }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LuxuryPage(maxWidth: 820) {
                    VStack(alignment: .leading, spacing: 22) {
                        encabezado
                        lunaDeHoy
                        tiraDeFases
                        ritualDeLaFase
                        proximasFases
                        cicloCompleto
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Fases lunares")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .tarotNightBackground()
            #if os(iOS)
            // La barra de navegacion pinta su propio material opaco por encima
            // del cielo: sin esto el fondo dinamico se cortaba justo debajo de
            // la barra de estado y arriba solo quedaba el violeta plano.
            // `JournalView` ya lo hacia asi. Verificado en captura.
            .toolbarBackground(.clear, for: .navigationBar)
            #endif
        }
        .onAppear {
            guard !aparecido else { return }
            withAnimation(.easeOut(duration: 0.7)) { aparecido = true }
        }
    }

    // MARK: - Encabezado

    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel(text: "Ciclo · Luna")
            Text("Fases lunares")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotIvory)
            Text("Cada fase pide una cosa distinta. Aquí tienes dónde está la luna hoy y el ritual que le corresponde, sin prisas y sin obligación.")
                .font(.system(size: 14, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(Color.tarotIvory.opacity(0.68))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 26)
    }

    // MARK: - Luna de hoy

    private var lunaDeHoy: some View {
        HStack(alignment: .center, spacing: 26) {
            MoonDiscView(illumination: posicion.illumination, waxing: posicion.age < LunarCycle.synodicMonth / 2)
                // 176 en lugar de 132: el halo necesita sitio propio alrededor del
                // disco o se recorta contra el borde del lienzo.
                .frame(width: 176, height: 176)
                .scaleEffect(aparecido ? 1 : 0.86)
                .opacity(aparecido ? 1 : 0)
                .rotationEffect(.degrees(aparecido ? 0 : -22))

            VStack(alignment: .leading, spacing: 6) {
                Text(posicion.kind.palabra.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(2.2)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                Text(posicion.kind.nombre)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotIvory)
                Text(fraseDeHoy)
                    .font(.system(size: 13.5, design: .serif))
                    .foregroundStyle(Color.tarotIvory.opacity(0.7))
                    .lineSpacing(4)
                Text(iluminacionTexto)
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.9))
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 26)
    }

    private var iluminacionTexto: String {
        let porcentaje = Int((posicion.illumination * 100).rounded())
        let dias = LunarCycle.daysUntil(proximaFasePrimaria, from: hoy)
        let diasTexto = dias < 1 ? "menos de un día" : String(format: "%.0f días", dias)
        return "\(porcentaje) % iluminada · faltan \(diasTexto) para \(proximaFasePrimaria.nombre.lowercased())"
    }

    private var proximaFasePrimaria: LunarPhaseKind {
        let primarias: [LunarPhaseKind] = [.newMoon, .firstQuarter, .fullMoon, .lastQuarter]
        return primarias
            .map { ($0, LunarCycle.daysUntil($0, from: hoy)) }
            .min { $0.1 < $1.1 }?.0 ?? .fullMoon
    }

    private var fraseDeHoy: String {
        let dias = Int(posicion.age.rounded())
        return "Día \(dias) del ciclo. \(posicion.kind.intencion)"
    }

    // MARK: - Tira de las ocho fases

    private var tiraDeFases: some View {
        // Ocho columnas en el ancho de un iPhone dejan muy poco por celda: con
        // 12 pt de separacion quedaban ~33 pt y los rotulos se truncaban
        // ("Semill", "Decisi", "Detalle"). Se reduce la separacion y se deja
        // que el texto encoja antes que cortarse.
        HStack(spacing: 6) {
            ForEach(Array(LunarPhaseKind.allCases.enumerated()), id: \.element) { indice, fase in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { seleccion = fase }
                } label: {
                    VStack(spacing: 8) {
                        MoonDiscView(
                            illumination: iluminacionDe(fase),
                            waxing: indice < 5
                        )
                        .frame(width: 34, height: 34)
                        .opacity(fase == activa ? 1 : 0.62)
                        Text(fase.palabra)
                            .font(.system(size: 9, weight: fase == activa ? .bold : .regular, design: .serif))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .foregroundStyle(fase == activa ? Color.tarotGold : Color.tarotIvory.opacity(0.55))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 2)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(fase == activa ? 0.06 : 0.02))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(fase == activa ? Color.tarotGold.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .opacity(aparecido ? 1 : 0)
                .offset(y: aparecido ? 0 : 10)
                .animation(.easeOut(duration: 0.45).delay(Double(indice) * 0.05), value: aparecido)
            }
        }
    }

    /// Iluminación representativa de cada fase (0 nueva, 0,5 cuartos, 1 llena).
    private func iluminacionDe(_ fase: LunarPhaseKind) -> Double {
        let indice = Double(LunarPhaseKind.allCases.firstIndex(of: fase) ?? 0)
        return (1 - cos(2 * Double.pi * indice / 8)) / 2
    }

    // MARK: - Ritual

    private var ritualDeLaFase: some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Ritual de \(activa.nombre.lowercased())")
            Text(activa.intencion)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(Color.tarotIvory)
                .lineSpacing(5)
            Rectangle()
                .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.06), Color.tarotGold.opacity(0.4), Color.tarotGold.opacity(0.06)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.75)
            Text(activa.ritual)
                .font(.system(size: 14.5, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Color.tarotIvory.opacity(0.9))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 26)
        .id(activa)
        .transition(.opacity)
    }

    // MARK: - Próximas fases

    private var proximasFases: some View {
        VStack(alignment: .leading, spacing: 12) {
            EyebrowLabel(text: "Lo que viene")
            ForEach(Array(LunarCycle.upcoming(after: hoy, count: 4).enumerated()), id: \.offset) { _, item in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.tarotGold.opacity(0.5))
                        .frame(width: 5, height: 5)
                    Text(item.kind.nombre)
                        .font(.system(size: 13.5, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.9))
                    Spacer()
                    Text(item.date.formatted(.dateTime.day().month(.wide)))
                        .font(.system(size: 12.5, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.tarotGold.opacity(0.85))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 22)
    }

    // MARK: - Ciclo completo

    private var cicloCompleto: some View {
        VStack(alignment: .leading, spacing: 14) {
            EyebrowLabel(text: "Las ocho fases y su ritual")
            ForEach(LunarPhaseKind.allCases) { fase in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        MoonDiscView(illumination: iluminacionDe(fase), waxing: (LunarPhaseKind.allCases.firstIndex(of: fase) ?? 0) < 5)
                            .frame(width: 30, height: 30)
                        Text(fase.nombre)
                            .font(.system(size: 14.5, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotIvory)
                        Text(fase.palabra)
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .tracking(1.4)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.tarotGold.opacity(0.16)))
                            .foregroundStyle(Color.tarotGold)
                        Spacer()
                    }
                    Text(fase.ritual)
                        .font(.system(size: 13.5, design: .serif))
                        .lineSpacing(5)
                        .foregroundStyle(Color.tarotIvory.opacity(0.72))
                }
                .padding(.vertical, 4)
                if fase != LunarPhaseKind.allCases.last {
                    Rectangle()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 0.75)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .luxuryGlass(cornerRadius: 26)
    }
}

/// El disco lunar, dibujado a partir de la fracción iluminada.
///
/// El truco: se pinta el disco claro entero y encima la zona oscura como union
/// (fase creciente) o resta (fase gibosa) de medio disco y una elipse, que es
/// como se comporta de verdad el terminador.
struct MoonDiscView: View {
    let illumination: Double
    let waxing: Bool

    /// Margen reservado alrededor del disco para que el halo desenfocado tenga
    /// sitio. Sin el, el aura se dibuja dentro del lienzo justo del tamano del
    /// disco y se corta en seco en el borde (se veia un semicirculo de luz en
    /// lugar de un halo completo). Verificado midiendo la captura.
    private var margenHalo: CGFloat { 0.34 }

    var body: some View {
        Canvas { contexto, tamano in
            let lado = min(tamano.width, tamano.height)
            let centro = CGPoint(x: tamano.width / 2, y: tamano.height / 2)
            // El radio del disco descuenta el margen del halo, asi el aura nunca
            // toca el borde del lienzo.
            let radio = lado / 2 * (1 - margenHalo)
            let disco = CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)

            // Halo: en su propia capa, para que el desenfoque no contagie al disco.
            contexto.drawLayer { halo in
                halo.addFilter(.blur(radius: radio * 0.38))
                halo.fill(Path(ellipseIn: disco), with: .color(Color.tarotGold.opacity(0.40)))
            }
            contexto.drawLayer { capa in

                let claridad = min(1, max(0, illumination))
                capa.fill(Path(ellipseIn: disco), with: .color(Color(red: 0.94, green: 0.92, blue: 0.99)))

                // Mitad oscura: la izquierda si crece, la derecha si mengua.
                var oscuro = Path()
                oscuro.move(to: CGPoint(x: centro.x, y: centro.y - radio))
                oscuro.addArc(
                    center: centro, radius: radio,
                    startAngle: .degrees(-90), endAngle: .degrees(90),
                    clockwise: waxing
                )
                oscuro.closeSubpath()

                // Terminador: elipse cuyo semieje horizontal mide |2f-1| radios.
                let semieje = radio * CGFloat(abs(2 * claridad - 1))
                if semieje > 0.4 {
                    var terminador = Path()
                    let escala = CGAffineTransform(translationX: centro.x, y: centro.y).scaledBy(x: semieje / radio, y: 1)
                    terminador.addEllipse(in: CGRect(x: -radio, y: -radio, width: radio * 2, height: radio * 2), transform: escala)
                    oscuro.addPath(terminador)
                }

                // La capa oscura se abre sobre el contexto de la capa actual
                // (`capa`), no sobre el exterior (`contexto`): abrir una capa
                // anidada desde el contexto padre mientras hay otra abierta
                // corrompe el display list de RenderBox y aborta la app con
                // «current layer doesn't match drawing state».
                capa.drawLayer { capaOscura in
                    capaOscura.fill(
                        oscuro,
                        with: .color(Color(red: 0.07, green: 0.06, blue: 0.13).opacity(0.92)),
                        style: FillStyle(eoFill: claridad > 0.5)
                    )
                }

                capa.stroke(Path(ellipseIn: disco), with: .color(Color.tarotGold.opacity(0.45)), lineWidth: 1)
            }
        }
    }
}
