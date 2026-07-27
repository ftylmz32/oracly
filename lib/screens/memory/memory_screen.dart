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

        return Icons.flag;


      case "interest":

        return Icons.favorite;


      case "job":

        return Icons.work;


      case "technology":

        return Icons.computer;



      default:

        return Icons.psychology;


    }

  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(



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



        child:


            _memories.isEmpty



            ? const Center(


                child:
                    Text(
                      "Henüz kayıtlı bilgi yok.",
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
                                      AppColors.white,

                                ),


                          ),




                      title:
                          Text(


                            memory.content,


                            style:
                                const TextStyle(

                              color:
                                  AppColors.white,

                            ),


                          ),





                      subtitle:
                          Text(



                            "${memory.category} • ${memory.importance}",



                            style:
                                const TextStyle(

                              color:
                                  AppColors.textSecondary,

                            ),



                          ),






                      trailing:
                          IconButton(



                            icon:
                                const Icon(

                                  Icons.delete,

                                  color:
                                      Colors.red,

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


    );


  }


}