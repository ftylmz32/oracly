import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'memory_service.dart';

class AiService {
  final MemoryService _memoryService = MemoryService();

  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return "API anahtarı bulunamadı.";
    }

    // Kullanıcı hafızalarını al
    final memories = await _memoryService.getMemories();

    String memoryContext = "Henüz kayıtlı kullanıcı bilgisi yok.";

    if (memories.isNotEmpty) {
      memoryContext = memories.join("\n");
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
Sen Oracly'sin.

Kullanıcıyla sıcak, doğal ve samimi konuş.
Türkçe cevap ver.
Kullanıcının adı Fatih.

Kullanıcı hakkında bildiklerin:

$memoryContext

Bu bilgileri sadece cevaplarını kişiselleştirmek için kullan.
""",

        "input": message,
      }),
    );

    if (response.statusCode != 200) {
      return "API hatası: ${response.statusCode}";
    }

    final data = jsonDecode(response.body);

    if (data["output"] != null) {
      for (var item in data["output"]) {
        if (item["content"] != null) {
          for (var content in item["content"]) {
            if (content["text"] != null) {
              return content["text"];
            }
          }
        }
      }
    }

    return "Cevap alınamadı.";
  }
}