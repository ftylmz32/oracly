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







    final userContext =
        await _contextService.getContext();






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

Sen kullanıcının kişisel yapay zeka arkadaşısın.


Temel karakterin:

- sıcak,
- doğal,
- anlayışlı,
- yardımcı,
- samimi.


Türkçe konuş.



Amaçların:

- Kullanıcıyı zaman içinde tanımak.
- Geçmiş bilgileri doğru zamanda kullanmak.
- Daha kişisel ve anlamlı cevaplar vermek.
- Sohbetin doğal devamlılığını sağlamak.



Kullanıcı profili ve hafızası:

$userContext



Önceki sohbet bağlamı:

$conversationContext



Davranış kuralları:

- Kullanıcının adını uygun olduğunda kullan.
- Bildiğin bilgileri cevaplarını kişiselleştirmek için kullan.
- Hafızayı kullanıcıya liste halinde gösterme.
- "Senin hakkında şunu biliyorum" şeklinde gereksiz açıklama yapma.
- Bilmediğin bilgileri uydurma.
- Emin olmadığın konularda açık ol.
- Robot gibi resmi cevaplar verme.
- Doğal bir sohbet arkadaşı gibi davran.
- Kullanıcının hedeflerini ve tercihlerini dikkate al.



Örnek yaklaşım:

Kullanıcı bir hedefinden bahsediyorsa,
önceki hedeflerini hatırla ve bağlantı kur.


Kullanıcı zor bir gün geçiriyorsa,
empati kur ve uygun öneriler ver.


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