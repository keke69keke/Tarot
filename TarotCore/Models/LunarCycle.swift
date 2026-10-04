import Foundation

/// Las ocho fases del ciclo lunar, con su intención y su ritual.
///
/// El cálculo es determinista y puro (mes sinódico medio desde una luna nueva
/// de referencia), sin dependencias ni red: el mismo día da siempre la misma
/// fase en cualquier dispositivo.
public enum LunarPhaseKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    public var id: String { rawValue }

    /// Nombre completo, como se lee en el ritual.
    public var nombre: String {
        switch self {
        case .newMoon: return "Luna nueva"
        case .waxingCrescent: return "Luna creciente"
        case .firstQuarter: return "Cuarto creciente"
        case .waxingGibbous: return "Gibosa creciente"
        case .fullMoon: return "Luna llena"
        case .waningGibbous: return "Gibosa menguante"
        case .lastQuarter: return "Cuarto menguante"
        case .waningCrescent: return "Luna menguante"
        }
    }

    /// Una sola palabra: el eje de la fase.
    public var palabra: String {
        switch self {
        case .newMoon: return "Semilla"
        case .waxingCrescent: return "Impulso"
        case .firstQuarter: return "Decisión"
        case .waxingGibbous: return "Detalle"
        case .fullMoon: return "Claridad"
        case .waningGibbous: return "Reparto"
        case .lastQuarter: return "Poda"
        case .waningCrescent: return "Descanso"
        }
    }

    /// Qué se trabaja en esta fase.
    public var intencion: String {
        switch self {
        case .newMoon:
            return "Plantar una sola intención para el ciclo que empieza, sin explicarla todavía."
        case .waxingCrescent:
            return "Mover la intención: el primer paso visible, aunque sea minúsculo."
        case .firstQuarter:
            return "Elegir: qué sostienes y qué sueltas cuando aparece la primera resistencia."
        case .waxingGibbous:
            return "Pulir y ordenar para que lo que crece tenga sitio donde crecer."
        case .fullMoon:
            return "Ver con claridad lo que estaba a medias y agradecer lo que ya floreció."
        case .waningGibbous:
            return "Repartir el hallazgo: lo que se comparte se integra."
        case .lastQuarter:
            return "Podar de verdad: dejar hueco material para lo que viene."
        case .waningCrescent:
            return "Soltar el ritmo y entregarse al descanso sin culpa."
        }
    }

    /// El ritual completo de la fase, en una frase que se pueda hacer hoy.
    public var ritual: String {
        switch self {
        case .newMoon:
            return "Enciende una vela y escribe en el diario una sola intención para este ciclo. Dila en voz alta una vez y guárdala: las semillas germinan en silencio."
        case .waxingCrescent:
            return "Haz cinco minutos de eso que llevas semanas aplazando. Cinco minutos contados. El movimiento es lo que alimenta el impulso."
        case .firstQuarter:
            return "Pide una opinión ajena sobre tu intención, revisa lo que no aguanta y decide en voz alta qué sostienes y qué sueltas."
        case .waxingGibbous:
            return "Ordena tu mesa, tu calendario y tu baraja. Termina un detalle pequeño que quede suelto: el orden de fuera sostiene el de dentro."
        case .fullMoon:
            return "Saca la carta que llevas días evitando leer, mírala sin prisa y escribe qué te muestra. Después agradece en voz alta lo que ya floreció."
        case .waningGibbous:
            return "Cuéntale tu hallazgo a alguien de confianza, o escríbelo para tu yo de dentro de un año. Lo que se guarda se diluye."
        case .lastQuarter:
            return "Suelta una cosa concreta: una suscripción, un compromiso, un objeto, un rencor pequeño. Que sea material, no mental."
        case .waningCrescent:
            return "Baja el ritmo a propósito: duerme, camina, respira. No cierres nada; deja que el ciclo se cierre solo."
        }
    }
}

/// Posición de la luna en un instante concreto.
public struct LunarPosition: Equatable, Sendable {
    public let kind: LunarPhaseKind
    /// Días transcurridos desde la última luna nueva (0 ..< mes sinódico).
    public let age: Double
    /// Fracción iluminada del disco, de 0 (nueva) a 1 (llena).
    public let illumination: Double
    public let date: Date

    public init(kind: LunarPhaseKind, age: Double, illumination: Double, date: Date) {
        self.kind = kind
        self.age = age
        self.illumination = illumination
        self.date = date
    }
}

/// Motor del ciclo lunar: todo puro y determinista.
public enum LunarCycle {
    /// Mes sinódico medio, en días.
    public static let synodicMonth: Double = 29.530588853

    /// Luna nueva de referencia: 2000-01-06 18:14 UTC.
    public static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    /// Fase que corresponde a una edad concreta del ciclo.
    public static func kind(forAge age: Double) -> LunarPhaseKind {
        let octavo = synodicMonth / 8
        // Se redondea al octavo mas cercano en vez de truncar hacia abajo: los
        // hitos del ciclo (luna llena, cuartos) caen justo en el borde de un
        // octavo, y el error de coma flotante los dejaba en 1.9999... o
        // 3.9999..., empujandolos a la fase anterior.
        let indice = Int((age / octavo).rounded()) % 8
        switch indice {
        case 0: return .newMoon
        case 1: return .waxingCrescent
        case 2: return .firstQuarter
        case 3: return .waxingGibbous
        case 4: return .fullMoon
        case 5: return .waningGibbous
        case 6: return .lastQuarter
        default: return .waningCrescent
        }
    }

    /// Posición de la luna para una fecha.
    public static func position(for date: Date) -> LunarPosition {
        let dias = date.timeIntervalSince(referenceNewMoon) / 86_400
        var edad = dias.truncatingRemainder(dividingBy: synodicMonth)
        if edad < 0 { edad += synodicMonth }
        let iluminacion = (1 - cos(2 * Double.pi * edad / synodicMonth)) / 2
        return LunarPosition(
            kind: kind(forAge: edad),
            age: edad,
            illumination: min(1, max(0, iluminacion)),
            date: date
        )
    }

    /// Días que faltan (o han pasado, si es negativo) hasta una fase concreta.
    /// Fraccion del ciclo en la que ocurre una fase: 0 luna nueva, 1/8 creciente,
    /// 1/4 cuarto creciente, 1/2 llena, 3/4 cuarto menguante, y asi hasta 7/8.
    public static func fraction(of kind: LunarPhaseKind) -> Double {
        let indice = LunarPhaseKind.allCases.firstIndex(of: kind) ?? 0
        return Double(indice) / 8
    }

    /// Dias que faltan hasta la proxima vez que ocurre esa fase (0 < d <= mes sinodico).
    public static func daysUntil(_ objetivo: LunarPhaseKind, from date: Date) -> Double {
        var delta = fraction(of: objetivo) * synodicMonth - position(for: date).age
        while delta <= 0 { delta += synodicMonth }
        return delta
    }

    /// Las fases completas que vienen despues de una fecha, en orden.
    public static func upcoming(after date: Date, count: Int = 4) -> [(kind: LunarPhaseKind, date: Date)] {
        var resultado: [(LunarPhaseKind, Date)] = []
        var cursor = date
        for _ in 0..<count {
            let siguiente = LunarPhaseKind.allCases
                .map { ($0, daysUntil($0, from: cursor)) }
                .filter { $0.1 > 0.05 }
                .min { $0.1 < $1.1 }
            guard let (kind, dias) = siguiente else { break }
            let fecha = cursor.addingTimeInterval(dias * 86_400)
            resultado.append((kind, fecha))
            cursor = fecha.addingTimeInterval(86_400)
        }
        return resultado.map { (kind: $0.0, date: $0.1) }
    }
}
