import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      return "API anahtarı bulunamadı.";
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-5.5",
        "input": message,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["output"][0]["content"][0]["text"] ??
          "Cevap alınamadı.";
    }

    return "Hata oluştu: ${response.statusCode}";
  }
}