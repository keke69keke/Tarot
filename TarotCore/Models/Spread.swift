import Foundation
import CoreGraphics

/// Defines a specific location within a spread (e.g., "The Past", "The Goal").
public struct SpreadPosition: Codable, Identifiable, Hashable {
    public let id: UUID
    public let type: SpreadPositionType?
    public var name: String
    public var displayName: String
    public var description: String?
    public var layoutCoordinate: CGPoint?

    // Custom initializer for easy creation
    public init(name: String, displayName: String? = nil, description: String? = nil, layoutCoordinate: CGPoint? = nil) {
        self.id = UUID()
        self.type = SpreadPositionType(rawValue: name)
        self.name = name
        self.displayName = displayName ?? name
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }

    // Compatibility initializer for older tests and modules.
    public init(id: SpreadPositionType, displayName: String, layoutCoordinate: CGPoint = .zero, description: String? = nil) {
        self.id = UUID()
        self.type = id
        self.name = id.rawValue
        self.displayName = displayName
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }

    // MARK: - Codable (Manual so `id` (UUID) and `layoutCoordinate` (CGPoint) encode cleanly)
    private enum CodingKeys: String, CodingKey {
        case id, type, name, displayName, description, layoutCoordinate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(layoutCoordinate, forKey: .layoutCoordinate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decodeIfPresent(SpreadPositionType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.layoutCoordinate = try container.decodeIfPresent(CGPoint.self, forKey: .layoutCoordinate)
    }
}

/// A lightweight set of common spread presets used across the app.
public enum SpreadType: String, CaseIterable, Codable, Identifiable {
    case dailyCard
    case threeCard
    case celticCross
    case fiveCard
    case horseshoe
    case relationship
    case twelveMonth
    case decision
    case pathOfLife
    case free          // Tirada libre: el usuario elige cuántas cartas
    
    // Phase 3 Extensions
    case astrological
    case chakraSpread
    case hexagram

    // Phase 4 — Esoteric Spreads
    case temperance       // La Templanza — Equilibrio Alquímico (6 cards)
    case treeOfLife       // Árbol de la Vida — 10 Sefirot Cabalísticas
    case starDavid        // Estrella de David — Hexagrama Sagrado (7 cards)
    case soulMirror       // Espejo del Alma — Sanación profunda (9 cards)
    case alchemyPath      // Gran Obra Alquímica — Nigredo→Rubedo (4 cards)
    case moonCycle        // Ciclo Lunar — 4 fases lunares

    // Phase 5 — New Practical Spreads
    case pyramid          // La Pirámide — Crecimiento espiritual (6 cards)
    case yesNo            // Lectura de Sí/No — Respuesta clara (3 cards)
    case lineage          // El Linaje — Herencia y propósito (7 cards)

    /// Returns the canonical positions for this spread type.
    public var positions: [SpreadPosition] {
        switch self {
        case .dailyCard:
            return [SpreadPosition(name: "Diario", description: "La energía que guía tu día")]
        case .threeCard:
            return [
                SpreadPosition(name: "Pasado", description: "Lo que ha dado forma a tu situación actual"),
                SpreadPosition(name: "Presente", description: "La energía dominante en este momento"),
                SpreadPosition(name: "Futuro", description: "El camino que se abre ante ti")
            ]
        case .celticCross:
            return [
                SpreadPosition(name: "Presente", description: "El corazón de la cuestión"),
                SpreadPosition(name: "Desafío", description: "Lo que se cruza en tu camino"),
                SpreadPosition(name: "Pasado", description: "Influencias del pasado reciente"),
                SpreadPosition(name: "Futuro", description: "Lo que se aproxima en el horizonte"),
                SpreadPosition(name: "Encima", description: "Tu objetivo consciente o ideal"),
                SpreadPosition(name: "Debajo", description: "La base inconsciente de la situación"),
                SpreadPosition(name: "Consejo", description: "La acción recomendada"),
                SpreadPosition(name: "Entorno", description: "Influencias externas y personas clave"),
                SpreadPosition(name: "Esperanzas", description: "Tus esperanzas y temores secretos"),
                SpreadPosition(name: "Resultado", description: "El desenlace probable si continúas este camino")
            ]
        case .fiveCard:
            return [
                SpreadPosition(name: "Situación", description: "El contexto central"),
                SpreadPosition(name: "Obstáculo", description: "Lo que bloquea tu avance"),
                SpreadPosition(name: "Acción", description: "La acción más poderosa que puedes tomar"),
                SpreadPosition(name: "Resultado", description: "El fruto de tu acción"),
                SpreadPosition(name: "Consejo", description: "Sabiduría del Arcano Mayor")
            ]
        case .horseshoe:
            return [
                SpreadPosition(name: "Pasado", description: "Influencias del pasado lejano"),
                SpreadPosition(name: "Presente", description: "El estado actual"),
                SpreadPosition(name: "Oculto", description: "Lo que permanece velado"),
                SpreadPosition(name: "Consejo", description: "El consejo del Tarot"),
                SpreadPosition(name: "Futuro Cercano", description: "Lo que viene en semanas"),
                SpreadPosition(name: "Futuro Lejano", description: "El horizonte a largo plazo"),
                SpreadPosition(name: "Resultado", description: "El resultado final")
            ]
        case .relationship:
            return [
                SpreadPosition(name: "Tú", description: "Tu energía en la relación"),
                SpreadPosition(name: "Pareja", description: "La energía de tu pareja"),
                SpreadPosition(name: "Fortalezas", description: "Los pilares que sostienen la relación"),
                SpreadPosition(name: "Desafíos", description: "Las tensiones a trabajar"),
                SpreadPosition(name: "Camino Mutuo", description: "El camino que construís juntos"),
                SpreadPosition(name: "Consejo", description: "Lo que el Tarot recomienda"),
                SpreadPosition(name: "Resultado", description: "El potencial de la relación")
            ]
        case .twelveMonth:
            return (1...12).map { i in
                let months = ["Enero","Febrero","Marzo","Abril","Mayo","Junio",
                              "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"]
                return SpreadPosition(name: "Mes \(i)", displayName: months[i-1],
                                      description: "Energía dominante en \(months[i-1])")
            }
        case .decision:
            return [
                SpreadPosition(name: "Situación", description: "El núcleo de tu dilema"),
                SpreadPosition(name: "Elección", description: "La naturaleza de la decisión que enfrentas"),
                SpreadPosition(name: "Consecuencia", description: "El resultado probable de tu elección"),
                SpreadPosition(name: "Consejo", description: "La sabiduría superior que te guía")
            ]
        case .pathOfLife:
            return [
                SpreadPosition(name: "Pasado", description: "Las raíces de tu camino"),
                SpreadPosition(name: "Presente", description: "El punto donde te encuentras"),
                SpreadPosition(name: "Futuro", description: "A dónde te dirige el camino"),
                SpreadPosition(name: "Desafío", description: "El mayor obstáculo a superar"),
                SpreadPosition(name: "Fortaleza", description: "Tu don más poderoso"),
                SpreadPosition(name: "Consejo", description: "La acción sabia a tomar"),
                SpreadPosition(name: "Resultado", description: "El destino al que te encaminas"),
                SpreadPosition(name: "Oculto", description: "Lo que aún no ves pero influye"),
                SpreadPosition(name: "Guía", description: "El arquetipo que te acompaña")
            ]
        case .astrological:
            return [
                SpreadPosition(name: "Casa 1: Yo", description: "Tu identidad, apariencia y comienzos"),
                SpreadPosition(name: "Casa 2: Dinero", description: "Recursos, valores y posesiones"),
                SpreadPosition(name: "Casa 3: Comunicación", description: "Mente, hermanos, viajes cortos"),
                SpreadPosition(name: "Casa 4: Hogar", description: "Familia, raíces, el pasado"),
                SpreadPosition(name: "Casa 5: Creatividad", description: "Placeres, romance, creatividad"),
                SpreadPosition(name: "Casa 6: Salud", description: "Trabajo, salud, servicio"),
                SpreadPosition(name: "Casa 7: Pareja", description: "Relaciones, socios, el 'otro'"),
                SpreadPosition(name: "Casa 8: Transformación", description: "Muerte, regeneración, lo oculto"),
                SpreadPosition(name: "Casa 9: Filosofía", description: "Creencias, viajes largos, enseñanzas"),
                SpreadPosition(name: "Casa 10: Carrera", description: "Reputación, vocación, éxito público"),
                SpreadPosition(name: "Casa 11: Amigos", description: "Comunidad, esperanzas, ideales"),
                SpreadPosition(name: "Casa 12: Subconsciente", description: "Lo oculto, karma, limitaciones")
            ]
        case .chakraSpread:
            return [
                SpreadPosition(name: "Chakra Raíz", description: "Seguridad, supervivencia, tierra. Color: Rojo"),
                SpreadPosition(name: "Chakra Sacro", description: "Creatividad, sexualidad, emociones. Color: Naranja"),
                SpreadPosition(name: "Chakra del Plexo Solar", description: "Poder personal, voluntad, ego. Color: Amarillo"),
                SpreadPosition(name: "Chakra del Corazón", description: "Amor, compasión, sanación. Color: Verde"),
                SpreadPosition(name: "Chakra de la Garganta", description: "Comunicación, verdad, expresión. Color: Azul"),
                SpreadPosition(name: "Chakra del Tercer Ojo", description: "Intuición, visión, sabiduría. Color: Índigo"),
                SpreadPosition(name: "Chakra Corona", description: "Conexión divina, conciencia pura. Color: Violeta")
            ]
        case .hexagram:
            return [
                SpreadPosition(name: "Pasado", description: "Las causas que originaron la situación"),
                SpreadPosition(name: "Presente", description: "La energía actual"),
                SpreadPosition(name: "Futuro", description: "El potencial que se despliega"),
                SpreadPosition(name: "Consejo Oculto", description: "La sabiduría que permanece velada"),
                SpreadPosition(name: "Entorno", description: "Las fuerzas externas que actúan"),
                SpreadPosition(name: "Esperanzas/Temores", description: "Lo que anhelas y lo que temes"),
                SpreadPosition(name: "Resultado Final", description: "La síntesis y desenlace")
            ]

        // MARK: Phase 4 — Esoteric Spreads

        case .temperance:
            return [
                SpreadPosition(name: "Agua — Lo Fluido", description: "Tu naturaleza emocional, receptiva, femenina. El río que cedes."),
                SpreadPosition(name: "Fuego — Lo Activo", description: "Tu voluntad, acción, impulso creativo. La llama que avanza."),
                SpreadPosition(name: "Cuerpo — Tierra", description: "El plano físico, la salud, las necesidades materiales."),
                SpreadPosition(name: "Espíritu — Éter", description: "Tu dimensión espiritual, alma, propósito superior."),
                SpreadPosition(name: "Desequilibrio", description: "Lo que actualmente está fuera de balance en tu vida."),
                SpreadPosition(name: "Templanza — Síntesis", description: "La alquimia que une los opuestos. El punto de equilibrio perfecto.")
            ]

        case .treeOfLife:
            return [
                SpreadPosition(name: "Kether — La Corona", description: "Conciencia pura, unidad con lo divino. El punto de origen."),
                SpreadPosition(name: "Chokmah — Sabiduría", description: "La fuerza creativa masculina, el Padre. Impulso primordial."),
                SpreadPosition(name: "Binah — Comprensión", description: "La forma receptiva femenina, la Madre. La Gran Mar."),
                SpreadPosition(name: "Chesed — Misericordia", description: "Amor, abundancia, generosidad. El rey benevolente."),
                SpreadPosition(name: "Geburah — Fuerza", description: "Poder, rigor, disciplina. La espada que corta lo innecesario."),
                SpreadPosition(name: "Tiphareth — Belleza", description: "El corazón del árbol. El Sol, el Cristo, el ser solar."),
                SpreadPosition(name: "Netzach — Victoria", description: "Emociones, deseos, naturaleza, Arte y Venus."),
                SpreadPosition(name: "Hod — Esplendor", description: "Intelecto, comunicación, magia ceremonial. Mercurio."),
                SpreadPosition(name: "Yesod — Fundamento", description: "El inconsciente, la Luna, los sueños, la memoria astral."),
                SpreadPosition(name: "Malkuth — El Reino", description: "La tierra, el cuerpo físico, la manifestación material.")
            ]

        case .starDavid:
            return [
                SpreadPosition(name: "Punto Norte — Fuego", description: "Tu voluntad ascendente, aspiración y propósito espiritual."),
                SpreadPosition(name: "Punto Sureste — Agua", description: "Tus emociones profundas, el inconsciente que fluye."),
                SpreadPosition(name: "Punto Suroeste — Tierra", description: "Tu fundamento material, recursos y realidad tangible."),
                SpreadPosition(name: "Punto Sur — Aire", description: "Tu mente, pensamientos y comunicación actuales."),
                SpreadPosition(name: "Punto Noreste — Espíritu", description: "Tu conexión con lo divino y la guía superior."),
                SpreadPosition(name: "Punto Noroeste — Tiempo", description: "El ciclo temporal: qué debe terminar y qué comenzar."),
                SpreadPosition(name: "Centro — Integración", description: "La síntesis alquímica de todos los elementos. Tu verdad central.")
            ]

        case .soulMirror:
            return [
                SpreadPosition(name: "Máscara — Persona", description: "La cara que muestras al mundo. Tu identidad social."),
                SpreadPosition(name: "Sombra — Inconsciente", description: "Lo que niegas o reprimes. Tu lado oscuro integrable."),
                SpreadPosition(name: "Anima/Animus", description: "Tu principio femenino/masculino interno. El complemento interior."),
                SpreadPosition(name: "Herida de Infancia", description: "El dolor temprano que aún condiciona tus respuestas."),
                SpreadPosition(name: "Don Oculto", description: "La fortaleza escondida bajo tu herida. Tu superpoder invisible."),
                SpreadPosition(name: "Patrón Kármico", description: "El ciclo que se repite en tu vida. El tema de tu alma."),
                SpreadPosition(name: "Llamado del Alma", description: "Tu vocación profunda. Para qué viniste a este mundo."),
                SpreadPosition(name: "Obstáculo Principal", description: "El mayor bloqueo a tu evolución espiritual actual."),
                SpreadPosition(name: "Integración — El Sí Mismo", description: "El arquetipo central. Quién eres cuando todo se integra.")
            ]

        case .alchemyPath:
            return [
                SpreadPosition(name: "Nigredo — Putrefacción", description: "La oscuridad, el caos, la disolución. ¿Qué debe morir en ti?"),
                SpreadPosition(name: "Albedo — Purificación", description: "La limpieza, la claridad emergente. ¿Qué se purifica en ti?"),
                SpreadPosition(name: "Citrinitas — Iluminación", description: "La conciencia solar, el amanecer del alma. ¿Qué se ilumina?"),
                SpreadPosition(name: "Rubedo — Perfección", description: "La Piedra Filosofal, la transmutación completa. ¿Quién emerges?")
            ]

case .moonCycle:
            return [
                SpreadPosition(name: "Luna Nueva — Semilla", description: "Lo que planta su semilla en tu vida. Nuevos comienzos e intenciones."),
                SpreadPosition(name: "Luna Creciente — Acción", description: "Lo que crece y pide tu acción y esfuerzo activo."),
                SpreadPosition(name: "Luna Llena — Plenitud", description: "Lo que llega a su máxima expresión. La revelación y la cosecha."),
                SpreadPosition(name: "Luna Menguante — Liberación", description: "Lo que debe soltarse, liberarse y transformarse antes del nuevo ciclo.")
            ]

        // MARK: Phase 5 — New Practical Spreads

        case .pyramid:
            return [
                SpreadPosition(name: "Base Izquierda — Raíces", description: "Tus cimientos, origen y lo que te sostiene."),
                SpreadPosition(name: "Base Centro — Equilibrio", description: "El estado presente de tu vida y tu centro."),
                SpreadPosition(name: "Base Derecha — Recursos", description: "Tus talentos y herramientas disponibles."),
                SpreadPosition(name: "Nivel Medio Izquierdo — Desafío", description: "El obstáculo que debes superar para crecer."),
                SpreadPosition(name: "Nivel Medio Derecho — Maestría", description: "La lección que estás aprendiendo ahora."),
                SpreadPosition(name: "Vértice — Ascensión", description: "La cima de tu crecimiento espiritual y el potencial más alto.")
            ]

        case .yesNo:
            return [
                SpreadPosition(name: "Situación Actual", description: "El contexto real de tu pregunta."),
                SpreadPosition(name: "Influencia Oculta", description: "Lo que impulsa o bloquea la respuesta."),
                SpreadPosition(name: "Resultado / Respuesta", description: "La tendencia y el desenlace probable.")
            ]

        case .lineage:
            return [
                SpreadPosition(name: "Linaje Familiar", description: "La herencia emocional y de patrones que cargas."),
                SpreadPosition(name: "Abuelos", description: "Las raíces ancestrales y su legado."),
                SpreadPosition(name: "Padres", description: "Lo que aprendiste de tus figuras parentales."),
                SpreadPosition(name: "Infancia", description: "Los condicionamientos tempranos de tu vida."),
                SpreadPosition(name: "Patrón Kármico", description: "El ciclo que se repite y debes sanar."),
                SpreadPosition(name: "Propósito", description: "La misión que trasciende tu linaje."),
                                SpreadPosition(name: "Liberación", description: "Lo que puedes soltar para honrar tu propio camino.")
            ]
        case .free:
            // Tirada libre por defecto (5 cartas); el usuario puede cambiarlo vía freeCardCount
            return (1...5).map { i in
                SpreadPosition(name: "Carta \(i)", displayName: "Carta \(i)",
                               description: "Posición libre \(i) de tu tirada.")
            }
        }
    }

    public var label: String {
        switch self {
        case .dailyCard:    return "Carta del día"
        case .threeCard:    return "Tres cartas"
        case .celticCross:  return "Cruz celta"
        case .fiveCard:     return "Cinco cartas"
        case .horseshoe:    return "Herradura (7)"
        case .relationship: return "Relaciones"
        case .twelveMonth:  return "12 meses"
        case .decision:     return "Decisión"
        case .pathOfLife:   return "Camino de vida"
        case .astrological: return "Astrológica (12 casas)"
        case .chakraSpread: return "Alineación de Chakras"
        case .hexagram:     return "Hexagrama"
        case .temperance:   return "✦ La Templanza"
        case .treeOfLife:   return "✦ Árbol de la Vida"
        case .starDavid:    return "✦ Estrella de David"
        case .soulMirror:   return "✦ Espejo del Alma"
        case .alchemyPath:  return "✦ Gran Obra Alquímica"
        case .moonCycle:    return "✦ Ciclo Lunar"
        case .pyramid:      return "✦ La Pirámide"
        case .yesNo:        return "✦ Sí / No"
        case .lineage:      return "✦ El Linaje"
        case .free:         return "Tirada libre"
        }
    }

    /// Short esoteric description shown in the spread selector.
    public var esotericDescription: String {
        switch self {
        case .dailyCard:    return "Una carta para enfocar tu energía diaria"
        case .threeCard:    return "Pasado, Presente y Futuro en tres cartas"
        case .celticCross:  return "La tirada más completa y profunda del Tarot"
        case .fiveCard:     return "Situación, obstáculo, acción y resultado"
        case .horseshoe:    return "Siete cartas en arco para visión completa"
        case .relationship: return "Dinámica profunda de pareja y vínculos"
        case .twelveMonth:  return "Un año completo, mes a mes"
        case .decision:     return "Claridad ante una elección importante"
        case .pathOfLife:   return "Tu camino vital en 9 cartas"
        case .astrological: return "Las 12 casas de tu cielo natal"
        case .chakraSpread: return "El estado de tus 7 centros energéticos"
        case .hexagram:     return "La Estrella de 6 puntas y el destino"
        case .temperance:   return "Equilibrio alquímico entre opuestos — Arcano XIV"
        case .treeOfLife:   return "Las 10 Sefirot del Árbol Cabalístico"
        case .starDavid:    return "Los 6 elementos sagrados + el centro integrador"
        case .soulMirror:   return "Exploración profunda del inconsciente y la sombra"
        case .alchemyPath:  return "Nigredo → Albedo → Citrinitas → Rubedo"
        case .moonCycle:    return "Las 4 fases lunares como guía espiritual"
        case .pyramid:      return "Base → Maestría → Vértice: tu crecimiento espiritual"
        case .yesNo:        return "Respuesta clara y orientadora ante una pregunta binaria"
        case .lineage:      return "Herencia, patrones familiares y propósito de tu alma"
        case .free:         return "Elige cuántas cartas se reparten y deja que el Triunfo guíe tu lectura"
        }
    }

    public var id: String { rawValue }

    /// Minimal jewel-like glyph — monocromo, se tiñe en oro en UI. Nada de emoji color.
    public var symbol: String {
        switch self {
        case .dailyCard:    return "○"
        case .threeCard:    return "◇"
        case .celticCross:  return "✚"
        case .fiveCard:     return "⬖"
        case .horseshoe:    return "⌒"
        case .relationship: return "∞"
        case .twelveMonth:  return "◎"
        case .decision:     return "⬔"
        case .pathOfLife:   return "⟡"
        case .astrological: return "✶"
        case .chakraSpread: return "◍"
        case .hexagram:     return "⬡"
        case .temperance:   return "⬢"
        case .treeOfLife:   return "⟐"
        case .starDavid:    return "✦"
        case .soulMirror:   return "◐"
        case .alchemyPath:  return "⬣"
        case .moonCycle:    return "☾"
        case .pyramid:      return "△"
        case .yesNo:        return "⬔"
        case .lineage:      return "⬡"
        case .free:         return "⁂"
        }
    }
}

public extension SpreadPositionType {
    static func from(_ rawValue: String) -> SpreadPositionType? {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "daily", "diario": return .daily
        case "past", "pasado": return .past
        case "present", "presente": return .present
        case "future", "futuro": return .future
        case "advice", "consejo": return .advice
        case "outcome", "resultado": return .outcome
        case "challenge", "desafío", "desafio": return .challenge
        case "strength", "fortaleza": return .strength
        case "shadow", "sombra": return .shadow
        case "environment", "entorno": return .environment
        case "unknown", "desconocido": return .unknown
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .daily: return "Diario"
        case .past: return "Pasado"
        case .present: return "Presente"
        case .future: return "Futuro"
        case .advice: return "Consejo"
        case .outcome: return "Resultado"
        case .challenge: return "Desafío"
        case .strength: return "Fortaleza"
        case .shadow: return "Sombra"
        case .environment: return "Entorno"
        case .unknown: return "Desconocido"
        }
    }
}

/// Represents a collection of positions that define the structure of a reading.
public struct Spread: Codable {
    /// Optional spread metadata kept for compatibility with older code: a spread may have a type and creation date.
    public var type: SpreadType?
    public var createdAt: Date?

    /// The standard, predefined positions (e.g., Past, Present, Future).
    public var standardPositions: [SpreadPosition]
    
    /// Optional list of custom/advanced positions defined by the user for this specific spread.
    /// If present, these take precedence or are added to the standard set.
    public var customPositions: [SpreadPosition]?

    /// Compatibility: some older code expects a list of drawn cards attached to the spread.
    public var drawnCards: [DrawnCard] = []

    // MARK: Initializers
    
    /// Initializes a Spread with only standard positions (e.g., 3-Card Spread).
    public init(standardPositions: [SpreadPosition]) {
        self.standardPositions = standardPositions
        self.customPositions = nil
        self.type = nil
        self.createdAt = nil
    }
    
    /// Initializes a Spread with custom positions, overriding or augmenting the standard set.
    public init(customPositions: [SpreadPosition], standardPositions: [SpreadPosition] = []) {
        self.customPositions = customPositions
        // If no standard positions are provided, use an empty array; otherwise, merge them.
        self.standardPositions = standardPositions.isEmpty ? [] : standardPositions
        self.type = nil
        self.createdAt = nil
    }

    /// Compatibility initializer: build a Spread from a SpreadType, drawn cards and createdAt.
    public init(type: SpreadType, drawnCards: [DrawnCard], createdAt: Date = Date()) {
        self.type = type
        self.createdAt = createdAt
        self.standardPositions = type.positions
        self.customPositions = nil
        self.drawnCards = drawnCards
    }

    /// Helper to get all unique positions in the spread, preservando orden semántico de la tirada.
    public var allPositions: [SpreadPosition] {
        var positions = self.standardPositions
        if let custom = self.customPositions {
            for customPos in custom where !positions.contains(where: { $0.id == customPos.id }) {
                positions.append(customPos)
            }
        }
        return positions
    }
}

// MARK: - Guía extendida de tiradas (información adicional)

public extension SpreadType {

    /// Breve relato de origen/tradición de la tirada.
    var story: String {
        switch self {
        case .dailyCard:
            return "La carta diaria es la práctica más antigua del tarot moderno: una sola carta contemplada cada mañana, herencia de los bancos de meditación de las órdenes herméticas del siglo XIX."
        case .threeCard:
            return "La tirada de tres cartas es la columna vertebral del tarot clásico: pasado, presente y futuro. Aparece ya en manuales franceses del XVIII y es la puerta de entrada recomendada por Waite."
        case .celticCross:
            return "La Cruz Celta fue popularizada por A. E. Waite en 'The Pictorial Key to the Tarot' (1910) y es la tirada más documentada de la tradición Rider-Waite: diez posiciones, dos cruces y un palo."
        case .fiveCard:
            return "Variante práctica derivada de la Cruz Celta, condensada a cinco posiciones para consultas concretas. Muy usada por lectores profesionales por su equilibrio entre profundidad y agilidad."
        case .horseshoe:
            return "La Herradura llega del tarot inglés victoriano: siete cartas en arco que simulan el amuleto de la suerte, leyendo el pasado lejano hasta el desenlace como un arco temporal."
        case .relationship:
            return "Las tiradas de vínculo se desarrollaron en el tarot psicológico del siglo XX, influido por Jung: dos columnas de energía (tú y el otro) que se encuentran en posiciones compartidas."
        case .twelveMonth:
            return "La rueda anual de doce casas toma prestada la estructura del horóscopo astrológico: una carta por mes, del cumpleaños al cumpleaños, como los almanaques astrales victorianos."
        case .decision:
            return "La tirada de decisión nace del tarot práctico contemporáneo: cuatro cartas que diseccionan un dilema en núcleo, naturaleza, consecuencia y consejo."
        case .pathOfLife:
            return "Una síntesis moderna de las tiradas de 'camino', inspirada en el Arcano del Loco: nueve cartas que siguen tu trayectoria desde las raíces hasta la guía que te acompaña."
        case .astrological:
            return "Las doce casas zodiacales aplicadas al tarot vienen de la astrología horaria grecorromana; Golden Dawn las integró al tarot como 'the twelve houses spread'."
        case .chakraSpread:
            return "La alineación de chakras fusiona el tarot con el sistema yogui de siete centros energéticos, popularizada en el tarot transpersonal de los años 90."
        case .hexagram:
            return "El hexagrama de seis puntas (sello de Salomón) encierra la unión de opuestos: arriba-abajo, fuego-agua, y el centro que los integra."
        case .temperance:
            return "Inspirada en el Arcano XIV, la Templanza: el ángel que vierte agua entre dos copas. Es una tirada de equilibrio alquímico entre elementos."
        case .treeOfLife:
            return "Las diez Sefirot del Árbol de la Vida cabalístico, columnas vertebrales del esoterismo occidental; la Golden Dawn asignó a cada carta un sendero del Árbol."
        case .starDavid:
            return "La Estrella de David como mandala de lectura: seis elementos alrededor de un centro integrador, eco del sello salomónico de la tradición mágica."
        case .soulMirror:
            return "Tirada junguiana de sombra: nueve espejos que van de la máscara social a la integración del Sí Mismo, en la línea de 'El hombre y sus símbolos'."
        case .alchemyPath:
            return "Las cuatro etapas de la Gran Obra alquímica —nigredo, albedo, citrinitas y rubedo— aplicadas como mapa de transformación personal."
        case .moonCycle:
            return "Las cuatro fases lunares como reloj de intenciones: sembrar en luna nueva, actuar en creciente, cosechar en llena y soltar en menguante."
        case .pyramid:
            return "La Pirámide asciende de la base material a la cima espiritual: seis cartas que escalan raíces, equilibrio, recursos, desafío, maestría y ascensión."
        case .yesNo:
            return "La consulta binaria es el uso más antiguo del tarot adivinatorio: tres cartas que contextualizan, revelan lo oculto y apuntan la respuesta."
        case .lineage:
            return "Tirada ancestral: explora la herencia familiar, los patrones repetidos y la misión personal que trasciende el linaje."
        case .free:
            return "La tirada libre es la forma más honesta de leer: tú decides cuántas cartas y el sentido de cada posición emerge al revelarlas."
        }
    }

    /// Cuándo conviene usar esta tirada.
    var bestFor: String {
        switch self {
        case .dailyCard:    return "Enfocar el día, meditar una energía, rutina matutina."
        case .threeCard:    return "Consultas rápidas, panorama general, principiantes."
        case .celticCross:  return "Preguntas profundas y complejas; la consulta 'grande'."
        case .fiveCard:     return "Situaciones concretas con un bloqueo claro a resolver."
        case .horseshoe:    return "Visiones completas de un tema sin llegar a la Cruz Celta."
        case .relationship: return "Vínculos de pareja, amistades o socios."
        case .twelveMonth:  return "Planificar un año, cumpleaños, ciclos anuales."
        case .decision:     return "Encrucijadas: elegir entre dos caminos."
        case .pathOfLife:   return "Revisar trayectoria vital y propósito."
        case .astrological: return "Foto completa del año en las 12 áreas de vida."
        case .chakraSpread: return "Diagnóstico energético y equilibrio personal."
        case .hexagram:     return "Unir opuestos: espíritu-materia, yo-tú."
        case .temperance:   return "Restaurar el balance cuando algo se desborda."
        case .treeOfLife:   return "Estudio espiritual profundo y mapas del ser."
        case .starDavid:    return "Sintetizar elementos y encontrar tu verdad central."
        case .soulMirror:   return "Trabajo de sombra y autoconocimiento serio."
        case .alchemyPath:  return "Procesos de cambio interior en etapas."
        case .moonCycle:    return "Rituales de luna nueva y llena, intenciones."
        case .pyramid:      return "Crecimiento personal paso a paso."
        case .yesNo:        return "Preguntas cerradas que piden dirección clara."
        case .lineage:      return "Sanar historia familiar y honrar raíces."
        case .free:         return "Preguntas abiertas sin estructura prefijada."
        }
    }

    /// Cómo leer la tirada, paso a paso.
    var howToRead: String {
        switch self {
        case .dailyCard:    return "Respira, formula tu intención del día y revela la carta. Contémplala un minuto: imagen, color, gesto. Pregúntate qué energía invita a encarnar hoy."
        case .threeCard:    return "Lee de izquierda a derecha como una frase: lo que fue, lo que es, lo que viene. Busca la transición entre la segunda y la tercera: ahí vive tu poder de acción."
        case .celticCross:  return "Empieza por el corazón (1-2), sigue con la columna (5-6) y termina con el bastón (7-10). El cruce 1-2 es el nudo; el 10, la resolución."
        case .fiveCard:     return "Sitúa primero el problema (1-2), después el movimiento (3) y por último el desenlace (4-5). La carta 3 es tu palanca."
        case .horseshoe:    return "Recorre el arco de extremo a extremo como una línea de tiempo; el centro (4, el consejo) es el pivote de la lectura."
        case .relationship: return "Lee primero tu columna (1-2), después la del otro (2-3), y cierra con las cartas compartidas: ahí se decide el vínculo."
        case .twelveMonth:  return "Lee los meses en orden y toma nota; busca los meses con Arcanos Mayores: son tus estaciones fuertes del año."
        case .decision:     return "Nombra el dilema antes de barajar. Lee el núcleo (1), la naturaleza de la elección (2), la consecuencia (3) y deja el consejo (4) para el final."
        case .pathOfLife:   return "Sigue el sendero en orden: raíces, presente, futuro. Las cartas 8-9 (oculto y guía) se leen como un susurro al final."
        case .astrological: return "Recorre las casas como un día astrológico: del yo (1) al subconsciente (12). Prioriza las casas que resuenan con tu pregunta."
        case .chakraSpread: return "De la raíz a la corona. Donde aparezca una carta invertida o difícil, ahí hay un centro que pide atención."
        case .hexagram:     return "Lee los tres pares de opuestos primero y el centro al final: la síntesis responde a la pregunta."
        case .temperance:   return "Empieza por los elementos (1-4), mira el desequilibrio (5) y termina en la síntesis (6): tu punto de equilibrio."
        case .treeOfLife:   return "Desciende de Kether a Malkuth, de la idea a la materia. La carta de Tiphareth (6) es el corazón de la lectura."
        case .starDavid:    return "Lee los seis puntos en orden y cierra con el centro: la verdad integrada que responde a tu consulta."
        case .soulMirror:   return "Léela en privado y con calma. Máscara (1) y sombra (2) se sostienen entre sí; la integración final (9) es el espejo completo."
        case .alchemyPath:  return "Sigue las etapas en orden: qué muere (nigredo), qué se aclara (albedo), qué se ilumina (citrinitas) y quién emerge (rubedo)."
        case .moonCycle:    return "De la luna nueva a la menguante: qué sembrar, qué hacer, qué celebrar y qué soltar antes del próximo ciclo."
        case .pyramid:      return "Sube por la pirámide: base material (1-3), nivel de proceso (4-5) y cima (6). El vértice es el potencial máximo."
        case .yesNo:        return "Formula una pregunta cerrada. La carta 1 contextualiza, la 2 revela la fuerza oculta y la 3 inclina la balanza: léela con su orientación."
        case .lineage:      return "Lee de atrás hacia adelante si buscas sanar: linaje, abuelos, padres, infancia... y termina en liberación: tu propio camino."
        case .free:         return "Reparte las cartas que elegiste y nombra cada posición en voz alta conforme la revelas: el significado se construye al leerla."
        }
    }

    /// Texto de detalle listo para mostrar en el selector.
    var detailSummary: String {
        "\(positions.count) cartas · \(story) Cómo leerla: \(howToRead) Ideal para: \(bestFor)"
    }
}
