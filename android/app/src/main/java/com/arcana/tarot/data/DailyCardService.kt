package com.arcana.tarot.data

import com.arcana.tarot.core.models.Card
import java.util.Calendar
import kotlin.math.abs

/**
 * Fase lunar aproximada mediante el mes sinódico (29.53 días) desde una
 * luna nueva de referencia. Sustituye a `LunarService` de la app iOS.
 */
object MoonPhase {

    private const val SYNODIC_MONTH = 29.530588853
    // Luna nueva de referencia: 2000-01-06 18:14 UTC ≈ 10962.76 días desde la época Unix.
    private const val REFERENCE_NEW_MOON_DAYS = 10962.76

    fun phaseName(timeMillis: Long): String {
        val daysSince = timeMillis / 86_400_000.0 - REFERENCE_NEW_MOON_DAYS
        val age = ((daysSince % SYNODIC_MONTH) + SYNODIC_MONTH) % SYNODIC_MONTH
        return when {
            age < 1.85 || age > 27.68 -> "Luna Nueva"
            age < 7.38 -> "Luna Creciente"
            age < 9.23 -> "Cuarto Creciente"
            age < 14.77 -> "Gibosa Creciente"
            age < 16.61 -> "Luna Llena"
            age < 22.15 -> "Gibosa Menguante"
            age < 24.00 -> "Cuarto Menguante"
            else -> "Luna Menguante"
        }
    }
}

/**
 * Carta del día determinista. Portado de `DeterministicDailyCardService`:
 * misma semilla (año * 366 + día del año) combinada con la fase lunar.
 */
class DailyCardService(private val cards: List<Card>) {

    fun dailyCard(calendar: Calendar = Calendar.getInstance()): Card {
        require(cards.isNotEmpty()) { "Un servicio de carta diaria necesita un mazo no vacío" }
        val year = calendar.get(Calendar.YEAR)
        val day = calendar.get(Calendar.DAY_OF_YEAR)
        val moonHash = MoonPhase.phaseName(calendar.timeInMillis).hashCode()
        val seed = (year * 366 + day) xor moonHash
        return cards[abs(seed) % cards.size]
    }
}
