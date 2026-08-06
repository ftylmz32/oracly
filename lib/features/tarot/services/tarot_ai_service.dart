import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../../core/copy/resilience_copy.dart';
import '../../../services/context_service.dart';
import '../models/tarot_card.dart';
import '../utils/tarot_constants.dart';
import '../utils/tarot_helpers.dart';

class TarotAiService {
  final ContextService _contextService = ContextService();

  Future<String> generateReading({
    required List<TarotCard> cards,
    required String intention,
  }) async {
    if (cards.isEmpty) {
      return 'Yorum oluşturmak için en az bir kart gerekli.';
    }

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return ResilienceCopy.aiConfigMissing;
    }

    final userContext = await _contextService.getContext();
    final spreadContext = TarotHelpers.formatSpreadContext(
      cards,
      intention,
    );

    final response = await http.post(
      Uri.parse(TarotConstants.openAiResponsesUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': TarotConstants.openAiModel,
        'instructions': TarotConstants.instructions(
          userContext,
        ),
        'input': '''
Aşağıdaki tarot açılımını yorumla. Kart bilgileri dışına çıkma.

$spreadContext

Lütfen bütünsel bir tarot yorumu yaz.
''',
      }),
    );

    if (response.statusCode != 200) {
      return ResilienceCopy.aiUnavailable;
    }

    return _parseResponse(response.body);
  }

  String _parseResponse(String body) {
    final data = jsonDecode(body);

    if (data is! Map<String, dynamic>) {
      return ResilienceCopy.aiResponseUnavailable;
    }

    final output = data['output'];
    if (output is! List) {
      return ResilienceCopy.aiResponseUnavailable;
    }

    for (final item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final content = item['content'];
      if (content is! List) {
        continue;
      }

      for (final block in content) {
        if (block is! Map<String, dynamic>) {
          continue;
        }

        final text = block['text'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }

    return 'Cevap alınamadı.';
  }
}
