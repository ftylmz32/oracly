/// Destem — optional informational browser for all 78 cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../deck/oracly_tarot_card.dart';
import '../../deck/oracly_tarot_deck.dart';
import '../../deck/oracly_tarot_enums.dart';
import 'destem_card_detail_screen.dart';
import 'destem_copy.dart';
import 'destem_section.dart';
import 'destem_seen.dart';

class DestemScreen extends ConsumerWidget {
  const DestemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readingHistoryProvider);
    return OraclyScaffold(
      safeArea: false,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OraclyChrome.screenSide,
            OraclyChrome.screenTop,
            OraclyChrome.screenSide,
            0,
          ),
          child: Column(
            children: [
              OraclyAppBar(
                title: DestemCopy.title,
                titleIcon: Icons.style_outlined,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: Text(
                  DestemCopy.subtitle,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.opening(
                    color: OraclyChrome.cream.withValues(alpha: 0.62),
                  ),
                ),
              ),
              Expanded(
                child: history.when(
                  loading: () => const OraclyCinematicLoading(compact: true),
                  error: (_, _) => _body(context, const {}),
                  data: (readings) => _body(
                    context,
                    DestemSeen.fromReadings(readings),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Set<String> seenIds) {
    return OraclyAdaptiveScrollView(
      padding: EdgeInsets.only(
        bottom: AppLayout.scrollBottomInset(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DestemSection(
            title: DestemCopy.sectionMajor,
            cards: OraclyTarotDeck.majorArcana,
            seenIds: seenIds,
            onOpen: (card) => _open(context, card, seenIds),
          ),
          for (final suit in const [
            OraclyTarotSuit.wands,
            OraclyTarotSuit.cups,
            OraclyTarotSuit.swords,
            OraclyTarotSuit.pentacles,
          ])
            DestemSection(
              title: DestemCopy.suitSection(suit),
              cards: OraclyTarotDeck.bySuit(suit),
              seenIds: seenIds,
              onOpen: (card) => _open(context, card, seenIds),
            ),
        ],
      ),
    );
  }

  void _open(
    BuildContext context,
    OraclyTarotCard card,
    Set<String> seenIds,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DestemCardDetailScreen(
          card: card,
          seen: seenIds.contains(card.id),
        ),
      ),
    );
  }
}
