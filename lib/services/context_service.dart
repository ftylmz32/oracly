import 'memory_service.dart';
import 'profile_service.dart';

class ContextService {

  final MemoryService _memoryService = MemoryService();
  final ProfileService _profileService = ProfileService();


  Future<String> getContext() async {

    final profile =
        await _profileService.getProfile();


    final memories =
        await _memoryService.getMemories();



    String context = "";


    // 👤 Profil bilgileri

    if (profile["name"] != null &&
        profile["name"].toString().isNotEmpty) {

      context +=
          "Kullanıcı adı: ${profile["name"]}\n";
    }


    if (profile["job"] != null &&
        profile["job"].toString().isNotEmpty) {

      context +=
          "Meslek: ${profile["job"]}\n";
    }



    final interests =
        profile["interests"] ?? [];


    if (interests.isNotEmpty) {

      context +=
          "İlgi alanları: ${interests.join(", ")}\n";
    }



    final goals =
        profile["goals"] ?? [];


    if (goals.isNotEmpty) {

      context +=
          "Hedefler: ${goals.join(", ")}\n";
    }



    // 🧠 Hafıza bilgileri

    if (memories.isNotEmpty) {

      context += "\nKullanıcının hatırlanan bilgileri:\n";


      for (var memory in memories) {

        context += "- $memory\n";

      }

    }



    if (context.isEmpty) {

      context =
          "Kullanıcı hakkında kayıtlı bilgi yok.";

    }


    return context;
  }
}