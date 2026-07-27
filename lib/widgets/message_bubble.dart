import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';



class MessageBubble extends StatelessWidget {

  final String message;
  final bool isUser;


  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });



  @override
  Widget build(BuildContext context) {


    return Align(

      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,


      child: Row(

        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,


        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [



          if (!isUser)

            Container(

              margin:
                  const EdgeInsets.only(
                    left: 12,
                    right: 8,
                    top: 8,
                  ),


              width: 36,

              height: 36,


              decoration: BoxDecoration(

                shape:
                    BoxShape.circle,


                color:
                    AppColors.primary,

              ),


              child: const Icon(

                Icons.auto_awesome,

                color:
                    AppColors.white,

                size: 20,

              ),

            ),





          Container(

            margin:
                const EdgeInsets.symmetric(
                  vertical: 6,
                ),


            padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),



            constraints:
                const BoxConstraints(
                  maxWidth: 290,
                ),




            decoration: BoxDecoration(


              color: isUser

                  ? AppColors.primary

                  : AppColors.surface,



              borderRadius:
                  BorderRadius.only(


                    topLeft:
                        const Radius.circular(20),


                    topRight:
                        const Radius.circular(20),


                    bottomLeft:
                        Radius.circular(
                          isUser ? 20 : 4,
                        ),


                    bottomRight:
                        Radius.circular(
                          isUser ? 4 : 20,
                        ),

                  ),




              boxShadow: [

                BoxShadow(

                  color:
                      Colors.black.withOpacity(
                        0.25,
                      ),

                  blurRadius:
                      8,

                  offset:
                      const Offset(0, 4),

                ),

              ],


            ),




            child: Text(

              message,


              style:
                  const TextStyle(

                    color:
                        AppColors.white,

                    fontSize:
                        15.5,

                    height:
                        1.4,

                  ),

            ),

          ),



        ],

      ),

    );

  }

}