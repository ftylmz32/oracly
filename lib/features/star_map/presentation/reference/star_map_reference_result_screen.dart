/// Yıldızname result — archive chapters, never an observatory report.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../models/star_map_reading.dart';
import 'star_map_reference_app_bar.dart';
import 'star_map_reference_atmosphere.dart';
import 'star_map_reference_planet_card.dart';
import 'star_map_reference_tokens.dart';
import 'star_map_result_footer.dart';
import 'star_map_result_section.dart';
import 'star_map_result_section_card.dart';

export 'star_map_result_section.dart';

class StarMapReferenceResultScreen extends ConsumerWidget {
  const StarMapReferenceResultScreen({
    super.key,
    required this.title,
    required this.sections,
    this.planets = const [],
    this.readingContext,
  });

  final String title;
  final List<StarMapResultSection> sections;
  final List<StarMapPlanetInfluence> planets;
  final OracleReadingContext? readingContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = sections.isEmpty
        ? title
        : sections.first.body.trim().isNotEmpty
            ? sections.first.body
            : sections.first.title;
    // Content-stable key — never DateTime.now() (that minted a new favorite id daily).
    final refKey = 'star-${Object.hash(title, insight)}';
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const StarMapReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            StarMapReferenceTokens.screenHorizontal,
            StarMapReferenceTokens.screenTop,
            StarMapReferenceTokens.screenHorizontal,
            AppLayout.scrollBottomInset(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                children: [
                  StarMapReferenceAppBar(
                    title: title,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(height: StarMapReferenceTokens.headerToChart),
                  Expanded(
                    child: OraclyAdaptiveScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sections.length; i++)
                            StarMapResultSectionCard(
                              section: sections[i],
                              hero: i == 0,
                              index: i,
                              showSeparator: i > 0,
                            ),
                          for (final planet in planets)
                            StarMapReferencePlanetCard(planet: planet),
                          StarMapResultFooter(
                            title: title,
                            sections: sections,
                            planets: planets,
                            insight: insight,
                            refKey: refKey,
                            readingContext: readingContext,
                          ),
                        ],
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
