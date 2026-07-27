import 'dart:async';

import 'package:flutter/material.dart';

import '../home/home_screen.dart';



class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();

}



class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {

    super.initState();


    Timer(

      const Duration(seconds: 2),

      () {

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) =>
                const HomeScreen(),

          ),

        );

      },

    );

  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
          Colors.black,


      body: Center(


        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [



            Container(

              width:100,

              height:100,


              decoration: BoxDecoration(

                shape:
                    BoxShape.circle,

                border:

                    Border.all(

                      color:
                          Colors.white24,

                      width:2,

                    ),

              ),


              child: const Center(

                child: Icon(

                  Icons.auto_awesome,

                  size:50,

                  color:
                      Colors.white,

                ),

              ),

            ),




            const SizedBox(height:30),




            const Text(

              "ORACLY",

              style: TextStyle(

                color:
                    Colors.white,

                fontSize:40,

                fontWeight:
                    FontWeight.bold,

                letterSpacing:
                    6,

              ),

            ),




            const SizedBox(height:10),




            const Text(

              "AI Mystic Companion",

              style: TextStyle(

                color:
                    Colors.white54,

                fontSize:16,

                letterSpacing:2,

              ),

            ),




          ],

        ),

      ),

    );

  }

}