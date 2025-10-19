import 'package:flutter/material.dart';
import 'package:guardian_shield/models/chat_message.dart';
import 'package:guardian_shield/services/ai_chat_service.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class AIChatScreen extends StatefulWidget {
  final String? conversationId;

  const AIChatScreen({super.key, this.conversationId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _aiChatService = AIChatService();
  final _supabaseService = SupabaseService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late String _conversationId;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId ?? _uuid.v4();
    _loadConversationHistory();
    
    if (_messages.isEmpty) {
      _addMessage(
        'Hello! I\'m here to provide support and guidance. Whether you\'ve experienced an emergency or just need someone to talk to, I\'m here to listen and help. How are you feeling today?',
        MessageRole.assistant,
        isInitial: true,
      );
    }
  }

  Future<void> _loadConversationHistory() async {
    try {
      final messages = await _supabaseService.getConversationMessages(_conversationId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
    }
  }

  void _addMessage(String content, MessageRole role, {bool isInitial = false}) {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        content: content,
        role: role,
        timestamp: DateTime.now(),
        conversationId: _conversationId,
      ));
    });
    _scrollToBottom();
  }

  void _updateLastMessage(String content) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
        final lastMessage = _messages.last;
        _messages[_messages.length - 1] = ChatMessage(
          id: lastMessage.id,
          conversationId: lastMessage.conversationId,
          content: lastMessage.content + content,
          role: lastMessage.role,
          timestamp: lastMessage.timestamp,
        );
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      conversationId: _conversationId,
    );
    
    _addMessage(text, MessageRole.user);

    // Save user message to database
    await _supabaseService.saveMessage(userMessage);

    setState(() => _isLoading = true);

    // Add empty assistant message that will be filled with streaming content
    _addMessage('', MessageRole.assistant);

    try {
      await _aiChatService.streamMessage(_messages, _conversationId, (chunk) {
        _updateLastMessage(chunk);
      });

      // Save the complete AI response to database
      final aiMessage = _messages.last;
      await _supabaseService.saveMessage(aiMessage);

    } catch (e) {
      _updateLastMessage('\n\n[Error: Unable to get response. Please try again.]');
    }

    setState(() => _isLoading = false);
  }

  void _openChatHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatHistoryScreen(
          onSelectConversation: (conversationId) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AIChatScreen(conversationId: conversationId),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Support',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Am always here to support you',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openChatHistory,
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Am here to help. Start a conversation',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(
                      message: _messages[index],
                      theme: theme,
                    ),
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Streaming response...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_upward_rounded, color: theme.colorScheme.onPrimary),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  topRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class ChatHistoryScreen extends StatefulWidget {
  final Function(String) onSelectConversation;

  const ChatHistoryScreen({
    super.key,
    required this.onSelectConversation,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _supabaseService.getConversations();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat History',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(conv['first_message'] ?? 'Conversation'),
                  subtitle: Text(
                    'Messages: ${conv['message_count']} • ${_formatDate(conv['created_at'])}',
                  ),
                  onTap: () => widget.onSelectConversation(conv['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
