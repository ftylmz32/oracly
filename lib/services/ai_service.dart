import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'context_service.dart';
import 'storage_service.dart';



class AiService {


  final ContextService _contextService =
      ContextService();


  final StorageService _storageService =
      StorageService();





  Future<String> sendMessage(
    String message,
  ) async {



    final apiKey =
        dotenv.env['OPENAI_API_KEY'];



    if (apiKey == null || apiKey.isEmpty) {

      return "API anahtarı bulunamadı.";

    }





    // 👤 Kullanıcı bilgileri

    final userContext =
        await _contextService.getContext();





    // 💬 Son konuşma bağlamı

    final conversationContext =
        await _storageService
            .getConversationContext();







    final response = await http.post(



      Uri.parse(
        'https://api.openai.com/v1/responses',
      ),



      headers: {


        'Content-Type':
            'application/json',



        'Authorization':
            'Bearer $apiKey',


      },





      body: jsonEncode({



        "model":
            "gpt-5.5",





        "instructions": """

Sen Oracly'sin.

Kullanıcının kişisel AI asistanısın.



Türkçe konuş.



Kullanıcıyla:

- sıcak,
- doğal,
- samimi,
- yardımcı

bir şekilde iletişim kur.



Görevin:

Kullanıcıyı zaman içinde tanımak,
önceki bilgileri kullanmak
ve konuşmanın devamlılığını sağlamaktır.



🧠 Kullanıcı hafızası:

$userContext



💬 Son konuşma geçmişi:

$conversationContext





Kurallar:

- Hafızadaki bilgileri uygun olduğunda kullan.
- Önceki konuşmanın bağlamını koru.
- Kullanıcı hakkında bilmediğin şeyleri uydurma.
- Emin olmadığın bilgileri gerçek gibi söyleme.
- Hafızayı gereksiz yere açıklama.
- Robot gibi cevap verme.
- Doğal bir AI arkadaşı gibi davran.



""",





        "input":
            message,



      }),


    );







    if (response.statusCode != 200) {


      return
          "API hatası: ${response.statusCode}";


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