package com.arcana.tarot.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.arcana.tarot.ui.theme.TarotColors

/**
 * Ilustración de una carta cargada desde los assets del APK.
 * `assetPath` es una URI `file:///android_asset/...` (ver CardRepository).
 */
@Composable
fun TarotCardImage(
    assetPath: String,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    reversed: Boolean = false,
    cornerRadius: Int = 12
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius.dp))
            .background(TarotColors.CardBase),
        contentAlignment = Alignment.Center
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(assetPath)
                .crossfade(true)
                .build(),
            contentDescription = contentDescription,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { rotationZ = if (reversed) 180f else 0f }
        )
    }
}

/** Dorso del mazo (asset card_back.png compartido con iOS). */
@Composable
fun TarotCardBack(assetPath: String, modifier: Modifier = Modifier, cornerRadius: Int = 12) {
    TarotCardImage(
        assetPath = assetPath,
        contentDescription = "Dorso del mazo",
        modifier = modifier,
        reversed = false,
        cornerRadius = cornerRadius
    )
}
