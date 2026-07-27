import '../../widgets/feature_card.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const OraclyApp());
}

class OraclyApp extends StatelessWidget {
  const OraclyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oracly',
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}