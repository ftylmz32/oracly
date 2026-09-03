/// Phase 2 — Dedicated intention ritual (reuses domain captureIntention).
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../domain/models/tarot_spread.dart';
import '../../presentation/widgets/intention_selection/intention_question_field.dart';
import '../../presentation/widgets/intention_selection/intention_selection_background.dart';
import '../../reading/reading_question.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';

class TarotRitualIntentionScreen extends StatefulWidget {
  const TarotRitualIntentionScreen({super.key});

  @override
  State<TarotRitualIntentionScreen> createState() =>
      _TarotRitualIntentionScreenState();
}

class _TarotRitualIntentionScreenState extends State<TarotRitualIntentionScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue({required bool skip}) {
    final text = skip ? '' : ReadingQuestion.sanitize(_controller.text);
    TarotScope.of(context).flow.captureIntention(
          TarotIntention(text: text, topic: 'general'),
        );
    OraclyNavigationService.openTarotModuleRoute(
      context,
      TarotRoutes.spreadSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const IntentionSelectionBackground(),
      child: SafeArea(
        child: Padding(
          padding: TarotTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                OraclyL10n.t('tarot.ritual.intention_title'),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OraclyL10n.t('tarot.ritual.intention_sub'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              IntentionQuestionField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                onExampleTap: (t) {
                  _controller.text = t;
                  setState(() {});
                },
              ),
              const Spacer(),
              OraclyButton(
                text: OraclyL10n.t('tarot.ritual.pick_spread'),
                isExpanded: true,
                onPressed: () => _continue(skip: false),
              ),
              TextButton(
                onPressed: () => _continue(skip: true),
                child: Text(
                  OraclyL10n.t('tarot.ritual.intention_skip'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
