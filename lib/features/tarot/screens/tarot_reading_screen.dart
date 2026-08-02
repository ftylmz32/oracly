import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/cosmic_background.dart';
import '../../../widgets/glass_card.dart';
import '../models/tarot_card.dart';
import '../services/tarot_ai_service.dart';
import '../widgets/tarot_reading_section.dart';
import '../widgets/tarot_result_cards.dart';

class TarotReadingScreen extends StatefulWidget {
  final List<TarotCard> cards;
  final String intention;

  const TarotReadingScreen({
    super.key,
    required this.cards,
    required this.intention,
  });

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final TarotAiService _tarotAiService = TarotAiService();

  bool _loading = true;
  String _reading = '';

  @override
  void initState() {
    super.initState();
    _generateReading();
  }

  Future<void> _generateReading() async {
    final reading = await _tarotAiService.generateReading(
      cards: widget.cards,
      intention: widget.intention,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _reading = reading;
    });
  }

  String get _intentionLabel {
    final text = widget.intention.trim();
    return text.isEmpty ? 'Belirtilmedi' : text;
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
          'Tarot Yorumu',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Text(
                    'Niyetin · $_intentionLabel',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Açılan kart',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TarotResultCards(
                      cards: widget.cards,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Kehanet',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: TarotReadingSection(
                    loading: _loading,
                    reading: _reading,
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
