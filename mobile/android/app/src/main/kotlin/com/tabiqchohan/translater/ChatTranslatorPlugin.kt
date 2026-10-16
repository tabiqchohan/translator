package com.tabiqchohan.translater

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Method + event channel bridge between the Flutter UI and the native live
 * chat translator (prefs, permissions, bubble, history).
 */
class ChatTranslatorPlugin : MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val CHANNEL = "com.tabiqchohan.translater/live_chat"
        private const val EVENTS = "com.tabiqchohan.translater/live_chat/events"
        private const val NOTIF_PERM_REQUEST = 8801

        @Volatile
        private var appContext: Context? = null

        @Volatile
        private var activity: Activity? = null

        @Volatile
        private var sink: EventChannel.EventSink? = null

        fun setActivity(a: Activity?) {
            activity = a
        }

        fun emit(data: Any) {
            try {
                sink?.success(data)
            } catch (_: Exception) {}
        }
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun onAttach(messenger: BinaryMessenger, context: Context) {
        appContext = context
        ChatTranslatorEngine.attach(context)
        methodChannel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
        eventChannel = EventChannel(messenger, EVENTS).also { it.setStreamHandler(this) }
    }

    fun onDetached(messenger: BinaryMessenger?) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        if (messenger == null) {
            appContext = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val ctx = appContext
        if (ctx == null) {
            result.error("no_context", "Live chat plugin context not ready", null)
            return
        }
        when (call.method) {
            "getStatus" -> result.success(
                mapOf(
                    "settings" to LiveChatPrefs.snapshot(ctx),
                    "canDrawOverlay" to ChatBubbleManager.canDraw(ctx),
                    "bubbleShowing" to ChatBubbleManager.isShowing,
                    "keyboardEnabled" to isKeyboardEnabled(ctx),
                    "notifPermGranted" to hasNotifPermission(ctx),
                ),
            )

            "setEnabled" -> {
                val v = call.argument<Boolean>("enabled") ?: false
                LiveChatPrefs.setEnabled(ctx, v)
                result.success(true)
            }

            "setTargetLang" -> {
                val v = call.argument<String>("lang") ?: "en"
                LiveChatPrefs.setTargetLang(ctx, v)
                result.success(true)
            }

            "setApps" -> {
                val apps = call.argument<List<String>>("apps")
                LiveChatPrefs.setEnabledApps(ctx, apps?.toSet() ?: emptySet())
                result.success(true)
            }

            "setBubbleDark" -> {
                val v = call.argument<Boolean>("dark") ?: false
                LiveChatPrefs.setBubbleDark(ctx, v)
                ChatBubbleManager.setDark(v)
                result.success(true)
            }

            "setAutoReply" -> {
                val v = call.argument<Boolean>("autoReply") ?: false
                LiveChatPrefs.setAutoReply(ctx, v)
                result.success(true)
            }

            "setNotify" -> {
                val v = call.argument<Boolean>("notify") ?: true
                LiveChatPrefs.setNotify(ctx, v)
                result.success(true)
            }

            "setBubble" -> {
                val v = call.argument<Boolean>("bubble") ?: false
                LiveChatPrefs.setBubble(ctx, v)
                result.success(true)
            }

            "setKeyboardLang" -> {
                val v = call.argument<String>("lang") ?: "en"
                LiveChatPrefs.setKeyboardLang(ctx, v)
                result.success(true)
            }

            "openKeyboardSettings" -> {
                open(ctx, Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
                result.success(true)
            }

            "showKeyboardPicker" -> {
                try {
                    val imm = ctx.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.showInputMethodPicker()
                } catch (_: Exception) {}
                result.success(true)
            }

            "isKeyboardEnabled" -> result.success(isKeyboardEnabled(ctx))

            "hasNotificationPermission" -> result.success(hasNotifPermission(ctx))

            "requestNotificationPermission" -> {
                requestNotifPermission(ctx)
                result.success(true)
            }

            "openAppNotificationSettings" -> {
                open(
                    ctx,
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName),
                )
                result.success(true)
            }

            "showReplyBar" -> {
                val source = call.argument<String>("source") ?: "Chat"
                ChatReplyBar.show(ctx, source, LiveChatPrefs.lastPkg(ctx))
                result.success(true)
            }

            "hideReplyBar" -> {
                ChatReplyBar.hide()
                result.success(true)
            }

            "hideBubble" -> {
                ChatBubbleManager.hide()
                result.success(true)
            }

            "testMessage" -> {
                val text = call.argument<String>("text") ?: "Aap kaisay hain?"
                val source = call.argument<String>("source") ?: "Test chat"
                ChatTranslatorEngine.offer(ctx, source, text, "com.whatsapp")
                result.success(true)
            }

            "openNotifPermission" -> {
                open(ctx, Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(true)
            }

            "openAccessibilityPermission" -> {
                open(ctx, Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                result.success(true)
            }

            "openOverlayPermission" -> {
                open(
                    ctx,
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${ctx.packageName}"),
                    ),
                )
                result.success(true)
            }

            "getHistory" -> result.success(chatHistory(ctx))

            "clearHistory" -> {
                ChatHistoryStore.clear(ctx)
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun chatHistory(ctx: Context): List<Map<String, Any?>> =
        ChatHistoryStore.history(ctx).map { e -> e }

    private fun isKeyboardEnabled(ctx: Context): Boolean = try {
        val imm = ctx.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.enabledInputMethodList.any {
            it.packageName == ctx.packageName &&
                it.serviceName == LingoKeyboardService::class.java.name
        }
    } catch (_: Exception) {
        false
    }

    private fun hasNotifPermission(ctx: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ctx.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotifPermission(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (hasNotifPermission(ctx)) return
        try {
            activity?.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                NOTIF_PERM_REQUEST,
            )
        } catch (_: Exception) {}
    }

    private fun open(ctx: Context, intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            ctx.startActivity(intent)
        } catch (_: Exception) {}
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        appContext?.let { ctx ->
            events?.success(
                mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(ctx), "reason" to "listener_registered"),
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}