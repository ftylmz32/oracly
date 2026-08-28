/// OR-404 / TAROT V2 — optional intention before cards are revealed.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/oracly_scaffold.dart';
import '../../../../../shared/widgets/oracly_text_action.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../reading/reading_question.dart';
import '../../../shared/tarot_scope.dart';
import '../../../theme/tarot_tokens.dart';
import '../tarot_flow_progress.dart';
import '../tarot_home/tarot_home_ornaments.dart';
import 'intention_question_field.dart';
import 'intention_selection_background.dart';
import 'intention_selection_footer.dart';
import 'intention_selection_header.dart';

/// Optional question — skip still continues the reading.
class IntentionSelectionScreen extends StatefulWidget {
  const IntentionSelectionScreen({
    super.key,
    required this.onSealed,
    this.initialText,
  });

  final VoidCallback onSealed;
  final String? initialText;

  @override
  State<IntentionSelectionScreen> createState() =>
      _IntentionSelectionScreenState();
}

class _IntentionSelectionScreenState extends State<IntentionSelectionScreen> {
  late final TextEditingController _controller;
  String? _topic;
  bool _sealed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final intention = TarotScope.maybeOf(context)?.flow.intention;
    _topic = intention?.topic;
    if (intention != null &&
        _controller.text.isEmpty &&
        intention.text.isNotEmpty) {
      _controller.text = intention.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String text) {
    if (_sealed) return;
    setState(() => _sealed = true);
    TarotScope.maybeOf(context)?.flow.setIntention(
          TarotIntention(text: ReadingQuestion.sanitize(text), topic: _topic),
        );
    widget.onSealed();
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const IntentionSelectionBackground(),
      child: Column(
        children: [
          const TarotFlowProgress(step: TarotRitualStep.intention),
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
                      const IntentionSelectionHeader(),
                      SizedBox(height: AppSpacing.lg),
                      IntentionQuestionField(
                        controller: _controller,
                        onChanged: (_) => setState(() {}),
                        onExampleTap: (example) {
                          _controller.text = example;
                          _controller.selection = TextSelection.collapsed(
                            offset: example.length,
                          );
                          setState(() {});
                        },
                      ),
                      SizedBox(height: AppSpacing.lg),
                      const TarotHomeGoldDivider(),
                      SizedBox(height: AppSpacing.md),
                      OraclyTextAction(
                        label: TarotPolishCopy.skipIntention,
                        onPressed: _sealed ? null : () => _commit(''),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IntentionSelectionFooter(
            enabled: !_sealed,
            onConfirm: _sealed ? null : () => _commit(_controller.text),
          ),
        ],
      ),
    );
  }
}
