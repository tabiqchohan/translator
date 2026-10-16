package com.tabiqchohan.translater

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Draggable, auto-dismissing floating bubble that shows the live translation
 * on top of any chat app. Drawn natively so it works while the Flutter app is
 * closed.
 */
object ChatBubbleManager {
    private const val AUTO_DISMISS_MS = 6_000L
    private const val MARGIN_DP = 16
    private const val WIDTH_DP = 260

    private var view: View? = null
    private var params: WindowManager.LayoutParams? = null
    private val handler = Handler(Looper.getMainLooper())
    private val dismissRunnable = Runnable { hide() }
    private var dark = false

    val isShowing: Boolean
        get() = view != null

    fun canDraw(context: Context): Boolean =
        Settings.canDrawOverlays(context)

    @SuppressLint("ClickableViewAccessibility")
    fun show(context: Context, source: String, original: String, translated: String) {
        ensureTheme()

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        if (!canDraw(context)) return

        if (view == null) {
            val bubble = buildView(context)
            view = bubble
            params = WindowManager.LayoutParams(
                dp(context, WIDTH_DP).toInt(),
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = dp(context, MARGIN_DP).toInt()
                y = dp(context, MARGIN_DP + 40).toInt()
            }
            wm.addView(bubble, params)
            attachDrag(bubble, wm)
        }

        val root = view as? LinearLayout
        root?.let {
            it.findViewById<TextView>(R2.id.bubbleOriginal).text = original + "\n\u2192"
            it.findViewById<TextView>(R2.id.bubbleTarget).text = translated
            it.findViewById<TextView>(R2.id.bubbleSource).text = source
        }

        handler.removeCallbacks(dismissRunnable)
        handler.postDelayed(dismissRunnable, AUTO_DISMISS_MS)
    }

    fun setDark(darkMode: Boolean) {
        dark = darkMode
        applyTheme()
    }

    fun hide() {
        handler.removeCallbacks(dismissRunnable)
        val wm = view?.context?.getSystemService(Context.WINDOW_SERVICE) as? WindowManager ?: return
        view?.let {
            try {
                wm.removeView(it)
            } catch (_: Exception) {}
        }
        view = null
        params = null
    }

    private fun ensureTheme() {
        dark = LiveChatPrefs.bubbleDark(view?.context ?: return)
    }

    private fun applyTheme() {
        val root = view as? LinearLayout ?: return
        val bg = if (dark) Color.parseColor("#F00F172A") else Color.parseColor("#F2FFFFFF")
        val fg = if (dark) Color.WHITE else Color.parseColor("#0F172A")
        val sub = if (dark) Color.parseColor("#B0CBD5E1") else Color.parseColor("#64748B")
        val shape = root.background as? android.graphics.drawable.GradientDrawable
        shape?.setColor(bg)
        root.findViewById<TextView>(R2.id.bubbleOriginal).setTextColor(sub)
        root.findViewById<TextView>(R2.id.bubbleTarget).setTextColor(fg)
        root.findViewById<TextView>(R2.id.bubbleSource).setTextColor(Color.parseColor("#818CF8"))
    }

    private fun buildView(context: Context): LinearLayout {
        val root = LinearLayout(context)
        root.orientation = LinearLayout.VERTICAL
        root.setPadding(dp(context, 14).toInt(), dp(context, 12).toInt(), dp(context, 14).toInt(), dp(context, 12).toInt())
        root.background = android.graphics.drawable.GradientDrawable().apply {
            cornerRadius = dp(context, 18)
            setColor(Color.parseColor("#F00F172A"))
            setStroke(dp(context, 1).toInt(), Color.parseColor("#38818CF8"))
        }
        root.setOnClickListener {
            val target = root.findViewById<TextView>(R2.id.bubbleTarget).text?.toString() ?: return@setOnClickListener
            val cb = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            cb.setPrimaryClip(ClipData.newPlainText("translated", target))
            Toast.makeText(context, "Translation copied", Toast.LENGTH_SHORT).show()
        }
        root.setOnLongClickListener {
            hide()
            true
        }

        val header = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                addView(TextView(context).apply {
                    text = "\u26A1 "
                    textSize = 12f
                    setTextColor(Color.parseColor("#8B5CF6"))
                })
                addView(TextView(context).apply {
                    id = R2.id.bubbleSource
                    text = "Live"
                    textSize = 12f
                    typeface = Typeface.DEFAULT_BOLD
                })
            }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

            addView(TextView(context).apply {
                text = "\u00D7"
                textSize = 16f
                setTextColor(Color.GRAY)
                setOnClickListener { hide() }
            })
        }
        root.addView(header)

        val target = TextView(context).apply {
            id = R2.id.bubbleTarget
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setLineSpacing(0f, 1.15f)
        }
        root.addView(target, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(context, 6).toInt()
        })

        val original = TextView(context).apply {
            id = R2.id.bubbleOriginal
            textSize = 12f
            setLineSpacing(0f, 1.2f)
        }
        root.addView(original, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(context, 4).toInt()
        })
        applyTheme()
        return root
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun attachDrag(root: View, wm: WindowManager) {
        root.setOnTouchListener(object : View.OnTouchListener {
            var startX = 0f
            var startY = 0f
            var startRootX = 0
            var startRootY = 0
            var moved = false

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        startX = event.rawX
                        startY = event.rawY
                        params?.let { p ->
                            startRootX = p.x
                            startRootY = p.y
                        }
                        moved = false
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - startX).toInt()
                        val dy = (event.rawY - startY).toInt()
                        params?.let { p ->
                            p.x = startRootX + dx
                            p.y = startRootY + dy
                            try { wm.updateViewLayout(root, p) } catch (_: Exception) {}
                            moved = true
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (!moved) {
                            root.performClick()
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun dp(context: Context, value: Int): Float =
        value * context.resources.displayMetrics.density
}

/**
 * Container of int ids constant to avoid resource files. We create views in
 * code and reference them via these ids (ids are namespaced to avoid clashes).
 */
object R2 {
    object id {
        const val bubbleSource = 0x10_00_01
        const val bubbleTarget = 0x10_00_02
        const val bubbleOriginal = 0x10_00_03
    }
}