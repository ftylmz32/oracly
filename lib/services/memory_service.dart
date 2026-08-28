import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memory_item.dart';



class MemoryService {


  static const String _nameKey =
      "user_name";


  static const String _memoryKey =
      "user_memories";





  // Kullanıcı adını kaydet

  Future<void> saveUserName(
    String name,
  ) async {

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






  // Yeni hafıza ekleme
  // Aynı bilgi varsa tekrar kaydetmez

  Future<void> addAdvancedMemory(
    MemoryItem item,
  ) async {


    final memories =
        await getAdvancedMemories();



    final exists =
        memories.any(

      (memory) =>

          memory.content
              .toLowerCase()
              .trim() ==
          item.content
              .toLowerCase()
              .trim(),

    );



    if (exists) {

      return;

    }





    memories.add(item);



    await _saveMemories(
      memories,
    );


  }







  // Hafızaları kaydet

  Future<void> _saveMemories(
    List<MemoryItem> memories,
  ) async {


    final prefs =
        await SharedPreferences.getInstance();



    final encoded =
        memories
            .map(

              (e) => jsonEncode(
                e.toJson(),
              ),

            )
            .toList();



    await prefs.setStringList(

      _memoryKey,

      encoded,

    );


  }








  // Gelişmiş hafızaları getir

  Future<List<MemoryItem>>
      getAdvancedMemories() async {


    final prefs =
        await SharedPreferences.getInstance();



    final data =
        prefs.getStringList(
          _memoryKey,
        ) ?? [];




    return data.map(


      (item) {


        try {


          return MemoryItem.fromJson(
            jsonDecode(item),
          );



        } catch(e) {


          return MemoryItem(

            category:
                "general",


            content:
                item,


            importance:
                "normal",


            createdAt:
                DateTime.now(),

          );


        }


      },


    ).toList();


  }








  // Hafıza var mı kontrol

  Future<bool> memoryExists(
    String content,
  ) async {


    final memories =
        await getAdvancedMemories();



    return memories.any(

      (memory) =>

          memory.content
              .toLowerCase()
              .trim() ==

          content
              .toLowerCase()
              .trim(),

    );


  }








  // Eski sistem uyumluluğu

  Future<List<String>> getMemories() async {


    final memories =
        await getAdvancedMemories();



    return memories

        .map(

          (e) => e.content,

        )

        .toList();


  }








  // Eski addMemory uyumluluğu

  Future<void> addMemory(
    String memory,
  ) async {


    await addAdvancedMemory(


      MemoryItem(


        category:
            "general",



        content:
            memory,



        importance:
            "normal",



        createdAt:
            DateTime.now(),



      ),


    );


  }









  // Tek hafıza silme

  Future<void> removeMemory(
    String memory,
  ) async {


    final memories =
        await getAdvancedMemories();



    memories.removeWhere(

      (item) =>

          item.content == memory,

    );



    await _saveMemories(
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

    // Personal Memory Core — compact summary, not raw chat.
    await prefs.remove('or_personal_memory_v1');
    await prefs.remove('discovery_surface_memory_v1');


  }


}