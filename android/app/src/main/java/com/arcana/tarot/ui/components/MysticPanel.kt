package com.arcana.tarot.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.arcana.tarot.ui.theme.TarotColors

/** Panel translúcido con borde dorado, equivalente a los paneles místicos de iOS. */
@Composable
fun MysticPanel(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        color = TarotColors.Panel,
        border = BorderStroke(1.dp, TarotColors.Border)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}
