// lib/core/messaging/enterchat_messaging_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../security/e2e_encryption_service.dart';
import '../security/key_management_service.dart';
import '../../shared/models/unified_message.dart';
import '../../shared/models/unified_conversation.dart';
import '../../shared/models/user_model.dart';
import 'dart:async';

class EnterChatMessagingService {
  static final EnterChatMessagingService _instance = EnterChatMessagingService._internal();
  factory EnterChatMessagingService() => _instance;
  EnterChatMessagingService._internal();

  final _supabase = Supabase.instance.client;
  final _encryption = E2EEncryptionService();
  final _keyManager = KeyManagementService();

  final _messageStreamController = StreamController<UnifiedMessage>.broadcast();
  final _conversationStreamController = StreamController<UnifiedConversation>.broadcast();
  final _typingStreamController = StreamController<TypingIndicator>.broadcast();

  Stream<UnifiedMessage> get messageStream => _messageStreamController.stream;
  Stream<UnifiedConversation> get conversationStream => _conversationStreamController.stream;
  Stream<TypingIndicator> get typingStream => _typingStreamController.stream;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;
  RealtimeChannel? _presenceChannel;

  Future<void> initialize() async {
    await _encryption.initialize();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Listen to new messages
    _messagesChannel = _supabase
        .channel('messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) async {
            await _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    // Listen to conversation updates
    _conversationsChannel = _supabase
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _handleConversationUpdate(payload.newRecord);
          },
        )
        .subscribe();

    // Presence for typing indicators
    _presenceChannel = _supabase.channel('presence:enterchat');
  }

  Future<void> _handleNewMessage(Map<String, dynamic> data) async {
    try {
      final message = await _decryptAndCreateMessage(data);
      _messageStreamController.add(message);
    } catch (e) {
      print('[EnterChatMessaging] Error handling new message: $e');
    }
  }

  void _handleConversationUpdate(Map<String, dynamic> data) {
    // Update conversation in local DB
  }

  Future<UnifiedMessage> _decryptAndCreateMessage(Map<String, dynamic> data) async {
    String content = data['content'];
    final isEncrypted = data['is_encrypted'] == true;

    if (isEncrypted) {
      final ciphertext = data['content'];
      final iv = data['encryption_iv'];
      final keyId = data['encryption_key_id'];

      content = await _encryption.decryptMessage(
        ciphertext: ciphertext,
        iv: iv,
        conversationKeyId: keyId,
      );
    }

    return UnifiedMessage(
      messageId: data['id'],
      sourceAppId: 'enterchat',
      sourceConversationId: data['conversation_id'],
      direction: data['sender_id'] == _supabase.auth.currentUser?.id
          ? MessageDirection.outgoing
          : MessageDirection.incoming,
      contentType: _parseContentType(data['content_type']),
      content: content,
      timestamp: DateTime.parse(data['created_at']),
      status: _parseMessageStatus(data['status']),
      isEncrypted: isEncrypted,
      encryptionKeyId: data['encryption_key_id'],
      replyToMessageId: data['reply_to_message_id'],
    );
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    ContentType contentType = ContentType.text,
    List<String>? attachmentUrls,
    String? replyToMessageId,
    bool encrypt = true,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      String finalContent = content;
      String? iv;
      String? keyId;

      if (encrypt) {
        // Get or create conversation key
        keyId = await _keyManager.getConversationKeyByConversationId(conversationId);
        
        if (keyId == null) {
          // Create new conversation key
          final conversationKey = await _encryption.createConversationKey(
            List.generate(32, (i) => i),
          );
          await _keyManager.saveConversationKey(
            conversationId: conversationId,
            key: conversationKey,
          );
          keyId = conversationKey;
        }

        final encrypted = await _encryption.encryptMessage(
          message: content,
          conversationKeyId: keyId,
        );

        finalContent = encrypted.ciphertext;
        iv = encrypted.iv;
      }

      final messageData = {
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': finalContent,
        'content_type': contentType.name,
        'is_encrypted': encrypt,
        'encryption_iv': iv,
        'encryption_key_id': keyId,
        'reply_to_message_id': replyToMessageId,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      // Handle attachments if any
      if (attachmentUrls != null && attachmentUrls.isNotEmpty) {
        await _handleAttachments(response['id'], attachmentUrls);
      }

      // Get other participants to send to
      final participants = await _getConversationParticipants(conversationId);
      
      // Send push notifications to other participants
      for (final participant in participants) {
        if (participant != userId) {
          await _sendPushNotification(participant, conversationId, content);
        }
      }

      return true;
    } catch (e) {
      print('[EnterChatMessaging] Error sending message: $e');
      return false;
    }
  }

  Future<void> _handleAttachments(String messageId, List<String> urls) async {
    for (final url in urls) {
      await _supabase.from('message_attachments').insert({
        'message_id': messageId,
        'url': url,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<String>> _getConversationParticipants(String conversationId) async {
    final response = await _supabase
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', conversationId);

    return (response as List).map((e) => e['user_id'].toString()).toList();
  }

  Future<void> _sendPushNotification(
    String userId,
    String conversationId,
    String content,
  ) async {
    // Implement push notification via FCM
    // This would call a Supabase Edge Function
    try {
      await _supabase.functions.invoke('send-notification', body: {
        'userId': userId,
        'conversationId': conversationId,
        'content': content,
      });
    } catch (e) {
      print('[EnterChatMessaging] Push notification error: $e');
    }
  }

  Future<String> createConversation({
    required List<String> participantIds,
    String? groupName,
    ConversationType type = ConversationType.oneToOne,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if 1-1 conversation already exists
      if (type == ConversationType.oneToOne && participantIds.length == 1) {
        final existing = await _findExistingConversation(userId, participantIds[0]);
        if (existing != null) return existing;
      }

      // Create conversation
      final conversationData = {
        'type': type.name,
        'name': groupName,
        'created_by': userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final conversation = await _supabase
          .from('conversations')
          .insert(conversationData)
          .select()
          .single();

      final conversationId = conversation['id'];

      // Add participants
      final participants = [userId, ...participantIds];
      for (final participantId in participants) {
        await _supabase.from('conversation_participants').insert({
          'conversation_id': conversationId,
          'user_id': participantId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      // Initialize encryption keys for conversation
      await _initializeConversationEncryption(conversationId, participants);

      return conversationId;
    } catch (e) {
      print('[EnterChatMessaging] Error creating conversation: $e');
      rethrow;
    }
  }

  Future<String?> _findExistingConversation(String user1Id, String user2Id) async {
    final response = await _supabase.rpc('find_conversation_between_users', params: {
      'user1_id': user1Id,
      'user2_id': user2Id,
    });

    return response?['conversation_id'];
  }

  Future<void> _initializeConversationEncryption(
    String conversationId,
    List<String> participantIds,
  ) async {
    // Generate shared key for conversation
    final myPrivateKey = await _keyManager.getUserPrivateKey();
    if (myPrivateKey == null) return;

    // For simplicity, using a generated key
    // In production, implement proper key exchange with all participants
    final conversationKey = await _encryption.createConversationKey(
      List.generate(32, (i) => i),
    );

    await _keyManager.saveConversationKey(
      conversationId: conversationId,
      key: conversationKey,
    );
  }

  Future<void> markAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _supabase.from('message_read_receipts').insert({
        'message_id': messageId,
        'user_id': _supabase.auth.currentUser?.id,
        'read_at': DateTime.now().toIso8601String(),
      });

      await _supabase.from('messages').update({
        'status': 'read',
      }).eq('id', messageId);
    } catch (e) {
      print('[EnterChatMessaging] Error marking as read: $e');
    }
  }

  Future<void> sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      await _presenceChannel?.track({
        'conversation_id': conversationId,
        'user_id': _supabase.auth.currentUser?.id,
        'is_typing': isTyping,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('[EnterChatMessaging] Error sending typing indicator: $e');
    }
  }

  Future<List<UnifiedConversation>> getConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('conversation_participants')
          .select('conversations(*), users(*)')
          .eq('user_id', userId)
          .order('conversations.updated_at', ascending: false);

      return (response as List).map((item) {
        final conv = item['conversations'];
        return UnifiedConversation(
          conversationId: conv['id'],
          sourceAppId: 'enterchat',
          displayName: conv['name'] ?? 'Unknown',
          type: _parseConversationType(conv['type']),
          lastMessageContent: conv['last_message'],
          lastMessageTime: conv['updated_at'] != null
              ? DateTime.parse(conv['updated_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('[EnterChatMessaging] Error getting conversations: $e');
      return [];
    }
  }

  Future<List<UnifiedMessage>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final messages = <UnifiedMessage>[];
      for (final data in response) {
        final message = await _decryptAndCreateMessage(data);
        messages.add(message);
      }

      return messages;
    } catch (e) {
      print('[EnterChatMessaging] Error getting messages: $e');
      return [];
    }
  }

  ContentType _parseContentType(String type) {
    return ContentType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ContentType.text,
    );
  }

  MessageStatus _parseMessageStatus(String status) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MessageStatus.sent,
    );
  }

  ConversationType _parseConversationType(String type) {
    return ConversationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ConversationType.oneToOne,
    );
  }

  void dispose() {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _messageStreamController.close();
    _conversationStreamController.close();
    _typingStreamController.close();
  }
}

class TypingIndicator {
  final String conversationId;
  final String userId;
  final bool isTyping;

  TypingIndicator({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}