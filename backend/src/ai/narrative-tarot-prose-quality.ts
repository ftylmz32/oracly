/** Phase 6E.3 — Narrative result prose quality (deterministic-future sentinels). */
export type NarrativeProseQualityFailure = {
  code: 'deterministicFuture';
  pattern: string;
};

const EN: RegExp[] = [
  /\bfuture\s+promises\b/i,
  /\bthe\s+future\s+promises\b/i,
  /\bwill\s+definitely\b/i,
  /\bwill\s+certainly\b/i,
  /\binevitably\b/i,
  /\bis\s+guaranteed\s+to\b/i,
  /\bwill\s+lead\s+to\b/i,
];

const TR: RegExp[] = [
  /\bkesinlikle\s+olacak\b/i,
  /\bkesin\s+olacak\b/i,
  /\bmutlaka\s+olacak\b/i,
  /\bkaçınılmaz\s+olarak\b/i,
  /\bgaranti(?:dir|li)?\b/i,
];

const RU: RegExp[] = [
  /\bбудущее\s+обещает\b/i,
  /\bобязательно\s+произойд/i,
  /\bнеизбежно\b/i,
  /\bгарантированно\b/i,
  /\bточно\s+произойд/i,
];

function patternsFor(language: string): RegExp[] {
  if (language === 'tr') return TR;
  if (language === 'ru') return RU;
  return EN;
}

/** Collect visible Narrative result prose for prophecy scanning. */
export function narrativeVisibleProse(result: {
  summary: string;
  synthesis: string;
  advice: string;
  closingMessage: string;
  reflectionPrompt: string | null;
  dailyFocus: string | null;
  cardReadings: { text: string }[];
  relationshipInsights: { text: string }[];
  recurringCardInsights: { text: string }[];
  recurringThemeInsights: { text: string }[];
  memoryInsights: { text: string }[];
  lifeAreas: { text: string }[];
}): string {
  const parts: string[] = [
    result.summary,
    result.synthesis,
    result.advice,
    result.closingMessage,
  ];
  if (result.reflectionPrompt) parts.push(result.reflectionPrompt);
  if (result.dailyFocus) parts.push(result.dailyFocus);
  for (const list of [
    result.cardReadings,
    result.relationshipInsights,
    result.recurringCardInsights,
    result.recurringThemeInsights,
    result.memoryInsights,
    result.lifeAreas,
  ]) {
    for (const item of list) parts.push(item.text);
  }
  return parts.join('\n');
}

/** Pure detector — returns failure or null. Does not throw for expected hits. */
export function findDeterministicFuture(
  text: string,
  language: string,
): NarrativeProseQualityFailure | null {
  for (const re of patternsFor(language)) {
    if (re.test(text)) {
      return { code: 'deterministicFuture', pattern: re.source };
    }
  }
  return null;
}
