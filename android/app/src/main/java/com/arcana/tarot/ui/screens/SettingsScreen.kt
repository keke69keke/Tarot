package com.arcana.tarot.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.MysticPanel
import com.arcana.tarot.ui.theme.TarotColors
import kotlin.math.roundToInt

/** Ajustes: nombre, invertidas, tirada libre y gestión de datos. */
@Composable
fun SettingsScreen(viewModel: AppViewModel) {
    var confirmClearJournal by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text(
            text = "Ajustes",
            style = MaterialTheme.typography.headlineSmall,
            color = TarotColors.Gold,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        MysticPanel(modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Tu nombre",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Ivory
                )
                OutlinedTextField(
                    value = viewModel.userName,
                    onValueChange = { viewModel.setUserName(it) },
                    label = { Text("¿Cómo te llamas?") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = "Lectura",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Ivory
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Cartas invertidas",
                            style = MaterialTheme.typography.bodyMedium,
                            color = TarotColors.Ivory
                        )
                        Text(
                            text = "Permite que el mazo revele cartas boca abajo.",
                            style = MaterialTheme.typography.bodySmall,
                            color = TarotColors.TextSecondary
                        )
                    }
                    Switch(
                        checked = viewModel.allowReversed,
                        onCheckedChange = { viewModel.setAllowReversed(it) },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = TarotColors.Gold,
                            checkedTrackColor = TarotColors.GoldDeep
                        )
                    )
                }
                Text(
                    text = "Cartas en la tirada libre: ${viewModel.freeCardCount}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = TarotColors.Ivory
                )
                Slider(
                    value = viewModel.freeCardCount.toFloat(),
                    onValueChange = { viewModel.setFreeCardCount(it.roundToInt()) },
                    valueRange = 1f..12f,
                    steps = 10,
                    colors = androidx.compose.material3.SliderDefaults.colors(
                        thumbColor = TarotColors.Gold,
                        activeTrackColor = TarotColors.GoldDeep
                    )
                )
            }
        }

        MysticPanel(modifier = Modifier.fillMaxWidth().padding(top = 12.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Datos",
                    style = MaterialTheme.typography.titleMedium,
                    color = TarotColors.Ivory
                )
                Text(
                    text = "Borrar el diario elimina todas las lecturas guardadas en este dispositivo. Esta acción no se puede deshacer.",
                    style = MaterialTheme.typography.bodySmall,
                    color = TarotColors.TextSecondary
                )
                OutlinedButton(
                    onClick = { confirmClearJournal = true },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Borrar el diario", color = TarotColors.AspectAmor)
                }
            }
        }

        Spacer(Modifier.height(24.dp))
        Text(
            text = "Nicole´s Tarot · versión Android 1.0",
            style = MaterialTheme.typography.labelSmall,
            color = TarotColors.TextSecondary,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        Spacer(Modifier.height(16.dp))
    }

    if (confirmClearJournal) {
        AlertDialog(
            onDismissRequest = { confirmClearJournal = false },
            title = { Text("¿Borrar el diario?", color = TarotColors.Ivory) },
            text = {
                Text(
                    "Se eliminarán ${viewModel.journalEntries.size} lecturas guardadas. Esta acción no se puede deshacer.",
                    color = TarotColors.TextSecondary
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearJournal()
                    confirmClearJournal = false
                }) {
                    Text("Borrar", color = TarotColors.AspectAmor)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmClearJournal = false }) {
                    Text("Cancelar", color = TarotColors.Gold)
                }
            }
        )
    }
}
