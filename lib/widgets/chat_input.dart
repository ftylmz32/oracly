import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';



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
              AppColors.background,



          border: Border(


            top: BorderSide(


              color:
                  AppColors.border,


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
                      AppColors.surface,



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
                            AppColors.white,


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
                                  AppColors.textSecondary,


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


                        AppColors.primary,


                        AppColors.primaryLight,


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
                              AppColors.white,



                        ),



                  ),



            ),




          ],



        ),



      ),



    );


  }

}