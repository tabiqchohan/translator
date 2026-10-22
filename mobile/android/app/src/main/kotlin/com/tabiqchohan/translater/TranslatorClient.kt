package com.tabiqchohan.translater

import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.StandardCharsets
import java.util.concurrent.Executors

/**
 * Minimal Redis-free HTTP client that calls the same public /api/translate
 * endpoint the Flutter app uses. Works even when the app is in the background.
 */
object TranslatorClient {
    private const val BASE_URL = "https://translator-two-dusky.vercel.app"

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun translate(
        text: String,
        target: String,
        source: String = "auto",
        onResult: (translated: String?, error: String?) -> Unit,
    ) {
        executor.execute {
            val (translated, error) = translateSync(text, target, source)
            mainHandler.post { onResult(translated, error) }
        }
    }

    private fun translateSync(
        text: String,
        target: String,
        source: String,
    ): Pair<String?, String?> {
        var conn: HttpURLConnection? = null
        try {
            val url = URL("$BASE_URL/api/translate")
            conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.connectTimeout = 12000
            conn.readTimeout = 12000
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            conn.setRequestProperty("Accept", "application/json")
            conn.setRequestProperty("User-Agent", "LingoVerse-Mobile-App/2.0-live")

            val body = JSONObject()
                .put("text", text)
                .put("targetLang", target)
                .put("sourceLang", source)
                .toString()

            conn.outputStream.use { os ->
                os.write(body.toByteArray(StandardCharsets.UTF_8))
            }

            val code = conn.responseCode
            val stream = if (code in 200..299) conn.inputStream else conn.errorStream
            val raw = stream?.bufferedReader()?.use { it.readText() } ?: ""

            if (code == 200 && raw.isNotBlank()) {
                val json = JSONObject(raw)
                if (json.has("text")) {
                    return json.getString("text").trim() to null
                }
                return null to (json.optString("message")
                    .ifBlank { json.optString("error", "Translation failed") })
            }
            return null to "HTTP $code"
        } catch (e: Exception) {
            return null to "No connection"
        } finally {
            conn?.disconnect()
        }
    }
}