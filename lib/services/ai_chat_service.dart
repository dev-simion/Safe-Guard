import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_shield/models/chat_message.dart';
import 'package:guardian_shield/services/supabase_service.dart';

// Sends an HTTPS request to our Supabase Edge Function, which forwards it to the OpenAI API. 
// The response is streamed back in real time—each chunk is displayed in the app as it arrives, 
// instead of waiting for the full response to complete. 
// The user's UID (their JWT token) is used to authenticate access to the server; 
// unauthenticated or non-existent users cannot access it because their UID is invalid.

class AIChatService {
  static const String _edgeFunctionUrl = 'https://xyipwzrftoipayfxrmcy.supabase.co/functions/v1/chat-server';

  Future<void> streamMessage(
    List<ChatMessage> messages,
    String conversationId,
    Function(String) onChunk,
  ) async {
    try {
      // Get current user's auth token
      final authToken = SupabaseService.client.auth.currentSession?.accessToken;
      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      // Prepare messages for the API (exclude empty messages)
      final apiMessages = messages
          .where((msg) => msg.content.trim().isNotEmpty)
          .map((msg) => {
                'role': msg.role.name,
                'content': msg.content,
              })
          .toList();

      final request = http.Request('POST', Uri.parse(_edgeFunctionUrl))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        })
        ..body = jsonEncode({
          'messages': apiMessages,
          'stream': true,
          'conversationId': conversationId,
        });

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        await response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'] ?? '';
              if (content.isNotEmpty) {
                onChunk(content);
              }
            } catch (e) {
              // Skip malformed JSON
            }
          }
        });
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Failed to stream: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Streaming error: $e');
    }
  }

  Future<String?> sendMessage(
    List<ChatMessage> messages,
    String conversationId,
  ) async {
    try {
      // Get current user's auth token
      final authToken = SupabaseService.client.auth.currentSession?.accessToken;
      if (authToken == null) {
        throw Exception('User not authenticated');
      }

      // Prepare messages for the API (exclude empty messages)
      final apiMessages = messages
          .where((msg) => msg.content.trim().isNotEmpty)
          .map((msg) => {
                'role': msg.role.name,
                'content': msg.content,
              })
          .toList();

      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'messages': apiMessages,
          'stream': false,
          'conversationId': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices']?[0]?['message']?['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Message error: $e');
    }
  }
}
