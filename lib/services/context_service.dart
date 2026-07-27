import 'memory_service.dart';
import 'profile_service.dart';


class ContextService {


  final MemoryService _memoryService =
      MemoryService();


  final ProfileService _profileService =
      ProfileService();





  Future<String> getContext() async {


    final profile =
        await _profileService.getProfile();



    final memories =
        await _memoryService.getMemories();





    StringBuffer context =
        StringBuffer();





    context.writeln(
      "KULLANICI PROFİLİ:",
    );





    final name =
        profile["name"]?.toString() ?? "";



    if (name.isNotEmpty) {

      context.writeln(
        "- Kullanıcı adı: $name",
      );

    }






    final job =
        profile["job"]?.toString() ?? "";



    if (job.isNotEmpty) {

      context.writeln(
        "- Meslek: $job",
      );

    }







    final interests =
        List<String>.from(
          profile["interests"] ?? [],
        );



    if (interests.isNotEmpty) {

      context.writeln(
        "- İlgi alanları: ${interests.join(", ")}",
      );

    }







    final goals =
        List<String>.from(
          profile["goals"] ?? [],
        );



    if (goals.isNotEmpty) {

      context.writeln(
        "- Hedefler: ${goals.join(", ")}",
      );

    }






    context.writeln("");



    context.writeln(
      "ORACLY HAFIZASI:",
    );





    if (memories.isNotEmpty) {


      for (var memory in memories) {

        context.writeln(
          "- $memory",
        );

      }


    } else {


      context.writeln(
        "- Kayıtlı hafıza yok.",
      );


    }






    return context.toString();


  }


}