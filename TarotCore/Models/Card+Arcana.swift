import Foundation

// MARK: - Lectura en profundidad (derivada, sin datos nuevos)

/// Contenido interpretativo adicional derivado de forma determinista de los
/// datos que ya tiene el mazo: número/arcano, palo, astrología, luz-sombra.
public extension Card {

    /// Número de arcano/palo en valor numérico (As=1 ... 10; cortes 11-14).
    private var numericValue: Int? {
        if arcanaType == .major {
            return id // 0...21
        }
        let offset = id - 22
        guard offset >= 0 else { return nil }
        return (offset % 14) + 1
    }

    /// Significado numerológico/arquetípico del número de la carta.
    var numerologyMeaning: String {
        if let n = numerology, !n.isEmpty { return n }
        switch numericValue {
        case 0:  return "0 — El Potencial: todo comienza y todo es posible; el vacío fértil antes del salto."
        case 1:  return "1 — El Origen: chispa, iniciativa pura, la semilla de la energía del palo."
        case 2:  return "2 — El Equilibrio: polaridad, decisión entre dos fuerzas, alianza incipiente."
        case 3:  return "3 — La Creación: lo uno y lo dos engendran lo tres; expansión, primer fruto."
        case 4:  return "4 — La Estructura: cimientos, orden, estabilidad que sostiene el crecimiento."
        case 5:  return "5 — La Prueba: conflicto y pérdida que enseñan; crisis como maestra."
        case 6:  return "6 — La Armonía: cooperación, victoria moral, reconciliación tras la prueba."
        case 7:  return "7 — La Evaluación: estrategia, paciencia, dominio interior del elemento."
        case 8:  return "8 — El Movimiento: potencia, velocidad, la energía se vuelve acción."
        case 9:  return "9 — La Madurez: casi culminación; fuerza de carácter y autosuficiencia."
        case 10: return "10 — La Culminación: el ciclo del palo se cierra y abre el siguiente."
        case 11: return "Paje — El Mensajero: estudio, curiosidad, energía en aprendizaje."
        case 12: return "Caballero — La Búsqueda: acción enfocada, aventura, misión del palo."
        case 13: return "Reina — La Receptividad: dominio interior, madurez emocional del elemento."
        case 14: return "Rey — El Dominio: autoridad madura; la energía del palo plenamente encarnada."
        default:
            let major = ["El Potencial","El Mago: voluntad y palabra creadora","La Intuición: lo oculto que guía",
                         "La Fecundidad: creatividad y abundancia","La Autoridad: estructura y tradición",
                         "El Maestro: sabiduría convencional y alianza","Los Amantes: elección, unión y valores",
                         "El Carro: voluntad triunfante y dirección","La Fuerza: coraje y dominio suave",
                         "El Ermitaño: introspección y guía interior","La Rueda: ciclos y punto de inflexión",
                         "La Justicia: causa y efecto, verdad y balance","El Colgado: pausa y mirada invertida",
                         "La Muerte: fin de ciclo y transformación","La Templanza: equilibrio y alquimia",
                         "El Diablo: ataduras y sombra que pide integrarse","La Torre: ruptura reveladora",
                         "La Estrella: esperanza y sanación","La Luna: sueños y laberinto interior",
                         "El Sol: claridad, júbilo y éxito","El Juicio: renacer y llamado",
                         "El Mundo: plenitud y cierre del ciclo"]
            if arcanaType == .major, id < major.count { return "\(id) — \(major[id])" }
            return "Arquetipo de la carta en el ciclo del mazo."
        }
    }

    /// Elemento y temperamento del palo (o del arcano).
    var elementMeaning: String {
        if let e = element, !e.isEmpty { return e }
        switch suit {
        case .wands:    return "Fuego — voluntad, pasión, impulso creador."
        case .cups:     return "Agua — emoción, vínculo, memoria del corazón."
        case .swords:   return "Aire — mente, verdad, palabra que corta."
        case .pentacles:return "Tierra — cuerpo, materia, abundancia concreta."
        case nil:
            return arcanaType == .major
                ? "Éter — el arcano opera sobre todos los elementos."
                : "Elemento del palo."
        }
    }

    /// Simbolismo visual clásico de la carta (Rider-Waite).
    var symbolism: String {
        if let ls = lightShadow, !ls.isEmpty {
            return "Luz y sombra de la carta: \(ls)"
        }
        switch suit {
        case .wands:    return "Varas y brotes: el fuego vegetal. Escenas al aire libre, gestos de arranque, ríos de energía."
        case .cups:     return "Copas y fuentes: el agua emocional. Manos que ofrecen, jardines, encuentros frente al mar."
        case .swords:   return "Espadas y cielos nublados: el aire mental. Bordes cortantes, banderas, paisajes fríos y claros."
        case .pentacles:return "Pentáculos y jardines: la tierra que da fruto. Manos, monedas, viñedos y arquitectura sólida."
        case nil:
            return arcanaType == .major
                ? "Arcano Mayor: figuras arquetípicas, sol/luna, ángeles y caminos — la gran carpintería del destino."
                : "Escena simbólica del día a día: gestos, elementos y animales que hablan."
        }
    }

    /// Ángulos temáticos: amor, trabajo y camino espiritual.
    var loveReading: String {
        let base = uprightMeaning
        let kw = base.keywords.prefix(3).joined(separator: ", ").lowercased()
        return "En el amor resuena su corazón de \(kw). Busca cómo esta energía pide darse — o protegerse — en tus vínculos cercanos."
    }

    var workReading: String {
        let base = uprightMeaning
        let kw = base.keywords.prefix(3).joined(separator: ", ").lowercased()
        return "En el trabajo y la abundancia apunta a \(kw). Pregunta práctica: ¿qué paso concreto pide esta carta hoy?"
    }

    var spiritualReading: String {
        if let my = mythology, !my.isEmpty {
            return "En tu camino espiritual dialoga con su mito: \(my)"
        }
        if let ch = chakras, !ch.isEmpty {
            return "En tu camino espiritual activa los centros de \(ch.lowercased())."
        }
        return "En tu camino espiritual, \(name.lowercased()) invita a integrar su lección: \(uprightMeaning.keywords.first?.lowercased() ?? "el mensaje") como práctica diaria."
    }
}
