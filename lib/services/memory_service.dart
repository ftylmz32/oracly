import 'package:shared_preferences/shared_preferences.dart';


class MemoryService {

  static const String _nameKey = "user_name";
  static const String _memoryKey = "user_memories";



  // Kullanıcı adını kaydet
  Future<void> saveUserName(String name) async {

    final prefs =
        await SharedPreferences.getInstance();


    await prefs.setString(
      _nameKey,
      name,
    );

  }




  // Kullanıcı adını getir
  Future<String?> getUserName() async {

    final prefs =
        await SharedPreferences.getInstance();


    return prefs.getString(
      _nameKey,
    );

  }




  // Hafızaya yeni bilgi ekle
  Future<void> addMemory(
    String memory,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();


    List<String> memories =
        prefs.getStringList(
          _memoryKey,
        ) ?? [];


    memories.add(memory);


    await prefs.setStringList(
      _memoryKey,
      memories,
    );

  }




  // Tüm hafızaları getir
  Future<List<String>> getMemories() async {

    final prefs =
        await SharedPreferences.getInstance();


    return prefs.getStringList(
      _memoryKey,
    ) ?? [];

  }




  // Tek hafıza sil
  Future<void> removeMemory(
    String memory,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();


    List<String> memories =
        prefs.getStringList(
          _memoryKey,
        ) ?? [];


    memories.remove(
      memory,
    );


    await prefs.setStringList(
      _memoryKey,
      memories,
    );

  }




  // Tüm hafızayı temizle
  Future<void> clearMemory() async {

    final prefs =
        await SharedPreferences.getInstance();


    await prefs.remove(
      _memoryKey,
    );

  }

}