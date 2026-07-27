import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memory_item.dart';
import '../../services/profile_service.dart';
import '../../services/memory_service.dart';



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






  // Yeni gelişmiş hafıza ekleme

  Future<void> addAdvancedMemory(
    MemoryItem item,
  ) async {


    final prefs =
        await SharedPreferences.getInstance();



    final memories =
        await getAdvancedMemories();



    memories.add(item);



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



    final prefs =
        await SharedPreferences.getInstance();



    await prefs.setStringList(

      _memoryKey,


      memories
          .map(
            (e) => jsonEncode(
              e.toJson(),
            ),
          )
          .toList(),


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