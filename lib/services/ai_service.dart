import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'context_service.dart';


class AiService {

  final ContextService _contextService = ContextService();



  Future<String> sendMessage(String message) async {

    final apiKey =
        dotenv.env['OPENAI_API_KEY'];



    if (apiKey == null || apiKey.isEmpty) {

      return "API anahtarı bulunamadı.";

    }



    // 👤 Kullanıcı bağlamını al

    final userContext =
        await _contextService.getContext();




    final response = await http.post(

      Uri.parse(
        'https://api.openai.com/v1/responses',
      ),


      headers: {

        'Content-Type': 'application/json',

        'Authorization':
            'Bearer $apiKey',

      },


      body: jsonEncode({

        "model": "gpt-5.5",


        "instructions": """

Sen Oracly'sin.

Kullanıcıyla sıcak, doğal ve samimi konuş.
Türkçe cevap ver.

Kullanıcı hakkında sahip olduğun bağlam:

$userContext


Bu bilgileri sadece cevaplarını kişiselleştirmek için kullan.

Kullanıcı hakkında emin olmadığın şeyleri uydurma.

""",


        "input": message,

      }),

    );



    if (response.statusCode != 200) {

      return "API hatası: ${response.statusCode}";

    }



    final data =
        jsonDecode(response.body);



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