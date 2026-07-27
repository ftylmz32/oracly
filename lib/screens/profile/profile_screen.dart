import 'package:flutter/material.dart';

import '../../services/profile_service.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
  });


  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();

}





class _ProfileScreenState extends State<ProfileScreen> {


  final ProfileService _profileService =
      ProfileService();



  Map<String, dynamic> _profile = {};




  @override
  void initState() {

    super.initState();

    _loadProfile();

  }






  Future<void> _loadProfile() async {


    final data =
        await _profileService.getProfile();


    if (!mounted) return;


    setState(() {

      _profile = data;

    });


  }







  Future<void> _showInputDialog({

    required String title,

    required TextEditingController controller,

    required Future<void> Function() onSave,

  }) async {



    await showDialog(

      context: context,

      builder: (_) {


        return AlertDialog(


          title:
              Text(title),



          content:
              TextField(

                controller:
                    controller,

              ),




          actions: [


            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child:
                  const Text("İptal"),

            ),




            ElevatedButton(


              onPressed: () async {


                if (controller.text.trim().isNotEmpty) {


                  await onSave();

                  await _loadProfile();


                }


                if (mounted) {

                  Navigator.pop(context);

                }


              },


              child:
                  const Text("Kaydet"),


            ),



          ],


        );


      },


    );


  }







  Future<void> _editName() async {


    final controller =
        TextEditingController(

          text:
              _profile["name"] ?? "",

        );



    await _showInputDialog(


      title:
          "İsim",



      controller:
          controller,



      onSave: () async {


        await _profileService.saveName(

          controller.text.trim(),

        );


      },


    );


  }







  Future<void> _editJob() async {


    final controller =
        TextEditingController(

          text:
              _profile["job"] ?? "",

        );



    await _showInputDialog(


      title:
          "Meslek",



      controller:
          controller,



      onSave: () async {


        await _profileService.saveJob(

          controller.text.trim(),

        );


      },


    );


  }







  Future<void> _addInterest() async {


    final controller =
        TextEditingController();



    await _showInputDialog(


      title:
          "İlgi Alanı",



      controller:
          controller,



      onSave: () async {


        final list =
            List<String>.from(

              _profile["interests"] ?? [],

            );



        list.add(

          controller.text.trim(),

        );



        await _profileService.saveInterests(

          list,

        );


      },


    );


  }







  Future<void> _addGoal() async {


    final controller =
        TextEditingController();



    await _showInputDialog(


      title:
          "Hedef",



      controller:
          controller,



      onSave: () async {


        final list =
            List<String>.from(

              _profile["goals"] ?? [],

            );



        list.add(

          controller.text.trim(),

        );



        await _profileService.saveGoals(

          list,

        );


      },


    );


  }








  @override
  Widget build(BuildContext context) {



    final name =
        _profile["name"] ?? "";



    final job =
        _profile["job"] ?? "";



    final interests =
        List<String>.from(

          _profile["interests"] ?? [],

        );



    final goals =
        List<String>.from(

          _profile["goals"] ?? [],

        );





    return Scaffold(



      appBar:
          AppBar(

            title:
                const Text("Profil"),

            centerTitle:
                true,

          ),






      body:
          ListView(


            padding:
                const EdgeInsets.all(20),



            children: [





              const CircleAvatar(


                radius:
                    45,


                child:
                    Icon(

                      Icons.person,

                      size:
                          50,

                    ),


              ),






              const SizedBox(
                height:20,
              ),






              ListTile(



                title:
                    Text(

                      name.isEmpty
                          ? "İsimsiz Kullanıcı"
                          : name,


                      style:
                          const TextStyle(

                            fontSize:22,

                            fontWeight:
                                FontWeight.bold,

                          ),


                    ),



                trailing:
                    IconButton(

                      icon:
                          const Icon(Icons.edit),


                      onPressed:
                          _editName,


                    ),



              ),






              _infoCard(

                "💼 Meslek",

                job.isEmpty
                    ? "Belirtilmemiş"
                    : job,

                _editJob,

              ),






              _listCard(

                "🎮 İlgi Alanları",

                interests,

                _addInterest,

              ),






              _listCard(

                "🎯 Hedefler",

                goals,

                _addGoal,

              ),




            ],


          ),


    );


  }








  Widget _infoCard(

    String title,

    String value,

    VoidCallback onEdit,

  ) {



    return Card(



      child:
          ListTile(



            title:
                Text(title),



            subtitle:
                Text(value),



            trailing:
                IconButton(

                  icon:
                      const Icon(Icons.edit),


                  onPressed:
                      onEdit,


                ),



          ),



    );



  }








  Widget _listCard(

    String title,

    List<String> items,

    VoidCallback onAdd,

  ) {



    return Card(



      child:
          Padding(



            padding:
                const EdgeInsets.all(16),



            child:
                Column(



                  crossAxisAlignment:
                      CrossAxisAlignment.start,



                  children: [




                    Row(



                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,



                      children: [



                        Text(

                          title,

                          style:
                              const TextStyle(

                                fontSize:18,

                                fontWeight:
                                    FontWeight.bold,

                              ),

                        ),




                        IconButton(

                          icon:
                              const Icon(Icons.add),


                          onPressed:
                              onAdd,


                        ),



                      ],



                    ),





                    if(items.isEmpty)

                      const Text(
                        "Henüz bilgi yok",
                      )

                    else

                      ...items.map(

                        (e) =>
                            Text("• $e"),

                      ),




                  ],



                ),



          ),



    );


  }


}