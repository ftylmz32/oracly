/// One real benefit — quiet chamber row, gold only as a whisper.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../models/premium_models.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceFeatureRow extends StatelessWidget {
  const PremiumReferenceFeatureRow({
    super.key,
    required this.benefit,
    required this.locked,
    this.onTap,
    this.highlighted = false,
  });

  final PremiumBenefit benefit;
  final bool locked;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final edge = highlighted ? 0.42 : 0.18;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PremiumReferenceTokens.plumLift.withValues(
              alpha: highlighted ? 0.82 : 0.55,
            ),
            PremiumReferenceTokens.ink.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: PremiumReferenceTokens.champagne.withValues(alpha: edge),
          width: highlighted ? 1.0 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: highlighted ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          benefit.title,
                          softWrap: true,
                          style: ReadingTypography.bodyCore(
                            color: OraclyChrome.cream.withValues(alpha: 0.94),
                          ),
                        ),
                      ),
                      if (benefit.requiresPremium) ...[
                        const SizedBox(width: 8),
                        Text(
                          PremiumCopy.exclusiveLabel,
                          style: ReadingTypography.micro(
                            color: PremiumReferenceTokens.champagne.withValues(
                              alpha: 0.78,
                            ),
                          ).copyWith(letterSpacing: 1.2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    benefit.description,
                    softWrap: true,
                    style: ReadingTypography.secondary(
                      color: OraclyChrome.cream.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : Icons.chevron_right_rounded,
                size: locked ? 16 : 18,
                color: PremiumReferenceTokens.champagne.withValues(
                  alpha: locked ? 0.55 : 0.40,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return child;
    return OraclyPressable(onTap: onTap, child: child);
  }
}
