import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/hero_orb.dart';

import '../../services/greeting_service.dart';
import '../../services/profile_service.dart';

import '../ai/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';



class HomeScreen extends StatefulWidget {

  const HomeScreen({
    super.key,
  });


  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();

}





class _HomeScreenState extends State<HomeScreen> {


  final GreetingService _greetingService =
      GreetingService();


  final ProfileService _profileService =
      ProfileService();




  String _greeting =
      "👋 Merhaba";


  String _message =
      "Bugün seni neler bekliyor keşfetmeye hazır mısın?";






  @override
  void initState() {

    super.initState();

    _loadGreeting();

  }







  Future<void> _loadGreeting() async {


    final profile =
        await _profileService.getProfile();



    final name =
        profile["name"]?.toString().trim();



    final userName =
        (name == null || name.isEmpty)
            ? "Oracly kullanıcısı"
            : name;




    if (!mounted) return;



    setState(() {


      _greeting =
          _greetingService.getGreeting(
            userName,
          );


      _message =
          _greetingService.getMessage();


    });


  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(

  backgroundColor:
      AppColors.background,


  body: CosmicBackground(

    child: SafeArea(

      child: SingleChildScrollView(

        padding:
            const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,


          children: [


            const Center(

              child: HeroOrb(

                size: 190,

              ),

            ),


            const SizedBox(
              height: 25,
            ),



            Text(

              "ORACLY",

              style:
                  AppTextStyles.logo,

            ),



            const SizedBox(
              height: 6,
            ),



            const Text(

              "AI Mystic Companion",

              style: TextStyle(

                color:
                    AppColors.textSecondary,

                fontSize:
                    16,

              ),

            ),



            const SizedBox(
              height: 32,
            ),



            GlassCard(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,


                children: [


                  Text(

                    _greeting,

                    style:
                        AppTextStyles.heading,

                  ),



                  const SizedBox(
                    height: 10,
                  ),



                  Text(

                    _message,

                    style:
                        AppTextStyles.body,

                  ),


                ],

              ),

            ),



            const SizedBox(
              height: 20,
            ),



            const GlassCard(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,


                children: [


                  Text(

                    "✨ Günün Enerjisi",

                    style:
                        AppTextStyles.heading,

                  ),



                  SizedBox(
                    height: 12,
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
                    height: 12,
                  ),



                  Text(

                    "%82 Ruhsal Enerji",

                    style:
                        AppTextStyles.caption,

                  ),


                ],

              ),

            ),



            const SizedBox(
              height: 24,
            ),



            FeatureCard(

              icon:
                  Icons.smart_toy_rounded,

              title:
                  "AI Danışman",

              subtitle:
                  "Merak ettiklerini bana sor.",


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
                  "Profil",

              subtitle:
                  "Bilgilerini ve hafızanı yönet.",


              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        ProfileScreen(),

                  ),

                );

              },

            ),



            FeatureCard(

              icon:
                  Icons.settings_rounded,

              title:
                  "Ayarlar",

              subtitle:
                  "Uygulama ve veri ayarlarını yönet.",


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
                  "Astroloji",

              subtitle:
                  "Günlük burç yorumlarını keşfet.",

              onTap: () {},

            ),



            FeatureCard(

              icon:
                  Icons.nightlight_round,

              title:
                  "Rüya Analizi",

              subtitle:
                  "Rüyalarının anlamını öğren.",

              onTap: () {},

            ),



            FeatureCard(

              icon:
                  Icons.style,

              title:
                  "Tarot",

              subtitle:
                  "Kartların sana ne söylediğini keşfet.",

              onTap: () {},

            ),


          ],


        ),

      ),

    ),

  ),

);
  }
}