/// Grounds coffee copy in vision symbols. Never invents unseen marks.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';
import '../models/coffee_symbol.dart';
import '../data/coffee_symbol_lexicon.dart';

abstract final class CoffeeFortuneComposer {
  CoffeeFortuneComposer._();

  /// BATCH 3A.1 found the backend writer's own text is the authoritative,
  /// quality-gated interpretation — human-quality.ts's observation_heavy
  /// gate already validated it server-side. BATCH 3A.2: a client-side
  /// legacy template (the old CoffeeFortuneStory/CoffeeFortuneLanes
  /// weaver) used to silently replace backend text that failed this
  /// composer's own (stricter, defense-in-depth) trust checks — turning a
  /// genuine backend failure into a fake "successful" observation-heavy
  /// reading. That is exactly the failure mode this batch removes: there
  /// is no legacy fallback left in this file. When `overall` fails the
  /// trust/quality bar this returns null — a typed failure the caller
  /// must treat as a failed analysis (honest retry/error state), never a
  /// degraded reading. Optional lanes that fail the same bar become
  /// empty (never invented, never template-woven) rather than blocking
  /// the whole reading, matching the backend's own "leave empty unless
  /// clearly supported" rule for those subjects.
  static CoffeeReading? compose(
    CoffeeReading raw, {
    List<String> themes = const [],
  }) {
    final overall = _authoritativeOverall(raw.overall);
    if (overall == null) return null;
    final firm = raw.symbols.where((s) => s.trust.isFirm).toList();
    final faint = raw.symbols.where((s) => !s.trust.isFirm).toList();
    final senses = CoffeeSymbolLexicon.presentIn(
      names: firm.map((s) => s.name),
    );
    return CoffeeReading(
      id: raw.id,
      createdAt: raw.createdAt,
      imagePath: raw.imagePath,
      visualObservation: FortuneVoice.scrub(raw.visualObservation),
      overall: overall,
      love: _authoritativeOrEmpty(raw.love),
      career: _authoritativeOrEmpty(raw.career),
      // Money stays intentionally suppressed — unrelated to this batch's
      // observation-heavy fix, preserved exactly as before.
      money: '',
      nearFuture: _authoritativeOrEmpty(raw.nearFuture),
      takeaway: _authoritativeOrEmpty(raw.takeaway),
      symbols: [
        for (final s in firm) _ground(s, senses),
        ...faint,
      ],
    );
  }

  /// `overall` is always required by the backend contract. A backend
  /// failure (empty, robotic, a raw evidence dump, or an overconfident
  /// absolute claim) must remain a failure — never silently replaced by
  /// a lower-quality, client-fabricated "reading".
  static String? _authoritativeOverall(String backendText) {
    final backend = FortuneVoice.scrub(backendText);
    // BATCH 3A's own quality gate requires a real coffee overall to be at
    // least 80 characters — anything shorter is not a genuine validated
    // synthesis (a placeholder, a truncated/degraded response, or a test
    // fixture), so it is treated as a failed analysis, not a reading.
    if (backend.length >= 80 &&
        !FortuneVoice.looksRobotic(backendText) &&
        !_looksLikeRawDump(backendText) &&
        !FortuneVoice.claimsCertainty(backendText)) {
      return backend;
    }
    return null;
  }

  /// love/career/money/nearFuture/takeaway are optional — the backend
  /// already decided whether real evidence supports this subject (per
  /// BATCH 3A's "leave empty unless clearly supported" writer rule), so:
  ///  - backend left it truly empty -> stays empty (no lane invented);
  ///  - backend wrote real, safe prose -> shown as-is, authoritative;
  ///  - backend text is robotic/a raw dump/an overconfident absolute
  ///    claim ("kesin", "mutlaka") -> not trusted blindly, but also never
  ///    template-woven — it stays empty, same as if nothing was said.
  static String _authoritativeOrEmpty(String backendText) {
    final backend = FortuneVoice.scrub(backendText);
    if (backend.isEmpty) return '';
    if (FortuneVoice.looksRobotic(backendText) ||
        _looksLikeRawDump(backendText) ||
        FortuneVoice.claimsCertainty(backendText) ||
        _assertsAbsoluteCertainty(backendText)) {
      return '';
    }
    return backend;
  }

  /// A genuine interpretation never contains a literal "name = meaning"
  /// pairing — that shape only comes from an older/degraded vision
  /// response being echoed verbatim, which is exactly the observation
  /// report this batch prevents from reaching the user.
  static bool _looksLikeRawDump(String text) => text.contains('=');

  /// Light defense-in-depth on top of BATCH 3A's server-side CERTAINTY
  /// check — an absolute, no-hedge claim in an optional subject lane
  /// (independent of whether it happened to match the server regex)
  /// should not be trusted verbatim in a product built on "symbolic
  /// reading, never a deterministic promise".
  static bool _assertsAbsoluteCertainty(String text) {
    return RegExp(
      r'\bkesin\b|\bmutlaka\b|\bdefinitely\b|\bcertainly\b|\bобязательно\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static CoffeeSymbol _ground(
    CoffeeSymbol symbol,
    List<CoffeeSymbolSense> senses,
  ) {
    final sense = CoffeeSymbolLexicon.match(symbol.name);
    if (sense == null) {
      return CoffeeSymbol(
        name: symbol.name,
        meaning: FortuneVoice.scrub(symbol.meaning),
        interpretation: FortuneVoice.scrub(symbol.interpretation),
        trust: symbol.trust,
      );
    }
    // Prefer what vision actually wrote; lexicon only fills empty gaps.
    final vision = FortuneVoice.scrub(symbol.interpretation);
    final meaning = vision.isNotEmpty
        ? vision
        : FortuneVoice.scrub(symbol.meaning).isNotEmpty
            ? FortuneVoice.scrub(symbol.meaning)
            : sense.meaning;
    return CoffeeSymbol(
      name: symbol.name,
      meaning: sense.meaning,
      interpretation: meaning,
      trust: symbol.trust,
    );
  }
}
