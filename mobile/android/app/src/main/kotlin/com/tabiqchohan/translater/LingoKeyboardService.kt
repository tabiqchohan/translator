package com.tabiqchohan.translater

import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.inputmethodservice.InputMethodService
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
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
 *
 * Layout follows the standard Android keyboard conventions: number row,
 * three letter rows, shift / backspace, a bottom row with hide-keyboard,
 * layout switch, globe, space, punctuation and enter.
 */
class LingoKeyboardService : InputMethodService() {

    private var targetLang = "en"
    private var shift = false
    private var symbolsMode = false
    private var translating = false
    private val typed = StringBuilder()
    private val letterKeys = LinkedHashMap<String, TextView>()

    private var shiftKey: TextView? = null
    private var translateButton: TextView? = null
    private var keysContainer: LinearLayout? = null

    private val isDark: Boolean
        get() = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    private val keyboardBg: Int
        get() = color(if (isDark) "#0B1120" else "#E9EEF8")
    private val keyBg: Int
        get() = color(if (isDark) "#1E293B" else "#FFFFFF")
    private val specialKeyBg: Int
        get() = color(if (isDark) "#334155" else "#CBD5E1")
    private val keyText: Int
        get() = color(if (isDark) "#E2E8F0" else "#1E293B")
    private val mutedText: Int
        get() = color(if (isDark) "#94A3B8" else "#64748B")
    private val accent: Int
        get() = color(if (isDark) "#818CF8" else "#6366F1")
    private val rippleTint: Int
        get() = color(if (isDark) "#33FFFFFF" else "#336366F1")
    private val barBg: Int
        get() = color(if (isDark) "#131C2E" else "#FFFFFF")

    private fun color(hex: String) = Color.parseColor(hex)

    override fun onCreateInputView(): View {
        targetLang = LiveChatPrefs.keyboardLang(this)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(keyboardBg)
            setPadding(dp(3), dp(6), dp(3), dp(8))
        }

        root.addView(buildTopBar())

        val keys = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        root.addView(keys)
        keysContainer = keys
        renderRows()

        return root
    }

    // ---------------------------------------------------------------- top bar

    private fun buildTopBar(): View {
        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { setMargins(dp(2), dp(0), dp(2), dp(6)) }
            setPadding(dp(4), dp(2), dp(4), dp(2))
            background = rounded(barBg, dp(14).toFloat())
        }

        val spinner = Spinner(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, dp(40), 1f).apply {
                setMargins(dp(2), 0, dp(4), 0)
            }
            adapter = ArrayAdapter(
                this@LingoKeyboardService,
                R.layout.lv_spinner_item,
                KeyboardLangs.all.map { it.second }
            ).also { it.setDropDownViewResource(R.layout.lv_spinner_dropdown) }
            setSelection(
                KeyboardLangs.all.indexOfFirst { it.first == targetLang }.coerceAtLeast(0)
            )
            background = resources.getDrawable(R.drawable.lv_spinner_bg, theme)
            setPopupBackgroundDrawable(
                rounded(color(if (isDark) "#1E293B" else "#FFFFFF"), dp(14).toFloat())
            )
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
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14.5f)
            isClickable = true
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                dp(36)
            ).apply {
                setMargins(dp(0), 0, dp(2), 0)
                setPadding(dp(18), 0, dp(18), 0)
            }
            background = ripple(accent, dp(12).toFloat())
            setOnClickListener { translateAndCommit() }
        }
        translateButton = btn
        bar.addView(btn)
        return bar
    }

    // ------------------------------------------------------------------ rows

    private fun renderRows() {
        val container = keysContainer ?: return
        container.removeAllViews()
        letterKeys.clear()
        shiftKey = null

        if (symbolsMode) {
            addRow(container, listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
                .map { ch -> key(ch, 1f, keyBg, keyText) { commitChar(ch) } }, heightDp = 38)
            addRow(container, listOf("@", "#", "$", "%", "&", "*", "-", "_", "+", "=")
                .map { ch -> key(ch, 1f, keyBg, keyText) { commitChar(ch) } })
            addRow(container, listOf(
                key("?123", 1.5f, specialKeyBg, keyText) { toggleSymbols(false) },
                key(";", 1f, keyBg, keyText) { commitChar(";") },
                key(",", 1f, keyBg, keyText) { commitChar(",") },
                key(".", 1f, keyBg, keyText) { commitChar(".") },
                key("!", 1f, keyBg, keyText) { commitChar("!") },
                key("?", 1f, keyBg, keyText) { commitChar("?") },
                key("'", 1f, keyBg, keyText) { commitChar("'") },
                key("\"", 1f, keyBg, keyText) { commitChar("\"") },
                key("⌫", 1.4f, specialKeyBg, keyText) { backspace() },
            ))
        } else {
            addRow(container, listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
                .map { ch -> key(ch, 1f, keyBg, keyText) { commitChar(ch) } }, heightDp = 38)
            addRow(container, listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
                .map { ch -> key(ch, 1f, keyBg, keyText) { commitLetter(ch) }.also { letterKeys[ch] = it } })
            addRow(container, listOf("a", "s", "d", "f", "g", "h", "j", "k", "l")
                .map { ch -> key(ch, 1f, keyBg, keyText) { commitLetter(ch) }.also { letterKeys[ch] = it } })
            addRow(container, listOf(
                key("⇧", 1.4f, specialKeyBg, keyText) { toggleShift() }.also { shiftKey = it },
                *listOf("z", "x", "c", "v", "b", "n", "m")
                    .map { ch ->
                        key(ch, 1f, keyBg, keyText) { commitLetter(ch) }.also { letterKeys[ch] = it }
                    }.toTypedArray(),
                key("⌫", 1.4f, specialKeyBg, keyText) { backspace() },
            ))
        }

        addRow(container, listOf(
            key("⌄", 1.2f, specialKeyBg, keyText) { requestHideSelf(0) },
            key(if (symbolsMode) "ABC" else "?123", 1.5f, specialKeyBg, keyText) {
                toggleSymbols(!symbolsMode)
            },
            key("🌐", 1.2f, specialKeyBg, keyText) { switchToNextInputMethod(false) },
            key("Space", 4.2f, keyBg, mutedText) { commitChar(" ") }.also {
                it.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            },
            key(",", 1f, keyBg, keyText) { commitChar(",") },
            key(".", 1f, keyBg, keyText) { commitChar(".") },
            key("↵", 1.6f, accent, Color.WHITE) { commitEnter() },
        ))
    }

    private fun addRow(
        root: LinearLayout,
        keys: List<View>,
        heightDp: Int = 46,
    ) {
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
        heightDp: Int = 46,
        onTap: () -> Unit,
    ): TextView = TextView(this).apply {
        text = label
        gravity = Gravity.CENTER
        setTextColor(textColor)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
        isClickable = true
        layoutParams = LinearLayout.LayoutParams(0, dp(heightDp), weight).apply {
            setMargins(dp(2), dp(2), dp(2), dp(2))
        }
        background = ripple(bg, dp(9).toFloat())
        setOnClickListener { onTap() }
        setOnLongClickListener {
            if (label == "⌫") {
                clearAll()
                true
            } else {
                false
            }
        }
        setOnTouchListener { v, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    v.animate().scaleX(0.93f).scaleY(0.93f).setDuration(70).start()
                    v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.animate().scaleX(1f).scaleY(1f).setDuration(70).start()
                }
            }
            false
        }
    }

    // ---------------------------------------------------------------- typing

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

    private fun clearAll() {
        val ic = currentInputConnection ?: return
        val len = typed.length
        if (len > 0) {
            ic.deleteSurroundingText(len, 0)
            typed.setLength(0)
        } else {
            ic.deleteSurroundingText(50, 0)
        }
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
        shiftKey?.apply {
            background = ripple(
                if (shift) accent else specialKeyBg,
                dp(9).toFloat()
            )
            setTextColor(if (shift) Color.WHITE else keyText)
        }
    }

    private fun toggleSymbols(toSymbols: Boolean) {
        symbolsMode = toSymbols
        shift = false
        renderRows()
    }

    // ------------------------------------------------------------- translate

    private fun translateAndCommit() {
        if (translating) return
        val ic: InputConnection = currentInputConnection ?: return
        val text = typed.toString().ifBlank {
            ic.getTextBeforeCursor(500, 0)?.toString().orEmpty()
        }
        if (text.isBlank()) return
        translating = true
        translateButton?.text = "…"
        translateButton?.isEnabled = false
        TranslatorClient.translate(text, targetLang, "auto") { out, _ ->
            translating = false
            translateButton?.text = "Translate"
            translateButton?.isEnabled = true
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
        symbolsMode = false
        renderRows()
        super.onStartInput(attribute, restarting)
    }

    // ----------------------------------------------------------------- utils

    private fun rounded(c: Int, radius: Float) = GradientDrawable().apply {
        setColor(c)
        cornerRadius = radius
    }

    private fun ripple(c: Int, radius: Float): RippleDrawable = RippleDrawable(
        ColorStateList.valueOf(rippleTint),
        rounded(c, radius),
        null
    )

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
