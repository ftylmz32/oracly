import 'package:flutter/material.dart';


class ChatInput extends StatelessWidget {

  final TextEditingController controller;
  final VoidCallback onSend;


  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });



  @override
  Widget build(BuildContext context) {


    return SafeArea(

      child: Container(

        padding:
            const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              14,
            ),


        decoration: BoxDecoration(

          color:
              const Color(0xff0b0b0b),


          border: Border(

            top: BorderSide(

              color:
                  Colors.white.withOpacity(
                    0.05,
                  ),

            ),

          ),

        ),



        child: Row(

          children: [



            Expanded(

              child: Container(

                decoration:
                    BoxDecoration(

                  color:
                      Colors.grey.shade900,


                  borderRadius:
                      BorderRadius.circular(
                        28,
                      ),

                ),


                child: TextField(

                  controller:
                      controller,


                  style:
                      const TextStyle(

                        color:
                            Colors.white,

                        fontSize:
                            15,

                      ),



                  decoration:
                      const InputDecoration(


                        hintText:
                            "Oracly'ye mesaj yaz...",


                        hintStyle:
                            TextStyle(

                              color:
                                  Colors.white54,

                            ),



                        contentPadding:
                            EdgeInsets.symmetric(

                              horizontal:
                                  20,

                              vertical:
                                  14,

                            ),



                        border:
                            InputBorder.none,


                      ),

                ),

              ),

            ),




            const SizedBox(
              width: 10,
            ),




            Container(

              width:
                  48,

              height:
                  48,


              decoration:
                  BoxDecoration(


                    shape:
                        BoxShape.circle,


                    gradient:
                        const LinearGradient(

                      colors: [

                        Colors.deepPurple,

                        Colors.purpleAccent,

                      ],

                    ),


                  ),



              child:
                  IconButton(


                    onPressed:
                        onSend,


                    icon:
                        const Icon(

                          Icons.arrow_upward_rounded,


                          color:
                              Colors.white,


                        ),

                  ),

            ),



          ],

        ),

      ),

    );

  }

}