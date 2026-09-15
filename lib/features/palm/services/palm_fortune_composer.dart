/// Grounds palm copy in vision lines. Never invents medical facts.
library;

import '../../../core/copy/fortune_voice.dart';
import '../data/palm_observation.dart';
import '../models/palm_reading.dart';

abstract final class PalmFortuneComposer {
  PalmFortuneComposer._();

  /// BATCH 3A.1 found the old PalmFortuneStory.build() never read
  /// raw.overall at all — it reconstructed an "overall" purely from the
  /// per-line property texts wrapped in canned L10n templates, discarding
  /// the backend's real, quality-gated interpretation on every reading.
  /// BATCH 3A.2: that legacy line-weaving fallback is removed entirely
  /// from this live path. Backend text is used verbatim whenever it
  /// clears this composer's trust/quality bar; when it does not, this
  /// returns null — a typed failure the caller must treat as a failed
  /// analysis (honest retry/error state), never a lower-quality
  /// client-fabricated "reading".
  static PalmReading? compose(
    PalmReading raw, {
    List<String> themes = const [],
  }) {
    final overall = _authoritativeOverall(raw.overall);
    if (overall == null) return null;
    return PalmReading(
      id: raw.id,
      createdAt: raw.createdAt,
      hand: raw.hand,
      imagePath: raw.imagePath,
      overall: overall,
      heartLine: PalmObservation.line(raw.heartLine),
      headLine: PalmObservation.line(raw.headLine),
      lifeLine: PalmObservation.line(raw.lifeLine),
      fateLine: PalmObservation.line(raw.fateLine),
      takeaway: PalmObservation.line(raw.takeaway),
      symbols: PalmObservation.marks(raw.symbols),
      themes: raw.themes,
    );
  }

  /// Palm's overall is always required by the backend contract, so an
  /// empty/robotic/dump/overconfident result here is a genuine backend
  /// failure — never silently replaced by a lower-quality "reading".
  static String? _authoritativeOverall(String backendText) {
    final backend = FortuneVoice.scrub(backendText);
    // BATCH 3A's own quality gate requires a real palm overall to be at
    // least 40 characters of actual synthesis — anything shorter is not
    // a genuine validated interpretation (placeholder/degraded/test
    // fixture), so it is treated as a failed analysis, not a reading.
    if (backend.length >= 40 &&
        !FortuneVoice.looksRobotic(backendText) &&
        !FortuneVoice.claimsCertainty(backendText) &&
        !backendText.contains('=')) {
      return backend;
    }
    return null;
  }
}
