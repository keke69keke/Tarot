package com.arcana.tarot

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.MenuBook
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Style
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.arcana.tarot.ui.AppViewModel
import com.arcana.tarot.ui.components.StarfieldBackground
import com.arcana.tarot.ui.screens.DailyCardScreen
import com.arcana.tarot.ui.screens.JournalScreen
import com.arcana.tarot.ui.screens.LibraryScreen
import com.arcana.tarot.ui.screens.ReadingScreen
import com.arcana.tarot.ui.screens.SettingsScreen
import com.arcana.tarot.ui.theme.TarotColors
import com.arcana.tarot.ui.theme.TarotTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val viewModel = AppViewModel(applicationContext)
        setContent {
            TarotTheme {
                TarotApp(viewModel)
            }
        }
    }
}

private enum class AppTab(val label: String, val icon: ImageVector) {
    READING("Tiradas", Icons.Rounded.Style),
    DAILY("Carta del día", Icons.Rounded.WbSunny),
    LIBRARY("Biblioteca", Icons.Rounded.MenuBook),
    JOURNAL("Diario", Icons.Rounded.Edit),
    SETTINGS("Ajustes", Icons.Rounded.Settings)
}

@Composable
fun TarotApp(viewModel: AppViewModel) {
    var selectedTabIndex by remember { mutableStateOf(0) }
    val tabs = AppTab.entries

    Scaffold(
        containerColor = TarotColors.Background,
        bottomBar = {
            NavigationBar(containerColor = TarotColors.BackgroundElevated) {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        selected = selectedTabIndex == index,
                        onClick = { selectedTabIndex = index },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = TarotColors.Gold,
                            selectedTextColor = TarotColors.Gold,
                            indicatorColor = TarotColors.GoldDeep.copy(alpha = 0.4f),
                            unselectedIconColor = TarotColors.TextSecondary,
                            unselectedTextColor = TarotColors.TextSecondary
                        )
                    )
                }
            }
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            StarfieldBackground(modifier = Modifier.fillMaxSize())
            when (selectedTabIndex) {
                0 -> ReadingScreen(viewModel)
                1 -> DailyCardScreen(viewModel)
                2 -> LibraryScreen(viewModel)
                3 -> JournalScreen(viewModel)
                else -> SettingsScreen(viewModel)
            }
        }
    }

    if (!viewModel.hasSeenWelcome) {
        WelcomeOverlay(viewModel)
    }
}

@Composable
private fun WelcomeOverlay(viewModel: AppViewModel) {
    var name by remember { mutableStateOf(viewModel.userName) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(TarotColors.Background.copy(alpha = 0.98f))
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Text(
                text = "✦",
                style = MaterialTheme.typography.displayMedium,
                color = TarotColors.Gold
            )
            Text(
                text = "Bienvenida a Nicole´s Tarot",
                style = MaterialTheme.typography.headlineSmall,
                color = TarotColors.Ivory,
                textAlign = TextAlign.Center
            )
            Text(
                text = "El universo ya alineó las cartas para tu viaje. Antes de comenzar, ¿cómo te llamas?",
                style = MaterialTheme.typography.bodyMedium,
                color = TarotColors.TextSecondary,
                textAlign = TextAlign.Center
            )
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Tu nombre") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Button(
                onClick = {
                    viewModel.setUserName(name.trim())
                    viewModel.completeWelcome()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = TarotColors.Gold,
                    contentColor = Color.White
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Comenzar el viaje")
            }
        }
    }
}
