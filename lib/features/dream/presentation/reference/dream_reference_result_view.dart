/// Reference-aligned dream result — meaning, symbols, emotion, reflection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/reading_version/models/reading_version_kind.dart';
import '../../../../core/reading_version/services/reading_version_payload.dart';
import '../../../../core/reading_version/widgets/reading_version_host.dart';
import '../../../../core/reading_ux/reading_long_form_scroll.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../controllers/dream_analysis_controller.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream.dart';
import '../../services/dream_reading_presentation.dart';
import 'dream_reference_app_bar.dart';
import 'dream_reference_result_actions.dart';
import 'dream_reference_tokens.dart';
import 'dream_result_emotional_section.dart';
import 'dream_result_premium_card.dart';
import 'dream_result_reflection_card.dart';
import 'dream_result_reference_actions.dart';
import 'dream_result_summary_card.dart';
import 'dream_result_symbols_section.dart';

class DreamReferenceResultView extends ConsumerStatefulWidget {
  const DreamReferenceResultView({
    super.key,
    required this.controller,
    required this.onNewDream,
    this.onEditDream,
  });

  final DreamAnalysisController controller;
  final VoidCallback onNewDream;
  final VoidCallback? onEditDream;

  @override
  ConsumerState<DreamReferenceResultView> createState() =>
      _DreamReferenceResultViewState();
}

class _DreamReferenceResultViewState
    extends ConsumerState<DreamReferenceResultView> {
  Dream? _displayDream;

  @override
  void didUpdateWidget(covariant DreamReferenceResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.dream?.id != widget.controller.dream?.id ||
        oldWidget.controller.versionReloadToken !=
            widget.controller.versionReloadToken) {
      _displayDream = widget.controller.dream;
    }
  }

  @override
  void initState() {
    super.initState();
    _displayDream = widget.controller.dream;
  }

  @override
  Widget build(BuildContext context) {
    final dream = _displayDream ?? widget.controller.dream;
    if (dream == null) return const SizedBox.shrink();

    final meaning = DreamReadingPresentation.overallMeaning(dream) ?? '';
    final emotional = DreamReadingPresentation.emotionalReading(dream) ?? '';
    final symbols = DreamReadingPresentation.symbolRows(dream);
    final tags = DreamReadingPresentation.emotionalTags(dream);
    final reflection = DreamReadingPresentation.reflectionQuote(dream);
    final analysis = DreamReadingPresentation.interpretation(dream);

    return ReadingLongFormScroll(
      kicker: DreamCopy.screenTitle,
      padding: EdgeInsets.fromLTRB(
        DreamReferenceTokens.screenHorizontal,
        DreamReferenceTokens.screenTop,
        DreamReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        const DreamReferenceAppBar(),
        SizedBox(height: AppSpacing.md),
        DreamResultSummaryCard(
          dream: dream,
          onEdit: widget.onEditDream,
        ),
        SizedBox(height: AppSpacing.lg),
        if (meaning.isNotEmpty)
          DreamResultPremiumCard(
            title: DreamCopy.resultMeaningTitle,
            body: meaning,
            icon: Icons.star_outline_rounded,
          ),
        DreamResultSymbolsSection(rows: symbols),
        DreamResultEmotionalSection(body: emotional, tags: tags),
        DreamResultReflectionCard(
          quote: reflection ?? DreamCopy.reflectionGeneric,
        ),
        DreamResultReferenceActions(
          dream: dream,
          analysis: analysis.isNotEmpty ? analysis : meaning,
          onReinterpret: () async {
            await widget.controller.reinterpret();
            return widget.controller.lastVersionAdded;
          },
        ),
        SizedBox(height: AppSpacing.md),
        ReadingVersionHost(
          rootId: dream.id,
          kind: ReadingVersionKind.dream,
          reloadToken: widget.controller.versionReloadToken,
          onSelect: (group) {
            final entry = group.activeEntry;
            if (entry == null) return;
            final next = ReadingVersionPayload.applyDream(dream, entry.data);
            if (next == null) return;
            setState(() => _displayDream = next);
          },
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            DreamCopy.readingFootnote(fromAi: dream.fromAi),
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(),
          ),
        ),
        DreamReferenceResultActions(
          dream: dream,
          analysis: analysis.isNotEmpty ? analysis : meaning,
          onNewDream: widget.onNewDream,
          onReinterpret: () async {
            await widget.controller.reinterpret();
            return widget.controller.lastVersionAdded;
          },
          versionReloadToken: widget.controller.versionReloadToken,
        ),
      ],
    );
  }
}
