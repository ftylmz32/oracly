/// Visual body for the single Home Oracle NextAction card.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../reference/home_reference_card_shell.dart';
import '../reference/home_reference_tokens.dart';
import 'home_oracle_next_action_premium_note.dart';

class HomeOracleNextActionBody extends StatelessWidget {
  const HomeOracleNextActionBody({
    super.key,
    required this.title,
    required this.body,
    required this.cta,
    required this.dismissLabel,
    required this.onOpen,
    required this.onDismiss,
    this.premiumHint,
    this.premiumCta,
    this.onPremium,
    this.archiveLine,
  });

  final String title;
  final String body;
  final String cta;
  final String dismissLabel;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;
  final String? premiumHint;
  final String? premiumCta;
  final VoidCallback? onPremium;
  final String? archiveLine;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    final hint = premiumHint?.trim() ?? '';
    final archive = archiveLine?.trim() ?? '';
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 10),
      child: Semantics(
        container: true,
        label: '$title. $body. $cta',
        child: HomeReferenceCardShell(
          premium: false,
          glowStrength: 0.72,
          borderRadius: HomeReferenceTokens.orGuideRadius,
          padding: EdgeInsets.fromLTRB(
            16,
            compact ? 12 : 14,
            12,
            compact ? 10 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ReadingTypography.sectionLabel(
                        color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                      ).copyWith(
                        fontSize: compact ? 11 : 12,
                        letterSpacing:
                            CraftsmanshipRhythm.sectionLabelTracking,
                      ),
                    ),
                  ),
                  OraclyPressable(
                    onTap: onDismiss,
                    child: Semantics(
                      button: true,
                      label: dismissLabel,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: OraclyChrome.cream.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                body,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.bodyCore(
                  color: OraclyChrome.cream.withValues(alpha: 0.90),
                ).copyWith(fontSize: compact ? 12.5 : 13.5, height: 1.38),
              ),
              if (archive.isNotEmpty) ...[
                SizedBox(height: compact ? 6 : 8),
                Text(
                  archive,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.62),
                  ),
                ),
              ],
              SizedBox(height: compact ? 8 : 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OraclyPressable(
                  onTap: onOpen,
                  child: Text(
                    cta,
                    style: ReadingTypography.footnote(
                      color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                    ).copyWith(
                      fontSize: compact ? 12 : 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              if (hint.isNotEmpty && onPremium != null)
                HomeOracleNextActionPremiumNote(
                  hint: hint,
                  cta: premiumCta ?? '',
                  onPremium: onPremium!,
                  compact: compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
