// lib/shared/models/unified_message.dart
import 'package:isar/isar.dart';

part 'unified_message.g.dart';

@collection
class UnifiedMessage {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String messageId;
  
  @Index()
  late String sourceAppId; // enterchat, whatsapp, telegram, etc.
  
  late String sourceConversationId;
  
  String? mappedContactId;
  
  @enumerated
  late MessageDirection direction;
  
  @enumerated
  late ContentType contentType;
  
  late String content;
  
  List<String>? attachmentUrls;
  
  @Index()
  late DateTime timestamp;
  
  @enumerated
  late MessageStatus status;
  
  String? replyToMessageId;
  
  bool isEncrypted = false;
  
  String? encryptionKeyId;
  
  Map<String, dynamic>? metadata;
  
  UnifiedMessage({
    required this.messageId,
    required this.sourceAppId,
    required this.sourceConversationId,
    this.mappedContactId,
    required this.direction,
    required this.contentType,
    required this.content,
    this.attachmentUrls,
    required this.timestamp,
    required this.status,
    this.replyToMessageId,
    this.isEncrypted = false,
    this.encryptionKeyId,
    this.metadata,
  });
}

enum MessageDirection {
  incoming,
  outgoing,
}

enum ContentType {
  text,
  image,
  video,
  audio,
  file,
  link,
  location,
  contact,
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

// lib/shared/models/unified_conversation.dart
import 'package:isar/isar.dart';

part 'unified_conversation.g.dart';

@collection
class UnifiedConversation {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String conversationId;
  
  @Index()
  late String sourceAppId;
  
  late String displayName;
  
  String? avatarUrl;
  
  @enumerated
  late ConversationType type;
  
  String? lastMessageContent;
  
  DateTime? lastMessageTime;
  
  int unreadCount = 0;
  
  bool isMuted = false;
  
  bool isPinned = false;
  
  bool isArchived = false;
  
  List<String>? participantIds;
  
  String? encryptionKeyId;
  
  Map<String, dynamic>? metadata;
  
  @Index()
  DateTime createdAt = DateTime.now();
  
  DateTime updatedAt = DateTime.now();
  
  UnifiedConversation({
    required this.conversationId,
    required this.sourceAppId,
    required this.displayName,
    this.avatarUrl,
    required this.type,
    this.lastMessageContent,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.participantIds,
    this.encryptionKeyId,
    this.metadata,
  });
}

enum ConversationType {
  oneToOne,
  group,
  channel,
  broadcast,
}

// lib/shared/models/user_model.dart
import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String userId;
  
  @Index()
  late String username;
  
  late String displayName;
  
  String? avatarUrl;
  
  String? bio;
  
  String? phoneNumber;
  
  String? email;
  
  late String publicKey;
  
  String? deviceFingerprint;
  
  @enumerated
  UserStatus status = UserStatus.offline;
  
  DateTime? lastSeen;
  
  bool isEnterChatUser = false;
  
  List<String>? linkedAppIds;
  
  Map<String, dynamic>? metadata;
  
  DateTime createdAt = DateTime.now();
  
  DateTime updatedAt = DateTime.now();
  
  UserModel({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    this.email,
    required this.publicKey,
    this.deviceFingerprint,
    this.status = UserStatus.offline,
    this.lastSeen,
    this.isEnterChatUser = false,
    this.linkedAppIds,
    this.metadata,
  });
}

enum UserStatus {
  online,
  offline,
  away,
  busy,
}

// lib/shared/models/wallet_account.dart
import 'package:isar/isar.dart';

part 'wallet_account.g.dart';

@collection
class WalletAccount {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String accountId;
  
  late String userId;
  
  double balance = 0.0;
  
  String currency = 'USD';
  
  bool isPinSet = false;
  
  String? pinHash;
  
  bool isLocked = false;
  
  int failedPinAttempts = 0;
  
  DateTime? lockedUntil;
  
  DateTime createdAt = DateTime.now();
  
  DateTime updatedAt = DateTime.now();
  
  WalletAccount({
    required this.accountId,
    required this.userId,
    this.balance = 0.0,
    this.currency = 'USD',
    this.isPinSet = false,
    this.pinHash,
    this.isLocked = false,
    this.failedPinAttempts = 0,
    this.lockedUntil,
  });
}

// lib/shared/models/wallet_transaction.dart
import 'package:isar/isar.dart';

part 'wallet_transaction.g.dart';

@collection
class WalletTransaction {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String transactionId;
  
  late String fromAccountId;
  
  late String toAccountId;
  
  late double amount;
  
  String currency = 'USD';
  
  @enumerated
  late TransactionType type;
  
  @enumerated
  late TransactionStatus status;
  
  String? description;
  
  String? referenceId;
  
  Map<String, dynamic>? metadata;
  
  @Index()
  DateTime timestamp = DateTime.now();
  
  WalletTransaction({
    required this.transactionId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.currency = 'USD',
    required this.type,
    required this.status,
    this.description,
    this.referenceId,
    this.metadata,
  });
}

enum TransactionType {
  transfer,
  topup,
  withdrawal,
  payment,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}