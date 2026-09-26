/// Display-ready historical reopen chrome — label + stored date only.
library;

import 'package:flutter/foundation.dart';

import '../../../core/l10n/oracly_format.dart';
import 'yildizname_result_chrome.dart';
import 'yildizname_result_types.dart';

@immutable
final class YildiznameHistoricalStatus {
  const YildiznameHistoricalStatus({
    required this.label,
    required this.formattedDate,
  });

  final String label;
  final String formattedDate;

  /// Quiet one-line provenance: `Kayıtlı yorum · 2 Tem 2026`.
  String get line => '$label · $formattedDate';

  /// Artifact source + stored date only. Live sources always null.
  /// Missing date ⇒ fail closed (no invented clock).
  static YildiznameHistoricalStatus? tryOf({
    required YildiznameResultSource source,
    required DateTime? createdAtUtc,
    String? languageCode,
  }) {
    if (!source.isArtifact) return null;
    final at = createdAtUtc;
    if (at == null) return null;
    final lang = YildiznameResultChrome.language(languageCode);
    return YildiznameHistoricalStatus(
      label: YildiznameResultChrome.historicalLabel(lang),
      formattedDate: OraclyFormat.dateCompact(at.toUtc(), languageCode: lang),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YildiznameHistoricalStatus &&
      other.label == label &&
      other.formattedDate == formattedDate;

  @override
  int get hashCode => Object.hash(label, formattedDate);
}
