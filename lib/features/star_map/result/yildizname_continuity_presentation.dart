/// Typed, display-ready continuity — labels only, no provenance IDs.
library;

import 'package:flutter/foundation.dart';

/// Verified archive echo for the canonical result screen.
@immutable
final class YildiznameContinuityPresentation {
  const YildiznameContinuityPresentation({
    required this.heading,
    required this.body,
    required this.labels,
  });

  static const empty = YildiznameContinuityPresentation(
    heading: '',
    body: '',
    labels: [],
  );

  /// Localized archive heading (chrome).
  final String heading;

  /// Localized supporting sentence (chrome).
  final String body;

  /// Evidence labels — stored theme labels, never translated.
  final List<String> labels;

  bool get isEmpty => labels.isEmpty;
  bool get isNotEmpty => labels.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is YildiznameContinuityPresentation &&
      other.heading == heading &&
      other.body == body &&
      listEquals(other.labels, labels);

  @override
  int get hashCode => Object.hash(heading, body, Object.hashAll(labels));
}
