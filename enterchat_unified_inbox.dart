// lib/features/unified_inbox/unified_inbox_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/unified_conversation.dart';
import 'unified_inbox_controller.dart';
import 'unified_thread_screen.dart';

class UnifiedInboxScreen extends ConsumerStatefulWidget {
  const UnifiedInboxScreen({super.key});

  @override
  ConsumerState<UnifiedInboxScreen> createState() => _UnifiedInboxScreenState();
}

class _UnifiedInboxScreenState extends ConsumerState<UnifiedInboxScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'enterchat', child: Text('EnterChat Only')),
              const PopupMenuItem(value: 'external', child: Text('External Only')),
              const PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
              const PopupMenuItem(value: 'telegram', child: Text('Telegram')),
              const PopupMenuItem(value: 'instagram', child: Text('Instagram')),
            ],
          ),
        ],
      ),
      body: conversations.when(
        data: (convs) {
          final filtered = _filterConversations(convs);
          
          if (filtered.isEmpty) {
            return const Center(
              child: Text('No conversations'),
            );
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final conv = filtered[index];
              return _ConversationTile(
                conversation: conv,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnifiedThreadScreen(conversation: conv),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open new conversation dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<UnifiedConversation> _filterConversations(List<UnifiedConversation> conversations) {
    switch (_selectedFilter) {
      case 'enterchat':
        return conversations.where((c) => c.sourceAppId == 'enterchat').toList();
      case 'external':
        return conversations.where((c) => c.sourceAppId != 'enterchat').toList();
      case 'all':
        return conversations;
      default:
        return conversations.where((c) => c.sourceAppId == _selectedFilter).toList();
    }
  }
}

class _ConversationTile extends StatelessWidget {
  final UnifiedConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: conversation.avatarUrl != null
                ? NetworkImage(conversation.avatarUrl!)
                : null,
            child: conversation.avatarUrl == null
                ? Text(conversation.displayName[0].toUpperCase())
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _AppBadge(appId: conversation.sourceAppId),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _formatTime(conversation.lastMessageTime!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessageContent ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? Colors.black87
                    : Colors.grey,
              ),
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class _AppBadge extends StatelessWidget {
  final String appId;

  const _AppBadge({required this.appId});

  @override
  Widget build(BuildContext context) {
    final color = _getAppColor(appId);
    final icon = _getAppIcon(appId);

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }

  Color _getAppColor(String appId) {
    switch (appId) {
      case 'whatsapp':
        return Colors.green;
      case 'telegram':
        return Colors.blue;
      case 'instagram':
        return Colors.pink;
      case 'messenger':
        return Colors.blueAccent;
      case 'enterchat':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAppIcon(String appId) {
    switch (appId) {
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send;
      case 'instagram':
        return Icons.camera_alt;
      case 'messenger':
        return Icons.messenger;
      case 'enterchat':
        return Icons.security;
      default:
        return Icons.message;
    }
  }
}

// lib/features/unified_inbox/unified_thread_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/unified_conversation.dart';
import '../../shared/models/unified_message.dart';
import 'unified_inbox_controller.dart';
import '../../core/bridge/bridge_engine.dart';
import '../../core/messaging/enterchat_messaging_service.dart';

class UnifiedThreadScreen extends ConsumerStatefulWidget {
  final UnifiedConversation conversation;

  const UnifiedThreadScreen({super.key, required this.conversation});

  @override
  ConsumerState<UnifiedThreadScreen> createState() => _UnifiedThreadScreenState();
}

class _UnifiedThreadScreenState extends ConsumerState<UnifiedThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _bridgeEngine = BridgeEngine();
  final _enterChatService = EnterChatMessagingService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(
      messagesProvider(widget.conversation.conversationId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.displayName),
            Text(
              'via ${widget.conversation.sourceAppId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (widget.conversation.sourceAppId != 'enterchat')
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: 'Invite to EnterChat',
              onPressed: _sendEnterChatInvite,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (msgs) {
                if (msgs.isEmpty) {
                  return const Center(child: Text('No messages'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final message = msgs[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _attachFile,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (widget.conversation.sourceAppId == 'enterchat') {
      await _enterChatService.sendMessage(
        conversationId: widget.conversation.conversationId,
        content: text,
      );
    } else {
      await _bridgeEngine.sendMessage(
        targetAppId: widget.conversation.sourceAppId,
        conversationId: widget.conversation.conversationId,
        message: text,
      );
    }
  }

  void _attachFile() {
    // Implement file attachment
  }

  void _sendEnterChatInvite() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite to EnterChat'),
        content: const Text(
          'Send an invitation link to this contact to connect via EnterChat\'s secure network?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Generate invite link and send
              Navigator.pop(context);
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final UnifiedMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.direction == MessageDirection.outgoing;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isEncrypted)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Encrypted',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(message.content),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                ),
                if (isOutgoing) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.pending:
        icon = Icons.access_time;
        color = Colors.grey;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 12, color: color);
  }
}