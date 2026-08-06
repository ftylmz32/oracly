/// OR-1020 / OR-404 — Deck selection with intention ritual prelude.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../theme/tarot_tokens.dart';
import '../../domain/models/tarot_spread.dart';
import '../../shared/tarot_scope.dart';
import '../widgets/deck_selection/deck_selection_background.dart';
import '../widgets/deck_selection/deck_selection_data.dart';
import '../widgets/deck_selection/deck_selection_deck_card.dart';
import '../widgets/deck_selection/deck_selection_entrance.dart';
import '../widgets/deck_selection/deck_selection_footer.dart';
import '../widgets/deck_selection/deck_selection_header.dart';
import '../widgets/deck_selection/deck_selection_orb.dart';
import '../widgets/intention_selection/intention_selection_screen.dart';

/// Sacred deck catalogue — intention ritual, then deck instrument.
class DeckSelectionScreen extends ConsumerStatefulWidget {
  const DeckSelectionScreen({super.key});

  @override
  ConsumerState<DeckSelectionScreen> createState() =>
      _DeckSelectionScreenState();
}

class _DeckSelectionScreenState extends ConsumerState<DeckSelectionScreen> {
  String? _selectedDeckId;
  late bool _intentionSealed;

  @override
  void initState() {
    super.initState();
    _intentionSealed = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final topic = TarotScope.of(context).flow.intention.topic;
    if (topic != null && topic.isNotEmpty) {
      _intentionSealed = true;
    }
  }

  void _selectDeck(String id) {
    setState(() => _selectedDeckId = id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: TarotTokens.transitionMedium,
      switchInCurve: TarotTokens.revealCurve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: !_intentionSealed
          ? IntentionSelectionScreen(
              key: const ValueKey('intention'),
              onSealed: () => setState(() => _intentionSealed = true),
            )
          : OraclyScaffold(
              key: const ValueKey('deck'),
              backgroundOverlay: const DeckSelectionBackground(),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: TarotTokens.screenPadding.copyWith(
                        top: AppSpacing.md,
                        bottom: AppSpacing.lg,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: TarotTokens.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DeckSelectionEntrance(
                                delay: DeckSelectionStagger.header,
                                child: const DeckSelectionHeader(),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              DeckSelectionEntrance(
                                delay: DeckSelectionStagger.orb,
                                child: const Align(
                                  alignment: Alignment.center,
                                  child: TarotDeckSelectionOrb(),
                                ),
                              ),
                              SizedBox(height: AppSpacing.xl),
                              for (var i = 0;
                                  i < TarotDeckCatalogue.decks.length;
                                  i++) ...[
                                if (i > 0) SizedBox(height: AppSpacing.md),
                                DeckSelectionEntrance(
                                  delay: DeckSelectionStagger.deck(i),
                                  child: DeckSelectionDeckCard(
                                    deck: TarotDeckCatalogue.decks[i],
                                    restIndex: i,
                                    selected: _selectedDeckId ==
                                        TarotDeckCatalogue.decks[i].id,
                                    onTap: () =>
                                        _selectDeck(TarotDeckCatalogue.decks[i].id),
                                  ),
                                ),
                              ],
                              SizedBox(height: AppSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  DeckSelectionFooter(
                    enabled: _selectedDeckId != null,
                    onConfirm: () async {
                      if (_selectedDeckId == null) return;
                      ref.read(selectedDeckProvider.notifier).state =
                          _selectedDeckId;
                      await ref
                          .read(tarotServiceProvider)
                          .selectDeck(_selectedDeckId!);
                      if (!context.mounted) return;

                      final scope = TarotScope.of(context);
                      final spread = scope.flow.spread;
                      final spreadTitle =
                          ref.read(selectedSpreadProvider) ?? spread.label;
                      final spreadType =
                          TarotSpreadType.fromTitle(spreadTitle) ?? spread;

                      await scope.reading.beginSession(
                        spread: spreadType,
                        deckId: _selectedDeckId!,
                        intention: scope.flow.intention,
                      );
                      await scope.reading.advanceToShuffle();
                      if (!context.mounted) return;
                      OraclyNavigationService.openShuffle(context);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
