/// Visible proof that a reading was handed to OR — compact memory ribbon.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import '../../services/or_context_bucket_helpers.dart';
import 'companion_reference_tokens.dart';

class CompanionHandoffBanner extends StatelessWidget {
  const CompanionHandoffBanner({super.key, required this.compact});

  final String compact;

  /// Arrival-only chip — e.g. "Rüya yorumundan devam ediliyor".
  static Widget contextOnly(String line) {
    final text = line.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return CompanionHandoffBanner(compact: text);
  }

  static String? of(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || !OrContextBucketHelpers.looksFeature(text)) {
      return null;
    }
    return text;
  }

  IconData _moduleIcon(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('tarot')) return Icons.auto_stories_outlined;
    if (lower.contains('rüya') || lower.contains('ruya')) {
      return Icons.nights_stay_outlined;
    }
    if (lower.contains('kahve')) return Icons.coffee_outlined;
    if (lower.contains('yıldız') || lower.contains('yildiz')) {
      return Icons.star_outline_rounded;
    }
    return Icons.bookmark_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final lines = compact
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();
    final source = lines.first;
    final preview = lines.skip(1).take(2).join(' · ');
    final lower = source.toLowerCase();
    final title = lower.contains('tarot')
        ? CompanionCopy.handoffBannerTarot
        : (lines.length == 1
            ? CompanionCopy.handoffContinuing
            : CompanionCopy.handoffBannerGeneric);

    return Semantics(
      label: '$title. $source. $preview',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompanionReferenceTokens.screenHorizontal,
          AppSpacing.s8,
          CompanionReferenceTokens.screenHorizontal,
          0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF100E16).withValues(alpha: 0.72),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.14),
              width: 0.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        OraclyChrome.gold.withValues(alpha: 0.05),
                        OraclyChrome.gold.withValues(alpha: 0.42),
                        OraclyChrome.gold.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 2),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            _moduleIcon(source),
                            size: 14,
                            color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ReadingTypography.sectionLabel(
                                  color: OraclyChrome.goldLight
                                      .withValues(alpha: 0.82),
                                  fontSize: 9.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preview.isEmpty ? source : '$source · $preview',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ReadingTypography.bodySmall(
                                  color: OraclyChrome.cream.withValues(alpha: 0.78),
                                ).copyWith(fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
