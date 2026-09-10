package com.arcana.tarot.data

import android.content.Context

/** Ajustes de usuario persistidos en SharedPreferences. */
class SettingsStore(context: Context) {

    private val prefs = context.getSharedPreferences("tarot_settings", Context.MODE_PRIVATE)

    var userName: String
        get() = prefs.getString(KEY_NAME, "") ?: ""
        set(value) = prefs.edit().putString(KEY_NAME, value).apply()

    var allowReversed: Boolean
        get() = prefs.getBoolean(KEY_REVERSED, true)
        set(value) = prefs.edit().putBoolean(KEY_REVERSED, value).apply()

    var hasSeenWelcome: Boolean
        get() = prefs.getBoolean(KEY_WELCOME, false)
        set(value) = prefs.edit().putBoolean(KEY_WELCOME, value).apply()

    var freeCardCount: Int
        get() = prefs.getInt(KEY_FREE_COUNT, 5)
        set(value) = prefs.edit().putInt(KEY_FREE_COUNT, value.coerceIn(1, 12)).apply()

    /** Día del año en que se reveló la última carta diaria (0 = no revelada hoy). */
    var dailyRevealedDay: Int
        get() = prefs.getInt(KEY_DAILY_DAY, 0)
        set(value) = prefs.edit().putInt(KEY_DAILY_DAY, value).apply()

    private companion object {
        const val KEY_NAME = "user_name"
        const val KEY_REVERSED = "allow_reversed"
        const val KEY_WELCOME = "has_seen_welcome"
        const val KEY_FREE_COUNT = "free_card_count"
        const val KEY_DAILY_DAY = "daily_revealed_day"
    }
}
