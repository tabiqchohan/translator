package com.tabiqchohan.translater

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Stores recent live-translation entries so the user can review them in the
 * Flutter app later. Capped to keep prefs small.
 */
object ChatHistoryStore {
    private const val MAX_ENTRIES = 100
    private const val KEY = "lc_history_data"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences("live_chat", Context.MODE_PRIVATE)

    fun history(context: Context): List<Map<String, Any?>> {
        val raw = prefs(context).getString(KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                mapOf(
                    "id" to o.optString("id"),
                    "source" to o.optString("source", "Chat"),
                    "original" to o.optString("original"),
                    "translated" to o.optString("translated"),
                    "targetLang" to o.optString("targetLang", "en"),
                    "timestamp" to o.optLong("timestamp"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun add(context: Context, source: String, original: String, translated: String, targetLang: String) {
        val p = prefs(context)
        val arr = run {
            val raw = p.getString(KEY, null)
            if (raw.isNullOrBlank()) JSONArray() else try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        }
        val entry = JSONObject()
            .put("id", System.currentTimeMillis().toString())
            .put("source", source)
            .put("original", original)
            .put("translated", translated)
            .put("targetLang", targetLang)
            .put("timestamp", System.currentTimeMillis())
        arr.put(entry)
        while (arr.length() > MAX_ENTRIES) arr.remove(0)
        p.edit().putString(KEY, arr.toString()).apply()
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY).apply()
    }
}