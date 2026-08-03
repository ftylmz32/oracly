import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/tarot_select_phase.dart';
import '../widgets/tarot_deck_stage.dart';
import '../widgets/tarot_setup_panel.dart';

class TarotSelectScreen extends StatefulWidget {
  const TarotSelectScreen({super.key});

  @override
  State<TarotSelectScreen> createState() =>
      _TarotSelectScreenState();
}

class _TarotSelectScreenState extends State<TarotSelectScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _intentionController =
      TextEditingController();

  TarotSelectPhase _phase = TarotSelectPhase.idle;
  int _spread = 1;
  late final AnimationController _alignController;

  static const _alignDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _alignController = AnimationController(
      vsync: this,
      duration: _alignDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _phase = TarotSelectPhase.ready);
        }
      });
  }

  @override
  void dispose() {
    _alignController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  void _startShuffle() {
    if (!_phase.canEditSetup) return;
    _alignController.reset();
    setState(() => _phase = TarotSelectPhase.shuffling);
  }

  void _onShuffleComplete() {
    if (!mounted) return;
    setState(() => _phase = TarotSelectPhase.aligning);
    _alignController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tarot',
          style: AppTextStyles.caption.copyWith(
            letterSpacing: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.background,
              AppColors.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TarotSetupPanel(
                  intentionController: _intentionController,
                  spread: _spread,
                  phase: _phase,
                  onSpreadChanged: (v) => setState(() => _spread = v),
                  onShuffle: _startShuffle,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: TarotDeckStage(
                      phase: _phase,
                      spread: _spread,
                      alignAnimation: _alignController,
                      onShuffleComplete: _onShuffleComplete,
                    ),
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
