package com.arcana.tarot.core.models

import kotlinx.serialization.Serializable

/**
 * Interpretación de una carta en una orientación (derecha o invertida).
 * Espejo exacto del JSON `cards.json` del paquete Swift (TarotContent).
 */
@Serializable
data class Interpretation(
    val summary: String = "",
    val keywords: List<String> = emptyList(),
    val contextual: Map<String, String> = emptyMap(),
    val aspects: Map<String, String> = emptyMap()
)

/**
 * Una carta del mazo de 78 (Rider-Waite).
 * 0–21: Arcanos Mayores; 22–77: Arcanos Menores agrupados por palo.
 */
@Serializable
data class Card(
    val id: Int = 0,
    val name: String = "",
    val number: String? = null,
    val arcanaType: String = "major",
    val imageName: String = "",
    val suit: String? = null,
    val upright: Interpretation = Interpretation(),
    val reversed: Interpretation = Interpretation(),
    val bookContent: String? = null,
    val astrology: String? = null,
    val kabbalah: String? = null,
    val numerology: String? = null,
    val element: String? = null,
    val lightShadow: String? = null,
    val yesNo: String? = null,
    val chakras: String? = null,
    val crystals: String? = null,
    val affirmation: String? = null,
    val mythology: String? = null,
    val zodiacalDecan: String? = null
) {
    val isMajor: Boolean get() = arcanaType == "major"

    val suitName: String?
        get() = when (suit) {
            "wands" -> "Bastos"
            "cups" -> "Copas"
            "swords" -> "Espadas"
            "pentacles" -> "Oros"
            else -> null
        }

    val arcanaLabel: String
        get() = if (isMajor) {
            "Arcano Mayor${number?.let { " $it" } ?: ""}"
        } else {
            "Arcano Menor${suitName?.let { " · $it" } ?: ""}"
        }
}

/** Envoltorio raíz del JSON: { "cards": [ ... ] } */
@Serializable
data class CardDeck(
    val cards: List<Card> = emptyList()
)
