import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'memory_service.dart';

class MemoryExtractor {
  final MemoryService _memoryService = MemoryService();

  Future<void> analyzeMessage(String message) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-5.5",
        "instructions": """
Sen bir hafıza analizcisisin.

Görevin:
Kullanıcının mesajında uzun süre hatırlanması gereken bilgi var mı kontrol et.

Önemli bilgiler:
- Kullanıcının hobileri
- Mesleği
- Hedefleri
- Tercihleri
- Kullandığı teknolojiler

Önemsiz bilgiler:
- Günlük hava durumu
- Geçici olaylar
- Anlık durumlar

Eğer önemli bilgi varsa sadece bilgiyi yaz.
Yoksa sadece NONE yaz.
""",
        "input": message,
      }),
    );

    if (response.statusCode != 200) {
      return;
    }

    final data = jsonDecode(response.body);

    String result = "";

    if (data["output"] != null) {
      for (var item in data["output"]) {
        if (item["content"] != null) {
          for (var content in item["content"]) {
            if (content["text"] != null) {
              result = content["text"];
            }
          }
        }
      }
    }

    if (result.isEmpty || result.contains("NONE")) {
      return;
    }

    await _memoryService.addMemory(result);
  }
}