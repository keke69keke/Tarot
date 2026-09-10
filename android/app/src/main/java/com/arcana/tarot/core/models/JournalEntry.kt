package com.arcana.tarot.core.models

import kotlinx.serialization.Serializable

/** Carta robada en una tirada, con su orientación. Portado de `DrawnCard.swift`. */
data class DrawnCard(
    val card: Card,
    val reversed: Boolean
) {
    val interpretation: Interpretation
        get() = if (reversed) card.reversed else card.upright
}

/** Instantánea serializable de una carta robada, para el diario. */
@Serializable
data class DrawnCardSnapshot(
    val cardId: Int,
    val reversed: Boolean,
    val positionName: String = ""
)

/**
 * Una lectura guardada en el diario personal (Requisito 3).
 * Portado de `JournalEntry.swift`; el límite de 2000 caracteres se aplica al guardar.
 */
@Serializable
data class JournalEntry(
    val id: String = java.util.UUID.randomUUID().toString(),
    val spreadType: String,
    val spreadLabel: String,
    val savedAt: Long = System.currentTimeMillis(),
    val moonPhase: String = "",
    val notes: String = "",
    val cards: List<DrawnCardSnapshot> = emptyList()
)
