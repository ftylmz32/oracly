import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _chatKey = "chat_history";


  // Sohbet geçmişini kaydet
  Future<void> saveMessages(
    List<Map<String, dynamic>> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(messages);

    await prefs.setString(
      _chatKey,
      encoded,
    );
  }



  // Sohbet geçmişini getir
  Future<List<Map<String, dynamic>>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_chatKey);

    if (data == null || data.isEmpty) {
      return [];
    }


    final decoded = jsonDecode(data);


    return List<Map<String, dynamic>>.from(
      decoded.map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }



  // Sohbet geçmişini temizle
  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_chatKey);
  }
}