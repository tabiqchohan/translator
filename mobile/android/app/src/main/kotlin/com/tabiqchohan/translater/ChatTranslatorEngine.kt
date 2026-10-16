package com.tabiqchohan.translater

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

/**
 * Shared pipeline: dedupe -> coalesce (batching + rate limit) -> translate ->
 * show bubble + save history + notify Flutter. Used by both the notification
 * listener and the accessibility service so messages never translate twice.
 */
object ChatTranslatorEngine {

    private class Msg(val source: String, val text: String, val packageName: String?)

    @Volatile
    var context: Context? = null
        private set

    private val seen = LinkedHashSet<String>()
    private val seenMax = 64

    private var pending: Msg? = null
    private var lastTranslateUptime = 0L

    private val handler = Handler(Looper.getMainLooper())
    private val runBatch = Runnable { flushPending() }

    /** Set by the accessibility service (Phase C auto-paste). */
    @Volatile
    var autoPasteConsumer: ((String) -> Unit)? = null

    fun attach(app: Context) {
        context = app
    }

    @Synchronized
    fun offer(context: Context, source: String, text: String, packageName: String?) {
        if (!LiveChatPrefs.enabled(context)) return
        val clean = text.trim()
        if (clean.isEmpty() || clean.length > 300) return

        val key = "${packageName ?: ""}|$source|$clean"
        if (!seen.add(key)) return
        while (seen.size > seenMax) {
            seen.remove(seen.first())
        }

        pending = Msg(source.trim(), clean, packageName)
        handler.removeCallbacks(runBatch)
        handler.post(runBatch)
    }

    private fun flushPending() {
        val msg = pending ?: return
        val ctx = context ?: return
        val wait = lastTranslateUptime + LiveChatPrefs.rateLimitMs(ctx) - SystemClock.uptimeMillis()
        if (wait > 0) {
            handler.postDelayed({ translateNow(msg) }, wait)
        } else {
            translateNow(msg)
        }
    }

    private fun translateNow(msg: Msg) {
        val ctx = context ?: return
        lastTranslateUptime = SystemClock.uptimeMillis()
        val target = LiveChatPrefs.targetLang(ctx)
        val incomingLang = ScriptLang.guess(msg.text)
        LiveChatPrefs.setLastIncomingLang(ctx, incomingLang)
        LiveChatPrefs.setLastPkg(ctx, msg.packageName ?: "")
        LiveChatPrefs.setLastOriginal(ctx, msg.text)
        TranslatorClient.translate(msg.text, target, "auto") { translated, _ ->
            if (translated == null) return@translate
            if (LiveChatPrefs.bubble(ctx)) {
                ChatBubbleManager.show(ctx, msg.source, msg.text, translated)
            }
            if (LiveChatPrefs.notify(ctx)) {
                ChatNotificationManager.show(ctx, msg.source, msg.text, translated, msg.packageName)
            }
            ChatHistoryStore.add(ctx, msg.source, msg.text, translated, target)
            ChatTranslatorPlugin.emit(
                mapOf(
                    "type" to "translated",
                    "source" to msg.source,
                    "original" to msg.text,
                    "translated" to translated,
                    "targetLang" to target,
                    "timestamp" to System.currentTimeMillis(),
                ),
            )
            if (LiveChatPrefs.autoReply(ctx)) {
                autoPasteConsumer?.invoke(translated)
            }
        }
    }
}