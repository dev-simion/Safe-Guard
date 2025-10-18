import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_shield/models/chat_message.dart';

class OpenAIService {
  static const _apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const _endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');
  static const _model = 'gpt-4o';

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
              'content': 'You are a compassionate and professional virtual counselor specializing in trauma support, crisis intervention, and emotional guidance. You help victims of bullying, harassment, assault, and other emergencies. Provide empathetic, actionable advice while encouraging users to seek professional help when needed. Be supportive, non-judgmental, and trauma-informed in your responses.',
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
