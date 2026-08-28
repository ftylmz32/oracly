/// Story of the dream, then editorial interpretation sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/chamber_narrative_block.dart';
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
import 'dream_result_hero.dart';
import 'dream_result_section_card.dart';

class DreamReferenceResultView extends ConsumerStatefulWidget {
  const DreamReferenceResultView({
    super.key,
    required this.controller,
    required this.onNewDream,
  });

  final DreamAnalysisController controller;
  final VoidCallback onNewDream;

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
    final story = DreamReadingPresentation.story(dream);
    final reading = DreamReadingPresentation.interpretation(dream);
    final sections = DreamReadingPresentation.sections(dream);

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
        SizedBox(height: DreamReferenceTokens.headerToIllustration),
        DreamResultHero(dream: dream),
        SizedBox(height: AppSpacing.lg),
        for (final section in sections) DreamResultSectionCard(section: section),
        if (sections.isEmpty && reading.isNotEmpty)
          ChamberNarrativeBlock(body: reading),
        if (dream != null)
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
            DreamCopy.readingFootnote(fromAi: dream?.fromAi ?? false),
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        DreamReferenceResultActions(
          dream: dream,
          analysis: reading.isNotEmpty ? reading : story,
          onNewDream: widget.onNewDream,
          onReinterpret: dream == null
              ? null
              : () async {
                  await widget.controller.reinterpret();
                  return widget.controller.lastVersionAdded;
                },
          versionReloadToken: widget.controller.versionReloadToken,
        ),
      ],
    );
  }
}
