import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../services/memory_extractor.dart';
import '../../services/storage_service.dart';

import '../../widgets/chat_input.dart';
import '../../widgets/message_bubble.dart';



class ChatScreen extends StatefulWidget {

  const ChatScreen({
    super.key,
  });


  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();

}





class _ChatScreenState extends State<ChatScreen> {


  final TextEditingController _controller =
      TextEditingController();


  final ScrollController _scrollController =
      ScrollController();



  final AiService _aiService =
      AiService();


  final MemoryExtractor _memoryExtractor =
      MemoryExtractor();


  final StorageService _storageService =
      StorageService();




  bool _isLoading = false;



  List<Map<String, dynamic>> _messages = [

    {
      "text":
          "👋 Merhaba Fatih!\nBen Oracly. Sana nasıl yardımcı olabilirim?",
      "isUser": false,
    },

  ];






  @override
  void initState() {

    super.initState();

    _loadMessages();

  }







  Future<void> _loadMessages() async {


    final savedMessages =
        await _storageService.loadMessages();



    if (!mounted) return;



    if (savedMessages.isNotEmpty) {


      setState(() {

        _messages =
            savedMessages;

      });


    }


  }









  Future<void> _sendMessage() async {


    final text =
        _controller.text.trim();



    if (text.isEmpty || _isLoading) return;





    setState(() {


      _messages.add({

        "text":
            text,

        "isUser":
            true,

      });



      _isLoading =
          true;


    });





    _controller.clear();



    await _storageService.saveMessages(
      _messages,
    );



    _scrollToBottom();






    await _memoryExtractor.analyzeMessage(
      text,
    );





    final response =
        await _aiService.sendMessage(
          text,
        );





    if (!mounted) return;





    setState(() {


      _messages.add({

        "text":
            response,

        "isUser":
            false,

      });



      _isLoading =
          false;



    });






    await _storageService.saveMessages(
      _messages,
    );



    _scrollToBottom();



  }









  void _scrollToBottom() {


    Future.delayed(

      const Duration(
        milliseconds:150,
      ),


      () {


        if (!_scrollController.hasClients) {
          return;
        }



        _scrollController.animateTo(


          _scrollController
              .position
              .maxScrollExtent,



          duration:
              const Duration(
                milliseconds:300,
              ),



          curve:
              Curves.easeOut,


        );


      },

    );


  }








  @override
  void dispose() {


    _controller.dispose();


    _scrollController.dispose();


    super.dispose();


  }









  @override
  Widget build(BuildContext context) {


    return Scaffold(



      appBar: AppBar(


        centerTitle:
            false,



        title: Row(


          children: [



            Container(

              width:
                  40,

              height:
                  40,


              decoration:
                  BoxDecoration(

                shape:
                    BoxShape.circle,


                color:
                    Colors.deepPurple.shade900,

              ),



              child:
                  const Icon(

                    Icons.auto_awesome,

                    color:
                        Colors.white,

                    size:
                        22,

                  ),


            ),




            const SizedBox(
              width:12,
            ),





            const Column(


              crossAxisAlignment:
                  CrossAxisAlignment.start,



              children: [



                Text(

                  "Oracly",

                  style:
                      TextStyle(

                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),




                Text(

                  "● Online",

                  style:
                      TextStyle(

                    fontSize:
                        12,

                    color:
                        Colors.greenAccent,

                  ),

                ),



              ],


            ),



          ],


        ),


      ),







      body: Column(


        children: [



          Expanded(


            child:
                ListView.builder(



              controller:
                  _scrollController,



              itemCount:
                  _messages.length,



              itemBuilder:
                  (context,index){



                final message =
                    _messages[index];



                return MessageBubble(

                  message:
                      message["text"],


                  isUser:
                      message["isUser"],


                );



              },


            ),



          ),








          if (_isLoading)


            const Padding(


              padding:
                  EdgeInsets.all(12),



              child:
                  Row(


                mainAxisAlignment:
                    MainAxisAlignment.center,



                children: [



                  SizedBox(

                    width:
                        14,

                    height:
                        14,


                    child:
                        CircularProgressIndicator(

                          strokeWidth:
                              2,

                        ),

                  ),




                  SizedBox(
                    width:10,
                  ),




                  Text(

                    "Oracly düşünüyor...",

                  ),



                ],



              ),



            ),








          ChatInput(

            controller:
                _controller,


            onSend:
                _sendMessage,


          ),




        ],



      ),


    );


  }


}