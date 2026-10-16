package com.tabiqchohan.translater

import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast

/**
 * Handles the Copy / Reply / Dismiss actions attached to a live-chat
 * translation notification.
 */
class ChatNotificationReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_COPY = "com.tabiqchohan.translater.NOTIF_COPY"
        const val ACTION_REPLY = "com.tabiqchohan.translater.NOTIF_REPLY"
        const val ACTION_DISMISS = "com.tabiqchohan.translater.NOTIF_DISMISS"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_COPY -> {
                val text = intent.getStringExtra("translated") ?: return
                val cb = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cb.setPrimaryClip(ClipData.newPlainText("translation", text))
                Toast.makeText(context, "Translation copied", Toast.LENGTH_SHORT).show()
            }

            ACTION_DISMISS -> {
                ChatNotificationManager.cancel(context, intent.getIntExtra("notifId", 0))
            }

            ACTION_REPLY -> {
                val source = intent.getStringExtra("source") ?: "Chat"
                val pkg = intent.getStringExtra("package")
                ChatReplyBar.show(context, source, pkg)
            }
        }
    }
}
