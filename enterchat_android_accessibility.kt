// android/app/src/main/kotlin/com/enterchat/bridge/BridgeAccessibilityService.kt
package com.enterchat.bridge

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

class BridgeAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "BridgeAccessibility"
        var instance: BridgeAccessibilityService? = null
        
        // App package names
        private val APP_PACKAGES = mapOf(
            "whatsapp" to "com.whatsapp",
            "telegram" to "org.telegram.messenger",
            "wechat" to "com.tencent.mm",
            "instagram" to "com.instagram.android",
            "messenger" to "com.facebook.orca",
            "signal" to "org.thoughtcrime.securesms",
            "discord" to "com.discord",
            "slack" to "com.Slack"
        )
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                   AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            
            packageNames = APP_PACKAGES.values.toTypedArray()
            notificationTimeout = 100
        }
        
        serviceInfo = info
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        
        val packageName = event.packageName?.toString() ?: return
        val appId = APP_PACKAGES.entries.find { it.value == packageName }?.key ?: return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED -> {
                handleNotification(appId, event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleWindowContentChanged(appId, event)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    private fun handleNotification(appId: String, event: AccessibilityEvent) {
        try {
            val notification = event.parcelableData as? android.app.Notification ?: return
            val extras = notification.extras
            
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            
            Log.d(TAG, "Notification from $appId: $title - $text")
            
            // Notify Flutter about new message
            BridgeMethodChannel.notifyNewMessage(appId, title, text)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling notification: ${e.message}")
        }
    }

    private fun handleWindowContentChanged(appId: String, event: AccessibilityEvent) {
        // Track UI changes for message list updates
    }

    fun listConversations(appId: String): JSONArray {
        val conversations = JSONArray()
        val packageName = APP_PACKAGES[appId] ?: return conversations
        
        try {
            val rootNode = rootInActiveWindow ?: return conversations
            
            when (appId) {
                "whatsapp" -> extractWhatsAppConversations(rootNode, conversations)
                "telegram" -> extractTelegramConversations(rootNode, conversations)
                "wechat" -> extractWeChatConversations(rootNode, conversations)
                "signal" -> extractSignalConversations(rootNode, conversations)
            }
            
            rootNode.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Error listing conversations: ${e.message}")
        }
        
        return conversations
    }

    private fun extractWhatsAppConversations(root: AccessibilityNodeInfo, result: JSONArray) {
        // Find conversation list
        val conversationNodes = findNodesByViewId(root, "com.whatsapp:id/conversations_row_contact_name")
        
        conversationNodes.forEach { node ->
            try {
                val name = node.text?.toString() ?: "Unknown"
                val parent = node.parent
                
                val lastMsg = findNodeInParent(parent, "com.whatsapp:id/conversations_row_message_snippet")?.text?.toString()
                val time = findNodeInParent(parent, "com.whatsapp:id/conversations_row_date")?.text?.toString()
                
                val conversation = JSONObject().apply {
                    put("id", name)
                    put("name", name)
                    put("lastMessage", lastMsg ?: "")
                    put("time", time ?: "")
                }
                
                result.put(conversation)
                parent?.recycle()
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting WhatsApp conversation: ${e.message}")
            }
        }
        
        conversationNodes.forEach { it.recycle() }
    }

    private fun extractTelegramConversations(root: AccessibilityNodeInfo, result: JSONArray) {
        val conversationNodes = findNodesByViewId(root, "org.telegram.messenger:id/dialog_name")
        
        conversationNodes.forEach { node ->
            try {
                val name = node.text?.toString() ?: "Unknown"
                val parent = node.parent
                
                val lastMsg = findNodeInParent(parent, "org.telegram.messenger:id/dialog_message")?.text?.toString()
                
                val conversation = JSONObject().apply {
                    put("id", name)
                    put("name", name)
                    put("lastMessage", lastMsg ?: "")
                }
                
                result.put(conversation)
                parent?.recycle()
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting Telegram conversation: ${e.message}")
            }
        }
        
        conversationNodes.forEach { it.recycle() }
    }

    private fun extractWeChatConversations(root: AccessibilityNodeInfo, result: JSONArray) {
        val conversationNodes = findNodesByViewId(root, "com.tencent.mm:id/conversation_list")
        
        // WeChat specific extraction logic
        conversationNodes.forEach { it.recycle() }
    }

    private fun extractSignalConversations(root: AccessibilityNodeInfo, result: JSONArray) {
        val conversationNodes = findNodesByViewId(root, "org.thoughtcrime.securesms:id/contact_name")
        
        conversationNodes.forEach { node ->
            try {
                val name = node.text?.toString() ?: "Unknown"
                
                val conversation = JSONObject().apply {
                    put("id", name)
                    put("name", name)
                    put("lastMessage", "")
                }
                
                result.put(conversation)
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting Signal conversation: ${e.message}")
            }
        }
        
        conversationNodes.forEach { it.recycle() }
    }

    fun sendMessage(appId: String, conversationId: String, message: String): Boolean {
        val packageName = APP_PACKAGES[appId] ?: return false
        
        try {
            // First, open the app
            if (!openApp(packageName)) return false
            
            Thread.sleep(2000)
            
            // Open the conversation
            if (!openConversation(appId, conversationId)) return false
            
            Thread.sleep(1000)
            
            // Find input field and send button
            val rootNode = rootInActiveWindow ?: return false
            
            val success = when (appId) {
                "whatsapp" -> sendWhatsAppMessage(rootNode, message)
                "telegram" -> sendTelegramMessage(rootNode, message)
                "wechat" -> sendWeChatMessage(rootNode, message)
                "signal" -> sendSignalMessage(rootNode, message)
                else -> false
            }
            
            rootNode.recycle()
            return success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending message: ${e.message}")
            return false
        }
    }

    private fun sendWhatsAppMessage(root: AccessibilityNodeInfo, message: String): Boolean {
        val inputField = findNodeByViewId(root, "com.whatsapp:id/entry")
        val sendButton = findNodeByViewId(root, "com.whatsapp:id/send")
        
        if (inputField != null && sendButton != null) {
            val args = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, message)
            }
            
            inputField.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
            Thread.sleep(200)
            inputField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            Thread.sleep(300)
            sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            
            inputField.recycle()
            sendButton.recycle()
            return true
        }
        
        inputField?.recycle()
        sendButton?.recycle()
        return false
    }

    private fun sendTelegramMessage(root: AccessibilityNodeInfo, message: String): Boolean {
        val inputField = findNodeByViewId(root, "org.telegram.messenger:id/chat_edit_text")
        val sendButton = findNodeByViewId(root, "org.telegram.messenger:id/chat_send_button")
        
        if (inputField != null && sendButton != null) {
            val args = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, message)
            }
            
            inputField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            Thread.sleep(300)
            sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            
            inputField.recycle()
            sendButton.recycle()
            return true
        }
        
        inputField?.recycle()
        sendButton?.recycle()
        return false
    }

    private fun sendWeChatMessage(root: AccessibilityNodeInfo, message: String): Boolean {
        // WeChat specific sending logic
        return false
    }

    private fun sendSignalMessage(root: AccessibilityNodeInfo, message: String): Boolean {
        val inputField = findNodeByViewId(root, "org.thoughtcrime.securesms:id/embedded_text_editor")
        val sendButton = findNodeByViewId(root, "org.thoughtcrime.securesms:id/send_button")
        
        if (inputField != null && sendButton != null) {
            val args = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, message)
            }
            
            inputField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            Thread.sleep(300)
            sendButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            
            inputField.recycle()
            sendButton.recycle()
            return true
        }
        
        inputField?.recycle()
        sendButton?.recycle()
        return false
    }

    private fun openApp(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(it)
            return true
        }
        return false
    }

    private fun openConversation(appId: String, conversationId: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        
        // Find and click on the conversation
        val conversationNode = findNodeByText(rootNode, conversationId)
        val clicked = conversationNode?.performAction(AccessibilityNodeInfo.ACTION_CLICK) ?: false
        
        conversationNode?.recycle()
        rootNode.recycle()
        
        return clicked
    }

    // Utility functions
    private fun findNodesByViewId(root: AccessibilityNodeInfo, viewId: String): List<AccessibilityNodeInfo> {
        val nodes = mutableListOf<AccessibilityNodeInfo>()
        val queue = mutableListOf(root)
        
        while (queue.isNotEmpty()) {
            val node = queue.removeAt(0)
            
            if (node.viewIdResourceName == viewId) {
                nodes.add(node)
            }
            
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        
        return nodes
    }

    private fun findNodeByViewId(root: AccessibilityNodeInfo, viewId: String): AccessibilityNodeInfo? {
        if (root.viewIdResourceName == viewId) return root
        
        for (i in 0 until root.childCount) {
            root.getChild(i)?.let { child ->
                val found = findNodeByViewId(child, viewId)
                if (found != null) return found
                child.recycle()
            }
        }
        
        return null
    }

    private fun findNodeByText(root: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        if (root.text?.toString()?.contains(text, ignoreCase = true) == true) return root
        
        for (i in 0 until root.childCount) {
            root.getChild(i)?.let { child ->
                val found = findNodeByText(child, text)
                if (found != null) return found
                child.recycle()
            }
        }
        
        return null
    }

    private fun findNodeInParent(parent: AccessibilityNodeInfo?, viewId: String): AccessibilityNodeInfo? {
        parent ?: return null
        return findNodeByViewId(parent, viewId)
    }
}