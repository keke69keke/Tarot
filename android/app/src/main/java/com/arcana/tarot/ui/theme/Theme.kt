package com.arcana.tarot.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = TarotColors.Gold,
    onPrimary = Color.White,
    primaryContainer = TarotColors.GoldDeep,
    onPrimaryContainer = TarotColors.Ivory,
    secondary = TarotColors.GoldHighlight,
    onSecondary = Color(0xFF1A1033),
    background = TarotColors.Background,
    onBackground = TarotColors.Ivory,
    surface = TarotColors.BackgroundElevated,
    onSurface = TarotColors.Ivory,
    surfaceVariant = TarotColors.CardBase,
    onSurfaceVariant = TarotColors.TextSecondary,
    outline = TarotColors.BorderStrong,
    error = Color(0xFFB82E2E),
    onError = Color.White
)

/** Tema oscuro místico, fiel a la paleta de la app iOS. */
@Composable
fun TarotTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
