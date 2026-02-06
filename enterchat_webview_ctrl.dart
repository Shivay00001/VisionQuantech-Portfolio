// lib/core/bridge/webview_controller.dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'app_registry.dart';
import '../../shared/models/unified_conversation.dart';
import '../../shared/models/unified_message.dart';
import 'dart:convert';

class WebViewBridgeController {
  final Map<String, InAppWebViewController> _controllers = {};
  final Map<String, HeadlessInAppWebView> _headlessWebViews = {};

  Future<void> initialize() async {
    print('[WebViewBridgeController] Initializing...');
  }

  Future<void> loadApp(AppConfig app) async {
    if (app.type != AppType.webview || app.webUrl == null) {
      throw Exception('App ${app.id} is not a web-based app');
    }

    if (_headlessWebViews.containsKey(app.id)) {
      print('[WebViewBridgeController] ${app.id} already loaded');
      return;
    }

    final headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(app.webUrl!)),
      initialSettings: InAppWebViewSettings(
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        cacheEnabled: true,
        thirdPartyCookiesEnabled: true,
      ),
      onWebViewCreated: (controller) {
        _controllers[app.id] = controller;
        print('[WebViewBridgeController] WebView created for ${app.id}');
      },
      onLoadStop: (controller, url) async {
        print('[WebViewBridgeController] ${app.id} loaded: $url');
        
        // Inject initialization script if available
        if (app.automationProfile.initScript != null) {
          await controller.evaluateJavascript(
            source: app.automationProfile.initScript!,
          );
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        print('[WebView-${app.id}] ${consoleMessage.message}');
      },
    );

    _headlessWebViews[app.id] = headlessWebView;
    await headlessWebView.run();
    
    // Wait for page to load
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<List<UnifiedConversation>> scrapeConversations(AppConfig app) async {
    final controller = _controllers[app.id];
    if (controller == null) {
      throw Exception('WebView not loaded for ${app.id}');
    }

    final script = app.automationProfile.scrapeConversationsScript;
    if (script == null) {
      return [];
    }

    try {
      final result = await controller.evaluateJavascript(source: script);
      if (result == null) return [];

      final List<dynamic> conversations = jsonDecode(result.toString());
      
      return conversations.map((conv) {
        return UnifiedConversation(
          conversationId: conv['id'] ?? conv['name'],
          sourceAppId: app.id,
          displayName: conv['name'] ?? 'Unknown',
          type: ConversationType.oneToOne,
          lastMessageContent: conv['lastMessage'],
          lastMessageTime: _parseTime(conv['time']),
        );
      }).toList();
    } catch (e) {
      print('[WebViewBridgeController] Error scraping conversations for ${app.id}: $e');
      return [];
    }
  }

  Future<List<UnifiedMessage>> scrapeMessages(
    AppConfig app,
    String conversationId,
  ) async {
    final controller = _controllers[app.id];
    if (controller == null) {
      throw Exception('WebView not loaded for ${app.id}');
    }

    // Navigate to conversation first
    await openConversation(app, conversationId);

    final script = app.automationProfile.scrapeMessagesScript;
    if (script == null) {
      return [];
    }

    try {
      final result = await controller.evaluateJavascript(source: script);
      if (result == null) return [];

      final List<dynamic> messages = jsonDecode(result.toString());
      
      return messages.map((msg) {
        return UnifiedMessage(
          messageId: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          sourceAppId: app.id,
          sourceConversationId: conversationId,
          direction: msg['direction'] == 'outgoing' 
              ? MessageDirection.outgoing 
              : MessageDirection.incoming,
          contentType: ContentType.text,
          content: msg['content'] ?? '',
          timestamp: DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()),
          status: MessageStatus.delivered,
        );
      }).toList();
    } catch (e) {
      print('[WebViewBridgeController] Error scraping messages for ${app.id}: $e');
      return [];
    }
  }

  Future<void> openConversation(AppConfig app, String conversationId) async {
    final controller = _controllers[app.id];
    if (controller == null) return;

    // App-specific navigation logic
    switch (app.id) {
      case 'whatsapp':
        await controller.evaluateJavascript(source: '''
          (function() {
            const conv = Array.from(document.querySelectorAll('div[data-testid="conversation"]'))
              .find(el => el.textContent.includes('$conversationId'));
            if (conv) conv.click();
          })();
        ''');
        break;
      case 'telegram':
        await controller.evaluateJavascript(source: '''
          (function() {
            const chat = Array.from(document.querySelectorAll('.chatlist-chat'))
              .find(el => el.textContent.includes('$conversationId'));
            if (chat) chat.click();
          })();
        ''');
        break;
    }

    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> fillMessageInput(AppConfig app, String message) async {
    final controller = _controllers[app.id];
    if (controller == null) return;

    final selector = app.automationProfile.webSelectors?['messageInput'];
    if (selector == null) return;

    await controller.evaluateJavascript(source: '''
      (function() {
        const input = document.querySelector('$selector');
        if (input) {
          input.focus();
          input.textContent = `$message`;
          input.dispatchEvent(new InputEvent('input', { bubbles: true }));
        }
      })();
    ''');
  }

  Future<void> attachFile(AppConfig app, String filePath) async {
    final controller = _controllers[app.id];
    if (controller == null) return;

    // File attachment logic varies by app
    // This would need native file picker integration
    print('[WebViewBridgeController] Attaching file: $filePath');
  }

  Future<void> clickSend(AppConfig app) async {
    final controller = _controllers[app.id];
    if (controller == null) return;

    final script = app.automationProfile.sendMessageScript;
    if (script != null) {
      await controller.evaluateJavascript(source: script);
    } else {
      final selector = app.automationProfile.webSelectors?['sendButton'];
      if (selector != null) {
        await controller.evaluateJavascript(source: '''
          (function() {
            const btn = document.querySelector('$selector');
            if (btn) btn.click();
          })();
        ''');
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> clearSession(String appId) async {
    final controller = _controllers[appId];
    if (controller != null) {
      await controller.clearCache();
    }
    
    _headlessWebViews[appId]?.dispose();
    _headlessWebViews.remove(appId);
    _controllers.remove(appId);
  }

  DateTime? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    
    try {
      // Handle relative times like "5m ago", "2h ago", "yesterday"
      final now = DateTime.now();
      
      if (timeStr.contains('m')) {
        final minutes = int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return now.subtract(Duration(minutes: minutes));
      }
      
      if (timeStr.contains('h')) {
        final hours = int.tryParse(timeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return now.subtract(Duration(hours: hours));
      }
      
      if (timeStr.toLowerCase().contains('yesterday')) {
        return now.subtract(const Duration(days: 1));
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    for (final webView in _headlessWebViews.values) {
      webView.dispose();
    }
    _headlessWebViews.clear();
    _controllers.clear();
  }
}