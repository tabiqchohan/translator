package com.tabiqchohan.translater

import android.accessibilityservice.AccessibilityService
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Phase B: universal accessibility engine. Reads newly appeared text nodes on
 * the screen of any enabled chat app (both sides of the conversation), and
 * optionally auto-pastes the translation into the reply field (Phase C).
 */
class ChatAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        ChatTranslatorEngine.attach(applicationContext)
        ChatTranslatorEngine.autoPasteConsumer = ::autoPaste
        LiveChatPrefs.setAccGranted(this, true)
        LiveChatPrefs.setAccRunning(this, true)
        ChatTranslatorPlugin.emit(
            mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(this), "reason" to "acc_connected"),
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!LiveChatPrefs.enabled(this)) return
        if (LiveChatPrefs.accRunning(this).not()) return

        val pkg = event?.packageName?.toString() ?: return
        if (pkg !in LiveChatPrefs.enabledApps(this)) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            -> {
                val root = rootInActiveWindow ?: return
                scan(root, pkg)
            }
        }
    }

    private fun scan(root: AccessibilityNodeInfo, pkg: String) {
        var editText: AccessibilityNodeInfo? = null
        var sawScrollable = false
        val messages = ArrayList<String>()

        fun walk(node: AccessibilityNodeInfo?, inScrollable: Boolean) {
            if (node == null) return

            if (node.isScrollable) {
                sawScrollable = true
            }
            if (node.className?.toString()?.contains("EditText") == true && node.isVisibleToUser) {
                editText = node
            }

            val isInsideScrollable = inScrollable || node.isScrollable
            if (isInsideScrollable && node.isVisibleToUser) {
                val t = node.text?.toString()?.trim()
                    ?: node.contentDescription?.toString()?.trim()
                if (t != null && t.isNotBlank() && t.length <= 200) {
                    messages.add(t)
                }
            }

            for (i in 0 until node.childCount) {
                walk(node.getChild(i), isInsideScrollable)
            }
        }

        walk(root, false)
        if (sawScrollable && messages.isNotEmpty()) {
            for (m in messages) {
                ChatTranslatorEngine.offer(this, "Chat", m, pkg)
            }
        }
        lastInputNode?.recycle()
        lastInputNode = editText
    }

    private var lastInputNode: AccessibilityNodeInfo? = null

    /** Phase C: paste the translated text into an empty reply field, if any. */
    private fun autoPaste(translated: String) {
        val target = findInputField() ?: return
        val current = target.text?.toString()?.trim() ?: ""
        if (current.isNotEmpty()) return
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, translated)
        }
        target.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        target.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
    }

    private fun findInputField(): AccessibilityNodeInfo? {
        val root = rootInActiveWindow
        if (root != null) {
            val found = findEditText(root)
            if (found != null) return found
        }
        return lastInputNode
    }

    private fun findEditText(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        var found: AccessibilityNodeInfo? = null
        fun walk(node: AccessibilityNodeInfo?) {
            if (found != null || node == null) return
            if (node.className?.toString()?.contains("EditText") == true && node.isVisibleToUser) {
                found = node
                return
            }
            for (i in 0 until node.childCount) walk(node.getChild(i))
        }
        walk(root)
        return found
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        ChatTranslatorEngine.autoPasteConsumer = null
        lastInputNode?.recycle()
        LiveChatPrefs.setAccRunning(this, false)
        LiveChatPrefs.setAccGranted(this, false)
        ChatTranslatorPlugin.emit(
            mapOf("type" to "status", "settings" to LiveChatPrefs.snapshot(this), "reason" to "acc_destroyed"),
        )
        super.onDestroy()
    }
}