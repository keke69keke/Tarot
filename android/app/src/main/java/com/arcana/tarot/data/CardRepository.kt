package com.arcana.tarot.data

import android.content.Context
import com.arcana.tarot.core.models.Card
import com.arcana.tarot.core.models.CardDeck
import kotlinx.serialization.json.Json

/**
 * Repositorio de cartas que carga `assets/cards.json` — el mismo JSON
 * que consume la app iOS a través de BundleCardRepository.
 */
class CardRepository(context: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }

    val cards: List<Card> by lazy { load(context) }

    private fun load(context: Context): List<Card> {
        val text = context.assets.open("cards.json").bufferedReader().use { it.readText() }
        return json.decodeFromString<CardDeck>(text).cards.sortedBy { it.id }
    }

    fun byId(id: Int): Card? = cards.firstOrNull { it.id == id }

    /** Ruta del asset con la ilustración de la carta. */
    fun imageAsset(card: Card): String = "file:///android_asset/cards/${card.imageName}.png"

    val cardBackAsset: String get() = "file:///android_asset/cards/card_back.png"
}
