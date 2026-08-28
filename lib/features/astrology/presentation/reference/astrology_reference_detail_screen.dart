/// Detailed astrology result — burç yorumu, not natal chart.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_reference_app_bar.dart';
import 'astrology_reference_atmosphere.dart';
import 'astrology_reference_detail_body.dart';
import 'astrology_reference_tokens.dart';

class AstrologyReferenceDetailScreen extends StatelessWidget {
  const AstrologyReferenceDetailScreen({
    super.key,
    required this.sign,
    required this.reading,
    this.themeLabels = const [],
  });

  final ZodiacSignContent sign;
  final AstrologyDailyReading reading;
  final List<String> themeLabels;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const AstrologyReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AstrologyReferenceTokens.screenHorizontal,
            AstrologyReferenceTokens.screenTop,
            AstrologyReferenceTokens.screenHorizontal,
            AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                children: [
                  AstrologyReferenceAppBar(
                    title: AstrologyPresentationCopy.todayTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(height: AstrologyReferenceTokens.headerToTabs),
                  Expanded(
                    child: OraclyAdaptiveScrollView(
                      child: AstrologyReferenceDetailBody(
                        sign: sign,
                        reading: reading,
                        themeLabels: themeLabels,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
