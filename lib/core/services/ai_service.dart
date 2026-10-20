import 'dart:convert';

import 'package:http/http.dart' as http;

class AiException implements Exception {
  final String message;
  AiException(this.message);

  @override
  String toString() => message;
}

/// الاتصال بنموذج الذكاء الاصطناعي (Groq) — مستخدم في الشات والتقرير الأسبوعي.
///
/// المفتاح بيتمرر وقت البناء عشان مايتحفظش في الكود:
/// `flutter run --dart-define=GROQ_API_KEY=...`
class AiService {
  static const _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_API_KEY',
  );
  static const _model = 'llama-3.3-70b-versatile';
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> complete(
    List<Map<String, String>> messages, {
    int maxTokens = 900,
    double temperature = 0.55,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': maxTokens,
              'temperature': temperature,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw AiException('تعذّر الاتصال. تأكد من اتصالك بالإنترنت.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw AiException('خطأ: ${data['error']?['message'] ?? response.statusCode}');
    }
    return data['choices'][0]['message']['content'] as String;
  }
}
