/// OR-030 / OR-1030 — Premium Tarot home screen with shuffle ritual.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../presentation/screens/card_selection_screen.dart';
import '../presentation/widgets/shuffle/shuffle_ritual_experience.dart';
import '../shared/constants/tarot_routes.dart';
import '../widgets/tarot_cinematic_background.dart';
import '../widgets/tarot_home_hero.dart';
import '../widgets/tarot_home_setup.dart';
import '../widgets/tarot_screen_header.dart';

/// Tarot tab root — premium setup screen with cinematic shuffle entry.
class TarotSelectScreen extends StatefulWidget {
  const TarotSelectScreen({super.key});

  @override
  State<TarotSelectScreen> createState() => _TarotSelectScreenState();
}

class _TarotSelectScreenState extends State<TarotSelectScreen> {
  bool _shuffling = false;

  void _beginShuffle() {
    if (_shuffling) return;
    setState(() => _shuffling = true);
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const TarotCinematicBackground(
        child: SizedBox.shrink(),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _shuffling ? 0 : 1,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOutCubic,
            child: IgnorePointer(
              ignoring: _shuffling,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: AppSpacing.screenHorizontal.copyWith(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TarotSelectHeader(),
                        SizedBox(height: AppSpacing.sm),
                        const TarotHomeHero(),
                        SizedBox(height: AppSpacing.lg + AppSpacing.xs),
                        TarotHomeSetup(onShuffle: _beginShuffle),
                        SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_shuffling)
            ShuffleRitualExperience(
              includeBackgroundDim: true,
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
    );
  }
}
