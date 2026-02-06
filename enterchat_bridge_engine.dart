// lib/core/bridge/bridge_engine.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'app_registry.dart';
import 'session_manager.dart';
import 'webview_controller.dart';
import 'automation_controller.dart';
import '../../shared/models/unified_message.dart';
import '../../shared/models/unified_conversation.dart';

class BridgeEngine {
  static final BridgeEngine _instance = BridgeEngine._internal();
  factory BridgeEngine() => _instance;
  BridgeEngine._internal();

  final AppRegistry _registry = AppRegistry();
  final SessionManager _sessionManager = SessionManager();
  final WebViewBridgeController _webViewController = WebViewBridgeController();
  final AutomationController _automationController = AutomationController();

  bool _isInitialized = false;
  final _messageStreamController = StreamController<UnifiedMessage>.broadcast();
  final _conversationStreamController = StreamController<UnifiedConversation>.broadcast();

  Stream<UnifiedMessage> get messageStream => _messageStreamController.stream;
  Stream<UnifiedConversation> get conversationStream => _conversationStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print('[BridgeEngine] Initializing...');

    // Initialize app registry
    await _registry.initialize();

    // Check installed apps
    final installedApps = await _checkInstalledApps();
    print('[BridgeEngine] Found ${installedApps.length} supported apps installed');

    // Initialize WebView sessions
    await _webViewController.initialize();

    // Request permissions
    await _requestPermissions();

    // Initialize automation controller
    await _automationController.initialize();

    // Start background sync
    _startBackgroundSync();

    _isInitialized = true;
    print('[BridgeEngine] Initialization complete');
  }

  Future<List<String>> _checkInstalledApps() async {
    try {
      const platform = MethodChannel('com.enterchat/bridge');
      final result = await platform.invokeMethod<List<dynamic>>('getInstalledApps');
      return result?.cast<String>() ?? [];
    } catch (e) {
      print('[BridgeEngine] Error checking installed apps: $e');
      return [];
    }
  }

  Future<void> _requestPermissions() async {
    try {
      const platform = MethodChannel('com.enterchat/bridge');
      await platform.invokeMethod('requestAccessibilityPermission');
      await platform.invokeMethod('requestOverlayPermission');
      await platform.invokeMethod('requestNotificationPermission');
    } catch (e) {
      print('[BridgeEngine] Error requesting permissions: $e');
    }
  }

  Future<void> syncAll() async {
    if (!_isInitialized) {
      throw Exception('BridgeEngine not initialized');
    }

    print('[BridgeEngine] Starting sync for all apps...');

    final activeApps = _registry.getActiveApps();
    
    for (final app in activeApps) {
      try {
        await _syncApp(app);
      } catch (e) {
        print('[BridgeEngine] Error syncing ${app.id}: $e');
      }
    }

    print('[BridgeEngine] Sync complete');
  }

  Future<void> _syncApp(AppConfig app) async {
    print('[BridgeEngine] Syncing ${app.id}...');

    if (app.type == AppType.webview) {
      await _syncWebApp(app);
    } else if (app.type == AppType.native) {
      await _syncNativeApp(app);
    }
  }

  Future<void> _syncWebApp(AppConfig app) async {
    try {
      // Load web client in hidden WebView
      await _webViewController.loadApp(app);

      // Wait for page load
      await Future.delayed(const Duration(seconds: 3));

      // Inject scraping script
      final conversations = await _webViewController.scrapeConversations(app);
      
      for (final conv in conversations) {
        _conversationStreamController.add(conv);
        
        // Optionally scrape recent messages
        final messages = await _webViewController.scrapeMessages(app, conv.conversationId);
        for (final msg in messages) {
          _messageStreamController.add(msg);
        }
      }
    } catch (e) {
      print('[BridgeEngine] Error syncing web app ${app.id}: $e');
    }
  }

  Future<void> _syncNativeApp(AppConfig app) async {
    try {
      // Use accessibility service to read notifications and UI
      final conversations = await _automationController.listConversations(app.id);
      
      for (final conv in conversations) {
        _conversationStreamController.add(conv);
      }
    } catch (e) {
      print('[BridgeEngine] Error syncing native app ${app.id}: $e');
    }
  }

  Future<bool> sendMessage({
    required String targetAppId,
    required String conversationId,
    required String message,
    List<String>? attachments,
  }) async {
    if (!_isInitialized) {
      throw Exception('BridgeEngine not initialized');
    }

    final app = _registry.getApp(targetAppId);
    if (app == null) {
      throw Exception('App not found: $targetAppId');
    }

    print('[BridgeEngine] Sending message via ${app.id}...');

    try {
      if (app.type == AppType.webview) {
        return await _sendMessageViaWeb(app, conversationId, message, attachments);
      } else if (app.type == AppType.native) {
        return await _sendMessageViaNative(app, conversationId, message, attachments);
      }
      return false;
    } catch (e) {
      print('[BridgeEngine] Error sending message: $e');
      return false;
    }
  }

  Future<bool> _sendMessageViaWeb(
    AppConfig app,
    String conversationId,
    String message,
    List<String>? attachments,
  ) async {
    try {
      // Ensure app is loaded
      await _webViewController.loadApp(app);

      // Navigate to conversation
      await _webViewController.openConversation(app, conversationId);

      // Fill message input
      await _webViewController.fillMessageInput(app, message);

      // Handle attachments if any
      if (attachments != null && attachments.isNotEmpty) {
        for (final attachment in attachments) {
          await _webViewController.attachFile(app, attachment);
        }
      }

      // Click send button
      await _webViewController.clickSend(app);

      return true;
    } catch (e) {
      print('[BridgeEngine] Error sending via web: $e');
      return false;
    }
  }

  Future<bool> _sendMessageViaNative(
    AppConfig app,
    String conversationId,
    String message,
    List<String>? attachments,
  ) async {
    try {
      return await _automationController.sendMessage(
        appId: app.id,
        conversationId: conversationId,
        message: message,
        attachments: attachments,
      );
    } catch (e) {
      print('[BridgeEngine] Error sending via native: $e');
      return false;
    }
  }

  void _startBackgroundSync() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isInitialized) {
        syncAll();
      }
    });
  }

  Future<List<UnifiedConversation>> getAllConversations({
    String? filterByAppId,
    bool includeArchived = false,
  }) async {
    // This would query local DB in real implementation
    return [];
  }

  Future<List<UnifiedMessage>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    // This would query local DB in real implementation
    return [];
  }

  AppConfig? getAppConfig(String appId) {
    return _registry.getApp(appId);
  }

  List<AppConfig> getSupportedApps() {
    return _registry.getAllApps();
  }

  List<AppConfig> getActiveApps() {
    return _registry.getActiveApps();
  }

  Future<void> connectApp(String appId) async {
    final app = _registry.getApp(appId);
    if (app == null) return;

    if (app.type == AppType.webview) {
      await _webViewController.loadApp(app);
      // Wait for user to login
    } else if (app.type == AppType.native) {
      await _automationController.setupApp(app.id);
    }

    await _registry.markAppAsActive(appId);
  }

  Future<void> disconnectApp(String appId) async {
    await _registry.markAppAsInactive(appId);
    await _webViewController.clearSession(appId);
  }

  void dispose() {
    _messageStreamController.close();
    _conversationStreamController.close();
    _webViewController.dispose();
  }
}