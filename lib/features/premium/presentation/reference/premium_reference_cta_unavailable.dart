/// Calm chamber plaque when store purchase is not open — never a fake buy.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceCtaUnavailable extends StatelessWidget {
  const PremiumReferenceCtaUnavailable({super.key, this.onRetry});

  final VoidCallback? onRetry;

  static const _velvet = Color(0xFF1A100C);
  static const _ink = Color(0xFF0A0608);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: false,
      label: PremiumCopy.ctaUnavailable,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: PremiumReferenceTokens.ctaRadius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_velvet, _ink],
          ),
          border: Border.all(
            color: OraclyChrome.goldLight.withValues(alpha: 0.34),
            width: 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: OraclyChrome.gold.withValues(alpha: 0.06),
              blurRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            children: [
              Text(
                PremiumCopy.ctaExplore,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
                  letterSpacing:
                      CraftsmanshipRhythm.sectionLabelTracking + 1.0,
                  color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                PremiumCopy.ctaUnavailable,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                PremiumCopy.ctaHint,
                textAlign: TextAlign.center,
                style: ReadingTypography.secondary(
                  color: OraclyA11y.creamHint(OraclyChrome.cream),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                OraclyPressable(
                  onTap: onRetry,
                  child: Text(
                    PremiumCopy.ctaRetryStore,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.metadata(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
