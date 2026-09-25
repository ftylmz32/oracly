/// Result spread visual — 7C geometry authority, static layout (Phase 7E).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../domain/models/tarot_spread.dart';
import '../../../ritual/geometry/tarot_spread_geometry_projection.dart';
import '../../../ritual/geometry/tarot_spread_geometry_resolver.dart';
import '../../../ritual/geometry/tarot_spread_visual_kind.dart';
import 'ai_reading_content.dart';
import 'reading_arrive.dart';
import 'reading_result_spread_tile.dart';
import 'reading_sacred_rhythm.dart';
import 'reading_story_face.dart';
import 'reading_story_strip.dart';

class ReadingResultSpread extends StatelessWidget {
  const ReadingResultSpread({
    super.key,
    required this.content,
    required this.progress,
    this.spread,
    this.exitProgress = 0,
    this.showSpreadLabel = false,
  });

  final AiReadingContent content;
  final TarotSpreadType? spread;
  final double progress;
  final double exitProgress;

  /// Prefer false when header already shows spread identity.
  final bool showSpreadLabel;

  @override
  Widget build(BuildContext context) {
    final type = spread;
    if (type == null || type.cardCount <= 1) {
      return ReadingStoryStrip(
        content: content,
        progress: progress,
        exitProgress: exitProgress,
        showSpreadLabel: showSpreadLabel,
      );
    }
    final kind = TarotSpreadGeometryResolver.kindFor(type);
    if (kind == TarotSpreadVisualKind.seven ||
        kind == TarotSpreadVisualKind.celticCross) {
      return ReadingStoryStrip(
        content: content,
        progress: progress,
        exitProgress: exitProgress,
        showSpreadLabel: showSpreadLabel,
      );
    }
    return _GeometrySpread(
      content: content,
      spread: type,
      kind: kind,
      progress: progress,
      exitProgress: exitProgress,
    );
  }
}

class _GeometrySpread extends StatelessWidget {
  const _GeometrySpread({
    required this.content,
    required this.spread,
    required this.kind,
    required this.progress,
    required this.exitProgress,
  });

  final AiReadingContent content;
  final TarotSpreadType spread;
  final TarotSpreadVisualKind kind;
  final double progress;
  final double exitProgress;

  @override
  Widget build(BuildContext context) {
    final faces = ReadingStoryFaceSpec.of(content);
    final opacity = (progress * (1 - exitProgress)).clamp(0.0, 1.0);
    final spec = TarotSpreadGeometryResolver.resolve(spread);

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.only(
          top: ReadingSacredRhythm.afterCard,
          bottom: CraftsmanshipRhythm.betweenActs * 0.25,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fieldH =
                TarotSpreadSettledProjection.fieldHeightFor(kind, width);
            final field = Size(width, fieldH);
            final cardSize = TarotSpreadSettledProjection.cardSizeFor(
              kind: kind,
              fieldWidth: width,
              fieldHeight: fieldH,
            );
            final tile = TarotSpreadSettledProjection.tileSizeFor(cardSize);
            return SizedBox(
              width: width,
              height: fieldH,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var i = 0;
                      i < faces.length && i < spec.slots.length;
                      i++)
                    Positioned.fromRect(
                      rect: TarotSpreadSettledProjection.rectFor(
                        spec.slots[i],
                        field,
                        tile,
                      ),
                      child: ReadingStoryArrive(
                        index: i,
                        count: faces.length,
                        master: progress,
                        child: ReadingResultSpreadTile(
                          spec: faces[i],
                          cardSize: cardSize,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
