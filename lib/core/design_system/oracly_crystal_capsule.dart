/// Crystal / gem count capsule — luminous gem · balance · + .
library;

import 'package:flutter/material.dart';

import '../accessibility/oracly_a11y.dart';
import '../l10n/l10n.dart';
import '../../shared/widgets/oracly_pressable.dart';
import 'app_borders.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'oracly_chrome.dart';
import 'oracly_gem_facet.dart';

/// Dark velvet glass pill with fine gold edge — rare wallet chrome.
class OraclyCrystalCapsule extends StatelessWidget {
  const OraclyCrystalCapsule({super.key, required this.count, this.onTap});

  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = OraclyL10n.t('settings.gems');
    final interactive = onTap != null;
    return OraclyPressable(
      onTap: onTap,
      label: '$label, $count',
      borderRadius: AppRadius.round,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: OraclyA11y.minTouchTarget),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.round,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1228).withValues(alpha: 0.94),
                OraclyChrome.elevatedSurface.withValues(alpha: 0.88),
                const Color(0xFF0A0612).withValues(alpha: 0.92),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
            border: Border.all(
              color: OraclyChrome.goldMuted.withValues(alpha: 0.52),
              width: AppBorders.hairline,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.34),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: OraclyChrome.violet.withValues(alpha: 0.16),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 3.5, 4, 3.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                  child: OraclyGemFacet(size: 16, glow: 0.88),
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 72),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      count,
                      style: AppTypography.caption.copyWith(
                        color: OraclyChrome.cream.withValues(alpha: 0.94),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.28,
                        height: 1,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (interactive) ...[
                  const SizedBox(width: 4),
                  ExcludeSemantics(
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            OraclyChrome.goldHighlight.withValues(alpha: 0.18),
                            OraclyChrome.goldMuted.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: OraclyChrome.goldPrimary.withValues(
                            alpha: 0.52,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 11,
                        color: OraclyA11y.goldReadable(
                          OraclyChrome.goldHighlight,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
