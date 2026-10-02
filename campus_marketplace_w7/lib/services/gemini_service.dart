import 'dart:convert';

import 'package:http/http.dart' as http;

const String GEMINI_API_KEY = String.fromEnvironment('GEMINI_API_KEY');

class GeminiService {
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-3-flash-preview',
    'gemini-2.5-flash',
  ];

  Future<String> generateText(String prompt) async {
    if (GEMINI_API_KEY.isEmpty ||
        GEMINI_API_KEY == 'YOUR_GEMINI_API_KEY') {
      throw Exception(
        'Gemini API key is missing or still using the placeholder value. '
        'Use --dart-define=GEMINI_API_KEY=YOUR_REAL_KEY when running the app.',
      );
    }

    String lastError = '';
    for (final model in _models) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decodedData = jsonDecode(response.body);
          if (decodedData['candidates'] == null ||
              decodedData['candidates'] is! List ||
              decodedData['candidates'].isEmpty) {
            continue;
          }

          final candidate = decodedData['candidates'][0];
          final parts = candidate['content']?['parts'];
          if (parts == null || parts is! List || parts.isEmpty) {
            continue;
          }

          final text = parts[0]['text'];
          if (text == null || text.toString().trim().isEmpty) {
            continue;
          }

          return text.toString();
        }

        if (response.statusCode == 429 || response.statusCode == 503) {
          lastError = 'โมเดล $model ติดข้อจำกัด (${response.statusCode})';
          continue;
        }

        throw Exception(
          'Failed to generate text. Status code: ${response.statusCode}\nBody: ${response.body}',
        );
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(
      'ใช้งานเกินโควต้าฟรีของ Gemini ทุกโมเดล กรุณารอประมาณ 1 นาทีแล้วลองใหม่อีกครั้ง ($lastError)',
    );
  }
}
