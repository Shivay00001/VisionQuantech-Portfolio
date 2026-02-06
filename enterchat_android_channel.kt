// android/app/src/main/kotlin/com/enterchat/bridge/BridgeMethodChannel.kt
package com.enterchat.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object BridgeMethodChannel {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null

    fun initialize(channel: MethodChannel, context: Context, activity: Activity) {
        this.channel = channel
        this.context = context
        this.activity = activity
    }

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                result.success(true)
            }
            "getInstalledApps" -> {
                result.success(getInstalledApps())
            }
            "requestAccessibilityPermission" -> {
                requestAccessibilityPermission()
                result.success(true)
            }
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(true)
            }
            "requestNotificationPermission" -> {
                result.success(true)
            }
            "isAccessibilityEnabled" -> {
                result.success(isAccessibilityEnabled())
            }
            "listConversations" -> {
                val appId = call.argument<String>("appId") ?: ""
                val conversations = listConversations(appId)
                result.success(conversations)
            }
            "sendMessage" -> {
                val appId = call.argument<String>("appId") ?: ""
                val conversationId = call.argument<String>("conversationId") ?: ""
                val message = call.argument<String>("message") ?: ""
                val attachments = call.argument<List<String>>("attachments")
                
                val success = sendMessage(appId, conversationId, message, attachments)
                result.success(success)
            }
            "openApp" -> {
                val packageName = call.argument<String>("packageName") ?: ""
                result.success(openApp(packageName))
            }
            "openConversation" -> {
                val appId = call.argument<String>("appId") ?: ""
                val conversationId = call.argument<String>("conversationId") ?: ""
                result.success(openConversation(appId, conversationId))
            }
            "setupApp" -> {
                val appId = call.argument<String>("appId") ?: ""
                result.success(true)
            }
            "getAppStatus" -> {
                val appId = call.argument<String>("appId") ?: ""
                result.success(getAppStatus(appId))
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<String> {
        val pm = context?.packageManager ?: return emptyList()
        val apps = mutableListOf<String>()
        
        val supportedPackages = mapOf(
            "whatsapp" to "com.whatsapp",
            "telegram" to "org.telegram.messenger",
            "wechat" to "com.tencent.mm",
            "instagram" to "com.instagram.android",
            "messenger" to "com.facebook.orca",
            "signal" to "org.thoughtcrime.securesms",
            "discord" to "com.discord",
            "slack" to "com.Slack"
        )
        
        supportedPackages.forEach { (appId, packageName) ->
            try {
                pm.getPackageInfo(packageName, 0)
                apps.add(appId)
            } catch (e: PackageManager.NameNotFoundException) {
                // App not installed
            }
        }
        
        return apps
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context?.startActivity(intent)
    }

    private fun requestOverlayPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(context)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${context?.packageName}")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context?.startActivity(intent)
            }
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val service = "${context?.packageName}/${BridgeAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            context?.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(service) == true
    }

    private fun listConversations(appId: String): List<Map<String, Any>> {
        val service = BridgeAccessibilityService.instance
        if (service == null) {
            return emptyList()
        }
        
        val jsonArray = service.listConversations(appId)
        val conversations = mutableListOf<Map<String, Any>>()
        
        for (i in 0 until jsonArray.length()) {
            val obj = jsonArray.getJSONObject(i)
            conversations.add(mapOf(
                "id" to obj.getString("id"),
                "name" to obj.getString("name"),
                "lastMessage" to obj.optString("lastMessage", ""),
                "time" to obj.optString("time", "")
            ))
        }
        
        return conversations
    }

    private fun sendMessage(
        appId: String,
        conversationId: String,
        message: String,
        attachments: List<String>?
    ): Boolean {
        val service = BridgeAccessibilityService.instance ?: return false
        return service.sendMessage(appId, conversationId, message)
    }

    private fun openApp(packageName: String): Boolean {
        val pm = context?.packageManager ?: return false
        val intent = pm.getLaunchIntentForPackage(packageName)
        
        intent?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context?.startActivity(it)
            return true
        }
        
        return false
    }

    private fun openConversation(appId: String, conversationId: String): Boolean {
        // This would be implemented based on app-specific deep links
        return false
    }

    private fun getAppStatus(appId: String): Map<String, Any> {
        return mapOf(
            "installed" to true,
            "accessible" to isAccessibilityEnabled(),
            "connected" to true
        )
    }

    fun notifyNewMessage(appId: String, title: String, text: String) {
        channel?.invokeMethod("onNewMessage", mapOf(
            "appId" to appId,
            "title" to title,
            "text" to text,
            "timestamp" to System.currentTimeMillis()
        ))
    }
}

// android/app/src/main/kotlin/com/enterchat/MainActivity.kt
package com.enterchat

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.enterchat.bridge.BridgeMethodChannel

class MainActivity: FlutterActivity() {
    private val BRIDGE_CHANNEL = "com.enterchat/bridge"
    private val AUTOMATION_CHANNEL = "com.enterchat/automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val bridgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL)
        val automationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL)
        
        BridgeMethodChannel.initialize(bridgeChannel, applicationContext, this)
        
        bridgeChannel.setMethodCallHandler { call, result ->
            BridgeMethodChannel.handleMethodCall(call, result)
        }
        
        automationChannel.setMethodCallHandler { call, result ->
            BridgeMethodChannel.handleMethodCall(call, result)
        }
    }
}