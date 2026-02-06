// lib/core/bridge/automation_controller.dart
import 'package:flutter/services.dart';
import '../../shared/models/unified_conversation.dart';

class AutomationController {
  static const platform = MethodChannel('com.enterchat/automation');

  Future<void> initialize() async {
    try {
      await platform.invokeMethod('initialize');
      print('[AutomationController] Initialized');
    } catch (e) {
      print('[AutomationController] Initialization error: $e');
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await platform.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      print('[AutomationController] Error checking accessibility: $e');
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      print('[AutomationController] Error requesting permission: $e');
    }
  }

  Future<List<UnifiedConversation>> listConversations(String appId) async {
    try {
      final result = await platform.invokeMethod<List<dynamic>>(
        'listConversations',
        {'appId': appId},
      );

      if (result == null) return [];

      return result.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return UnifiedConversation(
          conversationId: map['id']?.toString() ?? '',
          sourceAppId: appId,
          displayName: map['name']?.toString() ?? 'Unknown',
          type: ConversationType.oneToOne,
          lastMessageContent: map['lastMessage']?.toString(),
          lastMessageTime: map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : null,
          unreadCount: map['unreadCount'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      print('[AutomationController] Error listing conversations: $e');
      return [];
    }
  }

  Future<bool> sendMessage({
    required String appId,
    required String conversationId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'sendMessage',
        {
          'appId': appId,
          'conversationId': conversationId,
          'message': message,
          'attachments': attachments,
        },
      );
      return result ?? false;
    } catch (e) {
      print('[AutomationController] Error sending message: $e');
      return false;
    }
  }

  Future<bool> openApp(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'openApp',
        {'packageName': packageName},
      );
      return result ?? false;
    } catch (e) {
      print('[AutomationController] Error opening app: $e');
      return false;
    }
  }

  Future<bool> openConversation(String appId, String conversationId) async {
    try {
      final result = await platform.invokeMethod<bool>(
        'openConversation',
        {
          'appId': appId,
          'conversationId': conversationId,
        },
      );
      return result ?? false;
    } catch (e) {
      print('[AutomationController] Error opening conversation: $e');
      return false;
    }
  }

  Future<void> setupApp(String appId) async {
    try {
      await platform.invokeMethod('setupApp', {'appId': appId});
    } catch (e) {
      print('[AutomationController] Error setting up app: $e');
    }
  }

  Future<Map<String, dynamic>?> getAppStatus(String appId) async {
    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'getAppStatus',
        {'appId': appId},
      );
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('[AutomationController] Error getting app status: $e');
      return null;
    }
  }
}

// lib/core/bridge/session_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  Future<void> saveSession(String appId, Map<String, dynamic> sessionData) async {
    try {
      await _storage.write(
        key: 'session_$appId',
        value: jsonEncode(sessionData),
      );
    } catch (e) {
      print('[SessionManager] Error saving session for $appId: $e');
    }
  }

  Future<Map<String, dynamic>?> getSession(String appId) async {
    try {
      final data = await _storage.read(key: 'session_$appId');
      if (data == null) return null;
      return jsonDecode(data);
    } catch (e) {
      print('[SessionManager] Error getting session for $appId: $e');
      return null;
    }
  }

  Future<void> clearSession(String appId) async {
    try {
      await _storage.delete(key: 'session_$appId');
    } catch (e) {
      print('[SessionManager] Error clearing session for $appId: $e');
    }
  }

  Future<void> clearAllSessions() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      print('[SessionManager] Error clearing all sessions: $e');
    }
  }

  Future<List<String>> getActiveSessions() async {
    try {
      final all = await _storage.readAll();
      return all.keys
          .where((key) => key.startsWith('session_'))
          .map((key) => key.replaceFirst('session_', ''))
          .toList();
    } catch (e) {
      print('[SessionManager] Error getting active sessions: $e');
      return [];
    }
  }
}