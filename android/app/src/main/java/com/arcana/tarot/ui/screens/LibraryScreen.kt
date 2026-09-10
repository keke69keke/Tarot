package com.arcana.tarot.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.activity.compose.BackHandler
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.arcana.tarot.core.models.Card
import com.arcana.tarot.data.CardRepository
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.MysticPanel
import com.arcana.tarot.ui.components.TarotCardImage
import com.arcana.tarot.ui.theme.TarotColors

private data class LibraryFilter(val key: String, val label: String)

private val LIBRARY_FILTERS = listOf(
    LibraryFilter("all", "Todas"),
    LibraryFilter("major", "Arcanos Mayores"),
    LibraryFilter("wands", "Bastos"),
    LibraryFilter("cups", "Copas"),
    LibraryFilter("swords", "Espadas"),
    LibraryFilter("pentacles", "Oros")
)

/** Biblioteca: las 78 cartas con filtros y ficha de detalle completa. */
@Composable
fun LibraryScreen(viewModel: AppViewModel) {
    var filter by remember { mutableStateOf("all") }
    var selectedCard by remember { mutableStateOf<Card?>(null) }

    val card = selectedCard
    if (card != null) {
        CardDetail(
            card = card,
            repository = viewModel.repository,
            onBack = { selectedCard = null }
        )
    } else {
        val cards = viewModel.repository.cards
        val filtered = remember(filter, cards) {
            when (filter) {
                "major" -> cards.filter { it.isMajor }
                "wands" -> cards.filter { it.suit == "wands" }
                "cups" -> cards.filter { it.suit == "cups" }
                "swords" -> cards.filter { it.suit == "swords" }
                "pentacles" -> cards.filter { it.suit == "pentacles" }
                else -> cards
            }
        }

        Column(modifier = Modifier.fillMaxSize()) {
            Text(
                text = "Biblioteca",
                style = MaterialTheme.typography.headlineSmall,
                color = TarotColors.Gold,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                LIBRARY_FILTERS.forEach { option ->
                    FilterChip(
                        selected = filter == option.key,
                        onClick = { filter = option.key },
                        label = { Text(option.label) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = TarotColors.GoldDeep.copy(alpha = 0.5f),
                            selectedLabelColor = TarotColors.GoldHighlight
                        )
                    )
                }
            }
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = 16.dp, end = 16.dp, top = 12.dp, bottom = 24.dp
                ),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(filtered, key = { it.id }) { item ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        TarotCardImage(
                            assetPath = viewModel.repository.imageAsset(item),
                            contentDescription = item.name,
                            cornerRadius = 10,
                            modifier = Modifier
                                .fillMaxWidth()
                                .aspectRatio(0.62f)
                                .clickable { selectedCard = item }
                        )
                        Text(
                            text = item.name,
                            style = MaterialTheme.typography.labelSmall,
                            color = TarotColors.Ivory.copy(alpha = 0.85f),
                            textAlign = TextAlign.Center,
                            maxLines = 2,
                            modifier = Modifier.padding(top = 6.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CardDetail(card: Card, repository: CardRepository, onBack: () -> Unit) {
    BackHandler(onBack = onBack)
    var showUpright by remember { mutableStateOf(true) }
    var showBook by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Rounded.ArrowBack,
                    contentDescription = "Volver",
                    tint = TarotColors.Gold
                )
            }
            Text(
                text = "Ficha de la carta",
                style = MaterialTheme.typography.labelMedium,
                color = TarotColors.TextSecondary
            )
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(top = 8.dp)
        ) {
            TarotCardImage(
                assetPath = repository.imageAsset(card),
                contentDescription = card.name,
                cornerRadius = 14,
                modifier = Modifier.width(130.dp).aspectRatio(0.62f)
            )
            Spacer(Modifier.width(16.dp))
            Column {
                Text(
                    text = card.name,
                    style = MaterialTheme.typography.titleLarge,
                    color = TarotColors.Gold
                )
                Text(
                    text = card.arcanaLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = TarotColors.GoldHighlight
                )
                card.element?.takeIf { it.isNotBlank() }?.let {
                    Text(
                        text = "Elemento: $it",
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.TextSecondary
                    )
                }
                card.astrology?.takeIf { it.isNotBlank() }?.let {
                    Text(
                        text = "Astrología: $it",
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.TextSecondary
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = showUpright,
                onClick = { showUpright = true },
                label = { Text("Derecha") }
            )
            FilterChip(
                selected = !showUpright,
                onClick = { showUpright = false },
                label = { Text("Invertida") }
            )
        }

        val interpretation = if (showUpright) card.upright else card.reversed

        MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Significado",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Gold
                )
                Text(
                    text = interpretation.summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.Ivory.copy(alpha = 0.85f)
                )
                val keywords = interpretation.keywords.joinToString(" · ")
                if (keywords.isNotBlank()) {
                    Text(
                        text = keywords,
                        style = MaterialTheme.typography.labelSmall,
                        color = TarotColors.GoldWisdom
                    )
                }
            }
        }

        interpretation.contextual.forEach { (position, text) ->
            MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 10.dp)) {
                Column {
                    Text(
                        text = contextualLabel(position),
                        style = MaterialTheme.typography.titleSmall,
                        color = TarotColors.GoldHighlight
                    )
                    Text(
                        text = text,
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.Ivory.copy(alpha = 0.85f)
                    )
                }
            }
        }

        interpretation.aspects.forEach { (aspect, text) ->
            val aspectColor = when (aspect) {
                "Amor" -> TarotColors.AspectAmor
                "Salud" -> TarotColors.AspectSalud
                "Carrera" -> TarotColors.AspectCarrera
                "Economía" -> TarotColors.AspectEconomia
                else -> TarotColors.Gold
            }
            MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 10.dp)) {
                Column {
                    Text(
                        text = aspect,
                        style = MaterialTheme.typography.titleSmall,
                        color = aspectColor
                    )
                    Text(
                        text = text,
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.Ivory.copy(alpha = 0.85f)
                    )
                }
            }
        }

        MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 10.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "Correspondencias",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Gold
                )
                DetailField("Luz y sombra", card.lightShadow)
                DetailField("Sí / No", card.yesNo)
                DetailField("Chakras", card.chakras)
                DetailField("Cristales", card.crystals)
                DetailField("Afirmación", card.affirmation)
                DetailField("Mitología", card.mythology)
                DetailField("Decanato zodiacal", card.zodiacalDecan)
                DetailField("Cábala", card.kabbalah)
                DetailField("Numerología", card.numerology)
            }
        }

        card.bookContent?.takeIf { it.isNotBlank() }?.let { book ->
            MysticPanel(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 10.dp)
                    .clickable { showBook = !showBook }
            ) {
                Column {
                    Text(
                        text = if (showBook) {
                            "Guía Definitiva del Tarot ▲"
                        } else {
                            "Guía Definitiva del Tarot ▼"
                        },
                        style = MaterialTheme.typography.titleSmall,
                        color = TarotColors.GoldHighlight
                    )
                    if (showBook) {
                        Text(
                            text = book,
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.Ivory.copy(alpha = 0.8f),
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            }
        }

        Spacer(Modifier.height(24.dp))
    }
}

/** Traduce las claves contextuales del JSON (past, present…) al español. */
private fun contextualLabel(key: String): String = when (key.lowercase()) {
    "daily" -> "Diario"
    "past" -> "Pasado"
    "present" -> "Presente"
    "future" -> "Futuro"
    "advice" -> "Consejo"
    "outcome" -> "Resultado"
    "challenge" -> "Desafío"
    "strength" -> "Fortaleza"
    "shadow" -> "Sombra"
    "environment" -> "Entorno"
    else -> key.replaceFirstChar { it.uppercase() }
}

@Composable
private fun DetailField(label: String, value: String?) {
    value?.takeIf { it.isNotBlank() }?.let { text ->
        Column(modifier = Modifier.padding(top = 2.dp)) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = TarotColors.GoldHighlight
            )
            Text(
                text = text,
                style = MaterialTheme.typography.bodySmall,
                color = TarotColors.Ivory.copy(alpha = 0.85f)
            )
        }
    }
}
