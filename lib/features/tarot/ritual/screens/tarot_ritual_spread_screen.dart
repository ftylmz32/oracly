/// Phase 3 — Premium isolated spread selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../domain/models/tarot_spread.dart';
import '../../economy/tarot_economy.dart';
import '../../../gems/services/gem_spend_guard.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../widgets/ritual_spread_choice_card.dart';

class TarotRitualSpreadScreen extends ConsumerStatefulWidget {
  const TarotRitualSpreadScreen({super.key});

  @override
  ConsumerState<TarotRitualSpreadScreen> createState() =>
      _TarotRitualSpreadScreenState();
}

class _TarotRitualSpreadScreenState
    extends ConsumerState<TarotRitualSpreadScreen> {
  TarotSpreadType? _selected;

  static const _options = [
    TarotSpreadType.single,
    TarotSpreadType.threeCard,
    TarotSpreadType.fiveCard,
  ];

  Future<void> _confirm(TarotSpreadType spread) async {
    final allowed = GemSpendGuard.ensureAffordable(
      ref,
      context: context,
      cost: TarotEconomy.costFor(spread),
    );
    if (!allowed || !mounted) return;
    TarotScope.of(context).flow.selectSpread(spread);
    ref.read(selectedSpreadProvider.notifier).state = spread.label;
    OraclyNavigationService.openTarotModuleRoute(
      context,
      TarotRoutes.deckSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      child: SafeArea(
        child: Padding(
          padding: TarotTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                OraclyL10n.t('tarot.step.reveal'),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OraclyL10n.t('tarot.ritual.spread_sub'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final s = _options[i];
                    return RitualSpreadChoiceCard(
                      spread: s,
                      selected: _selected == s,
                      onTap: () {
                        setState(() => _selected = s);
                        _confirm(s);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
