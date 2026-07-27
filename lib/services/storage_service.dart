import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';



class StorageService {


  static const String _chatKey =
      "chat_history";





  // Sohbet geçmişini kaydet

  Future<void> saveMessages(

    List<Map<String, dynamic>> messages,

  ) async {


    final prefs =
        await SharedPreferences.getInstance();



    final encoded =
        jsonEncode(messages);



    await prefs.setString(

      _chatKey,

      encoded,

    );


  }







  // Sohbet geçmişini getir

  Future<List<Map<String, dynamic>>>
      loadMessages() async {


    final prefs =
        await SharedPreferences.getInstance();



    final data =
        prefs.getString(
          _chatKey,
        );



    if (data == null || data.isEmpty) {

      return [];

    }




    final decoded =
        jsonDecode(data);




    return List<Map<String, dynamic>>.from(


      decoded.map(

        (item) =>
            Map<String, dynamic>.from(item),


      ),


    );


  }








  // Son mesajları getir

  Future<List<Map<String, dynamic>>>
      getRecentMessages(

    int count,

  ) async {


    final messages =
        await loadMessages();



    if (messages.length <= count) {

      return messages;

    }



    return messages.sublist(

      messages.length - count,

    );


  }







  // AI için sohbet bağlamı

  Future<String> getConversationContext() async {


    final messages =
        await getRecentMessages(10);



    if (messages.isEmpty) {

      return "Henüz sohbet geçmişi yok.";

    }



    return messages.map((message) {


      final role =
          message["isUser"] == true

              ? "Kullanıcı"

              : "Oracly";



      return "$role: ${message["text"]}";


    }).join("\n");


  }








  // Sohbet geçmişini temizle

  Future<void> clearMessages() async {


    final prefs =
        await SharedPreferences.getInstance();



    await prefs.remove(

      _chatKey,

    );


  }


}