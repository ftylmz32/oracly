/// Gold glyph disc for interpretation lanes — icon language, not emoji.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/astrology_presentation_copy.dart';

enum AstrologyContentLaneKind { love, work, inner }

abstract final class AstrologyContentLaneMeta {
  AstrologyContentLaneMeta._();

  static String title(AstrologyContentLaneKind kind) => switch (kind) {
        AstrologyContentLaneKind.love => AstrologyPresentationCopy.laneLove,
        AstrologyContentLaneKind.work => AstrologyPresentationCopy.laneWork,
        AstrologyContentLaneKind.inner => AstrologyPresentationCopy.laneInner,
      };

  static IconData icon(AstrologyContentLaneKind kind) => switch (kind) {
        AstrologyContentLaneKind.love => AppIcons.star,
        AstrologyContentLaneKind.work => AppIcons.energy,
        AstrologyContentLaneKind.inner => AppIcons.moon,
      };
}

class AstrologyContentLaneGlyph extends StatelessWidget {
  const AstrologyContentLaneGlyph({
    super.key,
    required this.kind,
    this.size = 34,
  });

  final AstrologyContentLaneKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.46;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: OraclyChrome.goldLight.withValues(alpha: 0.62),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.28),
            OraclyChrome.violet.withValues(alpha: 0.36),
            OraclyChrome.deepNavy.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: OraclyChrome.goldMuted.withValues(alpha: 0.35),
                  width: 0.7,
                ),
              ),
              child: SizedBox(width: size * 0.78, height: size * 0.78),
            ),
            Icon(
              AstrologyContentLaneMeta.icon(kind),
              size: iconSize,
              color: OraclyChrome.goldLight.withValues(alpha: 0.96),
            ),
          ],
        ),
      ),
    );
  }
}

class AstrologyContentHeader extends StatelessWidget {
  const AstrologyContentHeader({
    super.key,
    required this.kind,
    this.compact = false,
  });

  final AstrologyContentLaneKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = AstrologyContentLaneMeta.title(kind);
    return Row(
      children: [
        AstrologyContentLaneGlyph(
          kind: kind,
          size: compact ? 30 : 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.94),
              fontSize: compact ? 10.5 : 11,
            ).copyWith(letterSpacing: 2.2),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OraclyChrome.goldLight.withValues(alpha: 0.78),
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(alpha: 0.35),
                blurRadius: 5,
              ),
            ],
          ),
          child: const SizedBox(width: 4, height: 4),
        ),
      ],
    );
  }
}
