package com.arcana.tarot.core.models

/**
 * Posición dentro de una tirada (p. ej. "El Pasado", "La Meta").
 * Portado de `Spread.swift` / `SpreadPosition`.
 */
data class SpreadPosition(
    val name: String,
    val displayName: String = name,
    val description: String = ""
)

private val MONTHS = listOf(
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
)

private fun monthsSpread() = (1..12).map { i ->
    SpreadPosition(
        name = "Mes $i",
        displayName = MONTHS[i - 1],
        description = "Energía dominante en ${MONTHS[i - 1]}"
    )
}

private fun freeSpread(count: Int = 5) = (1..count).map { i ->
    SpreadPosition(
        name = "Carta $i",
        displayName = "Carta $i",
        description = "Posición libre $i de tu tirada."
    )
}

/**
 * Tiradas predefinidas de la app. Portado fiel de `SpreadType` en Swift,
 * incluyendo las tiradas esotéricas de las fases 4 y 5.
 */
enum class SpreadType(
    val label: String,
    val symbol: String,
    val esotericDescription: String
) {
    DAILY_CARD(
        "Carta del día", "○",
        "Una carta para enfocar tu energía diaria"
    ),
    THREE_CARD(
        "Tres cartas", "◇",
        "Pasado, Presente y Futuro en tres cartas"
    ),
    CELTIC_CROSS(
        "Cruz celta", "✚",
        "La tirada más completa y profunda del Tarot"
    ),
    FIVE_CARD(
        "Cinco cartas", "⬖",
        "Situación, obstáculo, acción y resultado"
    ),
    HORSESHOE(
        "Herradura (7)", "⌒",
        "Siete cartas en arco para visión completa"
    ),
    RELATIONSHIP(
        "Relaciones", "∞",
        "Dinámica profunda de pareja y vínculos"
    ),
    TWELVE_MONTH(
        "12 meses", "◎",
        "Un año completo, mes a mes"
    ),
    DECISION(
        "Decisión", "⬔",
        "Claridad ante una elección importante"
    ),
    PATH_OF_LIFE(
        "Camino de vida", "⟡",
        "Tu camino vital en 9 cartas"
    ),
    ASTROLOGICAL(
        "Astrológica (12 casas)", "✶",
        "Las 12 casas de tu cielo natal"
    ),
    CHAKRA_SPREAD(
        "Alineación de Chakras", "◍",
        "El estado de tus 7 centros energéticos"
    ),
    HEXAGRAM(
        "Hexagrama", "⬡",
        "La Estrella de 6 puntas y el destino"
    ),
    TEMPERANCE(
        "✦ La Templanza", "⬢",
        "Equilibrio alquímico entre opuestos — Arcano XIV"
    ),
    TREE_OF_LIFE(
        "✦ Árbol de la Vida", "⟐",
        "Las 10 Sefirot del Árbol Cabalístico"
    ),
    STAR_DAVID(
        "✦ Estrella de David", "✦",
        "Los 6 elementos sagrados + el centro integrador"
    ),
    SOUL_MIRROR(
        "✦ Espejo del Alma", "◐",
        "Exploración profunda del inconsciente y la sombra"
    ),
    ALCHEMY_PATH(
        "✦ Gran Obra Alquímica", "⬣",
        "Nigredo → Albedo → Citrinitas → Rubedo"
    ),
    MOON_CYCLE(
        "✦ Ciclo Lunar", "☾",
        "Las 4 fases lunares como guía espiritual"
    ),
    PYRAMID(
        "✦ La Pirámide", "△",
        "Base → Maestría → Vértice: tu crecimiento espiritual"
    ),
    YES_NO(
        "✦ Sí / No", "⬔",
        "Respuesta clara y orientadora ante una pregunta binaria"
    ),
    LINEAGE(
        "✦ El Linaje", "⬡",
        "Herencia, patrones familiares y propósito de tu alma"
    ),
    FREE(
        "Tirada libre", "⁂",
        "Elige cuántas cartas se reparten y deja que el Triunfo guíe tu lectura"
    );

    val positions: List<SpreadPosition>
        get() = when (this) {
            DAILY_CARD -> listOf(
                SpreadPosition("Diario", description = "La energía que guía tu día")
            )
            THREE_CARD -> listOf(
                SpreadPosition("Pasado", description = "Lo que ha dado forma a tu situación actual"),
                SpreadPosition("Presente", description = "La energía dominante en este momento"),
                SpreadPosition("Futuro", description = "El camino que se abre ante ti")
            )
            CELTIC_CROSS -> listOf(
                SpreadPosition("Presente", description = "El corazón de la cuestión"),
                SpreadPosition("Desafío", description = "Lo que se cruza en tu camino"),
                SpreadPosition("Pasado", description = "Influencias del pasado reciente"),
                SpreadPosition("Futuro", description = "Lo que se aproxima en el horizonte"),
                SpreadPosition("Encima", description = "Tu objetivo consciente o ideal"),
                SpreadPosition("Debajo", description = "La base inconsciente de la situación"),
                SpreadPosition("Consejo", description = "La acción recomendada"),
                SpreadPosition("Entorno", description = "Influencias externas y personas clave"),
                SpreadPosition("Esperanzas", description = "Tus esperanzas y temores secretos"),
                SpreadPosition("Resultado", description = "El desenlace probable si continúas este camino")
            )
            FIVE_CARD -> listOf(
                SpreadPosition("Situación", description = "El contexto central"),
                SpreadPosition("Obstáculo", description = "Lo que bloquea tu avance"),
                SpreadPosition("Acción", description = "La acción más poderosa que puedes tomar"),
                SpreadPosition("Resultado", description = "El fruto de tu acción"),
                SpreadPosition("Consejo", description = "Sabiduría del Arcano Mayor")
            )
            HORSESHOE -> listOf(
                SpreadPosition("Pasado", description = "Influencias del pasado lejano"),
                SpreadPosition("Presente", description = "El estado actual"),
                SpreadPosition("Oculto", description = "Lo que permanece velado"),
                SpreadPosition("Consejo", description = "El consejo del Tarot"),
                SpreadPosition("Futuro Cercano", description = "Lo que viene en semanas"),
                SpreadPosition("Futuro Lejano", description = "El horizonte a largo plazo"),
                SpreadPosition("Resultado", description = "El resultado final")
            )
            RELATIONSHIP -> listOf(
                SpreadPosition("Tú", description = "Tu energía en la relación"),
                SpreadPosition("Pareja", description = "La energía de tu pareja"),
                SpreadPosition("Fortalezas", description = "Los pilares que sostienen la relación"),
                SpreadPosition("Desafíos", description = "Las tensiones a trabajar"),
                SpreadPosition("Camino Mutuo", description = "El camino que construís juntos"),
                SpreadPosition("Consejo", description = "Lo que el Tarot recomienda"),
                SpreadPosition("Resultado", description = "El potencial de la relación")
            )
            TWELVE_MONTH -> monthsSpread()
            DECISION -> listOf(
                SpreadPosition("Situación", description = "El núcleo de tu dilema"),
                SpreadPosition("Elección", description = "La naturaleza de la decisión que enfrentas"),
                SpreadPosition("Consecuencia", description = "El resultado probable de tu elección"),
                SpreadPosition("Consejo", description = "La sabiduría superior que te guía")
            )
            PATH_OF_LIFE -> listOf(
                SpreadPosition("Pasado", description = "Las raíces de tu camino"),
                SpreadPosition("Presente", description = "El punto donde te encuentras"),
                SpreadPosition("Futuro", description = "A dónde te dirige el camino"),
                SpreadPosition("Desafío", description = "El mayor obstáculo a superar"),
                SpreadPosition("Fortaleza", description = "Tu don más poderoso"),
                SpreadPosition("Consejo", description = "La acción sabia a tomar"),
                SpreadPosition("Resultado", description = "El destino al que te encaminas"),
                SpreadPosition("Oculto", description = "Lo que aún no ves pero influye"),
                SpreadPosition("Guía", description = "El arquetipo que te acompaña")
            )
            ASTROLOGICAL -> listOf(
                SpreadPosition("Casa 1: Yo", description = "Tu identidad, apariencia y comienzos"),
                SpreadPosition("Casa 2: Dinero", description = "Recursos, valores y posesiones"),
                SpreadPosition("Casa 3: Comunicación", description = "Mente, hermanos, viajes cortos"),
                SpreadPosition("Casa 4: Hogar", description = "Familia, raíces, el pasado"),
                SpreadPosition("Casa 5: Creatividad", description = "Placeres, romance, creatividad"),
                SpreadPosition("Casa 6: Salud", description = "Trabajo, salud, servicio"),
                SpreadPosition("Casa 7: Pareja", description = "Relaciones, socios, el 'otro'"),
                SpreadPosition("Casa 8: Transformación", description = "Muerte, regeneración, lo oculto"),
                SpreadPosition("Casa 9: Filosofía", description = "Creencias, viajes largos, enseñanzas"),
                SpreadPosition("Casa 10: Carrera", description = "Reputación, vocación, éxito público"),
                SpreadPosition("Casa 11: Amigos", description = "Comunidad, esperanzas, ideales"),
                SpreadPosition("Casa 12: Subconsciente", description = "Lo oculto, karma, limitaciones")
            )
            CHAKRA_SPREAD -> listOf(
                SpreadPosition("Chakra Raíz", description = "Seguridad, supervivencia, tierra. Color: Rojo"),
                SpreadPosition("Chakra Sacro", description = "Creatividad, sexualidad, emociones. Color: Naranja"),
                SpreadPosition("Chakra del Plexo Solar", description = "Poder personal, voluntad, ego. Color: Amarillo"),
                SpreadPosition("Chakra del Corazón", description = "Amor, compasión, sanación. Color: Verde"),
                SpreadPosition("Chakra de la Garganta", description = "Comunicación, verdad, expresión. Color: Azul"),
                SpreadPosition("Chakra del Tercer Ojo", description = "Intuición, visión, sabiduría. Color: Índigo"),
                SpreadPosition("Chakra Corona", description = "Conexión divina, conciencia pura. Color: Violeta")
            )
            HEXAGRAM -> listOf(
                SpreadPosition("Pasado", description = "Las causas que originaron la situación"),
                SpreadPosition("Presente", description = "La energía actual"),
                SpreadPosition("Futuro", description = "El potencial que se despliega"),
                SpreadPosition("Consejo Oculto", description = "La sabiduría que permanece velada"),
                SpreadPosition("Entorno", description = "Las fuerzas externas que actúan"),
                SpreadPosition("Esperanzas/Temores", description = "Lo que anhelas y lo que temes"),
                SpreadPosition("Resultado Final", description = "La síntesis y desenlace")
            )
            TEMPERANCE -> listOf(
                SpreadPosition("Agua — Lo Fluido", description = "Tu naturaleza emocional, receptiva, femenina. El río que cedes."),
                SpreadPosition("Fuego — Lo Activo", description = "Tu voluntad, acción, impulso creativo. La llama que avanza."),
                SpreadPosition("Cuerpo — Tierra", description = "El plano físico, la salud, las necesidades materiales."),
                SpreadPosition("Espíritu — Éter", description = "Tu dimensión espiritual, alma, propósito superior."),
                SpreadPosition("Desequilibrio", description = "Lo que actualmente está fuera de balance en tu vida."),
                SpreadPosition("Templanza — Síntesis", description = "La alquimia que une los opuestos. El punto de equilibrio perfecto.")
            )
            TREE_OF_LIFE -> listOf(
                SpreadPosition("Kether — La Corona", description = "Conciencia pura, unidad con lo divino. El punto de origen."),
                SpreadPosition("Chokmah — Sabiduría", description = "La fuerza creativa masculina, el Padre. Impulso primordial."),
                SpreadPosition("Binah — Comprensión", description = "La forma receptiva femenina, la Madre. La Gran Mar."),
                SpreadPosition("Chesed — Misericordia", description = "Amor, abundancia, generosidad. El rey benevolente."),
                SpreadPosition("Geburah — Fuerza", description = "Poder, rigor, disciplina. La espada que corta lo innecesario."),
                SpreadPosition("Tiphareth — Belleza", description = "El corazón del árbol. El Sol, el Cristo, el ser solar."),
                SpreadPosition("Netzach — Victoria", description = "Emociones, deseos, naturaleza, Arte y Venus."),
                SpreadPosition("Hod — Esplendor", description = "Intelecto, comunicación, magia ceremonial. Mercurio."),
                SpreadPosition("Yesod — Fundamento", description = "El inconsciente, la Luna, los sueños, la memoria astral."),
                SpreadPosition("Malkuth — El Reino", description = "La tierra, el cuerpo físico, la manifestación material.")
            )
            STAR_DAVID -> listOf(
                SpreadPosition("Punto Norte — Fuego", description = "Tu voluntad ascendente, aspiración y propósito espiritual."),
                SpreadPosition("Punto Sureste — Agua", description = "Tus emociones profundas, el inconsciente que fluye."),
                SpreadPosition("Punto Suroeste — Tierra", description = "Tu fundamento material, recursos y realidad tangible."),
                SpreadPosition("Punto Sur — Aire", description = "Tu mente, pensamientos y comunicación actuales."),
                SpreadPosition("Punto Noreste — Espíritu", description = "Tu conexión con lo divino y la guía superior."),
                SpreadPosition("Punto Noroeste — Tiempo", description = "El ciclo temporal: qué debe terminar y qué comenzar."),
                SpreadPosition("Centro — Integración", description = "La síntesis alquímica de todos los elementos. Tu verdad central.")
            )
            SOUL_MIRROR -> listOf(
                SpreadPosition("Máscara — Persona", description = "La cara que muestras al mundo. Tu identidad social."),
                SpreadPosition("Sombra — Inconsciente", description = "Lo que niegas o reprimes. Tu lado oscuro integrable."),
                SpreadPosition("Anima/Animus", description = "Tu principio femenino/masculino interno. El complemento interior."),
                SpreadPosition("Herida de Infancia", description = "El dolor temprano que aún condiciona tus respuestas."),
                SpreadPosition("Don Oculto", description = "La fortaleza escondida bajo tu herida. Tu superpoder invisible."),
                SpreadPosition("Patrón Kármico", description = "El ciclo que se repite en tu vida. El tema de tu alma."),
                SpreadPosition("Llamado del Alma", description = "Tu vocación profunda. Para qué viniste a este mundo."),
                SpreadPosition("Obstáculo Principal", description = "El mayor bloqueo a tu evolución espiritual actual."),
                SpreadPosition("Integración — El Sí Mismo", description = "El arquetipo central. Quién eres cuando todo se integra.")
            )
            ALCHEMY_PATH -> listOf(
                SpreadPosition("Nigredo — Putrefacción", description = "La oscuridad, el caos, la disolución. ¿Qué debe morir en ti?"),
                SpreadPosition("Albedo — Purificación", description = "La limpieza, la claridad emergente. ¿Qué se purifica en ti?"),
                SpreadPosition("Citrinitas — Iluminación", description = "La conciencia solar, el amanecer del alma. ¿Qué se ilumina?"),
                SpreadPosition("Rubedo — Perfección", description = "La Piedra Filosofal, la transmutación completa. ¿Quién emerges?")
            )
            MOON_CYCLE -> listOf(
                SpreadPosition("Luna Nueva — Semilla", description = "Lo que planta su semilla en tu vida. Nuevos comienzos e intenciones."),
                SpreadPosition("Luna Creciente — Acción", description = "Lo que crece y pide tu acción y esfuerzo activo."),
                SpreadPosition("Luna Llena — Plenitud", description = "Lo que llega a su máxima expresión. La revelación y la cosecha."),
                SpreadPosition("Luna Menguante — Liberación", description = "Lo que debe soltarse, liberarse y transformarse antes del nuevo ciclo.")
            )
            PYRAMID -> listOf(
                SpreadPosition("Base Izquierda — Raíces", description = "Tus cimientos, origen y lo que te sostiene."),
                SpreadPosition("Base Centro — Equilibrio", description = "El estado presente de tu vida y tu centro."),
                SpreadPosition("Base Derecha — Recursos", description = "Tus talentos y herramientas disponibles."),
                SpreadPosition("Nivel Medio Izquierdo — Desafío", description = "El obstáculo que debes superar para crecer."),
                SpreadPosition("Nivel Medio Derecho — Maestría", description = "La lección que estás aprendiendo ahora."),
                SpreadPosition("Vértice — Ascensión", description = "La cima de tu crecimiento espiritual y el potencial más alto.")
            )
            YES_NO -> listOf(
                SpreadPosition("Situación Actual", description = "El contexto real de tu pregunta."),
                SpreadPosition("Influencia Oculta", description = "Lo que impulsa o bloquea la respuesta."),
                SpreadPosition("Resultado / Respuesta", description = "La tendencia y el desenlace probable.")
            )
            LINEAGE -> listOf(
                SpreadPosition("Linaje Familiar", description = "La herencia emocional y de patrones que cargas."),
                SpreadPosition("Abuelos", description = "Las raíces ancestrales y su legado."),
                SpreadPosition("Padres", description = "Lo que aprendiste de tus figuras parentales."),
                SpreadPosition("Infancia", description = "Los condicionamientos tempranos de tu vida."),
                SpreadPosition("Patrón Kármico", description = "El ciclo que se repite y debes sanar."),
                SpreadPosition("Propósito", description = "La misión que trasciende tu linaje."),
                SpreadPosition("Liberación", description = "Lo que puedes soltar para honrar tu propio camino.")
            )
            FREE -> freeSpread()
        }
}
