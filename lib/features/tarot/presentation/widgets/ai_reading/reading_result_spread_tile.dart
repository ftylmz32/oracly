/// Compact result-spread tile sized by 7C projection (Phase 7E).
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/reading_typography.dart';
import 'reading_breathing_card_art.dart';
import 'reading_story_face.dart';

/// Fits [cardSize] + label chrome from settled projection (`tileSizeFor`).
class ReadingResultSpreadTile extends StatelessWidget {
  const ReadingResultSpreadTile({
    super.key,
    required this.spec,
    required this.cardSize,
  });

  final ReadingStoryFaceSpec spec;
  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${spec.name}, ${spec.position}, ${spec.orientation}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            spec.position,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(fontSize: 8),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: cardSize.width,
            height: cardSize.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(
                  color: OraclySignaturePalette.goldEngrave(0.72),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.md,
                child: Transform.rotate(
                  angle: spec.isReversed ? pi : 0,
                  child: ReadingBreathingCardArt(
                    imageAsset: spec.imageAsset,
                    rarityColor: spec.rarityColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
