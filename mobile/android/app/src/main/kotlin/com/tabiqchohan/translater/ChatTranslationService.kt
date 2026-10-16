package com.tabiqchohan.translater

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Phase A: universal notification reader. Reads incoming message notifications
 * from any enabled chat app and feeds the shared translation engine.
 */
class ChatTranslationService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        ChatTranslatorEngine.attach(applicationContext)
        LiveChatPrefs.setNotifGranted(this, true)
        LiveChatPrefs.setNotifRunning(this, true)
        ChatTranslatorPlugin.emit(
            mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(this), "reason" to "notif_connected"),
        )
    }

    override fun onListenerDisconnected() {
        LiveChatPrefs.setNotifRunning(this, false)
        ChatTranslatorPlugin.emit(
            mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(this), "reason" to "notif_disconnected"),
        )
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!LiveChatPrefs.enabled(this)) return
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        if (pkg !in LiveChatPrefs.enabledApps(this)) return

        val n = sbn.notification ?: return
        when (n.category) {
            Notification.CATEGORY_SERVICE,
            Notification.CATEGORY_PROGRESS,
            Notification.CATEGORY_SYSTEM,
            -> return
        }

        val extras = n.extras ?: return
        val title = extras.getString(Notification.EXTRA_TITLE)?.trim()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim()
        if (text.isNullOrBlank()) return

        ChatTranslatorEngine.offer(this, title ?: "Chat", text, pkg)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }

    override fun onDestroy() {
        LiveChatPrefs.setNotifRunning(this, false)
        ChatTranslatorPlugin.emit(
            mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(this), "reason" to "notif_destroyed"),
        )
        super.onDestroy()
    }
}