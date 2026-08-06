/// OR-404 — Premium intention ritual screen (visual experience).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/oracly_scaffold.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../shared/tarot_scope.dart';
import '../../../theme/tarot_tokens.dart';
import '../tarot_home/tarot_home_ornaments.dart';
import '../tarot_home/tarot_home_section_bridge.dart';
import 'intention_selection_background.dart';
import 'intention_selection_data.dart';
import 'intention_selection_footer.dart';
import 'intention_selection_header.dart';
import 'intention_topic_tile.dart';

/// Sacred intention selection — emotional prelude to the tarot ritual.
class IntentionSelectionScreen extends StatefulWidget {
  const IntentionSelectionScreen({
    super.key,
    required this.onSealed,
  });

  final VoidCallback onSealed;

  @override
  State<IntentionSelectionScreen> createState() =>
      _IntentionSelectionScreenState();
}

class _IntentionSelectionScreenState extends State<IntentionSelectionScreen> {
  String? _selectedId;

  void _selectTopic(IntentionTopicOption option) {
    setState(() => _selectedId = option.id);
    TarotScope.of(context).flow.setIntention(
          TarotIntention(text: option.title, topic: option.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const IntentionSelectionBackground(),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: TarotTokens.screenPadding.copyWith(
                top: AppSpacing.xl,
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
                      const IntentionSelectionHeader(),
                      SizedBox(height: AppSpacing.xl),
                      const TarotHomeSectionBridge(
                        kind: TarotHomeBridgeKind.purpleMist,
                      ),
                      SizedBox(height: AppSpacing.lg),
                      for (var row = 0; row < 2; row++) ...[
                        if (row > 0) SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var col = 0; col < 2; col++) ...[
                              if (col > 0) SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: IntentionTopicTile(
                                  option: IntentionTopicCatalogue
                                      .topics[row * 2 + col],
                                  selected: _selectedId ==
                                      IntentionTopicCatalogue
                                          .topics[row * 2 + col].id,
                                  onTap: () => _selectTopic(
                                    IntentionTopicCatalogue
                                        .topics[row * 2 + col],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      SizedBox(height: AppSpacing.lg),
                      Center(
                        child: SizedBox(
                          width: (TarotTokens.maxContentWidth - AppSpacing.lg) / 2,
                          child: IntentionTopicTile(
                            option: IntentionTopicCatalogue.topics[4],
                            selected:
                                _selectedId == IntentionTopicCatalogue.topics[4].id,
                            onTap: () =>
                                _selectTopic(IntentionTopicCatalogue.topics[4]),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      const TarotHomeGoldDivider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IntentionSelectionFooter(
            enabled: _selectedId != null,
            onConfirm: widget.onSealed,
          ),
        ],
      ),
    );
  }
}
