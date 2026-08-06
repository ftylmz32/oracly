import 'dart:async';

import 'dart:convert';

import 'dart:io';



import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;



import '../core/copy/resilience_copy.dart';

import 'ai_message_result.dart';

import 'context_service.dart';

import '../features/ai/services/conversation_response_guard.dart';

import 'storage_service.dart';



class AiService {

  final ContextService _contextService = ContextService();

  final StorageService _storageService = StorageService();



  static const _requestTimeout = Duration(seconds: 45);



  Future<AiMessageResult> sendMessage(String message) async {

    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {

      return const AiMessageResult.failure(ResilienceCopy.aiConfigMissing);

    }



    try {

      final userContext = await _contextService.getContext();

      final conversationContext =

          await _storageService.getConversationContext();



      final response = await http

          .post(

            Uri.parse('https://api.openai.com/v1/responses'),

            headers: {

              'Content-Type': 'application/json',

              'Authorization': 'Bearer $apiKey',

            },

            body: jsonEncode({

              'model': 'gpt-5.5',

              'instructions': '''

Sen OR'sun — Oracly'nin sakin yansıma arkadaşı.



Temel karakterin:

- sıcak, ölçülü, düşünceli

- sohbet botu değil; sessiz bir yansıma arkadaşı

- samimi ama abartısız



Türkçe konuş.



Amaçların:

- Kullanıcıya düşünmek için alan açmak

- Geçmiş bilgileri doğal ve nazikçe kullanmak

- Kısa, nefes alan paragraflarla yanıt vermek

- Ara sıra düşündürücü sorular sormak



Kullanıcı profili ve hafızası:

$userContext



Önceki sohbet bağlamı:

$conversationContext



Davranış kuralları:

- Sadece yukarıdaki gerçek bilgileri kullan; uydurma.

- Hafızayı liste halinde gösterme veya "şunu biliyorum" deme.

- Uzun duvar metinleri yazma; 2–4 kısa paragraf yeterli.

- Kesinlik, kader, korku dili kullanma.

- Sohbeti sürdürmeye baskı yapma; huzurla ayrılmaya izin ver.

- Robotik veya aşırı mistik ton kullanma.

''',

              'input': message,

            }),

          )

          .timeout(_requestTimeout);



      if (response.statusCode != 200) {

        return const AiMessageResult.failure(ResilienceCopy.aiUnavailable);

      }



      final data = jsonDecode(response.body);

      if (data['output'] != null) {

        for (final item in data['output']) {

          if (item['content'] != null) {

            for (final content in item['content']) {

              if (content['text'] != null) {

                return AiMessageResult.success(

                  ConversationResponseGuard.polish(content['text'] as String),

                );

              }

            }

          }

        }

      }



      return const AiMessageResult.failure(ResilienceCopy.aiEmptyResponse);

    } on TimeoutException {

      return const AiMessageResult.failure(ResilienceCopy.slowResponse);

    } on SocketException {

      return const AiMessageResult.failure(ResilienceCopy.offline);

    } on http.ClientException {

      return const AiMessageResult.failure(ResilienceCopy.offline);

    } catch (_) {

      return const AiMessageResult.failure(ResilienceCopy.aiUnavailable);

    }

  }

}

