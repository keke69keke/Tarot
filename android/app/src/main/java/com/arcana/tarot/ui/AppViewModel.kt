package com.arcana.tarot.ui

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.arcana.tarot.core.models.DrawnCard
import com.arcana.tarot.core.models.JournalEntry
import com.arcana.tarot.core.models.SpreadPosition
import com.arcana.tarot.core.models.SpreadType
import com.arcana.tarot.data.CardRepository
import com.arcana.tarot.data.DailyCardService
import com.arcana.tarot.data.JournalStore
import com.arcana.tarot.data.SettingsStore
import kotlin.random.Random

/**
 * Estado compartido de la app: equivalente ligero de `TarotViewModel` en iOS.
 * Expone repositorio, ajustes, diario y generación de tiradas como estado Compose.
 */
class AppViewModel(context: Context) {

    val repository = CardRepository(context)
    private val settings = SettingsStore(context)
    private val journalStore = JournalStore(context)
    val dailyService = DailyCardService(repository.cards)

    var userName by mutableStateOf(settings.userName)
        private set
    var allowReversed by mutableStateOf(settings.allowReversed)
        private set
    var freeCardCount by mutableStateOf(settings.freeCardCount)
        private set
    var journalEntries by mutableStateOf(journalStore.load())
        private set
    var hasSeenWelcome by mutableStateOf(settings.hasSeenWelcome)
        private set

    fun setUserName(value: String) {
        userName = value
        settings.userName = value
    }

    fun setAllowReversed(value: Boolean) {
        allowReversed = value
        settings.allowReversed = value
    }

    fun setFreeCardCount(value: Int) {
        freeCardCount = value.coerceIn(1, 12)
        settings.freeCardCount = freeCardCount
    }

    fun completeWelcome() {
        hasSeenWelcome = true
        settings.hasSeenWelcome = true
    }

    fun markDailyRevealed(dayOfYear: Int) {
        settings.dailyRevealedDay = dayOfYear
    }

    fun wasDailyRevealed(dayOfYear: Int): Boolean = settings.dailyRevealedDay == dayOfYear

    fun addJournalEntry(entry: JournalEntry) {
        journalEntries = listOf(entry) + journalEntries
        journalStore.save(journalEntries)
    }

    fun updateJournalEntry(entry: JournalEntry) {
        journalEntries = journalEntries.map { if (it.id == entry.id) entry else it }
        journalStore.save(journalEntries)
    }

    fun deleteJournalEntry(id: String) {
        journalEntries = journalEntries.filter { it.id != id }
        journalStore.save(journalEntries)
    }

    fun clearJournal() {
        journalEntries = emptyList()
        journalStore.save(journalEntries)
    }

    /** Posiciones de la tirada indicada; FREE usa freeCardCount. */
    fun positionsFor(type: SpreadType): List<SpreadPosition> =
        if (type == SpreadType.FREE) {
            freePositions(freeCardCount)
        } else {
            type.positions
        }

    fun freePositions(count: Int): List<SpreadPosition> =
        (1..count).map { i ->
            SpreadPosition(
                name = "Carta $i",
                displayName = "Carta $i",
                description = "Posición libre $i de tu tirada."
            )
        }

    /** Roba `count` cartas del mazo barajado, respetando el ajuste de invertidas. */
    fun drawCards(count: Int): List<DrawnCard> =
        repository.cards.shuffled()
            .take(count)
            .map { DrawnCard(card = it, reversed = allowReversed && Random.nextBoolean()) }
}
