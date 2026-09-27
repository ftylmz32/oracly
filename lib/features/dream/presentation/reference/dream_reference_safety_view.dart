/// Dream Phase 3 — local safety guidance in the Dream chamber. Not a
/// reading: no symbols, cards, versions, favorites, share or AI footnote.
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/oracly_error_state.dart';
import '../../safety/dream_safety_presentation.dart';

class DreamReferenceSafetyView extends StatelessWidget {
  const DreamReferenceSafetyView({
    super.key,
    required this.presentation,
    required this.onEdit,
    required this.onNewDream,
  });

  final DreamSafetyPresentation presentation;
  final VoidCallback onEdit;
  final VoidCallback onNewDream;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Semantics(
            liveRegion: true,
            child: OraclyErrorState(
              title: presentation.title,
              message: presentation.body,
              retryLabel: presentation.editLabel,
              onRetry: onEdit,
              secondaryLabel: presentation.newDreamLabel,
              onSecondary: onNewDream,
            ),
          ),
        ),
      ),
    );
  }
}
