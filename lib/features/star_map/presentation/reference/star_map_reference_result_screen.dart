/// Yıldızname result — archive chapters, never an observatory report.
///
/// The single canonical result owner: legacy live, artifact reopen and (later)
/// Narrative live all arrive as one typed [YildiznameResultPresentation].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../models/star_map_reading.dart';
import '../../result/yildizname_result_presentation.dart';
import '../../result/yildizname_result_types.dart';
import 'star_map_reference_app_bar.dart';
import 'star_map_reference_atmosphere.dart';
import 'star_map_reference_planet_card.dart';
import 'star_map_reference_tokens.dart';
import 'star_map_result_footer.dart';
import 'star_map_result_section.dart';
import 'star_map_result_section_card.dart';
import 'star_map_scope_note.dart';

export '../../result/yildizname_result_presentation.dart';
export '../../result/yildizname_result_types.dart';
export 'star_map_result_section.dart';

class StarMapReferenceResultScreen extends ConsumerWidget {
  const StarMapReferenceResultScreen({
    super.key,
    required this.presentation,
    this.readingContext,
  });

  /// Pre-typed compatibility entry: display-ready strings, no scope claim.
  ///
  /// Test-only — it keeps the frozen Phase 7A pixel baselines exercising the
  /// shared chrome. Production callers must pass a typed presentation.
  @visibleForTesting
  StarMapReferenceResultScreen.unscoped({
    super.key,
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    this.readingContext,
    String? artifactId,
    DateTime? artifactCreatedAt,
  }) : presentation = YildiznameResultPresentation.unscoped(
         title: title,
         sections: sections,
         planets: planets,
         artifactId: artifactId,
         createdAtUtc: artifactCreatedAt,
       );

  final YildiznameResultPresentation presentation;
  final OracleReadingContext? readingContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = presentation.title;
    final sections = presentation.sections;
    final planets = presentation.planets;
    final disclosure = presentation.scopeDisclosure;
    final hasSummary = sections.any(
      (s) => s.role == YildiznameSectionRole.summary,
    );
    bool isHero(int i) =>
        sections[i].role == YildiznameSectionRole.summary ||
        (!hasSummary && i == 0);
    final insight = sections.isEmpty
        ? title
        : sections.first.body.trim().isNotEmpty
        ? sections.first.body
        : sections.first.title;
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
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
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
                          if (disclosure != null)
                            StarMapScopeNote(disclosure: disclosure),
                          for (var i = 0; i < sections.length; i++)
                            StarMapResultSectionCard(
                              section: sections[i],
                              hero: isHero(i),
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
                            artifactId: presentation.artifactId,
                            artifactCreatedAt: presentation.createdAtUtc,
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
