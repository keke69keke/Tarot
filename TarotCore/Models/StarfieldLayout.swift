import CoreGraphics
import Foundation

// MARK: - Capas del cielo

/// Una capa de profundidad del fondo estrellado.
///
/// `depth` va de 0 (lo mas lejano) a 1 (primer plano). Todo lo de este archivo es
/// geometria y azar puros: no depende de SwiftUI, asi que se puede probar sin dibujar.
public struct StarLayerSpec: Equatable, Sendable {
    /// Distancia de la capa: 0 = fondo, 1 = primer plano.
    public let depth: Double
    /// Proporcion de estrellas del total que le toca a esta capa.
    public let fraction: Double
    public let sizeRange: ClosedRange<CGFloat>
    public let opacityRange: ClosedRange<Double>
    /// Desenfoque de la capa: la profundidad de campo es lo que vende la distancia.
    /// El fondo va con bruma (mas desenfocado cuanto mas lejos) y el bokeh de primer
    /// plano tambien va desenfocado a proposito, como en una foto con poca profundidad
    /// de campo; la capa nitida es la de las estrellas medias.
    public let blur: CGFloat
    /// Desplazamiento de la capa por unidad de inclinacion (0...1). La cercana se mueve mas.
    public let parallax: Double
    /// Deriva autonoma de la capa, en fracciones de pantalla por segundo. Va en el mismo
    /// sentido que el parallax: lo cercano se mueve mas que lo lejano.
    public let driftSpeed: Double
    /// Grados de giro 3D de la capa por unidad de inclinacion.
    public let tiltDegrees: Double
    /// Si dibuja halo en las estrellas grandes.
    public let drawsHalo: Bool
    /// Si la capa se pinta sumando luz (mezcla aditiva) en vez de tapando lo de atras.
    /// Un foco desenfocado y un halo suman luz; un disco opaco sobre las estrellas de
    /// detras las apaga y parece una mancha.
    public let addsLight: Bool

    public init(
        depth: Double,
        fraction: Double,
        sizeRange: ClosedRange<CGFloat>,
        opacityRange: ClosedRange<Double>,
        blur: CGFloat,
        parallax: Double,
        driftSpeed: Double,
        tiltDegrees: Double,
        drawsHalo: Bool,
        addsLight: Bool
    ) {
        self.depth = depth
        self.fraction = fraction
        self.sizeRange = sizeRange
        self.opacityRange = opacityRange
        self.blur = blur
        self.parallax = parallax
        self.driftSpeed = driftSpeed
        self.tiltDegrees = tiltDegrees
        self.drawsHalo = drawsHalo
        self.addsLight = addsLight
    }
}

/// Una estrella ya resuelta: posicion relativa (0...1) y aspecto.
public struct StarfieldStar: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let size: CGFloat
    /// 0 = estrella blanca fria, 1 = estrella ambar calida.
    public let warmth: Double
    public let opacity: Double
    public let twinkleDuration: Double
    public let twinkleDelay: Double

    public init(x: Double, y: Double, size: CGFloat, warmth: Double, opacity: Double, twinkleDuration: Double, twinkleDelay: Double) {
        self.x = x
        self.y = y
        self.size = size
        self.warmth = warmth
        self.opacity = opacity
        self.twinkleDuration = twinkleDuration
        self.twinkleDelay = twinkleDelay
    }
}

// MARK: - Geometria del cielo

/// Geometria y azar del fondo por capas.
public enum StarfieldLayout {

    /// Cinco profundidades: polvo lejano, estrellas medias, estrellas cercanas con halo
    /// y unas pocas motas grandes de primer plano. La suma de `fraction` es 1.
    public static let layers: [StarLayerSpec] = [
        StarLayerSpec(depth: 0.00, fraction: 0.40, sizeRange: 0.6...1.2, opacityRange: 0.22...0.50, blur: 1.1,  parallax: 0.10, driftSpeed: 0.0012, tiltDegrees: 0.6, drawsHalo: false, addsLight: false),
        StarLayerSpec(depth: 0.28, fraction: 0.28, sizeRange: 0.7...1.5, opacityRange: 0.30...0.62, blur: 0.7,  parallax: 0.30, driftSpeed: 0.0016, tiltDegrees: 1.5, drawsHalo: false, addsLight: false),
        StarLayerSpec(depth: 0.58, fraction: 0.20, sizeRange: 1.1...2.1, opacityRange: 0.42...0.85, blur: 0.50, parallax: 0.62, driftSpeed: 0.0021, tiltDegrees: 2.6, drawsHalo: true,  addsLight: false),
        StarLayerSpec(depth: 0.82, fraction: 0.09, sizeRange: 2.6...4.0, opacityRange: 0.62...1.00, blur: 0.0,  parallax: 0.85, driftSpeed: 0.0028, tiltDegrees: 3.6, drawsHalo: true,  addsLight: false),
        StarLayerSpec(depth: 1.00, fraction: 0.03, sizeRange: 3.8...5.6, opacityRange: 0.45...0.75, blur: 1.2,  parallax: 1.00, driftSpeed: 0.0035, tiltDegrees: 4.6, drawsHalo: true,  addsLight: true)
    ]

    /// Reparte `total` estrellas entre las capas segun su `fraction`.
    /// Garantiza que se devuelven tantos valores como capas y que la suma es exactamente `total`.
    public static func counts(total: Int) -> [Int] {
        guard total > 0 else { return Array(repeating: 0, count: layers.count) }
        if total <= layers.count {
            // Con muy pocas estrellas se reparte una por capa, empezando por la mas lejana.
            return (0..<layers.count).map { $0 < total ? 1 : 0 }
        }

        var result = layers.map { max(1, Int((Double(total) * $0.fraction).rounded())) }
        var difference = total - result.reduce(0, +)

        var index = 0
        while difference > 0 {
            result[index % result.count] += 1
            difference -= 1
            index += 1
        }
        index = 0
        // El sobrante se quita de las capas cercanas, que son las que menos estrellas llevan.
        while difference < 0 && index < 10 * result.count {
            let target = result.count - 1 - (index % result.count)
            if result[target] > 1 {
                result[target] -= 1
                difference += 1
            }
            index += 1
        }
        return result
    }

    /// Desplazamiento en puntos de una capa.
    /// `input` entra en -1...1 por eje (se recorta si viene fuera); el resultado nunca
    /// supera `maxOffset` y la capa mas cercana se desplaza mas que la lejana.
    public static func parallaxOffset(parallax: Double, depth: Double, input: CGSize, maxOffset: CGFloat) -> CGSize {
        let clampedX = min(max(input.width, -1), 1)
        let clampedY = min(max(input.height, -1), 1)
        let factor = CGFloat(min(max(parallax, 0), 1)) * CGFloat(min(max(depth, 0), 1))
        return CGSize(width: clampedX * maxOffset * factor, height: clampedY * maxOffset * factor)
    }

    /// Estrellas de una capa. Mismo `seed` = mismo cielo, en cualquier dispositivo y en
    /// cualquier aparicion, que es lo que evita que el fondo de saltos al navegar.
    public static func stars(seed: UInt64, count: Int, spec: StarLayerSpec) -> [StarfieldStar] {
        guard count > 0 else { return [] }
        var rng = SeededGenerator(seed: seed)
        return (0..<count).map { _ in
            StarfieldStar(
                x: Double.random(in: 0...1, using: &rng),
                y: Double.random(in: 0...1, using: &rng),
                size: CGFloat.random(in: spec.sizeRange, using: &rng),
                // Perspectiva atmosferica: lo lejano se apaga y se lava hacia el blanco
                // y lo cercano tiende al ambar. En una imagen fija es la pista de
                // profundidad que mas se nota, mas que el tamano.
                warmth: min(1, 0.35 * spec.depth + Double.random(in: 0...1, using: &rng) * (0.35 + 0.65 * spec.depth)),
                opacity: Double.random(in: spec.opacityRange, using: &rng),
                twinkleDuration: Double.random(in: 1.8...5.5, using: &rng),
                twinkleDelay: Double.random(in: 0...6, using: &rng)
            )
        }
    }

    /// PRNG SplitMix64: determinista, sin estado compartido y con buena distribucion
    /// para repartir estrellas por la pantalla.
    /// Escala minima que necesita una capa para que su desplazamiento no deje un borde sin
    /// estrellas. La escala esta anclada al centro, asi que por cada lado cubre la mitad del
    /// recorrido: de ahi el factor 2. Quitarlo no se nota con el fondo quieto, pero deja
    /// franjas vacias en las capas cercanas al llevar el parallax a tope, que es justo lo que
    /// paso una vez. El margen extra absorbe ademas el estrechamiento que provoca la
    /// perspectiva del giro 3D.
    public static func coverScale(
        parallax: Double,
        size: CGSize,
        maxOffset: CGFloat,
        margin: CGFloat = 12
    ) -> CGFloat {
        guard size.width > 1, size.height > 1 else { return 1 }
        let p = CGFloat(min(max(parallax, 0), 1))
        let shift = 2 * maxOffset * p + margin
        return 1 + max(shift / size.width, shift / size.height)
    }

    public struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64
        public init(seed: UInt64) { state = seed }
        public mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
}
