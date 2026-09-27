/**
 * Dream Phase 4C — cross-reading observations: per-language boilerplate,
 * repeat-pair consistency and verdict distributions. Flags, not failures.
 */
import type { Phase4cRecord } from './harness.js';
import { firstFailure, ROLE_SIMILARITY_FLAG, type ReadingObservation } from './observe-reading.js';
import { FIELDS, ngrams, normSentence, sentences, words } from './observe-text.js';

export const BOILERPLATE_MIN_DREAMS = 3;

type Groups = Map<string, Set<string>>;
const add = (m: Groups, key: string, caseId: string) => (m.get(key) ?? m.set(key, new Set()).get(key)!).add(caseId);
const report = (m: Groups, min: number) =>
  [...m].filter(([, ids]) => ids.size >= min)
    .map(([text, ids]) => ({ text, dreams: [...ids].sort() }))
    .sort((a, b) => b.dreams.length - a.dreams.length || a.text.localeCompare(b.text));

export function boilerplate(runs: Phase4cRecord[], language: string) {
  const sentencesBy: Groups = new Map(), openings: Groups = new Map(), grams: Groups = new Map();
  const conclusions: Groups = new Map(), reflections: Groups = new Map();
  for (const r of runs) {
    const d = r.stages?.parsed;
    if (r.language !== language || !d) continue;
    for (const f of FIELDS) {
      for (const s of sentences(d[f])) if (words(s).length >= 4) add(sentencesBy, normSentence(s), r.caseId);
      add(openings, `${f}: ${words(d[f]).slice(0, 3).join(' ')}`, r.caseId);
      const ws = words(d[f]);
      for (const n of [5, 6]) for (const g of new Set(ngrams(ws, n))) add(grams, g, r.caseId);
    }
    add(conclusions, words(d.conclusion).slice(0, 4).join(' '), r.caseId);
    add(reflections, words(d.dailyLifeReflection).slice(0, 4).join(' '), r.caseId);
  }
  return {
    identicalSentencesAcrossDreams: report(sentencesBy, 2),
    sharedOpenings: report(openings, BOILERPLATE_MIN_DREAMS),
    repeatedNgrams: report(grams, BOILERPLATE_MIN_DREAMS),
    conclusionTemplates: report(conclusions, BOILERPLATE_MIN_DREAMS),
    reflectionTemplates: report(reflections, BOILERPLATE_MIN_DREAMS),
  };
}

type ClientRow = { runId: string; clientResult: string } | undefined;

export function repeatPairs(runs: Phase4cRecord[], obs: Map<string, ReadingObservation>, client: Map<string, ClientRow>) {
  return runs.filter((r) => r.repeatOf).map((b) => {
    const a = runs.find((r) => r.runId === b.repeatOf)!;
    const [oa, ob] = [obs.get(a.runId)!, obs.get(b.runId)!] as Array<Extract<ReadingObservation, { parsed: true }>>;
    const finals = [a.backendFinal, b.backendFinal];
    const emotionOk = (o: typeof oa) => !o.emotionContradiction.summary && !o.emotionContradiction.emotionalTheme;
    const evidence = (o: typeof oa) => Object.values(o.sectionGrounded).every(Boolean);
    return {
      caseId: a.caseId,
      runs: [a.runId, b.runId],
      backend: finals.every((f) => f === 'PASS') ? 'both_pass' : finals.some((f) => f === 'PASS') ? 'mixed' : 'both_reject',
      firstFailures: [firstFailure(a), firstFailure(b)],
      sameFirstFailure: firstFailure(a) === firstFailure(b),
      emotionsPreserved: [emotionOk(oa), emotionOk(ob)],
      evidenceRetained: [evidence(oa), evidence(ob)],
      inventedDomain: [oa.unsupportedDomain, ob.unsupportedDomain],
      historyTruth: [a.stages?.phase4A ?? null, b.stages?.phase4A ?? null],
      clientResult: [client.get(a.runId)?.clientResult ?? null, client.get(b.runId)?.clientResult ?? null],
    };
  });
}

export function distributions(runs: Phase4cRecord[], obs: Map<string, ReadingObservation>) {
  const count = (keys: string[]) => keys.reduce<Record<string, number>>((m, k) => ({ ...m, [k]: (m[k] ?? 0) + 1 }), {});
  const parsed = [...obs.values()].filter((o): o is Extract<ReadingObservation, { parsed: true }> => o.parsed);
  const diag = (stage: 'phase2' | 'phase4A' | 'phase4B') => count(runs.map((r) => r.stages?.diagnostic?.[stage] ?? 'n/a'));
  return {
    backendFinalByLanguage: Object.fromEntries(['tr', 'en', 'ru'].map((l) => [l, count(runs.filter((r) => r.language === l).map((r) => r.backendFinal))])),
    backendFinalByCategory: Object.fromEntries([...new Set(runs.map((r) => r.category))].map((c) => [c, count(runs.filter((r) => r.category === c).map((r) => r.backendFinal))])),
    firstFailure: count(runs.map((r) => firstFailure(r) ?? 'PASS')),
    diagnosticIndependent: { phase2: diag('phase2'), phase4A: diag('phase4A'), phase4B: diag('phase4B') },
    roleSimilarityFlags: parsed
      .filter((o) => o.roleSimilarity.interpretationVsReflection >= ROLE_SIMILARITY_FLAG || o.roleSimilarity.summaryVsTheme >= ROLE_SIMILARITY_FLAG)
      .map((o) => ({ runId: o.runId, ...o.roleSimilarity })),
    repeatedImageryFlags: parsed.filter((o) => o.repeatedImagery.length).map((o) => ({ runId: o.runId, words: o.repeatedImagery })),
    unsupportedDomainFlags: parsed.filter((o) => o.unsupportedDomain).map((o) => ({ runId: o.runId, domain: o.unsupportedDomain })),
    historyClaimsWithoutHistory: parsed.filter((o) => !o.historySupplied && o.historyClaims.length).map((o) => ({ runId: o.runId, claims: o.historyClaims })),
  };
}
