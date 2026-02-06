// lib/features/unified_inbox/unified_inbox_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/unified_conversation.dart';
import '../../shared/models/unified_message.dart';
import '../../core/bridge/bridge_engine.dart';
import '../../core/messaging/enterchat_messaging_service.dart';
import '../../core/storage/local_db.dart';

final conversationsProvider = StreamProvider<List<UnifiedConversation>>((ref) {
  return LocalDB().watchConversations();
});

final messagesProvider = StreamProvider.family<List<UnifiedMessage>, String>(
  (ref, conversationId) {
    return LocalDB().watchMessages(conversationId);
  },
);

final unreadCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  return conversations.maybeWhen(
    data: (convs) => convs.fold<int>(0, (sum, conv) => sum + conv.unreadCount),
    orElse: () => 0,
  );
});

class UnifiedInboxController extends StateNotifier<AsyncValue<void>> {
  final BridgeEngine _bridgeEngine;
  final EnterChatMessagingService _messagingService;
  final LocalDB _localDB;

  UnifiedInboxController(
    this._bridgeEngine,
    this._messagingService,
    this._localDB,
  ) : super(const AsyncValue.data(null)) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const AsyncValue.loading();
    
    try {
      await _bridgeEngine.initialize();
      await _messagingService.initialize();
      
      _bridgeEngine.conversationStream.listen(_handleBridgedConversation);
      _bridgeEngine.messageStream.listen(_handleBridgedMessage);
      _messagingService.conversationStream.listen(_handleEnterChatConversation);
      _messagingService.messageStream.listen(_handleEnterChatMessage);
      
      await syncAll();
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _handleBridgedConversation(UnifiedConversation conversation) async {
    await _localDB.saveConversation(conversation);
  }

  void _handleBridgedMessage(UnifiedMessage message) async {
    await _localDB.saveMessage(message);
  }

  void _handleEnterChatConversation(UnifiedConversation conversation) async {
    await _localDB.saveConversation(conversation);
  }

  void _handleEnterChatMessage(UnifiedMessage message) async {
    await _localDB.saveMessage(message);
  }

  Future<void> syncAll() async {
    try {
      await _bridgeEngine.syncAll();
    } catch (e) {
      print('[UnifiedInboxController] Sync error: $e');
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _localDB.markConversationAsRead(conversationId);
    } catch (e) {
      print('[UnifiedInboxController] Mark as read error: $e');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    try {
      await _localDB.archiveConversation(conversationId);
    } catch (e) {
      print('[UnifiedInboxController] Archive error: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _localDB.deleteConversation(conversationId);
    } catch (e) {
      print('[UnifiedInboxController] Delete error: $e');
    }
  }
}

final unifiedInboxControllerProvider = StateNotifierProvider<
    UnifiedInboxController, AsyncValue<void>>((ref) {
  return UnifiedInboxController(
    BridgeEngine(),
    EnterChatMessagingService(),
    LocalDB(),
  );
});

// lib/core/storage/local_db.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/unified_conversation.dart';
import '../../shared/models/unified_message.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/wallet_account.dart';
import '../../shared/models/wallet_transaction.dart';

class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  Isar? _isar;

  Future<void> initialize() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [
        UnifiedConversationSchema,
        UnifiedMessageSchema,
        UserModelSchema,
        WalletAccountSchema,
        WalletTransactionSchema,
      ],
      directory: dir.path,
    );
  }

  Isar get isar {
    if (_isar == null) {
      throw Exception('LocalDB not initialized');
    }
    return _isar!;
  }

  Stream<List<UnifiedConversation>> watchConversations() {
    return isar.unifiedConversations
        .filter()
        .isArchivedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<UnifiedMessage>> watchMessages(String conversationId) {
    return isar.unifiedMessages
        .filter()
        .sourceConversationIdEqualTo(conversationId)
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }

  Future<void> saveConversation(UnifiedConversation conversation) async {
    await isar.writeTxn(() async {
      await isar.unifiedConversations.put(conversation);
    });
  }

  Future<void> saveMessage(UnifiedMessage message) async {
    await isar.writeTxn(() async {
      await isar.unifiedMessages.put(message);
      
      final conversation = await isar.unifiedConversations
          .filter()
          .conversationIdEqualTo(message.sourceConversationId)
          .findFirst();
      
      if (conversation != null) {
        conversation.lastMessageContent = message.content;
        conversation.lastMessageTime = message.timestamp;
        conversation.updatedAt = DateTime.now();
        
        if (message.direction == MessageDirection.incoming) {
          conversation.unreadCount++;
        }
        
        await isar.unifiedConversations.put(conversation);
      }
    });
  }

  Future<List<UnifiedConversation>> getConversations({
    String? filterByAppId,
    bool includeArchived = false,
  }) async {
    var query = isar.unifiedConversations.filter();
    
    if (filterByAppId != null) {
      query = query.sourceAppIdEqualTo(filterByAppId);
    }
    
    if (!includeArchived) {
      query = query.isArchivedEqualTo(false);
    }
    
    return await query.sortByUpdatedAtDesc().findAll();
  }

  Future<List<UnifiedMessage>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    return await isar.unifiedMessages
        .filter()
        .sourceConversationIdEqualTo(conversationId)
        .sortByTimestampDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await isar.writeTxn(() async {
      final conversation = await isar.unifiedConversations
          .filter()
          .conversationIdEqualTo(conversationId)
          .findFirst();
      
      if (conversation != null) {
        conversation.unreadCount = 0;
        await isar.unifiedConversations.put(conversation);
      }
    });
  }

  Future<void> archiveConversation(String conversationId) async {
    await isar.writeTxn(() async {
      final conversation = await isar.unifiedConversations
          .filter()
          .conversationIdEqualTo(conversationId)
          .findFirst();
      
      if (conversation != null) {
        conversation.isArchived = true;
        await isar.unifiedConversations.put(conversation);
      }
    });
  }

  Future<void> deleteConversation(String conversationId) async {
    await isar.writeTxn(() async {
      await isar.unifiedConversations
          .filter()
          .conversationIdEqualTo(conversationId)
          .deleteAll();
      
      await isar.unifiedMessages
          .filter()
          .sourceConversationIdEqualTo(conversationId)
          .deleteAll();
    });
  }

  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}