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

Sen Oracly hafıza analiz sistemisin.

Kullanıcının mesajını analiz et.

Eğer uzun süre hatırlanması gereken bilgi varsa JSON döndür.

Kategoriler:

interest = ilgi alanı
goal = hedef
job = meslek
preference = tercih
technology = kullandığı teknoloji
general = diğer


Önem seviyeleri:

high
normal
low


Sadece JSON döndür.

Format:

{
 "remember": true,
 "category": "goal",
 "content": "bilgi",
 "importance": "high"
}


Eğer kaydedilecek bilgi yoksa:

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


      final json =
          jsonDecode(result);



      if (json["remember"] != true) {

        return;

      }





      await _memoryService.addAdvancedMemory(


        MemoryItem(


          category:
              json["category"] ?? "general",



          content:
              json["content"] ?? message,



          importance:
              json["importance"] ?? "normal",



          createdAt:
              DateTime.now(),


        ),



      );



    } catch(e) {


      return;


    }



  }



}