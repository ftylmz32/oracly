/// Exact Yıldızname artifact reopen — stored prose + typed presentation only.
///
/// Same canonical result screen as a live reading. No provider call, no
/// astronomy, no birth data. Continuity is projected from owner-safe history
/// when available; history failure never blocks the reading.
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
import 'star_map_reference_result_screen.dart';

class StarMapArtifactReopenScreen extends ConsumerWidget {
  const StarMapArtifactReopenScreen({super.key, required this.artifact});

  final YildiznameArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to locale: chrome follows the app language, prose never does.
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
    return StarMapReferenceResultScreen(
      presentation: base.withContinuity(continuity),
      // Prose-only OR context — never birth date/place/time.
      readingContext: YildiznameArtifactOrContext.build(artifact),
    );
  }
}
