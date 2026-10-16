package com.tabiqchohan.translater

/**
 * Lightweight, offline Unicode-script guesser used to figure out which language
 * an incoming chat message is written in. Mirrors the Dart LanguageDetector so
 * the reply bar can translate replies back into the other person's language.
 */
object ScriptLang {

    fun guess(text: String): String {
        for (ch in text) {
            val c = ch.code
            when {
                c in 0x0600..0x06FF || c in 0x0750..0x077F ||
                    c in 0xFB50..0xFDFF || c in 0xFE70..0xFEFF -> return "ur"
                c in 0x0900..0x097F -> return "hi"
                c in 0x0980..0x09FF -> return "bn"
                c in 0x0400..0x04FF -> return "ru"
                c in 0x3040..0x30FF -> return "ja"
                c in 0x4E00..0x9FFF || c in 0x3400..0x4DBF -> return "zh"
                c in 0xAC00..0xD7AF -> return "ko"
                c in 0x0E00..0x0E7F -> return "th"
                c in 0x0590..0x05FF -> return "he"
                c in 0x0530..0x058F -> return "hy"
            }
        }
        return "en"
    }

    fun name(code: String): String = when (code.lowercase()) {
        "en" -> "English"
        "ur" -> "Urdu"
        "hi" -> "Hindi"
        "bn" -> "Bengali"
        "ar" -> "Arabic"
        "ru" -> "Russian"
        "ja" -> "Japanese"
        "zh" -> "Chinese"
        "ko" -> "Korean"
        "th" -> "Thai"
        "he" -> "Hebrew"
        "hy" -> "Armenian"
        "es" -> "Spanish"
        "fr" -> "French"
        "de" -> "German"
        "tr" -> "Turkish"
        "fa" -> "Persian"
        "pt" -> "Portuguese"
        else -> code.uppercase()
    }
}
