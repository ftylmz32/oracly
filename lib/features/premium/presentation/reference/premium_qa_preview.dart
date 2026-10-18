/// Debug-only Premium frames. Release builds never read or render these.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'premium_reference_plans_section.dart';
import 'premium_reference_tokens.dart';

enum PremiumQaPreviewKind { none, plans, unavailable }

abstract final class PremiumQaPreview {
  PremiumQaPreview._();

  static const _channel = MethodChannel('oracly/debug');

  static Future<PremiumQaPreviewKind> requested() async {
    if (kReleaseMode) return PremiumQaPreviewKind.none;
    try {
      final value = await _channel.invokeMethod<String>('premiumPreview');
      return switch (value) {
        'plans' => PremiumQaPreviewKind.plans,
        'unavailable' => PremiumQaPreviewKind.unavailable,
        _ => PremiumQaPreviewKind.none,
      };
    } catch (_) {
      return PremiumQaPreviewKind.none;
    }
  }

  static List<PremiumPlanModel> get fixturePlans => [
        for (final kind in PremiumPlanKind.values)
          PremiumPlanModel(
            kind: kind,
            label: switch (kind) {
              PremiumPlanKind.monthly => 'Aylık',
              PremiumPlanKind.yearly => 'Yıllık',
              PremiumPlanKind.lifetime => 'Ömür Boyu',
            },
            price: PremiumCopy.qaPreviewPrice,
            subtitle: '',
            isActive: false,
          ),
      ];
}

class PremiumQaPreviewBanner extends StatelessWidget {
  const PremiumQaPreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        PremiumCopy.qaPreview,
        textAlign: TextAlign.center,
        style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
          letterSpacing: 2.2,
          color: OraclyChrome.goldLight,
        ),
      ),
    );
  }
}

class PremiumQaPreviewPlans extends StatefulWidget {
  const PremiumQaPreviewPlans({super.key});

  @override
  State<PremiumQaPreviewPlans> createState() => _PremiumQaPreviewPlansState();
}

class _PremiumQaPreviewPlansState extends State<PremiumQaPreviewPlans> {
  PremiumPlanKind _selected = PremiumPlanKind.yearly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumReferencePlansSection(
          plans: PremiumQaPreview.fixturePlans,
          selected: _selected,
          onSelected: (kind) => setState(() => _selected = kind),
        ),
        SizedBox(height: PremiumReferenceTokens.plansToCta),
        OraclyPressable(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              PremiumCopy.qaPreviewCta,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(
                color: OraclyChrome.goldLight.withValues(alpha: 0.9),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
