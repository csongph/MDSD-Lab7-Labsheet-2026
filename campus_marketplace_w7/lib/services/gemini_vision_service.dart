import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

const String GEMINI_API_KEY = String.fromEnvironment('GEMINI_API_KEY');

class GeminiVisionService {
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-3-flash-preview',
    'gemini-2.5-flash',
  ];

  static const String _defaultPrompt = '''
คุณคือผู้ช่วยวิเคราะห์ภาพสินค้าออนไลน์
อ่านภาพสินค้าอย่างละเอียด แล้วให้ผลลัพธ์เป็น JSON เท่านั้น
โดยมีโครงสร้างดังนี้:
{
  "title": "ชื่อสินค้า",
  "category": "ประเภทสินค้า",
  "description": "คำอธิบายสั้น ๆ ของสินค้า"
}

กติกาให้ปฏิบัติตามดังนี้:
1. title ต้องเป็นชื่อสินค้าที่เหมาะสมและสั้น กระชับ
2. category ต้องเป็นประเภทสินค้า เช่น เสื้อผ้า, เครื่องใช้ไฟฟ้า, อุปกรณ์กีฬา, หนังสือ, ของใช้ภายในบ้าน, เครื่องประดับ, อื่น ๆ
3. description ต้องเขียนเป็นข้อความที่อธิบายสินค้าแบบเป็นกันเองและสั้น ๆ
4. ตอบเฉพาะ JSON เท่านั้น ห้ามมีคำอธิบายเพิ่มเติม ไม่ต้องมี ```json
''';

  Future<ListingDraft> analyzeProductImage(
    List<int> imageBytes, [
    String prompt = _defaultPrompt,
  ]) async {
    if (GEMINI_API_KEY.isEmpty || GEMINI_API_KEY == 'YOUR_GEMINI_API_KEY') {
      throw Exception(
        'Gemini API key is missing or still using the placeholder value. '
        'Use --dart-define=GEMINI_API_KEY=YOUR_REAL_KEY when running the app.',
      );
    }

    final base64Image = base64Encode(imageBytes);
    final mimeType = _detectMimeType(imageBytes);

    String lastError = '';
    for (final model in _models) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY',
      );

      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                      {
                        'inlineData': {
                          'mimeType': mimeType,
                          'data': base64Image,
                        },
                      },
                    ],
                  },
                ],
                'generationConfig': {
                  'responseMimeType': 'application/json',
                  'responseSchema': {
                    'type': 'OBJECT',
                    'properties': {
                      'title': {'type': 'STRING'},
                      'category': {'type': 'STRING'},
                      'description': {'type': 'STRING'},
                    },
                    'required': ['title', 'category', 'description'],
                  },
                },
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final decodedResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = decodedResponse['candidates'];

          // กรณี Gemini ถูกบล็อกโดย Safety Filter → candidates ว่างเปล่า
          if (candidates == null ||
              candidates is! List ||
              candidates.isEmpty) {
            throw Exception(
              'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
            );
          }

          final candidate = candidates[0];

          // กรณี Gemini ตอบกลับ แต่ถูกหยุดด้วยเหตุผล SAFETY
          final finishReason = candidate['finishReason'] as String?;
          if (finishReason == 'SAFETY') {
            throw Exception(
              'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
            );
          }

          final content = candidate['content'];
          final parts = content?['parts'];
          if (parts == null || parts is! List || parts.isEmpty) {
            continue;
          }

          String resultText = '';
          for (final part in parts) {
            if (part is Map && part['text'] != null) {
              resultText += part['text'] as String;
            }
          }

          if (resultText.trim().isEmpty) continue;
          final parsedJson = jsonDecode(resultText) as Map<String, dynamic>;
          return ListingDraft.fromJson(parsedJson);
        }

        if (response.statusCode == 429 || response.statusCode == 503) {
          lastError = 'โมเดล $model ติดข้อจำกัด (${response.statusCode})';
          continue;
        }

        throw Exception(
          'Failed to analyze image. Status code: ${response.statusCode}\nBody: ${response.body}',
        );
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(
      'ใช้งานเกินโควต้าฟรีของ Gemini ทุกโมเดล กรุณารอประมาณ 1 นาทีแล้วลองใหม่อีกครั้ง ($lastError)',
    );
  }

  String _detectMimeType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
