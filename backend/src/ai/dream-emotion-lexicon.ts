/** Canonical feeling words (light-folded) for the Dream emotion contract — TR / EN / RU. */
export type DreamEmotion =
  | 'fear' | 'anxiety' | 'calm' | 'joy' | 'sadness' | 'curiosity' | 'relief' | 'heaviness';

export const LEXICON: Array<[DreamEmotion, RegExp]> = [
  ['fear', /^(?:afraid|unafraid|fear\p{L}*|scared|scary|frighten\p{L}*|terrif\p{L}*|terror|panic\p{L}*|dread\p{L}*|kork\p{L}*|dehşet\p{L}*|panik\p{L}*|страх\p{L}*|страш\p{L}*|бесстраш\p{L}*|боял\p{L}*|боюсь|боится|бояться|испуг\p{L}*|испуга\p{L}*|ужас\p{L}*)$/u],
  ['anxiety', /^(?:anxi\p{L}*|worr\p{L}*|nervous\p{L}*|uneas\p{L}*|tense|tension|kaygı\p{L}*|endişe\p{L}*|tedirgin\p{L}*|gergin\p{L}*|huzursuz\p{L}*|тревог\p{L}*|тревож\p{L}*|беспоко\p{L}*|волновал\p{L}*|волнуюсь|волнение\p{L}*|взволнова\p{L}*|нервн\p{L}*)$/u],
  ['calm', /^(?:calm\p{L}*|peace\p{L}*|seren\p{L}*|relax\p{L}*|tranquil\p{L}*|sakin\p{L}*|huzur\p{L}*|dingin\p{L}*|rahat\p{L}*|спокой\p{L}*|неспокой\p{L}*|умиротвор\p{L}*|безмятеж\p{L}*)$/u],
  ['joy', /^(?:happy|happier|happiest|happily|happiness|unhappy|joy\p{L}*|glad\p{L}*|delight\p{L}*|cheerful\p{L}*|mutlu\p{L}*|sevin\p{L}*|neşe\p{L}*|радост\p{L}*|безрадост\p{L}*|радова\p{L}*|счастл\p{L}*|счасть\p{L}*|весел\p{L}*)$/u],
  ['sadness', /^(?:sad|sadly|sadness|unhapp\p{L}*|sorrow\p{L}*|grief|griev\p{L}*|melanchol\p{L}*|üzgün\p{L}*|üzüntü\p{L}*|üzül\p{L}*|hüzün\p{L}*|hüzn\p{L}*|keder\p{L}*|mutsuz\p{L}*|грус\p{L}*|печал\p{L}*|тоск\p{L}*)$/u],
  ['curiosity', /^(?:curio\p{L}*|merak\p{L}*|любопыт\p{L}*)$/u],
  ['relief', /^(?:relie(?:f|fs|ved|ve|ves|ving)|ferahla\p{L}*|rahatlad\p{L}*|rahatlam\p{L}*|облегчен\p{L}*)$/u],
  ['heaviness', /^(?:heavy|heavier|heaviness|heavily|ağırlık\p{L}*|тяжест\p{L}*|тяжел\p{L}*|тяжко)$/u],
];

/**
 * The word itself carries the negation (fearless, korkmadım, kaygısız,
 * бесстрашно). "korkutmuyor / korkutmadı / korkutmaz / korkutmayan" deny
 * fear; affirmative "korkutuyor / korkuttu / korkutucu / korkutmaya" never match.
 */
export const WORD_NEGATED: Array<[DreamEmotion, RegExp]> = [
  ['fear', /^(?:unafraid|fearless\p{L}*|korkusuz\p{L}*|бесстраш\p{L}*)$|^korkm[aeıiuü](?:[dyzmn]|$)|^korkutm(?:uyor|adı|az|ayan|amış|ayacak|adan)\p{L}*$/u],
  ['anxiety', /^(?:kaygısız\p{L}*|endişesiz\p{L}*)$|^(?:kaygılan|endişelen)m[aeıiuü](?:[dyzmn]|$)/u],
  ['calm', /^(?:huzursuz\p{L}*|rahatsız\p{L}*|неспокой\p{L}*|restless)$|^(?:sakinleş|rahatla)m[aeıiuü](?:[dyzmn]|$)/u],
  ['joy', /^(?:unhappy|joyless|neşesiz\p{L}*|безрадост\p{L}*)$|^sevinm[aeıiuü](?:[dyzmn]|$)/u],
  ['sadness', /^üzülm[aeıiuü](?:[dyzmn]|$)/u],
  ['curiosity', /^(?:incurious|meraksız\p{L}*)$/u],
  ['relief', /^rahatlam[aeıiuü](?:[dyzmn]|$)/u],
  ['heaviness', /^$/u],
];
