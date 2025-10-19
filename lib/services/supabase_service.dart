import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guardian_shield/models/chat_message.dart';
import 'package:flutter/foundation.dart';

// Public Safe Anon Key. Safe to Store on Client Side. RLS enabled in database. -- Supabase SDK.
class SupabaseService {
  static const String supabaseUrl = 'https://xyipwzrftoipayfxrmcy.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5aXB3enJmdG9pcGF5ZnhybWN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Mzg3MjcsImV4cCI6MjA3NjMxNDcyN30.aGj7zXs490ViP6VK0tP3hFhEkxgmEEFQ8VuWbJA2SjQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  // Chat Persistence Methods
  Future<void> saveMessage(ChatMessage message) async {
    try {
      // Ensure conversation exists before saving message
      await _ensureConversationExists(message.conversationId);
      
      await client.from('chat_messages').insert({
        'id': message.id,
        'conversation_id': message.conversationId,
        'user_id': client.auth.currentUser?.id,
        'content': message.content,
        'role': message.role.name,
        'timestamp': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error saving message: $e');
      rethrow;
    }
  }

  // Ensure conversation exists in the conversations table
  Future<void> _ensureConversationExists(String conversationId) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Check if conversation already exists
      final existing = await client
          .from('conversations')
          .select('id')
          .eq('id', conversationId)
          .maybeSingle();

      if (existing == null) {
        // Create the conversation
        await client.from('conversations').insert({
          'id': conversationId,
          'user_id': userId,
          'title': 'AI Counselor Chat',
        });
      }
    } catch (e) {
      print('Error ensuring conversation exists: $e');
      // Don't rethrow here to avoid blocking message saving
    }
  }

  Future<List<ChatMessage>> getConversationMessages(String conversationId) async {
    try {
      final data = await client
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true);

      return (data as List)
          .map((msg) => ChatMessage(
                id: msg['id'],
                conversationId: msg['conversation_id'],
                content: msg['content'],
                role: msg['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
                timestamp: DateTime.parse(msg['timestamp']),
              ))
          .toList();
    } catch (e) {
      print('Error loading conversation: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];

      // Get conversations with message count and latest message
      final data = await client
          .from('conversations')
          .select('''
            id, title, created_at,
            chat_messages!inner(content, timestamp)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Build conversation list with metadata
      return (data as List).map((conv) {
        final messages = conv['chat_messages'] as List;
        final firstMessage = messages.isNotEmpty ? messages.first : null;
        final content = firstMessage?['content'] ?? 'No messages';
        final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;

        return {
          'id': conv['id'],
          'first_message': preview,
          'message_count': messages.length,
          'created_at': conv['created_at'],
          'title': conv['title'] ?? 'AI Counselor Chat',
        };
      }).toList();
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete the conversation (messages will be deleted via CASCADE)
      await client
          .from('conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<void> createConversation(String conversationId, String title) async {
    try {
      await client.from('conversations').insert({
        'id': conversationId,
        'user_id': client.auth.currentUser?.id,
        'title': title,
      });
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Generic CRUD Methods
  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      throw _handleDatabaseError('select', table, e);
    }
  }

  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.maybeSingle();
    } catch (e) {
      throw _handleDatabaseError('selectSingle', table, e);
    }
  }

  /// Insert a record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insert', table, e);
    }
  }

  /// Insert multiple records into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      return await client.from(table).insert(data).select();
    } catch (e) {
      throw _handleDatabaseError('insertMultiple', table, e);
    }
  }

  /// Update records in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.select();
    } catch (e) {
      throw _handleDatabaseError('update', table, e);
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      throw _handleDatabaseError('delete', table, e);
    }
  }

  /// Get direct table reference for complex queries
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Handle database errors
  static String _handleDatabaseError(
    String operation,
    String table,
    dynamic error,
  ) {
    if (error is PostgrestException) {
      return 'Failed to $operation from $table: ${error.message}';
    } else {
      return 'Failed to $operation from $table: ${error.toString()}';
    }
  }
}