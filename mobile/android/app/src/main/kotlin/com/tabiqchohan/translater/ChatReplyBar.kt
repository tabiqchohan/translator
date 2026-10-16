package com.tabiqchohan.translater

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Focusable overlay bar that lets the user type a reply, translates it into the
 * other person's language and copies the result so it can be pasted into the
 * chat. Shown from a notification action or the app's Live Chat screen.
 */
object ChatReplyBar {

    private var view: View? = null
    private var ctx: Context? = null

    val isShowing: Boolean get() = view != null

    @SuppressLint("SetTextI18n")
    fun show(context: Context, source: String, packageName: String?) {
        if (!Settings.canDrawOverlays(context)) {
            Toast.makeText(
                context,
                "Enable \"Display over other apps\" to use the reply translator",
                Toast.LENGTH_LONG,
            ).show()
            return
        }
        hide()

        val app = context.applicationContext
        ctx = app
        val wm = app.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val dark = LiveChatPrefs.bubbleDark(app)
        val bg = if (dark) Color.parseColor("#F00F172A") else Color.parseColor("#F2FFFFFF")
        val fg = if (dark) Color.WHITE else Color.parseColor("#0F172A")
        val sub = if (dark) Color.parseColor("#B0CBD5E1") else Color.parseColor("#64748B")
        val fieldBg = if (dark) Color.parseColor("#20293E") else Color.parseColor("#F1F5F9")
        val target = LiveChatPrefs.lastIncomingLang(app)

        val root = LinearLayout(app).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(app, 16).toInt(), dp(app, 14).toInt(), dp(app, 16).toInt(), dp(app, 14).toInt())
            background = GradientDrawable().apply {
                cornerRadius = dp(app, 18)
                setColor(bg)
                setStroke(dp(app, 1).toInt(), Color.parseColor("#55818CF8"))
            }
        }

        val header = LinearLayout(app).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        header.addView(
            TextView(app).apply {
                text = "Reply translator"
                setTextColor(fg)
                textSize = 15f
                typeface = Typeface.DEFAULT_BOLD
            },
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f),
        )
        header.addView(
            TextView(app).apply {
                text = "\u00D7"
                textSize = 18f
                setTextColor(sub)
                setPadding(dp(app, 10).toInt(), 0, 0, 0)
                setOnClickListener { hide() }
            },
        )
        root.addView(header)

        root.addView(
            TextView(app).apply {
                text = "Translates your reply into ${ScriptLang.name(target)}"
                setTextColor(sub)
                textSize = 11f
                setPadding(0, dp(app, 4).toInt(), 0, dp(app, 8).toInt())
            },
        )

        val input = EditText(app).apply {
            hint = "Type your reply…"
            setHintTextColor(sub)
            setTextColor(fg)
            textSize = 15f
            inputType = InputType.TYPE_CLASS_TEXT or
                InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or
                InputType.TYPE_TEXT_FLAG_MULTI_LINE
            maxLines = 4
            setBackgroundColor(Color.TRANSPARENT)
        }
        val inputWrap = LinearLayout(app).apply {
            background = GradientDrawable().apply {
                cornerRadius = dp(app, 12)
                setColor(fieldBg)
            }
            setPadding(dp(app, 10).toInt(), dp(app, 6).toInt(), dp(app, 10).toInt(), dp(app, 6).toInt())
            addView(
                input,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
        }
        root.addView(inputWrap)

        val result = TextView(app).apply {
            setTextColor(fg)
            textSize = 15f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dp(app, 10).toInt(), 0, dp(app, 4).toInt())
            visibility = View.GONE
        }
        root.addView(result)

        val buttons = LinearLayout(app).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
        }
        val copyBtn = Button(app).apply { text = "Copy"; isEnabled = false }
        val translateBtn = Button(app).apply { text = "Translate" }

        translateBtn.setOnClickListener {
            val text = input.text?.toString()?.trim().orEmpty()
            if (text.isEmpty()) return@setOnClickListener
            translateBtn.isEnabled = false
            translateBtn.text = "…"
            TranslatorClient.translate(text, target, "auto") { translated, error ->
                translateBtn.isEnabled = true
                translateBtn.text = "Translate"
                if (translated != null) {
                    result.text = translated
                    result.visibility = View.VISIBLE
                    copyBtn.isEnabled = true
                } else {
                    Toast.makeText(app, error ?: "Translation failed", Toast.LENGTH_SHORT).show()
                }
            }
        }
        copyBtn.setOnClickListener {
            val t = result.text?.toString() ?: return@setOnClickListener
            val cb = app.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            cb.setPrimaryClip(ClipData.newPlainText("reply", t))
            Toast.makeText(app, "Reply copied — paste it into the chat", Toast.LENGTH_SHORT).show()
        }
        buttons.addView(copyBtn)
        buttons.addView(translateBtn)
        root.addView(buttons)

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or
                WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE
        }

        try {
            wm.addView(root, lp)
            view = root
            input.requestFocus()
            input.postDelayed({
                val imm = app.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                imm.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
            }, 180)
        } catch (_: Exception) {
            view = null
        }
    }

    fun hide() {
        val app = ctx ?: return
        val v = view ?: return
        val wm = app.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.removeView(v)
        } catch (_: Exception) {
        }
        view = null
    }

    private fun overlayType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

    private fun dp(context: Context, value: Int): Float =
        value * context.resources.displayMetrics.density
}
