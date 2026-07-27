import 'package:flutter/material.dart';

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


  List<String> _memories = [];



  @override
  void initState() {

    super.initState();

    _loadMemories();

  }




  Future<void> _loadMemories() async {

    final memories =
        await _memoryService.getMemories();


    if (!mounted) return;


    setState(() {

      _memories = memories;

    });

  }





  Future<void> _deleteMemory(
      String memory,
  ) async {


    await _memoryService.removeMemory(
      memory,
    );


    _loadMemories();

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Oracly Hafızası",
        ),

        centerTitle: true,

      ),



      body: Padding(

        padding: const EdgeInsets.all(20),


        child: _memories.isEmpty


            ? const Center(

                child: Text(
                  "Henüz kayıtlı bilgi yok.",
                ),

              )


            : ListView.builder(

                itemCount:
                    _memories.length,


                itemBuilder:
                    (context, index) {


                  final memory =
                      _memories[index];



                  return Card(

                    child: ListTile(

                      leading:
                          const Icon(
                            Icons.psychology,
                          ),


                      title:
                          Text(memory),


                      trailing:
                          IconButton(

                            icon:
                                const Icon(
                                  Icons.delete,
                                  color: Colors.red,
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