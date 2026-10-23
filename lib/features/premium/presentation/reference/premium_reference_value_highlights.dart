/// Compact preview of verified Premium capabilities, not an offer of new rights.
/// Pure presentation: never touches reading engines, entitlements or store price.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../models/premium_models.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceValueHighlights extends StatelessWidget {
  const PremiumReferenceValueHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    // The same catalogue drives the real gated experience cards below.
    // Never add paid coffee, monthly credit allowances or trial promises here.
    final benefits = PremiumCatalogue.concretePremiumExperiences;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PremiumReferenceTokens.champagne.withValues(alpha: 0.34),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PremiumReferenceTokens.plumLift.withValues(alpha: 0.82),
            PremiumReferenceTokens.ink.withValues(alpha: 0.96),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < benefits.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  color: PremiumReferenceTokens.champagne.withValues(
                    alpha: 0.19,
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      benefits[i].icon,
                      size: 20,
                      color: PremiumReferenceTokens.champagneSoft,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      benefits[i].title,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: ReadingTypography.metadata(
                        color: OraclyChrome.cream.withValues(alpha: 0.94),
                      ).copyWith(
                        fontSize: 11.5,
                        height: 1.18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
