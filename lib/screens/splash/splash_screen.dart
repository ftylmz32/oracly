import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../app/providers/app_providers.dart';

import '../../core/navigation/oracly_page_transitions.dart';

import '../../core/theme/app_colors.dart';

import '../../core/theme/app_text_styles.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

import '../../shared/navigation/oracly_navigation.dart';

import '../../widgets/cosmic_background.dart';



class SplashScreen extends ConsumerStatefulWidget {

  const SplashScreen({super.key});



  @override

  ConsumerState<SplashScreen> createState() => _SplashScreenState();

}



class _SplashScreenState extends ConsumerState<SplashScreen>

    with SingleTickerProviderStateMixin {

  late final AnimationController _fade;



  @override

  void initState() {

    super.initState();

    _fade = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 1200),

    )..forward();

    _bootstrap();

  }



  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait<dynamic>([
        ref.read(onboardingRepositoryProvider).isCompleted(),
        Future<void>.delayed(const Duration(milliseconds: 820)),
      ]);
      if (!mounted) return;

      final completed = results[0] as bool;
      final destination = completed
          ? const OraclyAppShell()
          : const OnboardingScreen();

      Navigator.pushReplacement(
        context,
        OraclyPageTransitions.fade(page: destination),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        OraclyPageTransitions.fade(page: const OraclyAppShell()),
      );
    }
  }



  @override

  void dispose() {

    _fade.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return CosmicBackground(

      showHeroGlow: true,

      child: Scaffold(

        backgroundColor: Colors.transparent,

        body: Center(

          child: FadeTransition(

            opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                Transform.translate(
                  offset: const Offset(-1.5, 0.8),
                  child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.22, -0.28),
                      colors: [
                        AppColors.goldLight.withValues(alpha: 0.14),
                        AppColors.transparent,
                      ],
                    ),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        blurRadius: 32,
                      ),
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.15),
                        blurRadius: 48,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 42,
                    color: AppColors.goldLight.withValues(alpha: 0.95),
                  ),
                ),
                ),

                const SizedBox(height: 32),

                Text('ORACLY', style: AppTextStyles.logo),

                const SizedBox(height: 12),

                Text(

                  'Bir an dur. Kendini dinle.',

                  style: AppTextStyles.caption.copyWith(

                    letterSpacing: 2.4,

                    fontSize: 13,

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

