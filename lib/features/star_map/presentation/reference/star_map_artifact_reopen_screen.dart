/// Exact Yıldızname artifact reopen — stored prose + typed presentation only.
///
/// Same canonical result screen as a live reading. No provider call, no
/// astronomy, no birth data: chrome and scope disclosure are derived from the
/// stored artifact evidence.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../artifacts/yildizname_artifact.dart';
import '../../artifacts/yildizname_artifact_or_context.dart';
import '../../artifacts/yildizname_artifact_presentation.dart';
import 'star_map_reference_result_screen.dart';

class StarMapArtifactReopenScreen extends StatelessWidget {
  const StarMapArtifactReopenScreen({super.key, required this.artifact});

  final YildiznameArtifact artifact;

  @override
  Widget build(BuildContext context) {
    // Subscribe to locale: chrome follows the app language, prose never does.
    final chromeLocale = OraclyL10n.depend(context);
    return StarMapReferenceResultScreen(
      presentation: YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: chromeLocale,
      ),
      // Prose-only OR context — never birth date/place/time.
      readingContext: YildiznameArtifactOrContext.build(artifact),
    );
  }
}
