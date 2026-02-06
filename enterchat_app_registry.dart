// lib/core/bridge/app_registry.dart
import 'package:flutter/foundation.dart';

enum AppType {
  webview,
  native,
  matrix,
  email,
  sms,
}

class AppConfig {
  final String id;
  final String displayName;
  final String iconAsset;
  final AppType type;
  final String? packageName; // For native apps
  final String? webUrl; // For web apps
  final AutomationProfile automationProfile;
  final AppCapabilities capabilities;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AppConfig({
    required this.id,
    required this.displayName,
    required this.iconAsset,
    required this.type,
    this.packageName,
    this.webUrl,
    required this.automationProfile,
    required this.capabilities,
    this.isActive = false,
    this.metadata,
  });

  AppConfig copyWith({bool? isActive}) {
    return AppConfig(
      id: id,
      displayName: displayName,
      iconAsset: iconAsset,
      type: type,
      packageName: packageName,
      webUrl: webUrl,
      automationProfile: automationProfile,
      capabilities: capabilities,
      isActive: isActive ?? this.isActive,
      metadata: metadata,
    );
  }
}

class AutomationProfile {
  // For WebView
  final Map<String, String>? webSelectors;
  
  // For Native Accessibility
  final Map<String, String>? accessibilityIds;
  
  // JavaScript injection templates
  final String? initScript;
  final String? scrapeConversationsScript;
  final String? scrapeMessagesScript;
  final String? sendMessageScript;

  AutomationProfile({
    this.webSelectors,
    this.accessibilityIds,
    this.initScript,
    this.scrapeConversationsScript,
    this.scrapeMessagesScript,
    this.sendMessageScript,
  });
}

class AppCapabilities {
  final bool supportsText;
  final bool supportsMedia;
  final bool supportsFiles;
  final bool supportsReply;
  final bool supportsGroup;
  final bool supportsVoiceCall;
  final bool supportsVideoCall;
  final bool supportsReadReceipts;
  final bool supportsTypingIndicator;

  AppCapabilities({
    this.supportsText = true,
    this.supportsMedia = false,
    this.supportsFiles = false,
    this.supportsReply = false,
    this.supportsGroup = false,
    this.supportsVoiceCall = false,
    this.supportsVideoCall = false,
    this.supportsReadReceipts = false,
    this.supportsTypingIndicator = false,
  });
}

class AppRegistry {
  static final AppRegistry _instance = AppRegistry._internal();
  factory AppRegistry() => _instance;
  AppRegistry._internal();

  final Map<String, AppConfig> _apps = {};

  Future<void> initialize() async {
    _apps.clear();
    
    // EnterChat native
    _apps['enterchat'] = AppConfig(
      id: 'enterchat',
      displayName: 'EnterChat',
      iconAsset: 'assets/icons/enterchat.png',
      type: AppType.native,
      automationProfile: AutomationProfile(),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
        supportsReadReceipts: true,
        supportsTypingIndicator: true,
      ),
      isActive: true,
    );

    // WhatsApp
    _apps['whatsapp'] = AppConfig(
      id: 'whatsapp',
      displayName: 'WhatsApp',
      iconAsset: 'assets/icons/whatsapp.png',
      type: AppType.webview,
      packageName: 'com.whatsapp',
      webUrl: 'https://web.whatsapp.com',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[data-testid="conversation"]',
          'conversationName': 'span[dir="auto"][title]',
          'messageInput': 'div[contenteditable="true"][data-tab="10"]',
          'sendButton': 'button[data-testid="compose-btn-send"]',
          'messageContainer': 'div[data-testid="msg-container"]',
          'attachButton': 'button[data-testid="attach-btn"]',
        },
        scrapeConversationsScript: '''
          (function() {
            const conversations = [];
            document.querySelectorAll('div[data-testid="conversation"]').forEach(conv => {
              const nameEl = conv.querySelector('span[dir="auto"][title]');
              const timeEl = conv.querySelector('span[data-testid="last-msg-time"]');
              const lastMsgEl = conv.querySelector('span[data-testid="last-msg-text"]');
              if (nameEl) {
                conversations.push({
                  id: conv.getAttribute('data-id') || nameEl.textContent,
                  name: nameEl.textContent,
                  lastMessage: lastMsgEl?.textContent || '',
                  time: timeEl?.textContent || '',
                });
              }
            });
            return JSON.stringify(conversations);
          })();
        ''',
        sendMessageScript: '''
          (function(message) {
            const input = document.querySelector('div[contenteditable="true"][data-tab="10"]');
            const sendBtn = document.querySelector('button[data-testid="compose-btn-send"]');
            if (input && sendBtn) {
              input.focus();
              input.textContent = message;
              input.dispatchEvent(new InputEvent('input', { bubbles: true }));
              setTimeout(() => sendBtn.click(), 100);
              return true;
            }
            return false;
          })
        ''',
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
        supportsReadReceipts: true,
      ),
    );

    // Telegram
    _apps['telegram'] = AppConfig(
      id: 'telegram',
      displayName: 'Telegram',
      iconAsset: 'assets/icons/telegram.png',
      type: AppType.webview,
      packageName: 'org.telegram.messenger',
      webUrl: 'https://web.telegram.org',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': '.chatlist-chat',
          'conversationName': '.user-title',
          'messageInput': '#editable-message-text',
          'sendButton': '.btn-send',
          'messageContainer': '.message',
        },
        scrapeConversationsScript: '''
          (function() {
            const conversations = [];
            document.querySelectorAll('.chatlist-chat').forEach(chat => {
              const nameEl = chat.querySelector('.user-title');
              const msgEl = chat.querySelector('.user-last-message');
              if (nameEl) {
                conversations.push({
                  id: chat.getAttribute('data-peer-id') || nameEl.textContent,
                  name: nameEl.textContent,
                  lastMessage: msgEl?.textContent || '',
                });
              }
            });
            return JSON.stringify(conversations);
          })();
        ''',
        sendMessageScript: '''
          (function(message) {
            const input = document.querySelector('#editable-message-text');
            const sendBtn = document.querySelector('.btn-send');
            if (input && sendBtn) {
              input.focus();
              input.innerHTML = message;
              input.dispatchEvent(new Event('input', { bubbles: true }));
              setTimeout(() => sendBtn.click(), 100);
              return true;
            }
            return false;
          })
        ''',
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // WeChat
    _apps['wechat'] = AppConfig(
      id: 'wechat',
      displayName: 'WeChat',
      iconAsset: 'assets/icons/wechat.png',
      type: AppType.native,
      packageName: 'com.tencent.mm',
      automationProfile: AutomationProfile(
        accessibilityIds: {
          'conversationList': 'com.tencent.mm:id/conversation_list',
          'messageInput': 'com.tencent.mm:id/input_edittext',
          'sendButton': 'com.tencent.mm:id/send_btn',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // Instagram
    _apps['instagram'] = AppConfig(
      id: 'instagram',
      displayName: 'Instagram',
      iconAsset: 'assets/icons/instagram.png',
      type: AppType.webview,
      packageName: 'com.instagram.android',
      webUrl: 'https://www.instagram.com/direct/inbox/',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[role="listitem"]',
          'messageInput': 'textarea[placeholder="Message..."]',
          'sendButton': 'button[type="submit"]',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsReply: true,
        supportsGroup: true,
      ),
    );

    // Facebook Messenger
    _apps['messenger'] = AppConfig(
      id: 'messenger',
      displayName: 'Messenger',
      iconAsset: 'assets/icons/messenger.png',
      type: AppType.webview,
      packageName: 'com.facebook.orca',
      webUrl: 'https://www.messenger.com',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[role="navigation"] a',
          'messageInput': 'div[contenteditable="true"][role="textbox"]',
          'sendButton': 'div[aria-label="Press enter to send"]',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // Signal
    _apps['signal'] = AppConfig(
      id: 'signal',
      displayName: 'Signal',
      iconAsset: 'assets/icons/signal.png',
      type: AppType.native,
      packageName: 'org.thoughtcrime.securesms',
      automationProfile: AutomationProfile(
        accessibilityIds: {
          'conversationList': 'org.thoughtcrime.securesms:id/conversation_list',
          'messageInput': 'org.thoughtcrime.securesms:id/embedded_text_editor',
          'sendButton': 'org.thoughtcrime.securesms:id/send_button',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // Discord
    _apps['discord'] = AppConfig(
      id: 'discord',
      displayName: 'Discord',
      iconAsset: 'assets/icons/discord.png',
      type: AppType.webview,
      packageName: 'com.discord',
      webUrl: 'https://discord.com/app',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[data-list-item-id*="channels"]',
          'messageInput': 'div[role="textbox"]',
          'sendButton': 'button[type="submit"]',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // Slack
    _apps['slack'] = AppConfig(
      id: 'slack',
      displayName: 'Slack',
      iconAsset: 'assets/icons/slack.png',
      type: AppType.webview,
      packageName: 'com.slack',
      webUrl: 'https://app.slack.com',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[role="listitem"]',
          'messageInput': 'div[role="textbox"][contenteditable="true"]',
          'sendButton': 'button[data-qa="texty_send_button"]',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsFiles: true,
        supportsReply: true,
        supportsGroup: true,
        supportsVoiceCall: true,
        supportsVideoCall: true,
      ),
    );

    // Twitter/X DM
    _apps['twitter'] = AppConfig(
      id: 'twitter',
      displayName: 'X (Twitter)',
      iconAsset: 'assets/icons/twitter.png',
      type: AppType.webview,
      packageName: 'com.twitter.android',
      webUrl: 'https://twitter.com/messages',
      automationProfile: AutomationProfile(
        webSelectors: {
          'conversationList': 'div[data-testid="conversation"]',
          'messageInput': 'div[data-testid="dmComposerTextInput"]',
          'sendButton': 'button[data-testid="dmComposerSendButton"]',
        },
      ),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsReply: true,
        supportsGroup: true,
      ),
    );

    // SMS (Android native)
    _apps['sms'] = AppConfig(
      id: 'sms',
      displayName: 'SMS',
      iconAsset: 'assets/icons/sms.png',
      type: AppType.sms,
      automationProfile: AutomationProfile(),
      capabilities: AppCapabilities(
        supportsText: true,
        supportsMedia: true,
        supportsGroup: true,
      ),
      isActive: true,
    );

    debugPrint('[AppRegistry] Initialized with ${_apps.length} apps');
  }

  AppConfig? getApp(String appId) => _apps[appId];

  List<AppConfig> getAllApps() => _apps.values.toList();

  List<AppConfig> getActiveApps() =>
      _apps.values.where((app) => app.isActive).toList();

  Future<void> markAppAsActive(String appId) async {
    final app = _apps[appId];
    if (app != null) {
      _apps[appId] = app.copyWith(isActive: true);
    }
  }

  Future<void> markAppAsInactive(String appId) async {
    final app = _apps[appId];
    if (app != null) {
      _apps[appId] = app.copyWith(isActive: false);
    }
  }
}