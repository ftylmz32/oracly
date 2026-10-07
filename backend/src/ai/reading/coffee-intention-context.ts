import { coffeePresumedUserState, coffeeUnsupportedExistingFact } from '../human-quality.js';
import type { CoffeeForbiddenAssumption } from './coffee-semantic-propositions.js';
import type { ReadingPersonalization } from './types.js';

/**
 * C2.9 — the ONE Coffee trusted-intention contract. Every intention effect
 * (authorized/required sections, assumption exceptions, person protections,
 * writer and repair subject) derives from this classifier; nothing else may
 * read intention text. Deterministic; classifies only the trusted intention,
 * never profile, memory, or history.
 */
export type CoffeeIntentionSubjectKind =
  | 'general'
  | 'love_relationships'
  | 'career_work'
  | 'money_finance'
  | 'person_of_interest'
  | 'custom_decision'
  | 'custom_other';

export type CoffeeSubjectSection = 'love' | 'career' | 'money';

/** Facts the user literally declared; the only facts intention may authorize. */
export type CoffeeUserDeclaredFact =
  | 'person_in_mind'
  | 'decision_exists'
  | 'current_relationship'
  /** Free text in which the user states their own present condition ("…bekliyorum"). */
  | 'stated_condition';

export type CoffeeTrustedIntentionContext = {
  intention: string;
  subjectKind: CoffeeIntentionSubjectKind;
  /** Optional domain sections this subject authorizes. */
  authorizedSections: CoffeeSubjectSection[];
  /** The subject section a successful reading MUST fill; null = overall carries the subject. */
  requiredSection: CoffeeSubjectSection | null;
  declaredFacts: CoffeeUserDeclaredFact[];
  /** Proposition-level bans lifted ONLY because the user declared the fact. */
  allowedAssumptionExceptions: CoffeeForbiddenAssumption[];
  /** Bans this subject ADDS regardless of propositions. */
  intentionForbiddenAssumptions: CoffeeForbiddenAssumption[];
};

/** Private writer/repair projection carried inside the story plan. */
export type CoffeeStorySubject = {
  kind: CoffeeIntentionSubjectKind;
  intention: string;
  requiredSection: CoffeeSubjectSection | null;
  declaredFacts: CoffeeUserDeclaredFact[];
  intentionForbiddenAssumptions: CoffeeForbiddenAssumption[];
};

/** Exact shipped product choices (Flutter CoffeeV2IntentionChoice). */
const CANONICAL: Record<string, CoffeeIntentionSubjectKind> = {
  'önümüzdeki dönem genel olarak': 'general',
  'aşk ve ilişkilerim hakkında': 'love_relationships',
  'işim ve kariyerim hakkında': 'career_work',
  'maddi durumum hakkında': 'money_finance',
  'aklımdaki kişiyle ilgili': 'person_of_interest',
};

const DOMAIN_WORDS: Record<CoffeeSubjectSection, string[]> = {
  love: ['aşk', 'aşkım', 'aşkı', 'ilişki', 'ilişkim', 'ilişkimi', 'ilişkimde', 'partner', 'partnerim', 'love', 'relationship'],
  career: ['kariyer', 'kariyerim', 'kariyerimde', 'iş', 'işim', 'işimde', 'işimi', 'meslek', 'mesleğim', 'career', 'job', 'work'],
  money: ['para', 'param', 'parasal', 'kazanç', 'kazancım', 'maddi', 'money', 'finance'],
};

const SECTION_BY_KIND: Partial<Record<CoffeeIntentionSubjectKind, CoffeeSubjectSection>> = {
  love_relationships: 'love',
  career_work: 'career',
  money_finance: 'money',
  person_of_interest: 'love',
};

const DECISION_WORD = /^(karar|seçim|seçenek|tercih|decision|choice)/u;
/** Literal current-relationship wording ("sevgilim", "eşimle", "ilişkimiz"); never the plural category "ilişkilerim". */
const CURRENT_RELATIONSHIP_WORD =
  /^((sevgili|eş|partner|nişanlı|koca|karı)m(la|le|ın|in|ı|i|a|e|da|de)?|ilişkim(iz)?(de|le|i|in|e)?)$/u;

/** First-person present progressive: the user describing their own state. */
const FIRST_PERSON_PRESENT = /(ıyorum|iyorum|uyorum|üyorum|yorum|ıyoruz|iyoruz|uyoruz|üyoruz)$/u;

const wordsOf = (value: string): string[] =>
  value.normalize('NFC').toLocaleLowerCase('tr-TR').match(/\p{L}+/gu) ?? [];

/** Domain sections named by free text (shared lexicon; also used for legacy memory/theme context). */
export function coffeeDomainSections(text: string | undefined): CoffeeSubjectSection[] {
  const words = new Set(wordsOf(text ?? ''));
  return (['love', 'career', 'money'] as const).filter((section) =>
    DOMAIN_WORDS[section].some((word) => words.has(word)));
}

export function classifyCoffeeIntention(raw: string | null | undefined): CoffeeTrustedIntentionContext | null {
  const intention = raw?.trim();
  if (!intention) return null;
  const canonical = CANONICAL[intention.normalize('NFC').toLocaleLowerCase('tr-TR')];
  const words = wordsOf(intention);
  const kind: CoffeeIntentionSubjectKind = canonical ?? (() => {
    if (words.some((word) => DECISION_WORD.test(word))) return 'custom_decision';
    const domains = coffeeDomainSections(intention);
    if (domains.length === 1) {
      return domains[0] === 'love' ? 'love_relationships' : domains[0] === 'career' ? 'career_work' : 'money_finance';
    }
    return 'custom_other';
  })();
  const declaredFacts: CoffeeUserDeclaredFact[] = [];
  if (kind === 'person_of_interest') declaredFacts.push('person_in_mind');
  if (kind === 'custom_decision') declaredFacts.push('decision_exists');
  if (!canonical && words.some((word) => CURRENT_RELATIONSHIP_WORD.test(word))) {
    declaredFacts.push('current_relationship');
  }
  if (
    !canonical
    && (words.some((word) => word.length > 5 && FIRST_PERSON_PRESENT.test(word))
      || coffeePresumedUserState([intention])
      || coffeeUnsupportedExistingFact([intention]))
  ) {
    declaredFacts.push('stated_condition');
  }
  const allowedAssumptionExceptions: CoffeeForbiddenAssumption[] = [
    ...(declaredFacts.includes('decision_exists') ? ['current_major_decision', 'options_assumption'] as const : []),
    ...(declaredFacts.includes('current_relationship') ? ['existing_relationship'] as const : []),
  ];
  const required = SECTION_BY_KIND[kind] ?? null;
  const authorizedSections = canonical
    ? (required ? [required] : [])
    : [...new Set([...(required ? [required] : []), ...coffeeDomainSections(intention)])];
  return {
    intention,
    subjectKind: kind,
    authorizedSections,
    requiredSection: required,
    declaredFacts,
    allowedAssumptionExceptions,
    intentionForbiddenAssumptions: kind === 'person_of_interest'
      ? ['existing_relationship', 'reciprocal_feeling']
      : [],
  };
}

export function coffeeStorySubject(context: CoffeeTrustedIntentionContext): CoffeeStorySubject {
  return {
    kind: context.subjectKind,
    intention: context.intention,
    requiredSection: context.requiredSection,
    declaredFacts: context.declaredFacts,
    intentionForbiddenAssumptions: context.intentionForbiddenAssumptions,
  };
}

/**
 * Optional sections authorized by personalization: the trusted intention
 * contract, plus legacy memory/theme keyword lanes (unchanged pre-C2.7B
 * behaviour; they never authorize facts or assumption exceptions).
 */
export function coffeePersonalizationSections(personalization?: ReadingPersonalization): CoffeeSubjectSection[] {
  const context = classifyCoffeeIntention(personalization?.intention);
  const legacy = coffeeDomainSections(
    [personalization?.memorySummary, ...(personalization?.relevantThemes ?? [])].filter(Boolean).join(' '),
  );
  return [...new Set([...(context?.authorizedSections ?? []), ...legacy])];
}
