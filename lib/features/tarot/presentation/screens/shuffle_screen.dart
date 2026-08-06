/// OR-1170 — Cinematic shuffle ritual screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../widgets/card_selection/card_selection_background.dart';
import '../widgets/shuffle/shuffle_ritual_experience.dart';
import 'card_selection_screen.dart';

/// Standalone shuffle route — shared background + ritual sequence.
class ShuffleScreen extends StatefulWidget {
  const ShuffleScreen({super.key});

  @override
  State<ShuffleScreen> createState() => _ShuffleScreenState();
}

class _ShuffleScreenState extends State<ShuffleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TarotScope.of(context).reading.performShuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CardSelectionBackground(),
            ShuffleRitualExperience(
              onComplete: () {
                Navigator.of(context).pushReplacement(
                  cardSelectionRitualRoute<void>(
                    page: const CardSelectionScreen(),
                    settings: const RouteSettings(name: TarotRoutes.cardSelection),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
