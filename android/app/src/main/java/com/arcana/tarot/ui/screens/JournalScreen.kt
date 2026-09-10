package com.arcana.tarot.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.arcana.tarot.core.models.JournalEntry
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.MysticPanel
import com.arcana.tarot.ui.theme.TarotColors
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Diario personal: lecturas guardadas con notas editables. */
@Composable
fun JournalScreen(viewModel: AppViewModel) {
    val entries = viewModel.journalEntries
    var editingEntry by remember { mutableStateOf<JournalEntry?>(null) }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = "Diario",
            style = MaterialTheme.typography.headlineSmall,
            color = TarotColors.Gold,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        )

        if (entries.isEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "✦",
                    style = MaterialTheme.typography.displayMedium,
                    color = TarotColors.GoldDeep
                )
                Text(
                    text = "Tu diario está vacío",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Ivory,
                    modifier = Modifier.padding(top = 12.dp)
                )
                Text(
                    text = "Guarda una lectura desde la pestaña de Tiradas y aparecerá aquí con sus notas.",
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        } else {
            LazyColumn(
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = 16.dp, end = 16.dp, bottom = 24.dp
                ),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(entries, key = { it.id }) { entry ->
                    JournalEntryCard(
                        entry = entry,
                        cardNames = entry.cards.mapNotNull { viewModel.repository.byId(it.cardId)?.name },
                        onOpen = { editingEntry = entry }
                    )
                }
            }
        }
    }

    editingEntry?.let { entry ->
        var notesText by remember(entry.id) { mutableStateOf(entry.notes) }
        AlertDialog(
            onDismissRequest = { editingEntry = null },
            title = { Text(entry.spreadLabel, color = TarotColors.Gold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = formatDate(entry.savedAt),
                        style = MaterialTheme.typography.bodySmall,
                        color = TarotColors.TextSecondary
                    )
                    if (entry.moonPhase.isNotBlank()) {
                        Text(
                            text = "☾ ${entry.moonPhase}",
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.GoldHighlight
                        )
                    }
                    val cardNames = entry.cards.mapNotNull { viewModel.repository.byId(it.cardId)?.name }
                    if (cardNames.isNotEmpty()) {
                        Text(
                            text = cardNames.joinToString(" · "),
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.Ivory.copy(alpha = 0.85f)
                        )
                    }
                    OutlinedTextField(
                        value = notesText,
                        onValueChange = { notesText = it.take(2000) },
                        label = { Text("Tus notas (${notesText.length}/2000)") },
                        minLines = 4,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.updateJournalEntry(entry.copy(notes = notesText))
                    editingEntry = null
                }) {
                    Text("Guardar", color = TarotColors.Gold)
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    viewModel.deleteJournalEntry(entry.id)
                    editingEntry = null
                }) {
                    Text("Eliminar", color = TarotColors.AspectAmor)
                }
            }
        )
    }
}

@Composable
private fun JournalEntryCard(
    entry: JournalEntry,
    cardNames: List<String>,
    onOpen: () -> Unit
) {
    MysticPanel(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = entry.spreadLabel,
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Gold
                )
            }
            Text(
                text = formatDate(entry.savedAt),
                style = MaterialTheme.typography.labelSmall,
                color = TarotColors.TextSecondary
            )
            if (cardNames.isNotEmpty()) {
                Text(
                    text = cardNames.joinToString(" · "),
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.Ivory.copy(alpha = 0.85f)
                )
            }
            if (entry.notes.isNotBlank()) {
                Text(
                    text = entry.notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.TextSecondary,
                    maxLines = 3
                )
            }
            Text(
                text = "Toca para editar o eliminar",
                style = MaterialTheme.typography.labelSmall,
                color = TarotColors.GoldHighlight,
                modifier = Modifier.padding(top = 6.dp)
            )
        }
    }
}

private fun formatDate(epochMillis: Long): String =
    SimpleDateFormat("d 'de' MMMM yyyy, HH:mm", Locale("es", "ES")).format(Date(epochMillis))
