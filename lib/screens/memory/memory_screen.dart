import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/memory_item.dart';
import '../../services/memory_service.dart';



class MemoryScreen extends StatefulWidget {

  const MemoryScreen({
    super.key,
  });


  @override
  State<MemoryScreen> createState() =>
      _MemoryScreenState();

}





class _MemoryScreenState extends State<MemoryScreen> {


  final MemoryService _memoryService =
      MemoryService();



  List<MemoryItem> _memories = [];



  @override
  void initState() {

    super.initState();

    _loadMemories();

  }







  Future<void> _loadMemories() async {


    final memories =
        await _memoryService.getAdvancedMemories();



    if (!mounted) return;



    setState(() {

      _memories = memories;

    });


  }







  Future<void> _deleteMemory(
      MemoryItem memory,
  ) async {


    final confirm =
        await showDialog<bool>(

          context: context,

          builder: (_) {

            return AlertDialog(

              title:
                  const Text("Hafızayı sil"),

              content:
                  const Text(
                    "Oracly bu bilgiyi unutacak. Emin misin?",
                  ),

              actions: [


                TextButton(

                  onPressed: () =>
                      Navigator.pop(
                        context,
                        false,
                      ),

                  child:
                      const Text("İptal"),

                ),



                ElevatedButton(

                  onPressed: () =>
                      Navigator.pop(
                        context,
                        true,
                      ),

                  child:
                      const Text("Sil"),

                ),


              ],

            );

          },

        );



    if (confirm != true) return;



    await _memoryService.removeMemory(
      memory.content,
    );



    _loadMemories();


  }








  IconData _categoryIcon(
    String category,
  ) {


    switch(category) {


      case "goal":

        return Icons.flag_rounded;



      case "interest":

        return Icons.favorite_rounded;



      case "job":

        return Icons.work_rounded;



      case "technology":

        return Icons.computer_rounded;



      default:

        return Icons.psychology_rounded;


    }


  }








  Color _importanceColor(
    String importance,
  ) {


    switch(importance) {


      case "high":

        return Colors.redAccent;



      case "medium":

        return AppColors.gold;



      default:

        return AppColors.textSecondary;


    }


  }









  @override
  Widget build(BuildContext context) {


    return Scaffold(



      backgroundColor:
          AppColors.background,



      appBar: AppBar(


        title:
            const Text(
              "Oracly Hafızası",
            ),


        centerTitle:
            true,


      ),






      body: Padding(


        padding:
            const EdgeInsets.all(20),



        child: Column(



          children: [



            Container(


              width:
                  double.infinity,



              padding:
                  const EdgeInsets.all(18),



              decoration:
                  BoxDecoration(

                color:
                    AppColors.surface,

                borderRadius:
                    BorderRadius.circular(20),

              ),




              child:
                  Column(


                    crossAxisAlignment:
                        CrossAxisAlignment.start,



                    children: [



                      const Text(

                        "🧠 Oracly Hafızası",

                        style:
                            TextStyle(

                              color:
                                  Colors.white,

                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.bold,

                            ),

                      ),



                      const SizedBox(
                        height:8,
                      ),



                      Text(

                        "${_memories.length} bilgi kayıtlı",

                        style:
                            const TextStyle(

                              color:
                                  AppColors.textSecondary,

                            ),

                      ),


                    ],


                  ),


            ),






            const SizedBox(
              height:20,
            ),






            Expanded(


              child:


                  _memories.isEmpty



                  ? const Center(


                      child:
                          Text(

                            "Oracly henüz seni tanımıyor.",

                            style:
                                TextStyle(

                                  color:
                                      Colors.white54,

                                ),

                          ),


                    )




                  : ListView.builder(



                      itemCount:
                          _memories.length,



                      itemBuilder:
                          (context,index) {



                        final memory =
                            _memories[index];




                        return Card(



                          color:
                              AppColors.surface,



                          margin:
                              const EdgeInsets.only(
                                bottom:12,
                              ),




                          child:
                              ListTile(



                            leading:
                                CircleAvatar(


                                  backgroundColor:
                                      AppColors.primary,



                                  child:
                                      Icon(

                                        _categoryIcon(
                                          memory.category,
                                        ),


                                        color:
                                            Colors.white,

                                      ),


                                ),





                            title:
                                Text(

                                  memory.content,

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors.white,

                                  ),

                                ),





                            subtitle:
                                Text(

                                  "${memory.category} • ${memory.importance}",


                                  style:
                                      TextStyle(

                                    color:
                                        _importanceColor(
                                          memory.importance,
                                        ),

                                  ),

                                ),






                            trailing:
                                IconButton(

                                  icon:
                                      const Icon(

                                        Icons.delete_outline,

                                        color:
                                            Colors.redAccent,

                                      ),


                                  onPressed: () {

                                    _deleteMemory(
                                      memory,
                                    );


                                  },


                                ),




                          ),


                        );


                      },


                    ),



            ),



          ],


        ),


      ),



    );


  }


}