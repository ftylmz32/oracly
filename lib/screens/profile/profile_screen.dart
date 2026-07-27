import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }


  Future<void> _loadProfile() async {
    final data = await _profileService.getProfile();

    setState(() {
      _profile = data;
    });
  }


  @override
  Widget build(BuildContext context) {

    final name = _profile["name"] ?? "";
    final job = _profile["job"] ?? "";

    final interests =
        _profile["interests"] ?? [];

    final goals =
        _profile["goals"] ?? [];


    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Profil",
        ),
        centerTitle: true,
      ),


      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(

          children: [

            const CircleAvatar(
              radius: 45,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),


            const SizedBox(height: 20),


            Center(
              child: Text(
                name.isEmpty
                    ? "İsimsiz Kullanıcı"
                    : name,

                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),


            const SizedBox(height: 30),



            _buildCard(
              "💼 Meslek",
              job.isEmpty
                  ? "Belirtilmemiş"
                  : job,
            ),



            _buildListCard(
              "🎮 İlgi Alanları",
              interests,
            ),



            _buildListCard(
              "🎯 Hedefler",
              goals,
            ),

          ],
        ),
      ),
    );
  }



  Widget _buildCard(
    String title,
    String value,
  ) {

    return Card(

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),


            const SizedBox(height: 8),


            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

          ],
        ),
      ),
    );
  }



  Widget _buildListCard(
    String title,
    List items,
  ) {

    return Card(

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),


            const SizedBox(height: 8),


            if (items.isEmpty)

              const Text(
                "Henüz bilgi yok",
              )


            else

              ...items.map(
                (item) => Text(
                  "• $item",
                ),
              ),

          ],
        ),
      ),
    );
  }
}