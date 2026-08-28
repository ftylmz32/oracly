/// Recurring-theme chips — real Personal Discovery labels only.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/discovery_theme.dart';
import '../../copy/astrology_presentation_copy.dart';

class AstrologyReferenceThemeChips extends StatelessWidget {
  const AstrologyReferenceThemeChips({
    super.key,
    this.labels = const [],
  });

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final clean = labels
        .map(_label)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        children: [
          Text(
            AstrologyPresentationCopy.recurringLabel,
            style: ReadingTypography.sectionLabel(
              color: OraclyChrome.goldLight.withValues(alpha: 0.82),
              fontSize: 11,
            ),
          ),
          SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            alignment: WrapAlignment.center,
            children: [
              for (final label in clean) _chip(label),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(String raw) {
    return DiscoveryTheme.resolve(raw)?.localized ?? raw.trim();
  }

  Widget _chip(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: OraclyChrome.goldMuted.withValues(alpha: 0.55),
        ),
        gradient: LinearGradient(
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.18),
            OraclyChrome.violet.withValues(alpha: 0.28),
            OraclyChrome.deepNavy.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          label,
          style: ReadingTypography.label(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ).copyWith(fontSize: 11, letterSpacing: 0.35),
        ),
      ),
    );
  }
}
