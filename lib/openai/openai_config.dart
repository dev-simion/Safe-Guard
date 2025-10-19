import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_shield/models/chat_message.dart';

class OpenAIService {
  static const _apiKey = String.fromEnvironment('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');
  static const _endpoint = String.fromEnvironment('https://api.openai.com/v1/chat/completions');
  static const _model = 'gpt-4o';

  static const String _systemPrompt = '''You are a compassionate and professional virtual counselor specializing in trauma support, crisis intervention, and emotional guidance. You help victims of bullying, harassment, assault, and other emergencies. Provide empathetic, actionable advice while encouraging users to seek professional help when needed. Be supportive, non-judgmental, and trauma-informed in your responses.''';

  Future<void> streamMessage(
    List<ChatMessage> messages,
    Function(String) onChunk,
  ) async {
    try {
      final request = http.Request('POST', Uri.parse(_endpoint))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            ...messages.map((msg) => {
              'role': msg.role.name,
              'content': msg.content,
            }),
          ],
          'temperature': 0.7,
          'max_tokens': 500,
          'stream': true,
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
        throw Exception('Failed to stream: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Streaming error: $e');
    }
  }

  Future<String?> sendMessage(List<ChatMessage> messages) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            ...messages.map((msg) => {
              'role': msg.role.name,
              'content': msg.content,
            }),
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getEmergencyGuidance(String alertType) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an emergency response advisor. Provide brief, clear, actionable safety tips.',
            },
            {
              'role': 'user',
              'content': 'I just triggered a $alertType emergency alert. What should I do while waiting for help?',
            },
          ],
          'temperature': 0.5,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}