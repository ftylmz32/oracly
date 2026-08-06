/// OR-400 / OR-406 — Subtle gold sacred accents for Tarot Home.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'oracly_sacred_identity.dart';

/// Hairline gold divider with center vesica accent — unified ORACLY DNA.
class TarotHomeGoldDivider extends StatelessWidget {
  const TarotHomeGoldDivider({super.key});

  @override
  Widget build(BuildContext context) => const OraclySacredDivider();
}

/// Tiny corner meridian ticks — OL-1 / OL-6 inspired.
class TarotHomeCornerOrnaments extends StatelessWidget {
  const TarotHomeCornerOrnaments({super.key});

  @override
  Widget build(BuildContext context) => const OraclySacredCornerOrnaments();
}

/// Section title with premium hierarchy for Tarot Home.
class TarotHomeSectionHeading extends StatelessWidget {
  const TarotHomeSectionHeading({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: OraclyTypography.sectionLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
        SizedBox(height: AppSpacing.md),
        const TarotHomeGoldDivider(),
      ],
    );
  }
}
