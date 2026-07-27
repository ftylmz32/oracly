import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/memory_item.dart';
import 'memory_service.dart';



class MemoryExtractor {


  final MemoryService _memoryService =
      MemoryService();






  Future<void> analyzeMessage(
    String message,
  ) async {


    final apiKey =
        dotenv.env['OPENAI_API_KEY'];



    if (apiKey == null || apiKey.isEmpty) {

      return;

    }








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

Sen Oracly'nin uzun vadeli hafıza analiz sistemisin.

Görevin kullanıcının mesajını incelemek.

SADECE kullanıcının gelecekteki deneyimini kişiselleştirmeye yarayacak bilgileri kaydet.

Kaydet:

- Kalıcı hedefler
- Meslek bilgileri
- Uzun vadeli projeler
- Hobiler
- İlgi alanları
- Teknoloji tercihleri
- Kalıcı kişisel tercihler


KAYDETME:

- Günlük olaylar
- Anlık ruh halleri
- Bugün olan şeyler
- Geçici planlar
- Selamlaşmalar
- Basit sohbetler
- Tahminler


Örnek:

"Kendi oyunumu yapmak istiyorum"

Kaydet.


"Bugün çok yoruldum"

Kaydetme.



Kategori:

goal = hedef
job = meslek
interest = ilgi alanı
technology = teknoloji
preference = tercih
general = diğer



Önem:

high = gelecekte çok önemli
normal = faydalı bilgi
low = az önemli



Sadece JSON döndür.


Kaydedilecek bilgi varsa:

{
 "remember": true,
 "category": "goal",
 "content": "Kullanıcı kendi oyununu yapmak istiyor",
 "importance": "high"
}


Kaydedilecek bilgi yoksa:

{
 "remember": false
}

""",





        "input":
            message,



      }),



    );








    if (response.statusCode != 200) {

      return;

    }








    final data =
        jsonDecode(response.body);




    String result = "";





    if (data["output"] != null) {


      for (var item in data["output"]) {


        if (item["content"] != null) {


          for (var content in item["content"]) {


            if (content["text"] != null) {


              result =
                  content["text"];


            }


          }


        }


      }


    }







    if (result.isEmpty) {

      return;

    }







    try {


      // Markdown JSON temizleme

      result =
          result
              .replaceAll(
                "```json",
                "",
              )
              .replaceAll(
                "```",
                "",
              )
              .trim();





      final json =
          jsonDecode(result);





      if (json["remember"] != true) {

        return;

      }






      final content =
          json["content"]?.toString();



      if (content == null ||
          content.isEmpty) {

        return;

      }







      await _memoryService.addAdvancedMemory(



        MemoryItem(



          category:
              json["category"] ??
                  "general",




          content:
              content,




          importance:
              json["importance"] ??
                  "normal",




          createdAt:
              DateTime.now(),



        ),



      );




    } catch(e) {


      return;


    }



  }



}