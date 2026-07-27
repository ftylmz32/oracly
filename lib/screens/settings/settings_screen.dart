import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../memory/memory_screen.dart';
import '../history/history_screen.dart';
import '../privacy/privacy_screen.dart';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Ayarlar",
        ),
        centerTitle: true,
      ),


      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [


          _settingsCard(

            context,

            icon: Icons.person,

            title: "Profil",

            subtitle:
                "Bilgilerini ve kişisel ayarlarını yönet",

            onTap: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const ProfileScreen(),

                ),

              );

            },

          ),




          _settingsCard(

            context,

            icon: Icons.psychology,

            title: "Hafıza",

            subtitle:
                "Oracly'nin öğrendiği bilgileri görüntüle",

            onTap: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const MemoryScreen(),

                ),

              );

            },

          ),




          _settingsCard(

            context,

            icon: Icons.history,

            title: "Sohbet Geçmişi",

            subtitle:
                "Eski konuşmalarını yönet",

            onTap: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const HistoryScreen(),

                ),

              );

            },

          ),




          _settingsCard(

            context,

            icon: Icons.security,

            title: "Gizlilik",

            subtitle:
                "Verilerini kontrol et",

            onTap: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (_) =>
                      const PrivacyScreen(),

                ),

              );

            },

          ),


        ],
      ),
    );
  }






  Widget _settingsCard(

    BuildContext context, {

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
            fontWeight: FontWeight.bold,
          ),
        ),


        subtitle: Text(
          subtitle,
        ),


        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),


        onTap: onTap,


      ),

    );
  }
}