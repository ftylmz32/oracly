/// Hero greeting copy stack — title, invite, optional first-reading CTA.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import 'home_reference_hero_detail_button.dart';

class HomeReferenceHeroCopy extends StatelessWidget {
  const HomeReferenceHeroCopy({
    super.key,
    required this.hello,
    required this.invite,
    this.ctaLabel,
    this.onCta,
  });

  final String hello;
  final String invite;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final titleSize = (24 / scale).clamp(18.0, 24.0);
    final bodySize = (14 / scale).clamp(12.0, 14.0);
    final showCta = onCta != null && (ctaLabel?.trim().isNotEmpty ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: LayoutBuilder(
          builder: (context, box) {
            final maxW = (box.maxWidth * 0.58).clamp(160.0, 240.0);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hello,
                        maxLines: scale > 1.15 ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            ReadingTypography.title(
                              color: OraclyChrome.cream.withValues(alpha: 0.98),
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: titleSize,
                              height: 1.14,
                              letterSpacing: 0.2,
                            ),
                      ),
                      const SizedBox(height: 7),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              OraclyChrome.gold.withValues(alpha: 0.55),
                              OraclyChrome.gold.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: const SizedBox(width: 36, height: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invite,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.secondary(
                          color: OraclyA11y.creamSecondary(OraclyChrome.cream),
                        ).copyWith(fontSize: bodySize, height: 1.42),
                      ),
                      if (showCta) ...[
                        const SizedBox(height: 10),
                        HomeReferenceHeroDetailButton(
                          label: ctaLabel!,
                          onPressed: onCta,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
