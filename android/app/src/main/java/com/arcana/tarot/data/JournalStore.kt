package com.arcana.tarot.data

import android.content.Context
import com.arcana.tarot.core.models.JournalEntry
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.io.File

/** Persistencia del diario en un archivo JSON dentro de `filesDir`. */
class JournalStore(context: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        prettyPrint = true
    }

    private val file: File = File(context.filesDir, "journal.json")

    fun load(): List<JournalEntry> {
        if (!file.exists()) return emptyList()
        return runCatching {
            json.decodeFromString(ListSerializer(JournalEntry.serializer()), file.readText())
        }.getOrDefault(emptyList())
    }

    fun save(entries: List<JournalEntry>) {
        runCatching {
            file.writeText(json.encodeToString(ListSerializer(JournalEntry.serializer()), entries))
        }
    }
}
