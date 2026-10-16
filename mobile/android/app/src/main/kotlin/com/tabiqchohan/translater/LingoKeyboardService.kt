package com.tabiqchohan.translater

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputConnection
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.Spinner
import android.widget.TextView

/**
 * LingoVerse keyboard (IME). Type in your own language (e.g. Roman Urdu),
 * pick the target language, then tap "Translate" — the typed text is replaced
 * with the translation right inside the chat box.
 */
class LingoKeyboardService : InputMethodService() {

    private var targetLang = "en"
    private var shift = false
    private var translating = false
    private val typed = StringBuilder()
    private val letterKeys = LinkedHashMap<String, TextView>()

    private var translateButton: TextView? = null

    private val letterBg = Color.parseColor("#FFFFFF")
    private val specialBg = Color.parseColor("#CBD2E1")
    private val accent = Color.parseColor("#6366F1")
    private val darkText = Color.parseColor("#1E293B")

    override fun onCreateInputView(): View {
        targetLang = LiveChatPrefs.keyboardLang(this)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#E7EBF3"))
            setPadding(dp(4), dp(6), dp(4), dp(10))
        }

        root.addView(buildTopBar())

        addRow(root, listOf(
            "q", "w", "e", "r", "t", "y", "u", "i", "o", "p"
        ).map { ch -> key(ch, 1f, letterBg, darkText) { commitLetter(ch) }.also { letterKeys[ch] = it } })

        addRow(root, listOf(
            "a", "s", "d", "f", "g", "h", "j", "k", "l"
        ).map { ch -> key(ch, 1f, letterBg, darkText) { commitLetter(ch) }.also { letterKeys[ch] = it } })

        addRow(root, listOf(
            key("⇧", 1.4f, specialBg, darkText) { toggleShift() },
            *listOf("z", "x", "c", "v", "b", "n", "m").map { ch ->
                key(ch, 1f, letterBg, darkText) { commitLetter(ch) }.also { letterKeys[ch] = it }
            }.toTypedArray(),
            key("⌫", 1.4f, specialBg, darkText) { backspace() },
        ))

        addRow(root, listOf(
            key("space", 5f, letterBg, darkText) { commitChar(" ") },
            key("↵", 1.6f, accent, Color.WHITE) { commitEnter() },
        ))

        return root
    }

    private fun buildTopBar(): View {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(2), dp(2), dp(2), dp(6)) }
            gravity = Gravity.CENTER_VERTICAL
        }

        val spinner = Spinner(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, dp(40), 1f)
            adapter = ArrayAdapter(
                this@LingoKeyboardService,
                android.R.layout.simple_spinner_dropdown_item,
                KeyboardLangs.all.map { it.second }
            )
            setSelection(KeyboardLangs.all.indexOfFirst { it.first == targetLang }.coerceAtLeast(0))
            onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?, view: View?, position: Int, id: Long
                ) {
                    targetLang = KeyboardLangs.all[position].first
                    LiveChatPrefs.setKeyboardLang(this@LingoKeyboardService, targetLang)
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
        bar.addView(spinner)

        val btn = TextView(this).apply {
            text = "Translate"
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            isClickable = true
            layoutParams = LinearLayout.LayoutParams(dp(120), dp(40)).apply {
                setMargins(dp(4), 0, 0, 0)
            }
            background = rounded(accent, dp(8).toFloat())
            setOnClickListener { translateAndCommit() }
        }
        translateButton = btn
        bar.addView(btn)
        return bar
    }

    private fun addRow(root: LinearLayout, keys: List<View>) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            gravity = Gravity.CENTER
        }
        keys.forEach { row.addView(it) }
        root.addView(row)
    }

    private fun key(
        label: String,
        weight: Float,
        bg: Int,
        textColor: Int,
        onTap: () -> Unit,
    ): TextView = TextView(this).apply {
        text = label
        gravity = Gravity.CENTER
        setTextColor(textColor)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
        isClickable = true
        layoutParams = LinearLayout.LayoutParams(0, dp(46), weight).apply {
            setMargins(dp(2), dp(2), dp(2), dp(2))
        }
        background = rounded(bg, dp(8).toFloat())
        setOnClickListener { onTap() }
    }

    private fun commitLetter(ch: String) {
        commitChar(if (shift) ch.uppercase() else ch)
        if (shift) {
            shift = false
            refreshShift()
        }
    }

    private fun commitChar(ch: String) {
        val ic = currentInputConnection ?: return
        ic.commitText(ch, 1)
        typed.append(ch)
    }

    private fun backspace() {
        val ic = currentInputConnection ?: return
        ic.deleteSurroundingText(1, 0)
        if (typed.isNotEmpty()) typed.deleteCharAt(typed.length - 1)
    }

    private fun commitEnter() {
        val ic = currentInputConnection ?: return
        ic.commitText("\n", 1)
        typed.setLength(0)
    }

    private fun toggleShift() {
        shift = !shift
        refreshShift()
    }

    private fun refreshShift() {
        letterKeys.forEach { (lower, view) ->
            view.text = if (shift) lower.uppercase() else lower
        }
    }

    private fun translateAndCommit() {
        if (translating) return
        val ic: InputConnection = currentInputConnection ?: return
        val text = typed.toString().ifBlank {
            ic.getTextBeforeCursor(500, 0)?.toString().orEmpty()
        }
        if (text.isBlank()) return
        translating = true
        translateButton?.text = "…"
        TranslatorClient.translate(text, targetLang, "auto") { out, _ ->
            translating = false
            translateButton?.text = "Translate"
            if (!out.isNullOrBlank()) {
                ic.beginBatchEdit()
                ic.deleteSurroundingText(text.length, 0)
                ic.commitText(out, 1)
                ic.endBatchEdit()
                typed.setLength(0)
            }
        }
    }

    override fun onStartInput(attribute: android.view.inputmethod.EditorInfo?, restarting: Boolean) {
        typed.setLength(0)
        shift = false
        refreshShift()
        super.onStartInput(attribute, restarting)
    }

    private fun rounded(color: Int, radius: Float) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()
}

/** Target languages offered by the keyboard (mirrors the app's language list). */
object KeyboardLangs {
    val all: List<Pair<String, String>> = listOf(
        "en" to "English",
        "ur" to "Urdu",
        "hi" to "Hindi",
        "es" to "Spanish",
        "fr" to "French",
        "de" to "German",
        "zh" to "Chinese (Simplified)",
        "zh-TW" to "Chinese (Traditional)",
        "ja" to "Japanese",
        "ko" to "Korean",
        "ar" to "Arabic",
        "pt" to "Portuguese",
        "ru" to "Russian",
        "tr" to "Turkish",
        "it" to "Italian",
        "nl" to "Dutch",
        "pl" to "Polish",
        "sv" to "Swedish",
        "da" to "Danish",
        "fi" to "Finnish",
        "th" to "Thai",
        "vi" to "Vietnamese",
        "ms" to "Malay",
        "id" to "Indonesian",
        "bn" to "Bengali",
        "pa" to "Punjabi",
        "fa" to "Persian (Farsi)",
        "ps" to "Pashto",
        "sd" to "Sindhi",
        "ta" to "Tamil",
        "te" to "Telugu",
        "mr" to "Marathi",
        "gu" to "Gujarati",
        "kn" to "Kannada",
        "ml" to "Malayalam",
        "ne" to "Nepali",
        "si" to "Sinhala",
        "my" to "Burmese (Myanmar)",
        "km" to "Khmer",
        "tl" to "Tagalog (Filipino)",
        "uk" to "Ukrainian",
        "cs" to "Czech",
        "el" to "Greek",
        "he" to "Hebrew",
        "ro" to "Romanian",
        "hu" to "Hungarian",
        "no" to "Norwegian",
        "sk" to "Slovak",
        "bg" to "Bulgarian",
        "hr" to "Croatian",
        "sr" to "Serbian",
        "sw" to "Swahili",
        "af" to "Afrikaans",
        "az" to "Azerbaijani",
        "uz" to "Uzbek",
        "kk" to "Kazakh",
    )
}
