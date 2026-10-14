/// Grounds palm copy in vision lines. Never invents medical facts.
library;

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
    // Every caller passes a SERVER result the backend already gated: its
    // wording is shown verbatim (only trimmed). The client never rewrites a
    // phrase (the old FortuneVoice.scrub swaps) and never drops sentences
    // (the old line grounding) — both silently altered the delivered reading.
    return PalmReading(
      id: raw.id,
      createdAt: raw.createdAt,
      hand: raw.hand,
      imagePath: raw.imagePath,
      overall: overall,
      heartLine: section(raw.heartLine),
      headLine: section(raw.headLine),
      lifeLine: section(raw.lifeLine),
      fateLine: section(raw.fateLine),
      takeaway: section(raw.takeaway),
      symbols: PalmObservation.marks(raw.symbols),
      themes: raw.themes,
    );
  }

  /// A section that is only a short "this line is not visible" placeholder
  /// ("Görülemiyor.") is not a reading and stays hidden; any real sentence —
  /// even one saying a line is faint — is shown exactly as written.
  ///
  /// The one rule every palm surface (result, clipboard, narration) uses.
  static String section(String text) {
    final trimmed = text.trim();
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (trimmed.isEmpty || (words <= 8 && PalmObservation.missing(trimmed))) return '';
    // Safety net for palm's one harmful category (both server engines already
    // refuse it): a sentence reading lifespan, illness, death, pregnancy or a
    // diagnosis from the palm is never shown. Nothing else is touched.
    final sentences = trimmed.split(RegExp(r'(?<=[.!?…])\s+'));
    final kept = sentences.where((s) => !_health.any((t) => PalmObservation.hasTerm(s, t))).toList();
    return kept.length == sentences.length ? trimmed : kept.join(' ').trim();
  }

  static const _health = [
    'ömür', 'ömrün', 'ömrü', 'hastalık', 'hastalığ', 'ölüm', 'teşhis', 'hamile', 'gebelik',
    'lifespan', 'illness', 'disease', 'death', 'diagnos', 'pregnan',
    'продолжительность жизни', 'болезн', 'смерт', 'диагноз', 'беремен',
  ];

  /// Palm's overall is always required by the backend contract. Only a
  /// structural failure — empty / placeholder (< 40 chars) or a raw
  /// key=value dump — is a failed analysis; a word list never rejects a
  /// natural fortune ("haber alacaksın", "hayatına girecek").
  static String? _authoritativeOverall(String backendText) {
    final backend = backendText.trim();
    if (backend.length >= 40 && !backend.contains('=')) return backend;
    return null;
  }
}
