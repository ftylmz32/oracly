/// RC-001 — Transitional copy for select → reveal → reading continuity.
library;

import '../l10n/l10n.dart';

abstract final class ReadingFlowCopy {
  ReadingFlowCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  /// Brief breath between reveal handoff and interpretation scroll.
  static String get introBreath => _t('reading.flow.breath');

  static String get introPreparing => _t('reading.flow.preparing');

  static String get revealSessionMissing => _t('reading.flow.reveal_missing');

  static String get readingSessionMissing =>
      _t('reading.flow.reading_missing');
}
