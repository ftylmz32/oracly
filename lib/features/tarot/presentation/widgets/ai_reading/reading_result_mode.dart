/// Presentation result mode — Narrative V2 vs legacy (Phase 7E / 7F).
///
/// Live routing uses [NarrativeTarotLiveGate]. History uses [modeOverride]
/// from persisted provenance — never the current feature flag.
library;

import '../../../domain/models/tarot_spread.dart';
import '../../../narrative/live/narrative_tarot_live_gate.dart';

enum ReadingResultMode { narrativeV2, legacy }

abstract final class ReadingResultModeResolver {
  ReadingResultModeResolver._();

  static ReadingResultMode of(TarotSpreadType? spread) {
    if (spread == null) return ReadingResultMode.legacy;
    return NarrativeTarotLiveGate.shouldUseNarrative(spread)
        ? ReadingResultMode.narrativeV2
        : ReadingResultMode.legacy;
  }

  /// History / reopen: persisted mode wins. Missing → conservative legacy.
  /// Live: omit [modeOverride] so current routing applies.
  static ReadingResultMode resolve({
    TarotSpreadType? spread,
    ReadingResultMode? modeOverride,
  }) {
    if (modeOverride != null) return modeOverride;
    return of(spread);
  }

  static ReadingResultMode? parsePersisted(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return ReadingResultMode.values.asNameMap()[raw.trim()];
  }

  static bool isNarrativeV2(
    TarotSpreadType? spread, {
    ReadingResultMode? modeOverride,
  }) =>
      resolve(spread: spread, modeOverride: modeOverride) ==
      ReadingResultMode.narrativeV2;
}
