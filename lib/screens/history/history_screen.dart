import 'package:flutter/material.dart';

import '../../services/storage_service.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});


  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();

}



class _HistoryScreenState extends State<HistoryScreen> {


  final StorageService _storageService =
      StorageService();


  List<Map<String, dynamic>> _messages = [];



  @override
  void initState() {

    super.initState();

    _loadHistory();

  }




  Future<void> _loadHistory() async {

    final messages =
        await _storageService.loadMessages();


    if (!mounted) return;


    setState(() {

      _messages = messages;

    });

  }




  Future<void> _clearHistory() async {


    await _storageService.clearMessages();


    _loadHistory();

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Sohbet Geçmişi",
        ),

        centerTitle: true,


        actions: [

          IconButton(

            icon: const Icon(
              Icons.delete_forever,
            ),


            onPressed: () async {


              await _clearHistory();


            },


          ),

        ],

      ),



      body: Padding(

        padding:
            const EdgeInsets.all(20),


        child: _messages.isEmpty


            ? const Center(

                child: Text(
                  "Henüz sohbet geçmişi yok.",
                ),

              )


            : ListView.builder(

                itemCount:
                    _messages.length,


                itemBuilder:
                    (context, index) {


                  final message =
                      _messages[index];


                  final isUser =
                      message["isUser"] ?? false;



                  return Align(

                    alignment: isUser

                        ? Alignment.centerRight

                        : Alignment.centerLeft,


                    child: Card(

                      child: Padding(

                        padding:
                            const EdgeInsets.all(12),


                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment.start,


                          children: [


                            Text(

                              isUser
                                  ? "Sen"
                                  : "Oracly",

                              style:
                                  const TextStyle(

                                fontWeight:
                                    FontWeight.bold,

                              ),

                            ),



                            const SizedBox(
                              height: 5,
                            ),



                            Text(
                              message["text"] ?? "",
                            ),


                          ],

                        ),

                      ),

                    ),

                  );

                },

              ),

      ),

    );

  }

}