package com.tabiqchohan.translater

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Posts one persistent notification per chat app holding the latest translated
 * message. The notification does not auto-cancel, so it stays in the shade
 * until the user swipes it away. Actions: Copy / Reply / Dismiss.
 */
object ChatNotificationManager {

    const val CHANNEL_ID = "lc_translation"

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Live Chat Translation",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Translations of incoming chat messages"
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    fun idFor(packageName: String?): Int = (packageName ?: "live").hashCode()

    fun show(
        context: Context,
        source: String,
        original: String,
        translated: String,
        packageName: String?,
    ) {
        try {
            ensureChannel(context)
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val id = idFor(packageName)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            val contentPI = launchIntent(context, packageName, flags)

            val copyPI = PendingIntent.getBroadcast(
                context,
                id * 10 + 1,
                Intent(context, ChatNotificationReceiver::class.java)
                    .setAction(ChatNotificationReceiver.ACTION_COPY)
                    .putExtra("translated", translated),
                flags,
            )
            val replyPI = PendingIntent.getBroadcast(
                context,
                id * 10 + 2,
                Intent(context, ChatNotificationReceiver::class.java)
                    .setAction(ChatNotificationReceiver.ACTION_REPLY)
                    .putExtra("source", source)
                    .putExtra("package", packageName),
                flags,
            )
            val dismissPI = PendingIntent.getBroadcast(
                context,
                id * 10 + 3,
                Intent(context, ChatNotificationReceiver::class.java)
                    .setAction(ChatNotificationReceiver.ACTION_DISMISS)
                    .putExtra("notifId", id),
                flags,
            )

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_translate)
                .setContentTitle(source)
                .setContentText(translated)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText("$translated\n\n— $original"),
                )
                .setAutoCancel(false)
                .setOngoing(false)
                .setOnlyAlertOnce(false)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setGroup("com.tabiqchohan.translater.LIVE_CHAT")
                .addAction(0, "Copy", copyPI)
                .addAction(0, "Reply", replyPI)
                .addAction(0, "Dismiss", dismissPI)

            if (contentPI != null) builder.setContentIntent(contentPI)

            nm.notify(id, builder.build())
        } catch (_: Exception) {
        }
    }

    fun cancel(context: Context, id: Int) {
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(id)
        } catch (_: Exception) {
        }
    }

    private fun launchIntent(context: Context, pkg: String?, flags: Int): PendingIntent? {
        if (pkg.isNullOrBlank()) return null
        val launch = context.packageManager.getLaunchIntentForPackage(pkg) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(context, pkg.hashCode(), launch, flags)
    }
}
