/// Phase 4 — One Oracly deck ready; begins session then opens ritual.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../presentation/screens/deck_selection_start.dart';
import '../../presentation/widgets/deck_selection/deck_selection_data.dart';
import '../../theme/tarot_tokens.dart';
import '../deck_visual_state.dart';
import '../widgets/ritual_deck_stack.dart';

class TarotRitualDeckReadyScreen extends ConsumerStatefulWidget {
  const TarotRitualDeckReadyScreen({super.key});

  @override
  ConsumerState<TarotRitualDeckReadyScreen> createState() =>
      _TarotRitualDeckReadyScreenState();
}

class _TarotRitualDeckReadyScreenState
    extends ConsumerState<TarotRitualDeckReadyScreen> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final ok = await DeckSelectionStart.confirm(
      context: context,
      ref: ref,
      deckId: TarotDeckCatalogue.activeId,
    );
    if (mounted && !ok) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      child: SafeArea(
        child: Padding(
          padding: TarotTokens.screenPadding,
          child: Column(
            children: [
              const Spacer(),
              const RitualDeckStack(
                visual: DeckVisualState(stackDepth: 1),
                layers: 6,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                OraclyL10n.t('tarot.ritual.deck_ready'),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OraclyL10n.t('tarot.ritual.deck_ready_sub'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              OraclyButton(
                text: OraclyL10n.t('tarot.continue'),
                isExpanded: true,
                isLoading: _starting,
                onPressed: _starting ? null : _start,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
