package com.arcana.tarot.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import com.arcana.tarot.data.MoonPhase
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.MysticPanel
import com.arcana.tarot.ui.components.TarotCardBack
import com.arcana.tarot.ui.components.TarotCardImage
import com.arcana.tarot.ui.theme.TarotColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Carta del día: determinista por fecha, con revelación persistente. */
@Composable
fun DailyCardScreen(viewModel: AppViewModel) {
    val calendar = remember { java.util.Calendar.getInstance() }
    val dayOfYear = remember { calendar.get(java.util.Calendar.DAY_OF_YEAR) }
    val card = remember { viewModel.dailyService.dailyCard(calendar) }
    val moon = remember { MoonPhase.phaseName(System.currentTimeMillis()) }
    val dateText = remember {
        SimpleDateFormat("EEEE, d 'de' MMMM yyyy", Locale("es", "ES")).format(Date())
    }
    var revealed by remember { mutableStateOf(viewModel.wasDailyRevealed(dayOfYear)) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text(
            text = "Carta del día",
            style = MaterialTheme.typography.headlineSmall,
            color = TarotColors.Gold
        )
        Text(
            text = dateText,
            style = MaterialTheme.typography.bodySmall,
            color = TarotColors.TextSecondary
        )
        Text(
            text = "☾ $moon",
            style = MaterialTheme.typography.bodySmall,
            color = TarotColors.GoldHighlight
        )

        if (!revealed) {
            Text(
                text = "Tu carta espera. Toca el dorso para revelarla.",
                style = MaterialTheme.typography.bodyMedium,
                color = TarotColors.Ivory.copy(alpha = 0.7f),
                textAlign = TextAlign.Center
            )
            TarotCardBack(
                assetPath = viewModel.repository.cardBackAsset,
                cornerRadius = 16,
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .aspectRatio(0.62f)
                    .clickable {
                        revealed = true
                        viewModel.markDailyRevealed(dayOfYear)
                    }
            )
        } else {
            TarotCardImage(
                assetPath = viewModel.repository.imageAsset(card),
                contentDescription = card.name,
                cornerRadius = 16,
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .aspectRatio(0.62f)
            )
            MysticPanel(modifier = Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
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
                    Text(
                        text = card.upright.summary,
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.Ivory.copy(alpha = 0.85f)
                    )
                    val keywords = card.upright.keywords.joinToString(" · ")
                    if (keywords.isNotBlank()) {
                        Text(
                            text = keywords,
                            style = MaterialTheme.typography.labelSmall,
                            color = TarotColors.GoldWisdom
                        )
                    }
                    card.affirmation?.takeIf { it.isNotBlank() }?.let { affirmation ->
                        Spacer(Modifier.height(4.dp))
                        Text(
                            text = "✧ $affirmation",
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.GoldHighlight
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(16.dp))
    }
}
