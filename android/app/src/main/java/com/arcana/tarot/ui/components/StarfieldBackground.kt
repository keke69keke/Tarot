package com.arcana.tarot.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import kotlin.random.Random

private data class Star(
    val x: Float,
    val y: Float,
    val radius: Float,
    val alpha: Float
)

/** Fondo de cielo estrellado sobre degradado púrpura, equivalente a StarfieldBackgroundView. */
@Composable
fun StarfieldBackground(starCount: Int = 110, modifier: Modifier = Modifier) {
    val stars = remember(starCount) {
        val random = Random(42)
        List(starCount) {
            Star(
                x = random.nextFloat(),
                y = random.nextFloat(),
                radius = 0.8f + random.nextFloat() * 1.6f,
                alpha = 0.15f + random.nextFloat() * 0.55f
            )
        }
    }
    Canvas(modifier = modifier) {
        drawRect(
            brush = Brush.verticalGradient(
                colors = listOf(Color(0xFF0F0A21), Color(0xFF1A1033))
            )
        )
        val width = size.width
        val height = size.height
        stars.forEach { star ->
            drawCircle(
                color = Color.White.copy(alpha = star.alpha),
                radius = star.radius,
                center = Offset(star.x * width, star.y * height)
            )
        }
    }
}
