/// Strip, celestial hero, one story — never a dashboard of tiny AŞK tiles.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../content/astrology/models/astrology_content.dart';
import '../../copy/astrology_presentation_copy.dart';
import '../../models/astrology_daily_reading.dart';
import 'astrology_hub_caption.dart';
import 'astrology_hub_story.dart';
import 'astrology_hub_wheel.dart';
import 'astrology_reference_cta.dart';
import 'astrology_reference_tokens.dart';
import 'astrology_reference_zodiac_tabs.dart';
import 'astrology_reference_supporting_insights.dart';
import 'astrology_reference_your_sky_section.dart';
import 'astrology_sign_transition.dart';
import 'astrology_supported_sky.dart';

class AstrologyReferenceHubBody extends StatelessWidget {
  const AstrologyReferenceHubBody({
    super.key,
    required this.signs,
    required this.selectedId,
    required this.selected,
    required this.reading,
    required this.onSelected,
    required this.onDetail,
    this.themeLabels = const <String>[],
    this.viewportHeight,
  });

  final List<ZodiacSignContent> signs;
  final String selectedId;
  final ZodiacSignContent selected;
  final AstrologyDailyReading reading;
  final ValueChanged<String> onSelected;
  final VoidCallback onDetail;
  final List<String> themeLabels;
  final double? viewportHeight;

  @override
  Widget build(BuildContext context) {
    final layout = AstrologyReferenceTokens.layoutFor(viewportHeight);
    final id = selected.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          layout.heroHeight,
          constraints.maxWidth.isFinite ? constraints.maxWidth * 0.92 : 320.0,
        ).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AstrologyHubWheel(
                sign: selected,
                side: side,
                sky: AstrologySupportedSky(sunSignId: id),
              ),
            ),
            SizedBox(height: layout.gap * 0.75),
            AstrologySignTransition(
              signId: id,
              scaleFrom: 0.97,
              child: AstrologyHubCaption(sign: selected),
            ),
            SizedBox(height: layout.gap),
            AstrologySignTransition(
              signId: id,
              scaleFrom: 0.985,
              child: AstrologyHubStory(reading: reading),
            ),
            SizedBox(height: layout.gap),
            AstrologySignTransition(
              signId: id,
              scaleFrom: 0.99,
              child: AstrologyReferenceSupportingInsights(
                reading: reading,
                themeLabels: themeLabels,
              ),
            ),
            SizedBox(height: layout.gap),
            AstrologySignTransition(
              signId: id,
              scaleFrom: 0.98,
              child: AstrologyReferenceYourSkySection(
                sign: selected,
                reading: reading,
              ),
            ),
            AstrologyReferenceCta(
              label: AstrologyPresentationCopy.detailCta,
              onPressed: onDetail,
            ),
            SizedBox(height: layout.gap * 2),
            AstrologyReferenceZodiacTabs(
              signs: signs,
              selectedId: selectedId,
              onSelected: onSelected,
            ),
          ],
        );
      },
    );
  }
}
