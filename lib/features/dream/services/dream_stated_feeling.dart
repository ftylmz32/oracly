/// A catalogue image that is itself a feeling (`dream_fear`) is told when
/// the dreamer names that feeling in any form — "korkmadım", "not afraid",
/// "I was scared" — so a reading that honours a stated or negated feeling is
/// never mistaken for an invented image. Mirrored by the backend
/// `dream-client-parity.ts`.
///
/// [shares] is the emotional-theme role grounding (Phase 4C.1): the theme
/// names a canonical feeling the dreamer also named, in any form ("relief"
/// for "relieved", "happiness" for "happy"). Same lexicon as the backend
/// `dream-emotion-contract.ts`; stance is left to the backend, so a body the
/// backend accepts is never dropped on device.
library;

abstract final class DreamStatedFeeling {
  DreamStatedFeeling._();

  static final _fear = RegExp(
    r'(?<!\p{L})(?:kork|dehşet|panik|afraid|unafraid|fear|scared|scary|frighten|terrif|terror|panic|dread)',
    unicode: true,
  );

  static bool tells(String catalogueId, String told) =>
      catalogueId == 'dream_fear' && _fear.hasMatch(told.toLowerCase());

  static RegExp _word(String body) => RegExp('^(?:$body)\$', unicode: true);

  static final _lexicon = <String, RegExp>{
    'fear': _word(r'afraid|unafraid|fear\p{L}*|scared|scary|frighten\p{L}*|terrif\p{L}*|terror|panic\p{L}*|dread\p{L}*|kork\p{L}*|dehşet\p{L}*|panik\p{L}*|страх\p{L}*|страш\p{L}*|бесстраш\p{L}*|боял\p{L}*|боюсь|боится|бояться|испуг\p{L}*|испуга\p{L}*|ужас\p{L}*'),
    'anxiety': _word(r'anxi\p{L}*|worr\p{L}*|nervous\p{L}*|uneas\p{L}*|tense|tension|kaygı\p{L}*|endişe\p{L}*|tedirgin\p{L}*|gergin\p{L}*|huzursuz\p{L}*|тревог\p{L}*|тревож\p{L}*|беспоко\p{L}*|волновал\p{L}*|волнуюсь|волнение\p{L}*|взволнова\p{L}*|нервн\p{L}*'),
    'calm': _word(r'calm\p{L}*|peace\p{L}*|seren\p{L}*|relax\p{L}*|tranquil\p{L}*|sakin\p{L}*|huzur\p{L}*|dingin\p{L}*|rahat\p{L}*|спокой\p{L}*|неспокой\p{L}*|умиротвор\p{L}*|безмятеж\p{L}*'),
    'joy': _word(r'happy|happier|happiest|happily|happiness|unhappy|joy\p{L}*|glad\p{L}*|delight\p{L}*|cheerful\p{L}*|mutlu\p{L}*|sevin\p{L}*|neşe\p{L}*|радост\p{L}*|безрадост\p{L}*|радова\p{L}*|счастл\p{L}*|счасть\p{L}*|весел\p{L}*'),
    'sadness': _word(r'sad|sadly|sadness|unhapp\p{L}*|sorrow\p{L}*|grief|griev\p{L}*|melanchol\p{L}*|üzgün\p{L}*|üzüntü\p{L}*|üzül\p{L}*|hüzün\p{L}*|hüzn\p{L}*|keder\p{L}*|mutsuz\p{L}*|грус\p{L}*|печал\p{L}*|тоск\p{L}*'),
    'curiosity': _word(r'curio\p{L}*|merak\p{L}*|любопыт\p{L}*'),
    'relief': _word(r'relie(?:f|fs|ved|ve|ves|ving)|ferahla\p{L}*|rahatlad\p{L}*|rahatlam\p{L}*|облегчен\p{L}*'),
    'heaviness': _word(r'heavy|heavier|heaviness|heavily|ağırlık\p{L}*|тяжест\p{L}*|тяжел\p{L}*|тяжко'),
  };

  static final _split = RegExp(r'[^\p{L}]+', unicode: true);

  /// Same fold as the backend `lightFold`: Turkish I/İ, ё → е.
  static String _fold(String s) => s
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('\u0307', '')
      .replaceAll('ё', 'е');

  static Set<String> feelings(String text) => {
        for (final w in _fold(text).split(_split))
          if (w.isNotEmpty)
            for (final e in _lexicon.entries)
              if (e.value.hasMatch(w)) e.key,
      };

  /// True when [claims] names a canonical feeling that [told] also names.
  static bool shares(String claims, String told) =>
      feelings(claims).intersection(feelings(told)).isNotEmpty;
}
