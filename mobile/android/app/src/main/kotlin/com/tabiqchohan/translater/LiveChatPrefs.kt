package com.tabiqchohan.translater

import android.content.Context
import android.content.SharedPreferences

/**
 * Persisted settings for the live chat translator shared between the Flutter
 * UI (via method channel) and the native background service(s).
 */
object LiveChatPrefs {
    private const val PREFS_NAME = "live_chat"

    const val KEY_ENABLED = "lc_enabled"
    const val KEY_NOTIF_GRANTED = "lc_notif_granted"
    const val KEY_ACCESSIBILITY_GRANTED = "lc_accessibility_granted"
    const val KEY_TARGET_LANG = "lc_target_lang"
    const val KEY_APPS = "lc_apps"
    const val KEY_BUBBLE_DARK = "lc_bubble_dark"
    const val KEY_AUTO_REPLY = "lc_auto_reply"
    const val KEY_RATE_LIMIT_MS = "lc_rate_limit_ms"
    const val KEY_BATCH_MS = "lc_batch_ms"
    const val KEY_HISTORY = "lc_history"
    const val KEY_NOTIF_RUNNING = "lc_notif_running"
    const val KEY_ACC_RUNNING = "lc_acc_running"
    const val KEY_NOTIFY = "lc_notify"
    const val KEY_BUBBLE = "lc_bubble"
    const val KEY_LAST_INCOMING_LANG = "lc_last_incoming_lang"
    const val KEY_LAST_PKG = "lc_last_pkg"
    const val KEY_LAST_ORIGINAL = "lc_last_original"
    const val KEY_KB_LANG = "lc_kb_lang"

    val defaultApps = setOf(
        "com.whatsapp",
        "com.whatsapp.w4b",
        "com.facebook.orca",
        "org.telegram.messenger",
        "com.instagram.android",
        "com.google.android.apps.messaging",
        "com.snapchat.android",
        "com.viber.voip",
        "com.skype.raider",
        "com.imo.android.imoim",
        "com.linecorp.line",
        "com.tencent.mm",
    )

    @Volatile
    private var prefs: SharedPreferences? = null

    private fun p(context: Context): SharedPreferences {
        if (prefs == null) {
            prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
        return prefs!!
    }

    fun enabled(context: Context): Boolean =
        p(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_ENABLED, value).apply()
    }

    fun notifGranted(context: Context): Boolean =
        p(context).getBoolean(KEY_NOTIF_GRANTED, false)

    fun setNotifGranted(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_NOTIF_GRANTED, value).apply()
    }

    fun accGranted(context: Context): Boolean =
        p(context).getBoolean(KEY_ACCESSIBILITY_GRANTED, false)

    fun setAccGranted(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_ACCESSIBILITY_GRANTED, value).apply()
    }

    fun notifRunning(context: Context): Boolean =
        p(context).getBoolean(KEY_NOTIF_RUNNING, false)

    fun setNotifRunning(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_NOTIF_RUNNING, value).apply()
    }

    fun accRunning(context: Context): Boolean =
        p(context).getBoolean(KEY_ACC_RUNNING, false)

    fun setAccRunning(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_ACC_RUNNING, value).apply()
    }

    fun targetLang(context: Context): String =
        p(context).getString(KEY_TARGET_LANG, "en") ?: "en"

    fun setTargetLang(context: Context, value: String) {
        p(context).edit().putString(KEY_TARGET_LANG, value).apply()
    }

    fun enabledApps(context: Context): Set<String> =
        p(context).getStringSet(KEY_APPS, defaultApps) ?: defaultApps

    fun setEnabledApps(context: Context, apps: Set<String>) {
        p(context).edit().putStringSet(KEY_APPS, apps).apply()
    }

    fun bubbleDark(context: Context): Boolean =
        p(context).getBoolean(KEY_BUBBLE_DARK, false)

    fun setBubbleDark(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_BUBBLE_DARK, value).apply()
    }

    fun autoReply(context: Context): Boolean =
        p(context).getBoolean(KEY_AUTO_REPLY, false)

    fun setAutoReply(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_AUTO_REPLY, value).apply()
    }

    /** Show each translation as a persistent notification (stays until dismissed). */
    fun notify(context: Context): Boolean =
        p(context).getBoolean(KEY_NOTIFY, true)

    fun setNotify(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_NOTIFY, value).apply()
    }

    /** Also show the quick-peek floating bubble. Off by default. */
    fun bubble(context: Context): Boolean =
        p(context).getBoolean(KEY_BUBBLE, false)

    fun setBubble(context: Context, value: Boolean) {
        p(context).edit().putBoolean(KEY_BUBBLE, value).apply()
    }

    fun lastIncomingLang(context: Context): String =
        p(context).getString(KEY_LAST_INCOMING_LANG, "en") ?: "en"

    fun setLastIncomingLang(context: Context, value: String) {
        p(context).edit().putString(KEY_LAST_INCOMING_LANG, value).apply()
    }

    fun lastPkg(context: Context): String =
        p(context).getString(KEY_LAST_PKG, "") ?: ""

    fun setLastPkg(context: Context, value: String) {
        p(context).edit().putString(KEY_LAST_PKG, value).apply()
    }

    fun lastOriginal(context: Context): String =
        p(context).getString(KEY_LAST_ORIGINAL, "") ?: ""

    fun setLastOriginal(context: Context, value: String) {
        p(context).edit().putString(KEY_LAST_ORIGINAL, value).apply()
    }

    /** Target language used by the LingoVerse keyboard (IME). */
    fun keyboardLang(context: Context): String =
        p(context).getString(KEY_KB_LANG, "en") ?: "en"

    fun setKeyboardLang(context: Context, value: String) {
        p(context).edit().putString(KEY_KB_LANG, value).apply()
    }

    fun rateLimitMs(context: Context): Long =
        p(context).getLong(KEY_RATE_LIMIT_MS, 700L)

    fun batchMs(context: Context): Long =
        p(context).getLong(KEY_BATCH_MS, 400L)

    fun update(context: Context, values: Map<String, Any>) {
        val e = p(context).edit()
        values.forEach { (k, v) ->
            when (v) {
                is Boolean -> e.putBoolean(k, v)
                is String -> e.putString(k, v)
                is Long -> e.putLong(k, v)
                is Int -> e.putLong(k, v.toLong())
                is Set<*> -> e.putStringSet(k, v.filterIsInstance<String>().toSet())
            }
        }
        e.apply()
    }

    fun snapshot(context: Context): Map<String, Any> = mapOf(
        KEY_ENABLED to enabled(context),
        KEY_NOTIF_GRANTED to notifGranted(context),
        KEY_ACCESSIBILITY_GRANTED to accGranted(context),
        KEY_NOTIF_RUNNING to notifRunning(context),
        KEY_ACC_RUNNING to accRunning(context),
        KEY_TARGET_LANG to targetLang(context),
        KEY_APPS to enabledApps(context).toList(),
        KEY_BUBBLE_DARK to bubbleDark(context),
        KEY_AUTO_REPLY to autoReply(context),
        KEY_NOTIFY to notify(context),
        KEY_BUBBLE to bubble(context),
        KEY_LAST_INCOMING_LANG to lastIncomingLang(context),
        KEY_KB_LANG to keyboardLang(context),
        KEY_RATE_LIMIT_MS to rateLimitMs(context),
        KEY_BATCH_MS to batchMs(context),
    )
}