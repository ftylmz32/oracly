import 'package:flutter/material.dart';

import '../../services/memory_service.dart';
import '../../services/storage_service.dart';
import '../../services/profile_service.dart';



class PrivacyScreen extends StatelessWidget {

  const PrivacyScreen({super.key});


  @override
  Widget build(BuildContext context) {


    final MemoryService memoryService =
        MemoryService();

    final StorageService storageService =
        StorageService();

    final ProfileService profileService =
        ProfileService();



    return Scaffold(


      appBar: AppBar(

        title: const Text(
          "Gizlilik",
        ),

        centerTitle: true,

      ),



      body: ListView(


        padding:
            const EdgeInsets.all(20),


        children: [



          _privacyCard(

            icon: Icons.psychology,

            title: "Hafızayı Temizle",

            subtitle:
                "Oracly'nin öğrendiği bilgileri sil",

            onTap: () async {


              await memoryService.clearMemory();

              if (!context.mounted) return;

              _showMessage(
                context,
                "Hafıza temizlendi.",
              );

            },

          ),




          _privacyCard(

            icon: Icons.history,

            title: "Sohbet Geçmişini Temizle",

            subtitle:
                "Tüm eski konuşmaları sil",

            onTap: () async {


              await storageService.clearMessages();

              if (!context.mounted) return;

              _showMessage(
                context,
                "Sohbet geçmişi temizlendi.",
              );


            },

          ),





          _privacyCard(

            icon: Icons.delete_forever,

            title: "Tüm Verileri Sıfırla",

            subtitle:
                "Profil, hafıza ve sohbetleri tamamen sil",

            onTap: () async {


              await memoryService.clearMemory();

              await storageService.clearMessages();

              await profileService.clearProfile();

              if (!context.mounted) return;

              _showMessage(
                context,
                "Tüm veriler sıfırlandı.",
              );


            },

          ),



        ],

      ),

    );

  }






  Widget _privacyCard({


    required IconData icon,

    required String title,

    required String subtitle,

    required VoidCallback onTap,


  }) {


    return Card(


      child: ListTile(


        leading: Icon(

          icon,

          size: 32,

        ),



        title: Text(

          title,

          style: const TextStyle(

            fontWeight:
                FontWeight.bold,

          ),

        ),



        subtitle:
            Text(subtitle),




        trailing:
            const Icon(

              Icons.arrow_forward_ios,

              size:18,

            ),



        onTap:onTap,


      ),

    );

  }






  void _showMessage(

    BuildContext context,

    String message,

  ) {


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
            Text(message),

      ),

    );

  }

}