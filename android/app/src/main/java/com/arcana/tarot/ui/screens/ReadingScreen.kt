package com.arcana.tarot.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.arcana.tarot.core.models.DrawnCard
import com.arcana.tarot.core.models.JournalEntry
import com.arcana.tarot.core.models.SpreadPosition
import com.arcana.tarot.core.models.SpreadType
import com.arcana.tarot.data.MoonPhase
import com.arcana.tarot.core.models.DrawnCardSnapshot
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.MysticPanel
import com.arcana.tarot.ui.components.TarotCardBack
import com.arcana.tarot.ui.components.TarotCardImage
import com.arcana.tarot.ui.theme.TarotColors

/** Pestaña de tiradas: selección de tirada, reparto e interpretación. */
@Composable
fun ReadingScreen(viewModel: AppViewModel) {
    var selectedSpread by remember { mutableStateOf<SpreadType?>(null) }
    var drawnCards by remember { mutableStateOf<List<DrawnCard>>(emptyList()) }
    val revealed = remember(drawnCards) { mutableStateListOf<Int>() }

    val spread = selectedSpread
    if (spread == null || drawnCards.isEmpty()) {
        SpreadChooser(
            onBack = { selectedSpread = null },
            onSelect = { type ->
                selectedSpread = type
                drawnCards = viewModel.drawCards(viewModel.positionsFor(type).size)
                revealed.clear()
            }
        )
    } else {
        val positions = viewModel.positionsFor(spread)
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "${spread.symbol} ${spread.label}",
                        style = MaterialTheme.typography.titleLarge,
                        color = TarotColors.Gold
                    )
                    Text(
                        text = spread.esotericDescription,
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.TextSecondary
                    )
                }
                OutlinedButton(onClick = {
                    selectedSpread = null
                    drawnCards = emptyList()
                }) {
                    Text("Cambiar")
                }
            }

            Spacer(Modifier.height(12.dp))

            positions.forEachIndexed { index, position ->
                val drawn = drawnCards.getOrNull(index)
                if (drawn != null && index in revealed) {
                    RevealedCard(position = position, drawn = drawn, viewModel = viewModel)
                } else if (drawn != null) {
                    FaceDownCard(
                        positionName = position.displayName,
                        assetPath = viewModel.repository.cardBackAsset,
                        index = index,
                        onReveal = { revealed.add(index) }
                    )
                }
            }

            if (revealed.size == drawnCards.size) {
                Spacer(Modifier.height(8.dp))
                JournalEntryActions(
                    viewModel = viewModel,
                    spread = spread,
                    positions = positions,
                    drawnCards = drawnCards,
                    onNewReading = {
                        selectedSpread = null
                        drawnCards = emptyList()
                    }
                )
            } else {
                Text(
                    text = "Toca una carta para revelarla (${revealed.size}/${drawnCards.size})",
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp)
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun SpreadChooser(onBack: () -> Unit, onSelect: (SpreadType) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text(
            text = "Elige tu tirada",
            style = MaterialTheme.typography.headlineSmall,
            color = TarotColors.Gold
        )
        Text(
            text = "Cada tirada abre una puerta distinta. Confía en tu intuición.",
            style = MaterialTheme.typography.bodySmall,
            color = TarotColors.TextSecondary,
            modifier = Modifier.padding(top = 4.dp, bottom = 16.dp)
        )
        SpreadType.entries.forEach { type ->
            MysticPanel(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .clickable { onSelect(type) }
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = type.symbol,
                        style = MaterialTheme.typography.headlineMedium,
                        color = TarotColors.Gold
                    )
                    Spacer(Modifier.width(14.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = type.label,
                            style = MaterialTheme.typography.titleMedium,
                            color = TarotColors.Ivory
                        )
                        Text(
                            text = type.esotericDescription,
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.TextSecondary
                        )
                        val countLabel = if (type == SpreadType.FREE) {
                            "Cartas ajustables"
                        } else {
                            "${type.positions.size} cartas"
                        }
                        Text(
                            text = countLabel,
                            style = MaterialTheme.typography.labelSmall,
                            color = TarotColors.GoldHighlight
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(8.dp))
        OutlinedButton(onClick = onBack, modifier = Modifier.fillMaxWidth()) {
            Text("Cancelar")
        }
    }
}

@Composable
private fun FaceDownCard(
    positionName: String,
    assetPath: String,
    index: Int,
    onReveal: (Int) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        TarotCardBack(
            assetPath = assetPath,
            cornerRadius = 14,
            modifier = Modifier
                .fillMaxWidth(0.45f)
                .aspectRatio(0.62f)
                .clickable { onReveal(index) }
        )
        Text(
            text = positionName,
            style = MaterialTheme.typography.labelMedium,
            color = TarotColors.GoldHighlight,
            modifier = Modifier.padding(top = 6.dp)
        )
    }
}

@Composable
private fun RevealedCard(
    position: SpreadPosition,
    drawn: DrawnCard,
    viewModel: AppViewModel
) {
    MysticPanel(modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            TarotCardImage(
                assetPath = viewModel.repository.imageAsset(drawn.card),
                contentDescription = drawn.card.name,
                reversed = drawn.reversed,
                cornerRadius = 10,
                modifier = Modifier
                    .width(96.dp)
                    .aspectRatio(0.62f)
            )
            Spacer(Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = position.displayName,
                    style = MaterialTheme.typography.labelMedium,
                    color = TarotColors.GoldHighlight
                )
                Text(
                    text = if (drawn.reversed) "${drawn.card.name} (invertida)" else drawn.card.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Ivory
                )
                if (position.description.isNotBlank()) {
                    Text(
                        text = position.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.TextSecondary,
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }
                Text(
                    text = drawn.interpretation.summary,
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.Ivory.copy(alpha = 0.85f),
                    modifier = Modifier.padding(top = 8.dp)
                )
                val keywords = drawn.interpretation.keywords.joinToString(" · ")
                if (keywords.isNotBlank()) {
                    Text(
                        text = keywords,
                        style = MaterialTheme.typography.labelSmall,
                        color = TarotColors.GoldWisdom,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun JournalEntryActions(
    viewModel: AppViewModel,
    spread: SpreadType,
    positions: List<SpreadPosition>,
    drawnCards: List<DrawnCard>,
    onNewReading: () -> Unit
) {
    var saved by remember { mutableStateOf(false) }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Button(
            onClick = {
                val entry = JournalEntry(
                    spreadType = spread.name,
                    spreadLabel = spread.label,
                    moonPhase = MoonPhase.phaseName(System.currentTimeMillis()),
                    cards = positions.mapIndexed { index, position ->
                        drawnCards.getOrNull(index)?.let { drawn ->
                            DrawnCardSnapshot(
                                cardId = drawn.card.id,
                                reversed = drawn.reversed,
                                positionName = position.displayName
                            )
                        }
                    }.filterNotNull()
                )
                viewModel.addJournalEntry(entry)
                saved = true
            },
            enabled = !saved,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (saved) "Guardada en tu diario ✦" else "Guardar lectura en el diario")
        }
        OutlinedButton(
            onClick = onNewReading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Nueva tirada")
        }
    }
}
