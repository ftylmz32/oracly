import {
  coffeeTurkishIsDemonstrativeOpener,
  coffeeTurkishStackedNominalization,
  coffeeTurkishTokens,
  type CoffeeM2TurkishRealizationPayload,
} from './coffee-m2-turkish-realization-policy.js';

/**
 * W4C.1 — DARK QA CHECKER. ADDITIVE AND DARK: no live path imports this.
 *
 * Deterministic post-gates for a writer's beat output against a W4C
 * realization payload. QA only: it validates, it never repairs or rewrites,
 * and it never grants a meaning.
 * - checkCoffeeM2TurkishRealization: referent ownership, tempo referent
 *   collision, avoid / overlap wording, openers, stacked nominalization,
 *   W4C.2 generic context subjects and cross-beat word-family collisions.
 * - validateCoffeeM2ScenarioSelection: scenario items by EXACT ID (never by
 *   prose similarity). Whether the prose really says the declared items is
 *   still a manual grounding audit.
 */

export type CoffeeM2RealizationViolation = {
  beat: string | null;
  code:
    | 'BEAT_COUNT'
    | 'FORBIDDEN_REFERENT'
    | 'TEMPO_REFERENT_COLLISION'
    | 'GLOBAL_AVOID'
    | 'BEAT_AVOID'
    | 'OVERLAP_NEVER_USE'
    | 'SAME_OPENER_AS_PREVIOUS'
    | 'DEMONSTRATIVE_OPENER_LIMIT'
    | 'STACKED_NOMINALIZATION'
    | 'GENERIC_CONTEXT_SUBJECT'
    | 'CROSS_BEAT_LEXICAL_COLLISION'
    | 'SCENARIO_UNKNOWN_ID'
    | 'SCENARIO_DUPLICATE_ID'
    | 'SCENARIO_TOO_MANY'
    | 'SCENARIO_TOO_FEW'
    | 'SCENARIO_INCOMPATIBLE_PAIR'
    | 'SCENARIO_ON_NON_SCENARIO_BEAT';
  detail: string;
};

const fold = (value: string) =>
  value
    .normalize('NFC')
    .toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/[îì]/g, 'i').replace(/[ûù]/g, 'u');
const escape = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/** Phrase occurs at a word start (inflection after it is allowed). */
const hasPhrase = (text: string, phrase: string) => new RegExp(`(^|[^a-z])${escape(fold(phrase))}`).test(text);
/** Blank out every allowed referent so its inner words cannot trip a forbidden check. */
const mask = (text: string, allowed: string[]) =>
  allowed.map(fold).sort((a, b) => b.length - a.length).reduce((t, a) => t.split(a).join(' '.repeat(a.length)), text);

export function checkCoffeeM2TurkishRealization(payload: CoffeeM2TurkishRealizationPayload, texts: string[]): CoffeeM2RealizationViolation[] {
  const out: CoffeeM2RealizationViolation[] = [];
  const beats = payload.realization.beats;
  if (texts.length !== beats.length) {
    out.push({ beat: null, code: 'BEAT_COUNT', detail: `${texts.length} != ${beats.length}` });
    return out;
  }
  let previousOpener = '';
  let demonstratives = 0;
  texts.forEach((raw, i) => {
    const id = `B${i + 1}`;
    const rb = beats[i];
    const text = fold(raw);
    if (rb.referent) {
      const masked = mask(text, rb.referent.referents);
      for (const f of rb.referent.forbiddenReferents) {
        if (hasPhrase(masked, f)) out.push({ beat: id, code: 'FORBIDDEN_REFERENT', detail: f });
      }
      if (rb.referent.kind === 'facet') {
        for (const noun of rb.referent.forbiddenEntityNouns) {
          const stems = [fold(noun), fold(noun).replace(/â/g, 'a')];
          if (stems.some((s) => new RegExp(`(^|[^a-z])${escape(s)}`).test(masked))) {
            out.push({ beat: id, code: 'TEMPO_REFERENT_COLLISION', detail: `${rb.referent.aboutClass} entity noun "${noun}" carries a tempo-bound facet; use: ${rb.referent.referents.join(' / ')}` });
          }
        }
      }
    }
    for (const a of payload.wording.avoid) if (hasPhrase(text, a)) out.push({ beat: id, code: 'GLOBAL_AVOID', detail: a });
    for (const a of rb.avoidWording) if (text.includes(fold(a))) out.push({ beat: id, code: 'BEAT_AVOID', detail: a });
    for (const o of rb.overlap) {
      for (const n of o.neverUse) if (hasPhrase(text, n)) out.push({ beat: id, code: 'OVERLAP_NEVER_USE', detail: `${o.cls}~${o.with}: ${n}` });
    }
    if (coffeeTurkishStackedNominalization(raw)) out.push({ beat: id, code: 'STACKED_NOMINALIZATION', detail: raw });
    if (rb.forbiddenGenericSubjects?.length) {
      const words = new Set(coffeeTurkishTokens(raw));
      for (const s of rb.forbiddenGenericSubjects) {
        if (words.has(s.toLocaleLowerCase('tr-TR'))) out.push({ beat: id, code: 'GENERIC_CONTEXT_SUBJECT', detail: s });
      }
    }
    const opener = (text.match(/[a-z]+/) ?? [''])[0];
    if (i > 0 && rb.avoidSameOpenerAsPrevious && opener === previousOpener) out.push({ beat: id, code: 'SAME_OPENER_AS_PREVIOUS', detail: opener });
    previousOpener = opener;
    if (coffeeTurkishIsDemonstrativeOpener(raw)) demonstratives += 1;
  });
  for (const f of payload.realization.crossBeat.lexicalCollisionFamilies ?? []) {
    const forms = new Set(f.forms);
    const hits = f.beats.filter((order) => coffeeTurkishTokens(texts[order - 1] ?? '').some((t) => forms.has(t)));
    if (hits.length === f.beats.length) {
      out.push({ beat: null, code: 'CROSS_BEAT_LEXICAL_COLLISION', detail: `${f.family}: ${hits.map((o) => `B${o}`).join('+')}` });
    }
  }
  if (demonstratives > payload.realization.crossBeat.demonstrativeOpenerMax) {
    out.push({ beat: null, code: 'DEMONSTRATIVE_OPENER_LIMIT', detail: `${demonstratives} > ${payload.realization.crossBeat.demonstrativeOpenerMax}` });
  }
  return out;
}

/** Exact-ID scenario selection validation against each beat's scenario contract. */
export function validateCoffeeM2ScenarioSelection(payload: CoffeeM2TurkishRealizationPayload, selections: string[][]): CoffeeM2RealizationViolation[] {
  const out: CoffeeM2RealizationViolation[] = [];
  if (selections.length !== payload.beats.length) {
    out.push({ beat: null, code: 'BEAT_COUNT', detail: `${selections.length} != ${payload.beats.length}` });
    return out;
  }
  payload.beats.forEach((beat, i) => {
    const id = `B${i + 1}`;
    const selected = selections[i];
    if (!beat.scenario) {
      if (selected.length) out.push({ beat: id, code: 'SCENARIO_ON_NON_SCENARIO_BEAT', detail: selected.join(',') });
      return;
    }
    const allowed = beat.scenario.manifestations;
    for (const m of selected) if (!allowed.includes(m)) out.push({ beat: id, code: 'SCENARIO_UNKNOWN_ID', detail: m });
    if (new Set(selected).size !== selected.length) out.push({ beat: id, code: 'SCENARIO_DUPLICATE_ID', detail: selected.join(',') });
    const cluster = payload.wording.scenarioClusters.find((c) => JSON.stringify(c.manifestations) === JSON.stringify(allowed));
    const choose = cluster?.choose ?? { min: 1, max: Math.min(2, allowed.length) };
    const n = new Set(selected).size;
    if (n > choose.max) out.push({ beat: id, code: 'SCENARIO_TOO_MANY', detail: `${n} > ${choose.max}` });
    if (n < choose.min) out.push({ beat: id, code: 'SCENARIO_TOO_FEW', detail: `${n} < ${choose.min}` });
    for (const pair of payload.realization.beats[i].scenarioIncompatiblePairs) {
      if (pair.every((m) => selected.includes(m))) out.push({ beat: id, code: 'SCENARIO_INCOMPATIBLE_PAIR', detail: pair.join('+') });
    }
  });
  return out;
}

export type CoffeeM2QaBeat = { id: string; text: string; scenarioItems: string[] };

/**
 * Strict QA output contract: {"beats":[{"id","scenarioItems"?,"text"}]}. With
 * `requireScenarioItems`, every beat must declare scenarioItems (QA metadata).
 * Never repairs.
 */
export function parseCoffeeM2QaWriterOutput(
  raw: string,
  beatCount: number,
  options: { requireScenarioItems: boolean },
): { ok: true; beats: CoffeeM2QaBeat[] } | { ok: false; errors: string[] } {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw.trim());
  } catch {
    return { ok: false, errors: ['invalid JSON'] };
  }
  const errors: string[] = [];
  const obj = parsed as { beats?: unknown };
  if (!obj || typeof obj !== 'object' || Array.isArray(obj) || Object.keys(obj).join() !== 'beats' || !Array.isArray(obj.beats)) {
    return { ok: false, errors: ['top level must be exactly {"beats": [...]}'] };
  }
  const list = obj.beats as Array<Record<string, unknown>>;
  if (list.length !== beatCount) errors.push(`beat count ${list.length} != ${beatCount}`);
  const want = Array.from({ length: beatCount }, (_, i) => `B${i + 1}`);
  if (JSON.stringify(list.map((b) => b?.id)) !== JSON.stringify(want.slice(0, list.length)) || list.length !== beatCount) errors.push('ids / order');
  const beats: CoffeeM2QaBeat[] = [];
  for (const b of list) {
    const keys = Object.keys(b ?? {}).sort();
    const allowed = options.requireScenarioItems ? ['id', 'scenarioItems', 'text'] : ['id', 'text'];
    if (JSON.stringify(keys) !== JSON.stringify(allowed)) errors.push(`beat ${String(b?.id)} fields ${keys.join(',')}`);
    if (typeof b?.text !== 'string' || !b.text.trim()) errors.push(`beat ${String(b?.id)} empty text`);
    const items = b?.scenarioItems;
    if (options.requireScenarioItems && (!Array.isArray(items) || items.some((x) => typeof x !== 'string'))) errors.push(`beat ${String(b?.id)} scenarioItems`);
    beats.push({ id: String(b?.id), text: String(b?.text ?? ''), scenarioItems: Array.isArray(items) ? (items as string[]) : [] });
  }
  return errors.length ? { ok: false, errors } : { ok: true, beats };
}

/** The ONLY public text: beat texts in order, one space apart. QA metadata never enters it. */
export function assembleCoffeeM2PublicReading(beats: ReadonlyArray<{ text: string }>): string {
  return beats.map((b) => b.text.trim()).join(' ');
}
