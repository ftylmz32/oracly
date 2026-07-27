import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/feature_card.dart';

import '../ai/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';



class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:
          AppColors.background,



      body: SafeArea(


        child: SingleChildScrollView(


          padding:
              const EdgeInsets.all(20),



          child: Column(



            crossAxisAlignment:
                CrossAxisAlignment.start,



            children: [



              Text(

                'ORACLY',

                style:
                    AppTextStyles.logo,

              ),




              const SizedBox(
                height:6,
              ),




              const Text(

                'AI Mystic Companion',

                style:
                    TextStyle(

                      color:
                          AppColors.textSecondary,


                      fontSize:
                          16,

                    ),

              ),





              const SizedBox(
                height:32,
              ),





              const GlassCard(

                child: Column(


                  crossAxisAlignment:
                      CrossAxisAlignment.start,



                  children: [



                    Text(

                      '👋 Günaydın',

                      style:
                          AppTextStyles.heading,

                    ),



                    SizedBox(
                      height:10,
                    ),



                    Text(

                      'Bugün sezgilerin oldukça güçlü görünüyor.\n'
                      'Kendine güven ve iç sesini dinle.',


                      style:
                          AppTextStyles.body,

                    ),



                  ],


                ),

              ),





              const SizedBox(
                height:20,
              ),






              const GlassCard(


                child: Column(


                  crossAxisAlignment:
                      CrossAxisAlignment.start,



                  children: [



                    Text(

                      '✨ Günün Enerjisi',

                      style:
                          AppTextStyles.heading,

                    ),




                    SizedBox(
                      height:12,
                    ),




                    LinearProgressIndicator(

                      value:
                          0.82,


                      minHeight:
                          10,


                      borderRadius:
                          BorderRadius.all(

                            Radius.circular(20),

                          ),


                      backgroundColor:
                          AppColors.surface,


                      valueColor:
                          AlwaysStoppedAnimation<Color>(

                            AppColors.gold,

                          ),

                    ),




                    SizedBox(
                      height:12,
                    ),




                    Text(

                      '%82 Ruhsal Enerji',

                      style:
                          AppTextStyles.caption,

                    ),



                  ],


                ),


              ),





              const SizedBox(
                height:24,
              ),






              FeatureCard(

                icon:
                    Icons.smart_toy_rounded,


                title:
                    'AI Danışman',


                subtitle:
                    'Merak ettiklerini bana sor.',



                onTap: () {


                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>
                          const ChatScreen(),

                    ),

                  );


                },


              ),





              FeatureCard(

                icon:
                    Icons.person_rounded,


                title:
                    'Profil',



                subtitle:
                    'Bilgilerini ve hafızanı yönet.',



                onTap: () {


                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>
                          const ProfileScreen(),

                    ),

                  );


                },


              ),






              FeatureCard(

                icon:
                    Icons.settings_rounded,


                title:
                    'Ayarlar',


                subtitle:
                    'Uygulama ve veri ayarlarını yönet.',



                onTap: () {


                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>
                          const SettingsScreen(),

                    ),

                  );


                },


              ),






              FeatureCard(

                icon:
                    Icons.auto_awesome,


                title:
                    'Astroloji',


                subtitle:
                    'Günlük burç yorumlarını keşfet.',


                onTap:(){},


              ),





              FeatureCard(

                icon:
                    Icons.nightlight_round,


                title:
                    'Rüya Analizi',


                subtitle:
                    'Rüyalarının anlamını öğren.',


                onTap:(){},


              ),





              FeatureCard(

                icon:
                    Icons.style,


                title:
                    'Tarot',


                subtitle:
                    'Kartların sana ne söylediğini keşfet.',


                onTap:(){},


              ),



            ],


          ),


        ),


      ),


    );


  }

}