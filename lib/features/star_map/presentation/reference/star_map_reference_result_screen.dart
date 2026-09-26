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
import '../../result/yildizname_result_actions_builder.dart';
import '../../result/yildizname_result_presentation.dart';
import 'star_map_reference_app_bar.dart';
import 'star_map_reference_atmosphere.dart';
import 'star_map_reference_tokens.dart';
import 'star_map_result_body_children.dart';
import 'star_map_result_section.dart';

export '../../result/yildizname_result_presentation.dart';
export '../../result/yildizname_result_types.dart';
export 'star_map_result_section.dart';

class StarMapReferenceResultScreen extends ConsumerWidget {
  const StarMapReferenceResultScreen({
    super.key,
    required this.presentation,
  });

  /// Test-only unscoped entry for frozen Phase 7A baselines.
  @visibleForTesting
  StarMapReferenceResultScreen.unscoped({
    super.key,
    required String title,
    required List<StarMapResultSection> sections,
    List<StarMapPlanetInfluence> planets = const [],
    OracleReadingContext? readingContext,
    String? artifactId,
    DateTime? artifactCreatedAt,
  }) : presentation = _unscopedWithOptionalOr(
         title: title,
         sections: sections,
         planets: planets,
         artifactId: artifactId,
         artifactCreatedAt: artifactCreatedAt,
         readingContext: readingContext,
       );

  final YildiznameResultPresentation presentation;

  static YildiznameResultPresentation _unscopedWithOptionalOr({
    required String title,
    required List<StarMapResultSection> sections,
    required List<StarMapPlanetInfluence> planets,
    String? artifactId,
    DateTime? artifactCreatedAt,
    OracleReadingContext? readingContext,
  }) {
    final base = YildiznameResultPresentation.unscoped(
      title: title,
      sections: sections,
      planets: planets,
      artifactId: artifactId,
      createdAtUtc: artifactCreatedAt,
    );
    if (readingContext == null) return base;
    return base.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: base,
        orContext: readingContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = presentation.title;
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
                        children: StarMapResultBodyChildren.build(
                          presentation: presentation,
                        ),
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
