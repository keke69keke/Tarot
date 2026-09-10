package com.arcana.tarot.core.models

data class Card(
    val id: String,
    val name: String,
    val imageName: String,
    val textureImageName: String,
    val type: CardType,
    val meaningUpright: String,
    val meaningReversed: String
)

enum class CardType {
    MAJOR, MINOR
}

enum class DeckType {
    RIDER_WAITE,
    MARSEILLE,
    HELLO_KITTY,
    THOTH,
    OSHO,
    DARK_SIDE,
    CELESTIAL,
    BOTANICAL
}

enum class CardBackDesign {
    CLASSIC,
    MODERN,
    MYSTIC
}
