/// Exact Yıldızname artifact reopen — stored prose + typed presentation only.
///
/// Continuity uses owner-safe history; actions use the artifact alone and never
/// wait on history load.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_or_context.dart';
import '../../artifacts/yildizname_artifact_presentation.dart';
import '../../artifacts/yildizname_artifact_providers.dart';
import '../../result/yildizname_continuity_presentation.dart';
import '../../result/yildizname_continuity_projector.dart';
import '../../result/yildizname_result_actions_builder.dart';
import 'star_map_reference_result_screen.dart';

class StarMapArtifactReopenScreen extends ConsumerWidget {
  const StarMapArtifactReopenScreen({super.key, required this.artifact});

  final YildiznameArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chromeLocale = OraclyL10n.depend(context);
    final base = YildiznameArtifactPresentation.of(
      artifact,
      chromeLocale: chromeLocale,
    );
    final historyAsync = ref.watch(yildiznameArtifactHistoryProvider);
    final continuity = historyAsync.when(
      data: (history) => YildiznameContinuityProjector.project(
        current: artifact,
        history: history,
        languageCode: chromeLocale,
      ),
      loading: () => YildiznameContinuityPresentation.empty,
      error: (_, _) => YildiznameContinuityPresentation.empty,
    );
    final withContinuity = base.withContinuity(continuity);
    final presentation = withContinuity.withActions(
      YildiznameResultActionsBuilder.build(
        presentation: withContinuity,
        orContext: YildiznameArtifactOrContext.build(artifact),
      ),
    );
    return StarMapReferenceResultScreen(presentation: presentation);
  }
}
