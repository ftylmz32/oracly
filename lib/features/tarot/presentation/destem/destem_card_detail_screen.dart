/// Full Destem card detail — all 78, from catalogue data only.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../deck/oracly_tarot_card.dart';
import 'destem_card_art.dart';
import 'destem_copy.dart';
import 'destem_detail_sections.dart';

class DestemCardDetailScreen extends StatelessWidget {
  const DestemCardDetailScreen({
    super.key,
    required this.card,
    this.seen = false,
  });

  final OraclyTarotCard card;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final name = card.name.of(OraclyL10n.code);
    return OraclyScaffold(
      safeArea: false,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OraclyChrome.screenSide,
            OraclyChrome.screenTop,
            OraclyChrome.screenSide,
            AppLayout.scrollBottomInset(context),
          ),
          child: Column(
            children: [
              OraclyAppBar(
                title: name,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: OraclyAdaptiveScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.s12),
                      Center(
                        child: DestemCardArt(
                          card: card,
                          width: 168,
                          height: 268,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: OraclyChrome.engravedTitle(size: 22),
                      ),
                      if (seen) ...[
                        SizedBox(height: AppSpacing.s8),
                        Text(
                          DestemCopy.seen,
                          textAlign: TextAlign.center,
                          style: ReadingTypography.footnote(
                            color: OraclyChrome.goldLight.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppSpacing.s8),
                      Text(
                        DestemCopy.subtitle,
                        textAlign: TextAlign.center,
                        style: ReadingTypography.footnote(
                          color: OraclyChrome.cream.withValues(alpha: 0.52),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      DestemDetailSections(card: card),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
