import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await dotenv.load(
    fileName: ".env",
  );


  runApp(
    const OraclyApp(),
  );

}



class OraclyApp extends StatelessWidget {

  const OraclyApp({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    return MaterialApp(

      debugShowCheckedModeBanner: false,


      title: 'Oracly',


      theme: AppTheme.dark,


      home: const SplashScreen(),


    );

  }

}