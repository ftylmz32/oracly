/// Quiet distinction: sign reading is not a natal chart.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/preview_capability_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';

class AstrologyReferenceKindNote extends StatelessWidget {
  const AstrologyReferenceKindNote({
    super.key,
    this.compact = false,
    this.basisNote = '',
  });

  final bool compact;

  /// What a personal reading was calculated from; replaces the sun-sign note.
  final String basisNote;

  /// Chamber honesty label — not a Preview availability badge.
  static String get label => PreviewCapabilityCopy.astrologyLabel;
  static String get detail => PreviewCapabilityCopy.astrologyDetail;

  @override
  Widget build(BuildContext context) {
    return Text(
      compact
          ? PreviewCapabilityCopy.astrologyLabel
          : (basisNote.isNotEmpty ? basisNote : detail),
      textAlign: compact ? TextAlign.center : TextAlign.start,
      style: ReadingTypography.footnote(
        color: OraclyChrome.cream.withValues(
          alpha: compact
              ? CraftsmanshipRhythm.secondaryInk
              : CraftsmanshipRhythm.labelInk,
        ),
      ),
    );
  }
}
