/// One observed mark row — number only when photo focus is grounded.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import 'coffee_reference_tokens.dart';

class CoffeeObservationRow {
  const CoffeeObservationRow({
    required this.index,
    required this.name,
    required this.reading,
  });

  final int? index;
  final String name;
  final String reading;
}

class CoffeeObservationCard extends StatelessWidget {
  const CoffeeObservationCard({super.key, required this.row});

  final CoffeeObservationRow row;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: CoffeeReferenceTokens.cardRadius,
        color: OraclyChrome.midnight.withValues(alpha: 0.52),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OraclyChrome.goldLight.withValues(alpha: 0.78),
                    OraclyChrome.gold.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (row.index != null) ...[
                          _IndexPip(index: row.index!),
                          SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Text(
                            row.name,
                            style: ReadingTypography.sectionTitle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (row.reading.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        row.reading,
                        style: ReadingTypography.bodySmall(
                          color: OraclyChrome.cream.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexPip extends StatelessWidget {
  const _IndexPip({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.70),
        ),
        color: OraclyChrome.midnight.withValues(alpha: 0.78),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: 0.12),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        '$index',
        style: ReadingTypography.micro(
          color: OraclyChrome.cream.withValues(alpha: 0.92),
        ).copyWith(fontSize: 10, height: 1),
      ),
    );
  }
}
