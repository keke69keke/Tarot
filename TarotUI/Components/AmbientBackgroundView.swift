import SwiftUI
import TarotCore

#if canImport(CoreMotion) && !os(macOS)
import CoreMotion
#endif

// MARK: - Capa ya generada

/// Una capa de profundidad con sus estrellas ya resueltas.
private struct StarLayer: Identifiable {
    let id: Int
    let spec: StarLayerSpec
    let stars: [StarfieldStar]
    /// Color ya resuelto de cada estrella: se calcula al generar el cielo, no en cada fotograma.
    let tints: [Color]
}

/// Interpola de blanco frio a ambar calido segun `warmth` (Ash Thorp: nada de azul frio).
private func starTint(_ warmth: Double) -> Color {
    let t = min(max(warmth, 0), 1)
    return Color(red: 1.00 - 0.06 * t, green: 1.00 - 0.16 * t, blue: 1.00 - 0.42 * t)
}

/// Fondo cinematografico por capas.
///
/// Cinco profundidades de estrellas (polvo lejano -> motas de primer plano) sobre la
/// nebulosa calida y la viñeta. Cada capa lleva su propio factor de parallax, un giro
/// 3D de pocos grados y un desenfoque segun su distancia, de modo que el cielo se mueve
/// con el puntero (macOS), con la inclinacion del dispositivo (iOS) y con una deriva
/// lenta propia. Un unico `TimelineView` alimenta todas las capas: el coste por
/// fotograma es el de dibujar puntos, no el de reconstruir vistas.
struct StarfieldBackgroundView: View {
    /// 150 es la densidad que mejor lee el fondo: con 110 se queda escaso de polvo fino y a
    /// partir de 200 el cielo empieza a competir con el texto. Se puede ajustar en cada punto
    /// de llamada.
    var starCount: Int = 150
    var showsNebula: Bool = true
    /// Desplazamiento maximo, en puntos, de la capa mas cercana.
    var parallaxStrength: CGFloat = 26

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var layers: [StarLayer] = []
    /// Entrada normalizada -1...1 del puntero (macOS) o de la inclinacion (iOS).
    @State private var pointer: CGSize = .zero
    /// 0...1 de la animacion de entrada.
    @State private var entry: Double = 0
    /// Instante del ultimo movimiento de puntero, para amortiguar por tiempo y no por evento.
    @State private var lastPointerMove: TimeInterval = 0

    #if canImport(CoreMotion) && !os(macOS)
    @StateObject private var tilt = DeviceTiltReader()
    #endif

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Con "reducir movimiento" el calendario queda en pausa: ni titileo, ni
                // deriva, ni parallax, y ningun bucle de fondo consumiendo CPU.
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        ForEach(layers) { layer in
                            StarLayerCanvas(
                                layer: layer,
                                time: time,
                                offset: offset(for: layer.spec),
                                offsetBase: parallaxStrength,
                                frameSize: geo.size,
                                entry: entry,
                                showsNebula: showsNebula && layer.id == 0
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // La viñeta queda fuera del TimelineView: es estatica y no cuesta nada.
                vignette
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(macOS)
            // En macOS el parallax sigue al puntero. En iOS el fondo no participa en el
            // hit-testing: alli mueve el acelerometro, que no lo necesita, asi que nunca
            // puede robar gestos ni desplazamientos al contenido que va encima.
            .onContinuousHover(coordinateSpace: CoordinateSpace.local) { phase in
                guard !reduceMotion else { return }
                switch phase {
                case .active(let point):
                    pointer = smoothed(pointer, towards: normalized(point, in: geo.size))
                case .ended:
                    pointer = smoothed(pointer, towards: .zero)
                }
            }
            #else
            .allowsHitTesting(false)
            #endif
        }
        .background(
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                Color.tarotBackgroundGradient.ignoresSafeArea()
            }
        )
        .ignoresSafeArea()
        .onAppear(perform: prepare)
        .onDisappear(perform: stopMotion)
        .onChange(of: reduceMotion) { _ in
            #if canImport(CoreMotion) && !os(macOS)
            if reduceMotion { tilt.stop() } else if scenePhase == .active { tilt.start() }
            #endif
        }
        .onChange(of: scenePhase) { _ in
            #if canImport(CoreMotion) && !os(macOS)
            if scenePhase == .active, !reduceMotion { tilt.start() } else { tilt.stop() }
            #endif
        }
    }

    // MARK: - Entrada

    /// Entrada total de las fuentes de movimiento: puntero/raton mas la inclinacion del
    /// dispositivo cuando existe. Se recorta dentro de `parallaxOffset`.
    private var motionInput: CGSize {
        #if canImport(CoreMotion) && !os(macOS)
        return CGSize(width: pointer.width + tilt.value.width, height: pointer.height + tilt.value.height)
        #else
        return pointer
        #endif
    }

    private func offset(for spec: StarLayerSpec) -> CGSize {
        StarfieldLayout.parallaxOffset(parallax: spec.parallax, depth: spec.depth, input: motionInput, maxOffset: parallaxStrength)
    }

    // MARK: - Preparacion

    private func prepare() {
        let counts = StarfieldLayout.counts(total: starCount)
        layers = StarfieldLayout.layers.enumerated().map { index, spec in
            let stars = StarfieldLayout.stars(
                seed: 0xA5A5_5A5A_1234_5678 &+ UInt64(index) &* 0x9E37_79B9,
                count: counts[index],
                spec: spec
            )
            return StarLayer(id: index, spec: spec, stars: stars, tints: stars.map { starTint($0.warmth) })
        }

        #if canImport(CoreMotion) && !os(macOS)
        if !reduceMotion { tilt.start() }
        #endif

        if reduceMotion {
            entry = 1
        } else {
            withAnimation(.easeOut(duration: 0.9)) { entry = 1 }
        }
    }

    private func stopMotion() {
        #if canImport(CoreMotion) && !os(macOS)
        tilt.stop()
        #endif
    }

    // MARK: - Ayudas

    private func normalized(_ point: CGPoint, in size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        let x = (point.x / size.width) * 2 - 1
        let y = (point.y / size.height) * 2 - 1
        return CGSize(width: max(-1, min(1, x)), height: max(-1, min(1, y)))
    }

    /// Filtro paso bajo: el puntero se mueve en saltos y el cielo no debe temblar. Se
    /// amortigua por tiempo (constante de 90 ms), no por evento, para que el fondo no se
    /// mueva el doble en una pantalla de 120 Hz que en una de 60.
    private func smoothed(_ current: CGSize, towards target: CGSize) -> CGSize {
        let now = Date().timeIntervalSinceReferenceDate
        let dt = lastPointerMove == 0
            ? 1.0 / 60.0
            : min(max(now - lastPointerMove, 1.0 / 240.0), 0.25)
        lastPointerMove = now
        let factor = CGFloat(1 - exp(-dt / 0.09))
        return CGSize(
            width: current.width + (target.width - current.width) * factor,
            height: current.height + (target.height - current.height) * factor
        )
    }

    /// Oscurece bordes y esquinas para que el contenido respire en el centro
    /// (contencion Kenya Hara sobre base cinematografica).
    private var vignette: some View {
        Canvas { context, canvasSize in
            let gradient = Gradient(colors: [.clear, Color.black.opacity(0.50)])
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .radialGradient(
                    gradient,
                    center: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.44),
                    startRadius: min(canvasSize.width, canvasSize.height) * 0.22,
                    endRadius: max(canvasSize.width, canvasSize.height) * 0.78
                )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

// MARK: - Dibujo de una capa

/// Dibuja una capa completa (nebulosa, si le toca, y sus estrellas) y la coloca en el
/// espacio con su parallax, su giro 3D y su desenfoque.
private struct StarLayerCanvas: View {
    let layer: StarLayer
    let time: Double
    let offset: CGSize
    /// Desplazamiento de referencia: la capa mas cercana se mueve como maximo esto.
    let offsetBase: CGFloat
    /// Tamano del marco, para calcular cuanto hay que agrandar la capa al moverse.
    let frameSize: CGSize
    let entry: Double
    let showsNebula: Bool

    var body: some View {
        blurredCanvas
            // Escala de cobertura (que no queden franjas al desplazarse) y entrada escalonada.
            .scaleEffect(coverScale * (0.982 + 0.018 * progress))
        .offset(offset)
        .rotation3DEffect(
            .degrees(Double(offset.width) / Double(max(offsetBase, 1)) * layer.spec.tiltDegrees),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.35
        )
        .rotation3DEffect(
            .degrees(Double(-offset.height) / Double(max(offsetBase, 1)) * layer.spec.tiltDegrees),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.35
        )
        .opacity(progress)
    }

    /// El desenfoque de la capa es la profundidad de campo: cuanto mas lejos, mas suave.
    /// Se omite cuando es cero (la capa nitida) para no encadenar una pasada de desenfoque
    /// en balde.
    @ViewBuilder
    private var blurredCanvas: some View {
        if layer.spec.blur > 0 {
            canvas.blur(radius: layer.spec.blur)
        } else {
            canvas
        }
    }

    private var canvas: some View {
        Canvas { context, size in
            if showsNebula {
                drawNebula(in: &context, size: size)
            }
            for (index, star) in layer.stars.enumerated() {
                draw(star, tint: layer.tints[index], in: &context, size: size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Cuanto hay que agrandar la capa para que, con el desplazamiento maximo posible,
    /// siga cubriendo el marco entero: sin esto el parallax dejaria franjas sin estrellas.
    private var coverScale: CGFloat {
        // La cuenta vive en TarotCore para poder vigilarla con tests: aqui se descubrio a
        // mano que sin el factor 2 las capas cercanas dejan franja al inclinar a tope.
        StarfieldLayout.coverScale(
            parallax: layer.spec.parallax,
            size: frameSize,
            maxOffset: offsetBase
        )
    }

    /// Entrada escalonada por profundidad: primero el polvo lejano, despues lo cercano.
    private var progress: Double {
        // `depth` esta acotado a 0...1, asi que el denominador nunca baja de 0,75.
        let delay = layer.spec.depth * 0.25
        return min(1, max(0, (entry - delay) / (1 - delay)))
    }

    /// Nebulosa calida y cinematografica (Ash Thorp): luz ambar + magenta, nunca azul
    /// indigo. Pocas fuentes, grandes y suaves = profundidad.
    private func drawNebula(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let sources: [(CGPoint, Color)] = [
            (CGPoint(x: w * 0.24, y: size.height * 0.20), Color(red: 0.78, green: 0.52, blue: 0.22, opacity: 0.11)),
            (CGPoint(x: w * 0.80, y: size.height * 0.52), Color(red: 0.44, green: 0.19, blue: 0.38, opacity: 0.13)),
            (CGPoint(x: w * 0.46, y: size.height * 0.92), Color(red: 0.32, green: 0.20, blue: 0.36, opacity: 0.10))
        ]
        for (center, color) in sources {
            let radius = w * 0.78
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(Gradient(colors: [color, .clear]), center: center, startRadius: 0, endRadius: radius)
            )
        }
    }

    private func draw(_ star: StarfieldStar, tint: Color, in context: inout GraphicsContext, size: CGSize) {
        // Deriva lenta y diagonal, dando la vuelta por los bordes.
        let drift = (time * layer.spec.driftSpeed).truncatingRemainder(dividingBy: 1.0)
        var x = star.x + drift
        var y = star.y + drift * 0.35
        x = x.truncatingRemainder(dividingBy: 1.0)
        if x < 0 { x += 1.0 }
        y = y.truncatingRemainder(dividingBy: 1.0)
        if y < 0 { y += 1.0 }

        // Titileo
        let phase = (time + star.twinkleDelay) / star.twinkleDuration
        let twinkle = 0.5 + 0.5 * sin(phase * 2 * .pi)
        // Fundido en los bordes: la deriva da la vuelta por los lados y sin esto una
        // estrella saltaria de un borde al otro de golpe.
        let edgeFade = min(1.0, min(min(x, 1 - x), min(y, 1 - y)) * 25)
        let opacity = star.opacity * (0.45 + 0.55 * twinkle) * edgeFade

        let px = x * size.width
        let py = y * size.height
        let r = star.size

        // Un disco opaco taparia las estrellas de las capas de atras y pareceria una
        // mancha; sumando luz se comporta como un foco o un halo real.
        if layer.spec.addsLight {
            context.blendMode = .plusLighter
        }

        // Halo de las estrellas grandes de las capas cercanas.
        if layer.spec.drawsHalo && star.size > 1.6 {
            context.blendMode = .plusLighter
            let haloRect = CGRect(x: px - r * 3, y: py - r * 3, width: r * 6, height: r * 6)
            context.fill(
                Path(ellipseIn: haloRect),
                with: .radialGradient(
                    Gradient(colors: [tint.opacity(opacity * 0.38), .clear]),
                    center: CGPoint(x: px, y: py),
                    startRadius: 0,
                    endRadius: r * 3
                )
            )
        }

        context.fill(
            Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
            with: .color(tint.opacity(opacity))
        )

        context.blendMode = .normal
    }

}

#if canImport(CoreMotion) && !os(macOS)

/// Lee la inclinacion del dispositivo con el acelerometro (el mismo que ya usa
/// SomaticService) y la entrega normalizada (-1...1), tomando como cero la postura en la
/// que se abrio la pantalla. Va amortiguado para que no maree y a 20 Hz, que para un
/// fondo que se mueve unos puntos es de sobra.
private final class DeviceTiltReader: ObservableObject {
    @Published var value: CGSize = .zero

    private let motionManager = CMMotionManager()
    private var baseline: (x: Double, y: Double)?

    func start() {
        // Cada vez que la vista aparece, la postura de referencia se toma de nuevo: si no,
        // al volver se mediria contra la inclinacion de la sesion anterior y daria un salto.
        baseline = nil
        guard motionManager.isAccelerometerAvailable, !motionManager.isAccelerometerActive else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 20.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            guard let base = self.baseline else {
                self.baseline = (x, y)
                return
            }
            // +-0.35 g respecto a la postura inicial = fondo de escala.
            let full = 0.35
            let dx = (x - base.x) / full
            let dy = (y - base.y) / full
            let clamped = CGSize(width: max(-1, min(1, dx)), height: max(-1, min(1, dy)))
            withAnimation(.easeOut(duration: 0.35)) { self.value = clamped }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        value = .zero
    }
}

#endif
