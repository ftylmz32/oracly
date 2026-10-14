/**
 * V3N1 — versioned Coffee V3 narrative successor. Offline only: every
 * provider call is a FAKE transport; writer outputs are SIMULATED (authored
 * offline). These tests prove grounding, dedup, honesty and gates — NOT real
 * provider narrative quality.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { coffeeM2WriterPromptSha256 } from '../src/ai/reading/coffee-m2-writer-prompt.js';
import {
  COFFEE_V3_OBSERVATION_ADJUSTMENTS_STAGE,
  COFFEE_V3_OBSERVER_STAGE,
  FROZEN_COFFEE_M2_PROMPT_SHA256,
  CoffeeV3TerminalFailure,
  excludeCrossKindAmbiguities,
  runCoffeeV3Reading,
} from '../src/ai/reading/coffee-v3-live-pipeline.js';
import { buildCoffeeV3MarkMap, type CoffeeV3MarkMap } from '../src/ai/reading/coffee-v3-mark-map.js';
import { createReadingStageStore } from '../src/ai/reading/stage-cache.js';
import { COFFEE_V3N_MIN_CLAIMS, COFFEE_V3N_TABLES, planCoffeeV3Narrative } from '../src/ai/reading/coffee-v3n-narrative-plan.js';
import {
  COFFEE_V3N_RESULT_CONTRACT,
  COFFEE_V3N_WRITER_REJECTIONS_STAGE,
  FROZEN_COFFEE_V3N_PROMPT_SHA256,
  runCoffeeV3NarrativeReading,
} from '../src/ai/reading/coffee-v3n-narrative-pipeline.js';
import {
  COFFEE_V3N_WRITER_PROMPT,
  acceptCoffeeV3Narrative,
  coffeeV3NPayloadLeaks,
  coffeeV3NRefusedTerms,
  coffeeV3NWriterPayload,
  coffeeV3NWriterPromptSha256,
} from '../src/ai/reading/coffee-v3n-narrative-writer.js';
import type { OpenAiCompleteOptions } from '../src/ai/openai-transport.js';
import type { CoffeeMultiViewObservationV3 } from '../src/ai/reading/types.js';
import { C31_SET_IDS, c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { M1_QA_CUPS, m1Observation, type M1FixtureSpec, type M1MarkSpec } from './fixtures/coffee-m1-fixtures.js';
import {
  COFFEE_V3N_PREMIUM_WRITER_OUTPUT,
  COFFEE_V3N_RITAG_WRITER_OUTPUT,
  COFFEE_V3N_SIMULATED_SCENARIOS,
  coffeeV3PremiumSpec,
  toThreeViewObservation,
} from './fixtures/coffee-v3-three-view.js';
import { fakeJpeg, testConfig } from './helpers.js';

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const GENERAL = 'Önümüzdeki dönem genel olarak';
/** SIMULATED stand-in with the shape of the first real run's M2 → W4 reading (two generic sentences); real readings are never committed. */
const LIVE_THIN_READING = 'Önümüzdeki günlerde önün açılırken birkaç farklı yol da görünüyor. Bu yollar bir anda değil, zaman zaman ilerliyor.';

/** Cup / shape / position vocabulary that must never reach the person. */
const VISUAL_WORDS = /(?<!\p{L})(fincan\p{L}*|telve\p{L}*|tabak|tabağ\p{L}*|kulp\p{L}*|kulb\p{L}*|şekil\p{L}*|şekl\p{L}*|çizgi\p{L}*|leke\p{L}*|iz|izi|izler\p{L}*)(?!\p{L})/iu;
/** The previous V3N simulated reading (shape narration) — now a refused regression. */
const PREVIOUS_SHAPE_NARRATION = JSON.stringify({ paragraphs: [
  { claims: ['c1', 'c2'], text: 'Fincanına baktığımda ilk gözüme çarpan, dibinden ağzına doğru yükselen, hiç kesilmeden uzanan bir çizgi oluyor. Bu bana, vermen gereken kararla ilgili bir konunun yakın zamanda ivme kazanabileceğini, adım adım yukarı doğru gidebileceğini düşündürüyor. Aceleyle gelen bir hareket gibi durmuyor; zamana yayılan, uzun soluklu ama giderek güçlenen bir gelişme gibi görünüyor. Fincanın dibine doğru ise telvenin çekildiği açık, ferah bir alan var. Daha uzun vadede bu konunun önünün açılabileceğini, sana nefes aldıran bir aralık oluşabileceğini anlatıyor gibi.' },
  { claims: ['c3'], text: 'Fincanın ortalarına geldiğimde dallara ayrılan bir iz dikkatimi çekiyor. Önümüzdeki dönemde önünde birden fazla seçeneğin belirebileceğini, bu seçeneklerin birbirinden daha net ayrışabileceğini anlatıyor sanki. Hangisinin ağır basacağını telve söylemiyor; ama seçenekler şekillendikçe kararın da kendi yönünü bulabileceği hissini veriyor.' },
] });
const three = (spec: M1FixtureSpec): CoffeeMultiViewObservationV3 => toThreeViewObservation(m1Observation(spec));
const mapOf = (obs: CoffeeMultiViewObservationV3): CoffeeV3MarkMap => {
  const built = buildCoffeeV3MarkMap(obs);
  if (built.status !== 'ok') throw new Error(`fixture map ${built.status}`);
  return built.map;
};
const planOf = (spec: M1FixtureSpec, intention = DECISION) => planCoffeeV3Narrative(mapOf(three(spec)), classifyCoffeeIntention(intention));
/**
 * Isolates a LEXICAL rule (time words, anchors, contradiction, visual words…)
 * from the story-weight contract: every claim required (the first one core)
 * under the per-claim budget those fixtures were written for. The story
 * contract itself (core / support / minor) is tested on the real weights.
 */
const everyClaimRequired = (p: ReturnType<typeof planOf>): ReturnType<typeof planOf> => ({
  ...p,
  claims: p.claims.map((c, i) => ({ ...c, weight: i === 0 ? 'core' : 'support' })),
  budget: { minWords: 8 * p.claims.length + 16, maxWords: 60 * p.claims.length + 40 },
});
const planAllOf = (spec: M1FixtureSpec, intention = DECISION) => everyClaimRequired(planOf(spec, intention));
const RITAG = () => c31Spec('C3F-RITAG', { clearAreas: true });
const words = (s: string) => s.match(/\S+/g)?.length ?? 0;

// ---------------------------------------------------------------------------

describe('E1 structural-only evidence becomes richer, still grounded', () => {
  it('RITAG (structure-only, the shape of the first real run): frozen M2 keeps 2 beats; V3N keeps 3 grounded claims with provenance', () => {
    const map = mapOf(three(RITAG()));
    const m2 = planCoffeeM2Writer(interpretCoffeeM2(map, classifyCoffeeIntention(DECISION)).meaning).plan;
    expect(m2.beats).toHaveLength(2);
    const plan = planCoffeeV3Narrative(map, classifyCoffeeIntention(DECISION));
    expect(plan.status).toBe('planned');
    expect(plan.claims.map((c) => c.theme)).toEqual(['rising', 'opening', 'options']);
    const markIds = new Set(map.cupMarks.map((m) => m.id));
    for (const c of plan.claims) {
      expect(c.provenance.marks.length, c.id).toBeGreaterThan(0);
      for (const m of c.provenance.marks) expect(markIds.has(m), `${c.id}:${m}`).toBe(true);
      expect(c.seen).toMatch(/^fincanın /);
    }
    // The rising line is described by its own direction and span, never twice.
    expect(plan.claims[0].seen).toBe('fincanın dibinden ağzına doğru yükselen bir çizgi');
    expect(plan.claims[0].qualities).toEqual(expect.arrayContaining(['kesintisiz akan', 'zamana yayılan, uzun soluklu']));
  });

  it('across the frozen C3.1 corpus, every set that V3N plans is grounded mark-by-mark; a base pool is never read as a sign', () => {
    for (const id of C31_SET_IDS) {
      const spec = c31Spec(id, { clearAreas: true });
      const map = mapOf(three(spec));
      const plan = planCoffeeV3Narrative(map, classifyCoffeeIntention(GENERAL));
      if (plan.status !== 'planned') continue;
      expect(plan.claims.length, id).toBeGreaterThanOrEqual(COFFEE_V3N_MIN_CLAIMS);
      for (const c of plan.claims) {
        const marks = [...map.cupMarks, ...map.saucerMarks].filter((m) => c.provenance.marks.includes(m.id));
        if (c.theme === 'wish_gathering' || c.theme === 'release' || c.theme === 'circulating') continue;
        expect(marks.length, `${id}:${c.id}`).toBeGreaterThan(0);
        if (c.theme === 'weight') expect(marks.every((m) => m.band !== 'lower_base'), `${id}:${c.id}`).toBe(true);
      }
    }
  });
});

describe('E2 strong object evidence enriches without invented specifics', () => {
  it('a strong, clearly seen tree adds ONE licensed symbol claim near the handle; nothing else is named', () => {
    const plan = planOf(coffeeV3PremiumSpec());
    const objects = plan.claims.filter((c) => c.theme === 'object');
    expect(objects).toHaveLength(1);
    expect(objects[0]).toMatchObject({ symbol: 'ağaç', placement: 'close_circle', horizon: 'near', certainty: 'clear' });
    expect(objects[0].seen).toBe('fincanın ağzına yakın, kulbun yakınında ağaç gibi duran bir şekil');
    expect(plan.claims.filter((c) => c.symbol !== null)).toHaveLength(1);
  });

  it('weak, partially seen or conflicting resemblances never license a symbol', () => {
    const base = RITAG();
    for (const mark of [
      { id: 'w1', resemblances: [{ label: 'tree', strength: 'weak' as const }], hours: 1, band: 'rim_upper' as const },
      { id: 'p1', label: 'tree', visibility: 'partial' as const, hours: 1, band: 'rim_upper' as const },
      { id: 'c1', resemblances: [{ label: 'tree', strength: 'strong' as const }, { label: 'bird', strength: 'strong' as const }], hours: 1, band: 'rim_upper' as const },
    ]) {
      const plan = planOf({ ...base, marks: [...base.marks, mark] });
      expect(plan.claims.every((c) => c.symbol === null), mark.id).toBe(true);
    }
  });
});

describe('E3 the saucer contributes only when physically meaningful', () => {
  const clean = { surfaceState: 'clean' as const, flow: { present: false, direction: 'none' as const } };
  it('a clean saucer with no marks adds nothing', () => {
    const plan = planOf({ ...RITAG(), saucer: clean });
    expect(plan.claims.some((c) => c.surface === 'saucer')).toBe(false);
    expect(plan.paragraphs.some((p) => p.role === 'saucer')).toBe(false);
  });
  it('an observed flow toward the centre adds one saucer claim, told last', () => {
    const plan = planOf({ ...RITAG(), saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_center' } } });
    const saucer = plan.claims.filter((c) => c.surface === 'saucer');
    expect(saucer.map((c) => c.theme)).toEqual(['wish_gathering']);
    expect(plan.paragraphs.at(-1)).toEqual({ role: 'saucer', claims: [saucer[0].id] });
  });
  it('a saucer pool or a lone blob is context, never a claim', () => {
    const plan = planOf({ ...RITAG(), saucer: clean, marks: [...RITAG().marks, { id: 'sp', saucer: true, topology: 'pool', label: null }, { id: 'sb', saucer: true, topology: 'patch', label: null }] });
    expect(plan.claims.some((c) => c.surface === 'saucer')).toBe(false);
  });
});

describe('E4 duplicate cup-view evidence never produces duplicate claims', () => {
  const rising = (id: string, extra: Partial<M1MarkSpec> = {}): M1MarkSpec => ({ id, label: null, topology: 'line', form: { verticalDirection: 'rising' }, band: 'middle', ...extra });
  it('one mark trusted in BOTH cup photos is one claim, flagged as seen in both views', () => {
    const spec = { ...RITAG(), marks: [...RITAG().marks, rising('X', { slots: ['cup_handle_far', 'cup_turn_a'] })] };
    const map = mapOf(three(spec));
    const x = map.cupMarks.filter((m) => m.id === 'X');
    expect(x).toHaveLength(1); // the map trusted the cross-view merge: one physical mark
    expect(x[0].coverage).toEqual({ count: 2, slots: ['cup_view_a', 'cup_view_b'] });
    const claims = planOf(spec).claims.filter((c) => c.theme === 'rising');
    expect(claims).toHaveLength(1);
    expect(claims[0].provenance).toMatchObject({ seenInBothCupViews: true, slots: ['cup_view_a', 'cup_view_b'] });
    expect(claims[0].provenance.marks).toEqual(expect.arrayContaining(['X']));
  });
  it('a possible-same pair, or two separate marks with the same reading, is still ONE claim (strengthened, not repeated)', () => {
    const pair = planOf({ ...RITAG(), marks: [...RITAG().marks, rising('Y1'), rising('Y2', { hours: 9 })], ambiguities: [['Y1', 'Y2']] });
    expect(pair.claims.filter((c) => c.theme === 'rising')).toHaveLength(1);
    const separate = planOf({ ...RITAG(), marks: [...RITAG().marks, rising('Z1', { band: 'rim_upper' })] });
    const r = separate.claims.filter((c) => c.theme === 'rising');
    expect(r).toHaveLength(1);
    expect(r[0].qualities).toContain('güçlü biçimde vurgulanan');
    expect(new Set(separate.claims.map((c) => `${c.theme}|${c.symbol}`)).size).toBe(separate.claims.length);
  });
});

describe('E5 sparse evidence is never padded into a reading', () => {
  it('no marks, or fewer than the minimum grounded claims, is an honest insufficient plan', () => {
    expect(planOf({ marks: [] })).toMatchObject({ status: 'insufficient', reason: 'no_grounded_claims', claims: [] });
    expect(planOf(c31Spec('C3F-BASAK', { clearAreas: true }), GENERAL)).toMatchObject({ status: 'insufficient', reason: 'below_min_claims' });
  });
  it('the pipeline refuses an insufficient plan BEFORE any writer call (terminal invalid)', async () => {
    const r = await run(three(c31Spec('C3F-BASAK', { clearAreas: true })), [COFFEE_V3N_RITAG_WRITER_OUTPUT], { intention: GENERAL });
    expect(failure(r.error)).toBe('invalid:v3n_below_min_claims');
    expect(r.writerCalls()).toHaveLength(0);
  });
});

describe('E6 the narrative is meaningfully richer than the previous two-sentence reading (SIMULATED writer)', () => {
  it('same RITAG fixture: the simulated V3N reading passes every gate, tells each claim as LIFE meaning, never the cup', () => {
    const plan = planOf(RITAG());
    const accepted = acceptCoffeeV3Narrative(plan, COFFEE_V3N_RITAG_WRITER_OUTPUT);
    expect(accepted.ok).toBe(true);
    if (!accepted.ok) return;
    expect(accepted.metrics.paragraphs).toBe(2);
    // Short and dense is the target now; richer means every required meaning told, not length.
    expect(words(accepted.reading)).toBeGreaterThan(2 * words(LIVE_THIN_READING));
    expect(accepted.reading).not.toMatch(VISUAL_WORDS);
    // The evidence stays server-side: no seen phrase reaches the reading.
    for (const c of plan.claims) expect(accepted.reading, c.id).not.toContain(c.seen);
  });

  it('REGRESSION (exact): the shape-narrating sentence is refused as visual description', () => {
    const plan = planOf(RITAG());
    const good = JSON.parse(COFFEE_V3N_RITAG_WRITER_OUTPUT) as { paragraphs: Array<{ claims: string[]; text: string }> };
    const raw = JSON.stringify({ paragraphs: [{ ...good.paragraphs[0], text: `Fincanın dibinden ağzına doğru yükselen bir çizgi görüyorum. ${good.paragraphs[0].text}` }, good.paragraphs[1]] });
    const r = acceptCoffeeV3Narrative(plan, raw);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('visual_description');
  });

  it('REGRESSION: the previous V3N (shape-narrating) simulated reading is now refused in full', () => {
    const r = acceptCoffeeV3Narrative(planOf(RITAG()), PREVIOUS_SHAPE_NARRATION);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.failures).toContain('visual_description');
      for (const w of ['fincanına', 'çizgi', 'telvenin', 'iz']) expect(r.details).toContain(`visual_description:${w}`);
    }
  });

  it('REGRESSION: the exact live two-sentence reading would be rejected by the V3N gates (thin), even in the right structure', () => {
    const plan = planOf(RITAG());
    const asPlanned = JSON.stringify({ paragraphs: plan.paragraphs.map((p, i) => ({ claims: p.claims, text: LIVE_THIN_READING.split('. ')[i] ?? 'Bir yol beliriyor gibi.' })) });
    const r = acceptCoffeeV3Narrative(plan, asPlanned);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('too_thin');
  });
});

describe('V3N acceptance gates reject what premium must not be', () => {
  const plan = planOf(RITAG());
  const good = JSON.parse(COFFEE_V3N_RITAG_WRITER_OUTPUT) as { paragraphs: Array<{ claims: string[]; text: string }> };
  const withText = (i: number, text: string) => JSON.stringify({ paragraphs: good.paragraphs.map((p, j) => (j === i ? { ...p, text } : p)) });
  const appended = (i: number, extra: string) => withText(i, `${good.paragraphs[i].text} ${extra}`);
  const failuresOf = (raw: string) => {
    const r = acceptCoffeeV3Narrative(plan, raw);
    return r.ok ? [] : r.failures;
  };

  it('accepts the simulated good reading', () => expect(failuresOf(COFFEE_V3N_RITAG_WRITER_OUTPUT)).toEqual([]));
  it.each([
    ['generic cliché', appended(1, 'Her şey yoluna girecek gibi görünüyor.'), 'generic_cliche'],
    ['absolute certainty', appended(1, 'Bu kesinlikle olacak gibi.'), 'absolute_certainty'],
    ['advice / command', appended(1, 'Acele etme, belki her şey zamanla netleşebilir.'), 'advice_or_command'],
    ['closing summary', appended(1, 'Kısacası önün açık görünüyor.'), 'closing_summary'],
    ['causal link', appended(1, 'Çünkü seçenekler belirebilir.'), 'causal_link'],
    ['a symbol / shape', appended(1, 'Bir kuş gibi duran şekil de olabilir.'), 'visual_description'],
    ['cup geometry', appended(1, 'Kulbun yanındaki leke de bunu destekliyor gibi.'), 'visual_description'],
    ['analysis narration', appended(1, 'Baktığımda bu ihtimal dikkatimi çekiyor gibi.'), 'visual_description'],
    ['an empty fits-anyone line', appended(1, 'Önünde güzel gelişmeler var gibi görünüyor.'), 'generic_cliche'],
    ['unsupported specific event', appended(1, 'Yakında bir düğün olabilir.'), 'unsupported_specific'],
    ['a date', appended(1, 'Belki de ekim ayında netleşebilir.'), 'unsupported_specific'],
    ['a number', appended(1, 'Belki üç ay içinde, 3 seçenek belirebilir.'), 'unsupported_specific'],
    ['a proper name', appended(1, 'Belki Ahmet de bu yolda olabilir.'), 'proper_name'],
    ['meta language', appended(1, 'Bu gözlem ihtimal anlatıyor.'), 'meta_language'],
    ['contradiction with a claim', withText(0, good.paragraphs[0].text.replace('ivme kazandığı hissediliyor', 'ivme kazandığı ama sonra geriye gidiyor gibi olduğu hissediliyor')), 'contradiction'],
    ['repetition', appended(1, good.paragraphs[1].text), 'repetitive'],
    ['no tentative language', withText(1, 'Önümüzdeki dönemde önünde birden fazla seçenek beliriyor. Bu seçenekler birbirinden ayrışıyor ve kararın netleşiyor.'), 'not_tentative'],
    ['padding beyond the evidence budget', appended(1, Array.from({ length: 50 }, (_, i) => `Seçeneklerin ${['biri', 'öteki', 'bir başkası', 'hepsi', 'çoğu'][i % 5]} ${['yarın', 'sonra', 'bir gün', 'zamanla', 'yavaşça'][Math.floor(i / 5) % 5]} ${['belirebilir', 'netleşebilir', 'ayrışabilir', 'çoğalabilir', 'değişebilir', 'durulabilir', 'güçlenebilir', 'şekillenebilir', 'yönlenebilir', 'olgunlaşabilir'][Math.floor(i / 5)]}.`).join(' ')), 'padded'],
    ['fluent but generic, not anchored to the claim', withText(1, 'Önümüzdeki dönem senin için oldukça anlamlı olabilir. İçindeki ses sana yol gösterebilir ve hissettiklerin daha da derinleşebilir. Zaman sana kendi cevabını getirebilir gibi görünüyor.'), 'ungrounded_claim'],
  ])('rejects %s', (_label, raw, expected) => expect(failuresOf(raw)).toContain(expected));

  it('the writer shapes the story, but cannot invent claims, exceed three paragraphs or leave the core untold', () => {
    // Invented id / duplicate id / empty text / more than three paragraphs: structural refusal.
    expect(failuresOf(JSON.stringify({ paragraphs: [{ ...good.paragraphs[0], claims: ['c1', 'c2', 'c9'] }, good.paragraphs[1]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf(JSON.stringify({ paragraphs: [{ ...good.paragraphs[0], claims: ['c1', 'c1'] }, good.paragraphs[1]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf(JSON.stringify({ paragraphs: [{ ...good.paragraphs[0], text: ' ' }, good.paragraphs[1]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[0], good.paragraphs[1], good.paragraphs[1], good.paragraphs[1]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf('not json')).toEqual(['malformed_json']);
    // A required (core / support) meaning left out of every paragraph is untold.
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[1]] }))).toContain('ungrounded_claim');
    // Declaring a meaning the paragraph never tells is refused.
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[0], { ...good.paragraphs[1], claims: ['c3', 'c2'] }] }))).toContain('ungrounded_claim');
    // Reordering and leaving the optional (minor) meaning out are the writer's choice.
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[1], good.paragraphs[0]] }))).not.toContain('paragraph_structure');
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[0]] }))).toEqual([]);
  });

  it('a strong sign is told by its LIFE meaning only: naming the sign itself is refused even though it was seen', () => {
    const premium = planOf(coffeeV3PremiumSpec());
    expect(premium.claims.find((c) => c.symbol === 'ağaç')).toBeTruthy(); // evidence kept server-side
    const out = JSON.parse(COFFEE_V3N_PREMIUM_WRITER_OUTPUT) as { paragraphs: Array<{ claims: string[]; text: string }> };
    expect(acceptCoffeeV3Narrative(premium, COFFEE_V3N_PREMIUM_WRITER_OUTPUT).ok).toBe(true);
    expect(COFFEE_V3N_PREMIUM_WRITER_OUTPUT).not.toMatch(/ağaç|ağac/u);
    const named = JSON.stringify({ paragraphs: [{ ...out.paragraphs[0], text: `Bir ağaç belirebilir gibi. ${out.paragraphs[0].text}` }, out.paragraphs[1]] });
    const r = acceptCoffeeV3Narrative(premium, named);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('visual_description');
  });

  it('every SIMULATED scenario (different cups and intentions) passes the gates with life-only language', () => {
    for (const s of COFFEE_V3N_SIMULATED_SCENARIOS) {
      const plan = planOf(c31Spec(s.setId, { clearAreas: true }), s.intention);
      const r = acceptCoffeeV3Narrative(plan, s.output);
      expect(r.ok, `${s.setId}: ${r.ok ? '' : r.details.join(',')}`).toBe(true);
      if (r.ok) {
        expect(r.reading, s.setId).not.toMatch(VISUAL_WORDS);
        expect(r.metrics.words, s.setId).toBeGreaterThanOrEqual(plan.budget.minWords);
      }
    }
  });

  it('no token-substring false positives: "çevrene" is not "evren", "aralık" (a gap) is not a date, "birden fazla" is not "birdenbire"', () => {
    expect(failuresOf(appended(1, 'Önündeki açılım sana ve çevrene ferah bir aralık bırakabilir.'))).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// Pipeline (fake transport; zero real provider calls)
// ---------------------------------------------------------------------------

function fakeTransport(observation: unknown, writer: string[]) {
  const calls: OpenAiCompleteOptions[] = [];
  const queue = [...writer];
  return {
    calls,
    observerCalls: () => calls.filter((c) => c.jsonSchema?.name === 'coffee_v3_observation'),
    writerCalls: () => calls.filter((c) => c.jsonMode === true),
    transport: {
      async complete(options: OpenAiCompleteOptions): Promise<string> {
        calls.push(options);
        if (options.jsonSchema?.name === 'coffee_v3_observation') return JSON.stringify(observation);
        const next = queue.shift();
        if (next === undefined) throw new Error('unexpected_extra_writer_call');
        return next;
      },
    },
  };
}
const STAGED = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
async function run(observation: unknown, writer: string[], opts: { intention?: string; expectedPromptSha256?: string; language?: 'tr' | 'en' } = {}) {
  const fake = fakeTransport(observation, writer);
  let result: Record<string, unknown> | null = null;
  let error: unknown = null;
  try {
    result = await runCoffeeV3NarrativeReading({
      config: testConfig(),
      transport: fake.transport,
      stageStore: createReadingStageStore(),
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: opts.intention ?? DECISION,
      language: opts.language ?? 'tr',
      identity: 'owner-a',
      parentKey: 'reading-operation:v3n',
      ...(opts.expectedPromptSha256 ? { expectedPromptSha256: opts.expectedPromptSha256 } : {}),
    });
  } catch (e) {
    error = e;
  }
  return { ...fake, result, error };
}
const failure = (e: unknown) => (e instanceof CoffeeV3TerminalFailure ? `${e.failureCode}:${e.reason}` : String(e));

describe('first real V3N run failure: diagnosis and proven false rejections', () => {
  /**
   * A synthetic cup with the SAME plan shape as the real run (opening + settling
   * in paragraph 1, a turn toward the outer world in paragraph 2, all "near",
   * general intention). The real observation stays outside the repository.
   */
  const LIVE_SHAPE: M1FixtureSpec = {
    marks: [
      { id: 'O', label: null, kind: 'clear_area', band: 'rim_upper', bandCoverage: ['rim_upper', 'middle', 'lower_base'] },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle', 'lower_base'], hours: 4 },
      { id: 'T', label: null, topology: 'line', form: { course: 'bending' }, band: 'rim_upper', hours: 6 },
    ],
  };
  const P1 = 'Yakın zamanda iş tarafında önünün açılabileceği, sana nefes aldıran ferah bir alan oluşabileceği hissediliyor. Bu ferahlıkla birlikte hareketli bir meselenin yavaş yavaş durulup sakinleşebileceği de seziliyor; telaşın yerini daha dingin bir ritim alıyor ve günlerin biraz daha hafif akıyor gibi. Kendi temponu yeniden bulman için bu rahatlama sana alan bırakabilir.';
  const P2 = 'Aynı dönemde dışarıdaki, daha uzak çevrelerde beklenmedik bir dönüş belirebilir. Planladığından biraz farklı bir yöne doğru bir değişim, sanki kendiliğinden gelişebilir gibi görünüyor; bu yön değişimi seni yormadan yeni bir yol açıyor gibi.';
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3'], text: p2 }] });
  const plan = () => planAllOf(LIVE_SHAPE, GENERAL);
  const findingsOf = (raw: string) => {
    const r = acceptCoffeeV3Narrative(plan(), raw);
    return r.ok ? [] : r.findings;
  };

  it('the synthetic fixture reproduces the real plan shape (3 claims, 2 paragraphs, all near, general focus)', () => {
    const p = plan();
    expect(p.claims.map((c) => c.theme)).toEqual(['opening', 'settling', 'turn']);
    expect(p.claims.map((c) => c.horizon)).toEqual(['near', 'near', 'near']);
    expect(p.claims[2].placement).toBe('outer_world');
    expect(p.paragraphs).toEqual([{ role: 'opening', claims: ['c1', 'c2'] }, { role: 'development', claims: ['c3'] }]);
    expect(p.focus).toMatchObject({ kind: 'general', area: null });
    // Owner decision: the floor only flags an obviously incomplete text (no fixed 76).
    expect(p.budget).toEqual({ minWords: 40, maxWords: 220 });
    expect(acceptCoffeeV3Narrative(p, out(P1, P2)).ok).toBe(true);
  });

  it.each([
    ['manner adverbial "bir şekilde" is life language, not a shape', P1.replace('yavaş yavaş durulup', 'sakin bir şekilde durulup')],
    ['echoing the question words "genel olarak" inside a sentence', P1.replace('Yakın zamanda iş tarafında', 'Yakın zamanda, genel olarak bakınca, iş tarafında')],
    ['the emotional "kalbinde" is not the heart sign', P1.replace('de seziliyor;', 'kalbinde de seziliyor;')],
  ])('PROVEN false rejection fixed: %s', (_label, p1) => {
    const r = acceptCoffeeV3Narrative(plan(), out(p1, P2));
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('PROVEN false rejection fixed: a capital after a colon starts a sentence (TDK), not a name', () => {
    const r = acceptCoffeeV3Narrative(plan(), out(P1, `${P2.slice(0, -1)}: Bu değişim sana iyi gelebilir.`));
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it.each([
    ['naming the heart sign', out(P1.replace('Yakın zamanda', 'Bir kalp belirebilir; yakın zamanda'), P2), 'visual_description', 'kalp'],
    ['a shape', out(P1, `${P2} Bu şekil sana yön gösteriyor gibi.`), 'visual_description', 'şekil'],
    ['"Genel olarak" as an opener', out(`Genel olarak ${P1.charAt(0).toLocaleLowerCase('tr-TR')}${P1.slice(1)}`, P2), 'generic_cliche', 'genel olarak'],
    ['a real proper name mid-sentence', out(P1, P2.replace('dışarıdaki,', 'Ahmet ile dışarıdaki,')), 'proper_name', '[redacted]'],
  ])('still refused (quality not loosened): %s', (_label, raw, code, term) => {
    expect(findingsOf(raw)).toEqual(expect.arrayContaining([expect.objectContaining({ code, term })]));
  });

  it('findings attribute each refusal to its paragraph and claim; a suspected name is never recorded', () => {
    const raw = out('Yakın zamanda her şey yoluna girecek gibi görünüyor ve kendini daha iyi hissedebilirsin, Ahmet.', `${P2} Fincanında bunu görüyorum.`);
    const f = findingsOf(raw);
    expect(f).toEqual(expect.arrayContaining([
      expect.objectContaining({ code: 'generic_cliche', paragraph: 1, term: 'her şey yoluna girecek' }),
      expect.objectContaining({ code: 'ungrounded_claim', paragraph: 1, claim: 'c1' }),
      expect.objectContaining({ code: 'ungrounded_claim', paragraph: 1, claim: 'c2' }),
      expect.objectContaining({ code: 'visual_description', paragraph: 2, term: 'fincanında' }),
      expect.objectContaining({ code: 'proper_name', paragraph: 1, term: '[redacted]' }),
    ]));
    expect(JSON.stringify(f)).not.toContain('Ahmet');
  });

  it('a pipeline refusal records structured reasons per attempt in the operation stage — no text, no secret', async () => {
    const store = createReadingStageStore();
    const thinOut = out('Bir yol beliriyor gibi.', 'Fincanında bir şekil var gibi.');
    const fake = fakeTransport(three(LIVE_SHAPE), [thinOut, thinOut]);
    const err = await runCoffeeV3NarrativeReading({
      config: testConfig(), transport: fake.transport, stageStore: store,
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: GENERAL, language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:diag',
    }).catch((e) => e);
    expect(failure(err)).toMatch(/^unavailable:v3n_quality_gates_failed:a1=.*visual_description.*;a2=/);
    const rejections = store.get<Array<Record<string, unknown>>>('owner-a', 'reading-operation:diag', COFFEE_V3N_WRITER_REJECTIONS_STAGE);
    expect(rejections).toHaveLength(2);
    expect(rejections![0]).toMatchObject({ attempt: 1, outputChars: thinOut.length, failures: expect.arrayContaining(['too_thin', 'visual_description']) });
    expect(rejections![0].outputSha256).toMatch(/^[0-9a-f]{64}$/);
    expect(rejections![0].findings).toEqual(expect.arrayContaining([expect.objectContaining({ code: 'visual_description', paragraph: 2 })]));
    const stored = JSON.stringify(rejections);
    expect(stored).not.toContain('Bir yol beliriyor gibi');
    expect(stored).not.toMatch(/Bearer|sk-|data:image/);
  });
});

describe('premium acceptance is decided by meaning coverage, not length (comparable ~50–65 word fixtures)', () => {
  const LIVE_SHAPE: M1FixtureSpec = {
    marks: [
      { id: 'O', label: null, kind: 'clear_area', band: 'rim_upper', bandCoverage: ['rim_upper', 'middle', 'lower_base'] },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle', 'lower_base'], hours: 4 },
      { id: 'T', label: null, topology: 'line', form: { course: 'bending' }, band: 'rim_upper', hours: 6 },
    ],
  };
  const plan = () => planAllOf(LIVE_SHAPE, GENERAL);
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3'], text: p2 }] });
  const GOOD_P1 = 'Yakın zamanda iş tarafında önünün açılabileceği, sana nefes aldıran ferah bir alan oluşabileceği hissediliyor. Bu ferahlıkla birlikte hareketli bir meselenin yavaş yavaş durulup sakinleşebileceği de seziliyor; telaşın yerini daha dingin bir ritim alabilir.';
  const GOOD_P2 = 'Aynı dönemde dışarıdaki, daha uzak çevrelerde beklenmedik bir dönüş belirebilir. Planladığından biraz farklı bir yöne doğru bir değişim, sanki kendiliğinden gelişebilir gibi görünüyor.';

  /** SIMULATED, authored offline — comparable length; only meaning differs. */
  const POSITIVE: Array<[string, string]> = [
    ['all three claims told naturally', out(GOOD_P1, GOOD_P2)],
    ['different natural wording', out(
      'Kısa süre içinde nefesinin biraz açılabileceği, iş tarafında önünün ferahlayabileceği seziliyor. Hareketli bir mesele de yavaş yavaş sakinleşip yerine oturabilir ve günlerin daha dengeli akıyor gibi görünüyor.',
      'Bu dönemde dış çevrende beklenmedik bir dönüş yaşanabilir; işler planladığından farklı bir yöne değişiyor ve bu değişim sana yeni bir bakış açısı kazandırıyor gibi.',
    )],
  ];
  const NEGATIVE: Array<[string, string, string]> = [
    ['fluent but generic (no claim told)', out(
      'Yakın zamanda hayatında anlamlı şeylerin yaşanabileceği hissediliyor. İçindeki ses sana doğru yolu gösterebilir ve hissettiklerin derinleşebilir; kendine biraz daha güvenebileceğin bir dönem gibi görünüyor.',
      'Dışarıdaki çevrelerde de seni mutlu edecek gelişmeler olabilir, belki yeni insanlarla tanışabilirsin. Zaman sana kendi cevabını getirebilir gibi; hayatın akışı sanki senden yana çevrilebilir.',
    ), 'ungrounded_claim'],
    ['keyword list instead of meaning', out(
      'Yakın zamanda açılım, ferahlık, sakinleşme ve durulma görülebilir. Bunlar hayatının farklı konuları gibi; her biri ayrı bir anlam taşıyabilir ve sana bir şeyler anlatabilir.',
      'Aynı dönemde dışarıda beklenmedik bir dönüş, yön değişimi. Hepsi bir arada düşünüldüğünde dönem hareketli ama anlamlı görünebilir ve sana düşünmek için biraz zaman tanıyabilir.',
    ), 'claim_underdeveloped'],
    ['a planned claim left untold', out(
      GOOD_P1,
      'Aynı dönemde dışarıdaki, daha uzak çevrelerde insanlarla ilişkilerin hareketlenebilir. Biraz daha sosyal, biraz daha canlı bir ritim sanki seni çağırıyor olabilir.',
    ), 'ungrounded_claim'],
    ['a claim told without its supported place', out(
      GOOD_P1,
      'Aynı dönemde beklenmedik bir dönüş belirebilir. Planladığından biraz farklı bir yöne doğru bir değişim, sanki kendiliğinden ve sessizce gelişebilir gibi görünüyor.',
    ), 'claim_incomplete'],
    ['an unsupported, certain prediction', out(
      GOOD_P1,
      'Aynı dönemde dışarıdaki, daha uzak çevrelerden beklenmedik bir dönüş olarak bir iş teklifi alacaksın; planladığından farklı bir yöne doğru bir değişim yaşanabilir.',
    ), 'certain_prediction'],
    ['a contradiction with a claim', out(
      GOOD_P1.replace('yavaş yavaş durulup sakinleşebileceği', 'hızlanıyor gibi görünüp sonra sakinleşebileceği'),
      GOOD_P2,
    ), 'contradiction'],
    ['visual description', out(
      GOOD_P1,
      'Kulbun karşısındaki kıvrılan iz, dışarıdaki çevrelerde beklenmedik bir dönüşe işaret ediyor gibi; planladığından farklı bir yöne değişim belirebilir.',
    ), 'visual_description'],
    ['repetition', out(
      GOOD_P1,
      'Aynı dönemde dışarıdaki, daha uzak çevrelerde beklenmedik bir dönüş belirebilir. Daha uzak çevrelerde beklenmedik bir dönüş, sanki kendiliğinden gelişebilir gibi görünüyor.',
    ), 'repetitive'],
  ];
  const wordsOf = (raw: string) => (JSON.parse(raw) as { paragraphs: Array<{ text: string }> }).paragraphs.reduce((n, p) => n + words(p.text), 0);

  it('every positive and negative fixture is of comparable length (48–68 words)', () => {
    const outOfBand = [...POSITIVE, ...NEGATIVE.map(([l, r]) => [l, r] as [string, string])]
      .map(([label, raw]) => [label, wordsOf(raw)] as const)
      .filter(([, n]) => n < 48 || n > 68);
    expect(outOfBand).toEqual([]);
  });

  it.each(POSITIVE)('ACCEPTED (~50–65 words is eligible): %s', (_label, raw) => {
    const r = acceptCoffeeV3Narrative(plan(), raw);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it.each(NEGATIVE)('REJECTED at the same length: %s', (_label, raw, code) => {
    const r = acceptCoffeeV3Narrative(plan(), raw);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.failures).toContain(code);
      expect(r.failures).not.toContain('too_thin'); // length is not what refused it
      expect(r.findings.length).toBeGreaterThan(0);
    }
  });

  it('three claims alone never earn acceptance: the claim count is identical in every fixture above', () => {
    expect(plan().claims).toHaveLength(3);
    expect(NEGATIVE.length).toBeGreaterThan(POSITIVE.length);
  });

  it('a horizon back-reference ("Aynı dönemde") counts only when that time was already stated', () => {
    const noEarlierHorizon = out(GOOD_P1.replace('Yakın zamanda iş', 'İş'), GOOD_P2);
    const r = acceptCoffeeV3Narrative(plan(), noEarlierHorizon);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('claim_incomplete');
  });

  it('REGRESSION: the previous real two-sentence reading stays refused (thin and incomplete)', () => {
    const p = plan();
    const live = out(LIVE_THIN_READING.split('. ')[0] + '.', LIVE_THIN_READING.split('. ')[1]);
    const r = acceptCoffeeV3Narrative(p, live);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toEqual(expect.arrayContaining(['too_thin', 'ungrounded_claim']));
  });
});

describe('claim-scoped contradiction (real run: c1 forbids "ara ara", c2 in the same paragraph licenses it)', () => {
  /**
   * A continuous-tempo claim and a broken branching course told in one
   * paragraph. (The real run's continuous claim was a clear area — a clear
   * area no longer carries any tempo; a continuous descending trail does.)
   */
  const SHARED: M1FixtureSpec = {
    marks: [
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', continuity: 'continuous' }, band: 'rim_upper' },
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken' }, band: 'rim_upper' },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const P2 = 'İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin.';
  const P1_STEADY = 'Yakın zamanda zihnini yoran telaşın yavaş yavaş durulup sakinleşebileceği seziliyor; bu sakinlik kesintisiz bir akış gibi.';
  const shared = () => {
    const p = planAllOf(SHARED, GENERAL);
    const steady = p.claims.find((c) => c.theme === 'settling')!;
    const options = p.claims.find((c) => c.theme === 'options')!;
    return { p, steady, options };
  };
  const outFor = (p1: string) => {
    const { p } = shared();
    return JSON.stringify({ paragraphs: p.paragraphs.map((para, i) => ({ claims: para.claims, text: i === 0 ? p1 : P2 })) });
  };
  const check = (p1: string) => acceptCoffeeV3Narrative(shared().p, outFor(p1));
  const STEADY_ARA_ARA = 'Yakın zamanda zihnini yoran telaş ara ara durulup sakinleşebilir gibi. Yakın zamanda önünde birden fazla seçenek belirebilir; bu seçenekler kendi temposunda netleşebilir.';

  it('the fixture reproduces the conflict: one paragraph, the continuous claim forbids "ara ara", c-options licenses it', () => {
    const { p, steady, options } = shared();
    expect(p.paragraphs[0].claims).toEqual(expect.arrayContaining([steady.id, options.id]));
    expect(steady.avoid).toContain('ara ara');
    expect(options.qualities).toContain('kesik kesik, ara ara ilerleyen');
  });

  it('POSITIVE: "ara ara" in a sentence that tells ONLY the options claim is accepted', () => {
    const r = check(`${P1_STEADY} Önünde de iki teklif ya da birden fazla seçenek beliriyor; bu seçenekler ara ara, kendi temposunda netleşiyor gibi.`);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: "ara ara" describing the continuous claim itself is still a contradiction', () => {
    const { steady } = shared();
    const r = check(STEADY_ARA_ARA);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.findings).toEqual(expect.arrayContaining([expect.objectContaining({ code: 'contradiction', paragraph: 1, claim: steady.id, term: 'ara ara' })]));
  });

  it('AMBIGUOUS: a sentence telling both claims with "ara ara" is refused (ownership cannot be established)', () => {
    const r = check(`${P1_STEADY} Yakın zamanda telaş durulurken seçenekler de ara ara belirebilir gibi görünüyor; bu da sana yeni bir yol gösterebilir.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('contradiction');
  });

  it('AMBIGUOUS: "ara ara" in a sentence that tells no claim at all is refused, never assumed to be the licensing one', () => {
    const { steady } = shared();
    const r = check(`${P1_STEADY} Yakın zamanda önünde birden fazla seçenek belirebilir gibi görünüyor. Bu süreç de ara ara ilerleyebilir.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.findings).toEqual(expect.arrayContaining([expect.objectContaining({ code: 'contradiction', claim: steady.id, term: 'ara ara' })]));
  });

  it('the refusal stays visible in writerRejections-style findings (code, paragraph, claim, term)', () => {
    const r = check(STEADY_ARA_ARA);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details.some((d) => d.startsWith('contradiction:'))).toBe(true);
  });
});

describe('narrative quality (first accepted real reading: generic, repetitive, mechanical) — same four-claim plan', () => {
  /**
   * Synthetic cup with the SAME plan shape as the accepted real run (the owner's
   * observation stays outside the repo): options + settling (near) open the
   * reading; a saucer flow toward the edge (release) and a saucer turn close it.
   */
  const FOUR: M1FixtureSpec = {
    marks: [
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const plan = () => planAllOf(FOUR, GENERAL);
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3', 'c4'], text: p2 }] });

  /** SIMULATED "before": the accepted real reading's style (copied notes, placeholders, a hedge in every clause). */
  const BEFORE = out(
    'Yakın zamanda önünde birden fazla seçenek ya da yön belirebilir. Bunlar zamanla birbirinden ayrışırken süreç ara ara ilerleyebilir; ucu açık ve uzun soluklu bir dönem hissi verebilir. Aynı zamanda hareketli bir konu da yavaş yavaş yerine oturabilir ve telaşın azaldığı bir akış başlayabilir.',
    'İçinde tuttuğun bir şeyin dışarı akması, paylaşma isteğiyle birlikte bir hafifleme getirebilir. Bunun yanı sıra bir konuda farklı bir yöne dönebilirsin; yeni bir yön belirdiğinde gidişat beklenmedik biçimde değişebilir.',
  );
  /** SIMULATED "after": the same four meanings as one connected, personal story (authored offline, NOT provider output). */
  const AFTER = out(
    'Yakın zamanda önünde iki teklif ya da birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
    'Sakinliğin ortasında, içinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe hafiflediğini, omuzlarındaki yükün azaldığını fark edebilirsin. Aynı günlerde kendini planladığından biraz farklı bir yöne dönerken bulman da olası; beklenmedik ama sana yabancı gelmeyecek bir dönüş gibi.',
  );

  it('the fixture reproduces the real four-claim plan shape', () => {
    const p = plan();
    expect(p.claims.map((c) => c.theme)).toEqual(['options', 'settling', 'release', 'turn']);
    expect(p.claims.map((c) => c.horizon)).toEqual(['near', 'near', null, null]);
    expect(p.paragraphs.map((x) => x.claims)).toEqual([['c1', 'c2'], ['c3', 'c4']]);
    // At most two qualities per claim, tempo first (the real writer pasted all three).
    expect(p.claims[0].qualities).toEqual(['kesik kesik, ara ara ilerleyen', 'zamana yayılan, uzun soluklu']);
  });

  it('BEFORE (generic, mechanical) is now refused as mechanical style — placeholders and a hedge in every clause', () => {
    const r = acceptCoffeeV3Narrative(plan(), BEFORE);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.failures).toContain('mechanical_style');
      expect(r.details.some((d) => d.startsWith('mechanical_style:placeholders='))).toBe(true);
      expect(r.details.some((d) => d.startsWith('mechanical_style:hedges='))).toBe(true);
    }
  });

  it('AFTER (connected, personal, varied) passes every existing gate with the same four meanings', () => {
    const r = acceptCoffeeV3Narrative(plan(), AFTER);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
    if (r.ok) expect(r.reading).not.toMatch(VISUAL_WORDS);
  });

  it.each([
    ['fabricated specificity (a specific person)', out(
      'Yakın zamanda önünde iki teklif ya da birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
      'Sakinliğin ortasında, eski bir arkadaşınla içinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe hafiflediğini fark edebilirsin. Aynı günlerde kendini planladığından biraz farklı bir yöne dönerken bulman da olası; beklenmedik bir dönüş gibi.',
    ), 'unsupported_specific'],
    ['unsupported causation between two meanings', out(
      'Yakın zamanda önünde iki teklif ya da birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
      'Sakinliğin ortasında, içinde biriktirdiklerini paylaşma isteği uyanabilir ve hafifleyebilirsin. Bu hafifleme sayesinde planladığından farklı bir yöne dönerken bulabilirsin kendini; beklenmedik bir dönüş gibi.',
    ), 'causal_link'],
    ['a certain prediction', AFTER.replace('dönerken bulman da olası', 'döneceksin'), 'certain_prediction'],
  ])('NEGATIVE: %s', (_label, raw, code) => {
    const r = acceptCoffeeV3Narrative(plan(), raw);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain(code);
  });

  it('the writer prompt now asks for one connected story, own words, varied intuition and no definite future', () => {
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('Bu bir hikâyedir, madde listesi değil.');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('kopyalanacak cümle DEĞİLDİR');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('her cümleyi "-abilir" ile bitirme');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('"-acaksın / -eceksin" yok');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('Hiçbir yerde kesin sebep-sonuç yok');
    // Fortune-teller contract: concrete life scenes, linked meanings as one development, unlinked side by side.
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('lifeScenes listesindeki gündelik hayat gelişmelerinden');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('Bağı olmayan anlamları aynı dönemde yan yana anlat');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('sağlık, hastalık, hamilelik, ölüm, kaza');
    expect(COFFEE_V3N_WRITER_PROMPT).not.toContain('("hafiften", "belli belirsiz").');
  });
});

describe('cross-kind possible-same pair (real run: residue patch ~ clear area destroyed a usable reading)', () => {
  /** Synthetic (the owner's observation stays outside the repo): a usable cup plus one residue~clear-area pair. */
  const CROSS: M1FixtureSpec = {
    marks: [
      { id: 'R', label: null, topology: 'patch', form: { grouping: 'clustered' }, band: 'middle' },
      { id: 'C', label: null, kind: 'clear_area', band: 'middle', hours: 5 },
      { id: 'L', label: null, topology: 'line', form: { verticalDirection: 'rising' }, band: 'rim_upper' },
      { id: 'B', label: null, topology: 'line', form: { course: 'branching' }, band: 'lower_base' },
      { id: 'L2', label: null, topology: 'line', form: { verticalDirection: 'rising' }, band: 'rim_upper', hours: 9 },
    ],
    ambiguities: [['R', 'C'], ['L', 'L2']],
  };
  const obsOf = (spec: M1FixtureSpec) => three(spec);

  it('the frozen map still refuses the raw pair (its contract is unchanged)', () => {
    expect(buildCoffeeV3MarkMap(obsOf(CROSS))).toEqual({ status: 'invalid', failure: 'cross_kind_ambiguity' });
  });

  it('POSITIVE: only the cross-kind pair is excluded; both marks keep their own kind; nothing is merged or reclassified', () => {
    const obs = obsOf(CROSS);
    const before = JSON.stringify(obs);
    const { observation, excluded } = excludeCrossKindAmbiguities(obs);
    expect(JSON.stringify(obs)).toBe(before); // the original observation is untouched
    expect(excluded).toEqual([{ marks: ['R', 'C'], kinds: ['residue', 'clear_area'], reason: 'cross_kind_not_mergeable' }]);
    expect(observation.ambiguities.map((a) => a.marks)).toEqual([['L', 'L2']]); // same-kind pair kept
    expect(observation.marks).toEqual(obs.marks);
    const built = buildCoffeeV3MarkMap(observation);
    if (built.status !== 'ok') throw new Error(built.status);
    const r = built.map.cupMarks.find((m) => m.id === 'R')!;
    const c = built.map.cupMarks.find((m) => m.id === 'C')!;
    expect(r.kind).toBe('residue');
    expect(c.kind).toBe('clear_area');
    expect(r.identityGroup).not.toBe(c.identityGroup); // never merged
    expect(built.map.cupMarks.find((m) => m.id === 'L')!.identityGroup).toBe(built.map.cupMarks.find((m) => m.id === 'L2')!.identityGroup);
  });

  it('the unresolved identity keeps the affected claims soft in the narrative plan', () => {
    const { observation, excluded } = excludeCrossKindAmbiguities(obsOf(CROSS));
    const built = buildCoffeeV3MarkMap(observation);
    if (built.status !== 'ok') throw new Error(built.status);
    const soft = new Set(excluded.flatMap((e) => e.marks));
    const plan = planCoffeeV3Narrative(built.map, classifyCoffeeIntention(GENERAL), { softMarks: soft });
    expect(plan.status).toBe('planned');
    const affected = plan.claims.filter((c) => c.provenance.marks.some((m) => soft.has(m)));
    expect(affected.length).toBeGreaterThan(0);
    for (const c of affected) expect(c.certainty, c.id).toBe('soft');
    expect(planCoffeeV3Narrative(built.map, classifyCoffeeIntention(GENERAL)).claims.find((c) => c.theme === 'opening')?.certainty).toBe('clear');
  });

  it.each([
    ['an ambiguity naming an unknown mark', { ...CROSS, ambiguities: [['R', 'C'], ['L', 'NOPE']] as Array<[string, string]> }, 'unknown_ambiguity_mark'],
    ['a self ambiguity', { ...CROSS, ambiguities: [['R', 'C'], ['L', 'L']] as Array<[string, string]> }, 'self_ambiguity'],
    ['a duplicated same-kind ambiguity', { ...CROSS, ambiguities: [['R', 'C'], ['L', 'L2'], ['L2', 'L']] as Array<[string, string]> }, 'duplicate_ambiguity'],
  ])('NEGATIVE (still fail-closed): %s', (_label, spec, failure) => {
    const { observation } = excludeCrossKindAmbiguities(obsOf(spec as M1FixtureSpec));
    expect(buildCoffeeV3MarkMap(observation)).toEqual({ status: 'invalid', failure });
  });

  it('NEGATIVE: other cross-kind evidence errors (a resemblance on a clear area) still fail closed', () => {
    const spec: M1FixtureSpec = { ...CROSS, marks: CROSS.marks.map((m) => (m.id === 'C' ? { ...m, resemblances: [{ label: 'tree', strength: 'strong' as const }] } : m)) };
    const { observation } = excludeCrossKindAmbiguities(obsOf(spec));
    expect(buildCoffeeV3MarkMap(observation)).toEqual({ status: 'invalid', failure: 'clear_area_resemblance' });
  });

  it('the pipeline proceeds to the writer, records the exclusion, and never alters the cached observation', async () => {
    const store = createReadingStageStore();
    const obs = obsOf(CROSS);
    const fake = fakeTransport(obs, ['not json', 'not json']);
    const err = await runCoffeeV3NarrativeReading({
      config: testConfig(), transport: fake.transport, stageStore: store,
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: GENERAL, language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:cross',
    }).catch((e) => e);
    // No map failure any more: the run reached the (scripted, failing) writer.
    expect(failure(err)).toMatch(/^unavailable:v3n_quality_gates_failed:/);
    expect(fake.writerCalls()).toHaveLength(2);
    expect(store.get('owner-a', 'reading-operation:cross', COFFEE_V3_OBSERVATION_ADJUSTMENTS_STAGE)).toEqual({
      excluded: [{ marks: ['R', 'C'], kinds: ['residue', 'clear_area'], reason: 'cross_kind_not_mergeable' }],
    });
    const cached = store.get<{ ambiguities: Array<{ marks: string[] }> }>('owner-a', 'reading-operation:cross', 'coffee_v3_observer');
    expect(cached?.ambiguities.map((a) => a.marks)).toEqual([['R', 'C'], ['L', 'L2']]);
  });

  it('writer-only replay: a cached (recorded) observation is used verbatim — zero observer requests', async () => {
    const store = createReadingStageStore();
    const recorded = obsOf(CROSS);
    const before = JSON.stringify(recorded);
    store.set('owner-a', 'reading-operation:replay', COFFEE_V3_OBSERVER_STAGE, structuredClone(recorded));
    const fake = fakeTransport({ never: 'used' }, ['not json', 'not json']);
    const err = await runCoffeeV3NarrativeReading({
      config: testConfig(), transport: fake.transport, stageStore: store,
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: GENERAL, language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:replay',
    }).catch((e) => e);
    expect(fake.observerCalls()).toHaveLength(0);
    expect(fake.writerCalls()).toHaveLength(2); // the writer budget and every gate are unchanged
    expect(failure(err)).toMatch(/^unavailable:v3n_quality_gates_failed:/);
    expect(JSON.stringify(store.get('owner-a', 'reading-operation:replay', COFFEE_V3_OBSERVER_STAGE))).toBe(before);
  });

  it('the retired M2 path is unchanged: the raw cross-kind pair still ends as map_invalid (no exclusion, no writer)', async () => {
    const store = createReadingStageStore();
    const fake = fakeTransport(obsOf(CROSS), []);
    const err = await runCoffeeV3Reading({
      config: testConfig(), transport: fake.transport, stageStore: store,
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: GENERAL, language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:m2',
    }).catch((e) => e);
    expect(failure(err)).toBe('unavailable:map_invalid:cross_kind_ambiguity');
    expect(fake.observerCalls()).toHaveLength(1);
    expect(fake.writerCalls()).toHaveLength(0);
    expect(store.get('owner-a', 'reading-operation:m2', COFFEE_V3_OBSERVATION_ADJUSTMENTS_STAGE)).toBeNull();
  });
});

describe('final offline review: six-claim real plan shape (options · opening | settling · many_details | release · turn)', () => {
  /** Synthetic (the owner's observation stays outside the repo) with the SAME plan as the replayed real observation. */
  const SIX: M1FixtureSpec = {
    marks: [
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'O', label: null, kind: 'clear_area', band: 'lower_base', hours: 3 },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open', continuity: 'continuous' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'], hours: 4 },
      { id: 'P', label: null, topology: 'patch', form: { grouping: 'clustered', continuity: 'broken' }, band: 'rim_upper', hours: 9 },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const plan = () => planAllOf(SIX, GENERAL);
  const out = (p2: string) => JSON.stringify({
    paragraphs: [
      { claims: ['c1', 'c2'], text: 'Yakın zamanda önünde iki teklif ya da birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar bir anda değil, ara ara ve kendi zamanlarında netleşecek gibi. Daha ileride ise bir konunun önü açılıyor, sana nefes aldıran ferah bir alan doğuyor gibi görünüyor.' },
      { claims: ['c3', 'c4'], text: p2 },
      { claims: ['c5', 'c6'], text: 'İçinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe hafiflediğini fark edebilirsin. Aynı günlerde planladığından biraz farklı bir yöne dönerken bulman da olası; beklenmedik ama sana yabancı gelmeyecek bir dönüş gibi.' },
    ],
  });
  const BUSY = 'Aynı dönemde küçük işler ara ara telaşlı anlar yaşatıp günlerini dolduruyor; kalabalık ama dağınık olmayan bir gündem seziliyor.';

  it('reproduces the real plan: six claims, three paragraphs', () => {
    const p = plan();
    expect(p.claims.map((c) => c.theme)).toEqual(['options', 'opening', 'settling', 'many_details', 'release', 'turn']);
    expect(p.paragraphs.map((x) => x.claims)).toEqual([['c1', 'c2'], ['c3', 'c4'], ['c5', 'c6']]);
    expect(p.claims.map((c) => c.placement)).toEqual([null, null, null, null, null, null]);
  });

  it('options and turn no longer hand the writer the same "a new direction appears" meaning (real reading repeated "yön" three times)', () => {
    const [options, turn] = [plan().claims[0], plan().claims[5]];
    expect(options.meaning).not.toMatch(/yön/u);
    for (const e of turn.elaborations) expect(e).not.toMatch(/yönün belirmesi/u);
  });

  it('settling and many_details share no licensed word: each one, told with its own material, is not refused as the other', () => {
    const p = plan();
    const own = acceptCoffeeV3Narrative(p, out(`Yakın günlerde gündemindeki bir mesele kesintisiz, sakin bir akışla yavaş yavaş durulup yerine oturuyor gibi. ${BUSY}`));
    expect(own.ok, own.ok ? '' : own.details.join(',')).toBe(true);
    for (const e of p.claims[2].elaborations) for (const a of p.claims[3].anchors) expect(e, a).not.toMatch(new RegExp(`(^|\s)${a}`, 'u'));
  });

  it('NEGATIVE kept: a sentence that tells both and carries an avoided term is still refused (ownership ambiguous)', () => {
    const r = acceptCoffeeV3Narrative(plan(), out(`Yakın günlerde hareketli bir mesele kesintisiz, sakin bir akışla yavaş yavaş durulup yerine oturuyor gibi. ${BUSY}`));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toContain('contradiction:c4:kesintisiz');
  });
});

describe('premium quality: meaning tables, hub links, quality cap, copied plan notes (real-cup root causes)', () => {
  const fold = (x: string) => x.normalize('NFC').toLocaleLowerCase('tr-TR');
  const toks = (x: string) => fold(x).match(/[\p{L}\p{N}]+/gu) ?? [];
  const has = (text: string, phrase: string) => {
    const t = toks(text);
    const p = toks(phrase);
    for (let i = 0; i + p.length <= t.length; i += 1) if (p.every((w, j) => t[i + j].startsWith(w))) return true;
    return false;
  };
  const withScenes = (v: { meaning: string; elaborations: string[] }, scenes: string[]) => ({ meaning: v.meaning, elaborations: [...v.elaborations, ...scenes] });
  const entries = [
    ...Object.entries(COFFEE_V3N_TABLES.THEME_TEXT).map(([k, v]) => ({ id: `theme:${k}`, text: withScenes(v, (COFFEE_V3N_TABLES.THEME_SCENES as Record<string, string[]>)[k]), anchors: (COFFEE_V3N_TABLES.THEME_ANCHORS as Record<string, string[]>)[k] })),
    ...Object.entries(COFFEE_V3N_TABLES.SIGN_TEXT).map(([k, v]) => ({ id: `sign:${k}`, text: withScenes(v, (COFFEE_V3N_TABLES.SIGN_SCENES as Record<string, string[]>)[k]), anchors: (COFFEE_V3N_TABLES.SIGN_ANCHORS as Record<string, string[]>)[k] })),
  ];

  it.each(entries.map((e) => [e.id, e] as const))('%s: a lived meaning — no placeholder, own anchor, no other theme’s anchor, no refused word', (_id, e) => {
    const all = [e.text.meaning, ...e.text.elaborations].join(' ');
    // The real reading repeated the tables' "bir konunun / bir konuda / bir şeyin".
    expect(fold(all)).not.toMatch(/\bbir (konu(?!ş)|süreç|şey|yön)/u);
    expect(e.anchors.some((a) => has(e.text.meaning, a)), e.text.meaning).toBe(true);
    // Every elaboration and life scene is recognized as THIS meaning when the writer tells it.
    for (const part of e.text.elaborations) expect(e.anchors.some((a) => has(part, a)), `${e.id}: ${part}`).toBe(true);
    for (const other of entries) {
      if (other.id === e.id) continue;
      for (const a of other.anchors) if (!e.anchors.includes(a)) expect(has(all, a), `${e.id} uses ${other.id} anchor "${a}"`).toBe(false);
    }
    expect(coffeeV3NRefusedTerms(all)).toEqual([]);
  });

  /** Synthetic cup with the real cups' structure: a base pool that the branching and the descending trails run into. */
  const HUB: M1FixtureSpec = {
    marks: [
      { id: 'P', label: null, topology: 'pool', surface: 'cup_base', band: 'lower_base' },
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', continuity: 'continuous', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    relations: [{ a: 'P', b: 'B', kind: 'connected' }, { a: 'P', b: 'S', kind: 'connected' }],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };

  it('POSITIVE: claims joined through an unclaimed hub (the base pool) are linked; the pool itself stays context', () => {
    const p = planOf(HUB, GENERAL);
    expect(p.claims.map((c) => c.theme)).toEqual(['options', 'settling', 'release', 'turn']);
    expect(p.claims.some((c) => c.provenance.marks.includes('P'))).toBe(false);
    expect(p.links).toEqual([{ a: 'c1', b: 'c2', kind: 'linked' }]);
  });

  it('NEGATIVE: no hub link without a connected relation (near / touching never link)', () => {
    expect(planOf({ ...HUB, relations: [] }, GENERAL).links).toEqual([]);
    expect(planOf({ ...HUB, relations: [{ a: 'P', b: 'B', kind: 'near' }, { a: 'P', b: 'S', kind: 'touching' }] }, GENERAL).links).toEqual([]);
    // One claim connected to the hub has nothing to be linked with.
    expect(planOf({ ...HUB, relations: [{ a: 'P', b: 'B', kind: 'connected' }] }, GENERAL).links).toEqual([]);
  });

  it('every claim carries at most two qualities, tempo first', () => {
    for (const spec of [HUB, coffeeV3PremiumSpec()]) {
      for (const c of planOf(spec, GENERAL).claims) {
        expect(c.qualities.length, c.id).toBeLessThanOrEqual(2);
        const tempo = c.qualities.findIndex((q) => q === 'kesintisiz akan' || q === 'kesik kesik, ara ara ilerleyen');
        if (tempo !== -1) expect(tempo, c.id).toBe(0);
      }
    }
  });

  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3', 'c4'], text: p2 }] });
  /** SIMULATED lazy writer: each plan note pasted once, glued with hedges (passed every older gate). */
  const NOTE_DUMP = out(
    'Yakın zamanda önünde birden fazla seçeneğin, bir yol ayrımının belirmesi olası; kesik kesik, ara ara ilerleyen bir hal gibi. Yine yakın günlerde zihnini yoran telaşın yavaş yavaş durulması, günlerinin sakinleşmesi seziliyor; telaşın azaldığı, daha dingin günler gibi.',
    'İçinde tuttuklarını dışa vurman, dile dökünce gelen hafiflik olası; omuzlarındaki yükün hafiflemesi gibi. Planlarında beklenmedik bir dönüş, alışık olduğun düzenin değişmesi de seziliyor; planladığından farklı bir rotaya dönme gibi.',
  );
  /** Human-authored (synthetic) natural telling of the same four meanings, using the hub link. */
  const NATURAL = out(
    'Yakın zamanda kendini iki teklif arasında, bir yol ayrımında bulabilirsin; önünde birden fazla seçenek beliriyor ama hepsi bir anda değil, ara ara ve kendi zamanında netleşiyor gibi. Bu seçeneklerle aynı yerden beslenen bir sakinleşme de var: yakın günlerde zihnini yoran telaş yavaş yavaş duruluyor, içindeki dalgalanma yatışıyor gibi.',
    'İçinde tuttuklarını dile dökme ihtiyacı uyanabilir; paylaştıkça omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde planlarında beklenmedik bir dönüş de olası; alışık olduğun düzen biraz değişiyor ama bu değişim sana yabancı gelmeyecek gibi.',
  );

  it('NEGATIVE: a dump of the plan notes is refused as mechanical style (copied_notes)', () => {
    const r = acceptCoffeeV3Narrative(planAllOf(HUB, GENERAL), NOTE_DUMP);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details.some((d) => d.startsWith('mechanical_style:copied_notes='))).toBe(true);
  });

  it('POSITIVE: the natural, connected telling of the same meanings passes every gate', () => {
    const r = acceptCoffeeV3Narrative(planAllOf(HUB, GENERAL), NATURAL);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });
});

describe('after the first real writer run: natural Turkish no longer refused, real defects still refused', () => {
  /** Synthetic cup with the SAME six-claim plan as the replayed real observation. */
  const SIX_REAL: M1FixtureSpec = {
    marks: [
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'O', label: null, kind: 'clear_area', band: 'lower_base', hours: 3, form: { continuity: 'continuous' } },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open', continuity: 'continuous' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'], hours: 4 },
      { id: 'P', label: null, topology: 'patch', form: { grouping: 'clustered', continuity: 'broken' }, band: 'rim_upper', hours: 9 },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const plan = () => planAllOf(SIX_REAL, GENERAL);
  const P1 = 'Yakın zamanda kendini iki teklif arasında, bir yol ayrımında bulabilirsin; önünde birden fazla seçenek beliriyor ama hepsi bir anda değil, ara ara netleşiyor gibi. Daha ileride ise içini ferahlatan bir genişlik seziliyor; sanki derin bir nefes almana alan açılıyor gibi.';
  const P2 = (near: string) => `${near} zihnini yoran telaş yavaş yavaş duruluyor, günlerin daha dingin akmaya başlıyor gibi. Küçük işler ve ayrıntılar da ara ara yoğunlaşıp günlerini dolduruyor; kalabalık ama dağınık olmayan, canlı bir tempo bu.`;
  const P3 = 'İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde planlarında beklenmedik bir dönüş de olası; alışık olduğun düzen biraz değişiyor ama bu değişim sana yabancı gelmeyecek gibi.';
  const raw = (a: string, b: string, c: string) =>
    JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: a }, { claims: ['c3', 'c4'], text: b }, { claims: ['c5', 'c6'], text: c }] });
  const verdict = (a: string, b: string, c: string) => acceptCoffeeV3Narrative(plan(), raw(a, b, c));

  it('the fixture has the real plan shape', () => {
    expect(plan().claims.map((c) => c.theme)).toEqual(['options', 'opening', 'settling', 'many_details', 'release', 'turn']);
  });

  it('a clear area carries no tempo: no "kesintisiz akan" quality, no "ara ara" ban on the opening', () => {
    const opening = plan().claims.find((c) => c.theme === 'opening')!;
    expect(opening.qualities).not.toContain('kesintisiz akan');
    expect(opening.qualities).not.toContain('kesik kesik, ara ara ilerleyen');
    expect(opening.avoid).not.toContain('ara ara');
    // The real second sample's pattern: the options' "ara ara" beside an opening word.
    const r = verdict('Yakın zamanda önünde iki teklif ya da birden fazla seçenek beliriyor; bunlar ara ara netleşirken içine ferah bir nefes de doluyor gibi. Daha ileride ise içini ferahlatan bir genişlik seziliyor; sanki derin bir nefes almana alan açılıyor gibi.', P2('Yakın günlerde'), P3);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it.each(['Yakın günlerde', 'Bu aralar', 'Şu günlerde', 'Önümüzdeki haftalarda', 'Kısa vadede'])('natural near time "%s" conveys the horizon', (near) => {
    const r = verdict(P1, P2(near), P3);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: a paragraph that never conveys its near time is still incomplete', () => {
    const r = verdict(P1, P2('').trim().replace(/^z/, 'Z'), P3);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toEqual(expect.arrayContaining(['claim_incomplete:c3:horizon=near', 'claim_incomplete:c4:horizon=near']));
  });

  it('release told as "hafiflik / rahatlık / içini dökmek" is recognized', () => {
    const r = verdict(P1, P2('Yakın günlerde'), 'İçini dökünce gelen o hafiflik ve rahatlık bu günlerde sana iyi gelecek gibi görünüyor. Aynı günlerde planlarında beklenmedik bir dönüş de olası; alışık olduğun düzen biraz değişiyor ama bu değişim sana yabancı gelmeyecek gibi.');
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: a closing paragraph that never tells the release is still refused', () => {
    const r = verdict(P1, P2('Yakın günlerde'), 'Aynı günlerde planlarında beklenmedik bir dönüş de olası; alışık olduğun düzen biraz değişiyor ama bu değişim sana yabancı gelmeyecek gibi. Kendini yeni bir rotada bulman da olası gibi görünüyor.');
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toContain('ungrounded_claim:c5');
  });

  it('"… gibi duran" about one of the reading’s own meanings is life language', () => {
    for (const x of ['planlarında beklenmedik bir dönüş gibi duran bir değişiklik de olası', 'planlarında bir rahatlama gibi duran beklenmedik bir dönüş de olası']) {
      const r = verdict(P1, P2('Yakın günlerde'), `İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde ${x}; alışık olduğun düzen biraz değişiyor gibi.`);
      expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
    }
  });

  it.each(['ok', 'hilal'])('NEGATIVE: "%s gibi duran" (a seen shape) is still a visual description', (shape) => {
    const r = verdict(P1, P2('Yakın günlerde'), `İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde ${shape} gibi duran o işaret planlarında beklenmedik bir dönüşü anlatıyor; alışık olduğun düzen değişiyor gibi.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toContain('visual_description:gibi duran');
  });

  it('NEGATIVE: repeated "Bu …" openers stay repetitive (the first real sample’s valid refusal)', () => {
    const r = verdict(P1, 'Bu aralar zihnini yoran telaş yavaş yavaş duruluyor gibi. Bu sakinlik günlerine de yansıyor gibi görünüyor. Bu dönemde küçük işler ve ayrıntılar ara ara yoğunlaşıp günlerini dolduruyor gibi.', P3);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('repetitive');
  });

  // Second real writer run: both samples were refused on one word each (synthetic sentences of the same build).
  const P3_RELEASE_VERB = 'Bir yandan içinde tuttuklarını dile dökme ihtiyacın belirginleşebilir; söze dönüşenler omuzlarındaki ağırlığı hafifletiyor sanki. Tam bu sırada planlarında hesaba katmadığın bir dönüş hissediliyor; alıştığın düzen biraz değişiyor gibi.';

  it('"söze dönüşenler" (the verb dönüşmek) does not tell the turn meaning: the release keeps its own words', () => {
    const r = verdict(P1, P2('Yakın günlerde'), P3_RELEASE_VERB);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('the noun "dönüş" (a turn in one’s plans) still tells the turn; with no turn word the turn stays untold', () => {
    const untold = verdict(P1, P2('Yakın günlerde'), 'Bir yandan içinde tuttuklarını dile dökme ihtiyacın belirginleşebilir; söze dönüşenler omuzlarındaki ağırlığı hafifletiyor sanki. Bu duygular zamanla başka bir hâle dönüşüyor gibi.');
    expect(untold.ok).toBe(false);
    if (!untold.ok) expect(untold.details).toContain('ungrounded_claim:c6');
  });

  it('a route metaphor "farklı bir rotaya / yöne kıvrılabilir" is life language', () => {
    for (const x of ['alıştığın düzen farklı bir rotaya kıvrılabilir', 'planların başka bir yöne kıvrılabilir']) {
      const r = verdict(P1, P2('Yakın günlerde'), `İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin. Tam bu sırada planlarında hesaba katmadığın bir dönüş hissediliyor; ${x}.`);
      expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
    }
  });

  it.each(['kıvrılarak ilerleyen bir hat da beklenmedik bir dönüşü anlatıyor', 'yukarı kıvrılan o hat beklenmedik bir dönüşü anlatıyor'])(
    'NEGATIVE: a curving mark ("%s") is still a visual description',
    (x) => {
      const r = verdict(P1, P2('Yakın günlerde'), `İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; dile döktükçe omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde ${x}; alışık olduğun düzen değişiyor gibi.`);
      expect(r.ok).toBe(false);
      if (!r.ok) expect(r.failures).toContain('visual_description');
    },
  );
});

describe('signs to one story: visually linked signs are told together, unlinked ones are never joined', () => {
  /** SYNTHETIC cup (not photo evidence): bird CONNECTED to a path; fish only NEAR the path; a heart apart. */
  const FOUR_SIGNS: M1FixtureSpec = {
    marks: [
      { id: 'K', label: 'a bird in flight', band: 'rim_upper', form: { motion: 'moving', openness: 'open' } },
      { id: 'Y', label: 'a winding path', band: 'middle', form: { course: 'bending' } },
      { id: 'B', label: 'a fish', band: 'middle', hours: 8, form: { motion: 'moving' } },
      { id: 'H', label: 'a heart', band: 'lower_base', hours: 5 },
    ],
    relations: [{ a: 'K', b: 'Y', kind: 'connected' }, { a: 'Y', b: 'B', kind: 'near' }],
  };
  const plan = () => planOf(FOUR_SIGNS, GENERAL);
  const symbolsOf = (p: ReturnType<typeof plan>, ids: string[]) => ids.map((id) => p.claims.find((c) => c.id === id)!.symbol);

  it('the bird and the path it is connected to share the opening paragraph (they used to be split)', () => {
    const p = plan();
    expect(p.paragraphs.map((x) => symbolsOf(p, x.claims))).toEqual([['kuş', 'yol'], ['balık', 'kalp']]);
    expect(p.links).toEqual([{ a: 'c1', b: 'c2', kind: 'linked' }]);
  });

  it('NEGATIVE: "near" is not a link and nothing is invented between unrelated signs', () => {
    expect(planOf({ ...FOUR_SIGNS, relations: [] }, GENERAL).links).toEqual([]);
    expect(planOf({ ...FOUR_SIGNS, relations: [{ a: 'Y', b: 'B', kind: 'near' }] }, GENERAL).links).toEqual([]);
    // Without a link the salience / time order is untouched (bird + fish open, as before).
    const p = planOf({ ...FOUR_SIGNS, relations: [] }, GENERAL);
    expect(symbolsOf(p, p.paragraphs[0].claims)).toEqual(['kuş', 'balık']);
  });

  it('the real-cup plans keep their paragraphs (hub / within links already sat together)', () => {
    const rich = planOf(M1_QA_CUPS.general_rich_three.spec, GENERAL);
    expect(rich.links).toEqual([]);
    expect(rich.paragraphs.map((x) => symbolsOf(rich, x.claims))).toEqual([['balık', 'yüzük'], ['yol']]);
  });

  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3', 'c4'], text: p2 }] });
  /** Human-authored (synthetic) telling of the linked bird → path thread and the separate fish / heart. */
  const STORY = out(
    'Yakın zamanda sana doğru gelen bir haber seziliyor; beklemediğin bir anda kapını çalan bir ses gibi. O haberle birlikte önümüzdeki dönemde hayatının yönü yeniden çiziliyor gibi; sanki içindeki pusula yavaşça başka bir yöne dönüyor.',
    'Önümüzdeki dönemde eline geçebilecek bir kısmet de var; bereketli bir imkânın sana yaklaştığı hissediliyor. Daha uzun vadede ise dış dünyada, daha uzak çevrelerde gönlünü kıpırdatan bir duygu beliriyor gibi; içinde sessizce bekleyen bir yer yeniden ısınıyor sanki.',
  );

  it('the connected story passes; the hedge "hissediliyor" no longer counts as the heart\u2019s "his" (feeling)', () => {
    const r = acceptCoffeeV3Narrative(plan(), STORY);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: a heart told only through the hedge "hissediliyor" stays untold', () => {
    const r = acceptCoffeeV3Narrative(plan(), out(
      'Yakın zamanda sana doğru gelen bir haber seziliyor; beklemediğin bir anda kapını çalan bir ses gibi. O haberle birlikte önümüzdeki dönemde hayatının yönü yeniden çiziliyor gibi; sanki içindeki pusula yavaşça başka bir yöne dönüyor.',
      'Önümüzdeki dönemde eline geçebilecek bir kısmet de var; bereketli bir imkânın sana yaklaştığı hissediliyor. Daha uzun vadede ise dış dünyada, daha uzak çevrelerde sakin bir dönem hissediliyor; her şey kendi yerini buluyor gibi.',
    ));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toContain('ungrounded_claim:c4');
  });

  it('NEGATIVE: the same four meanings as a bare list are still refused', () => {
    const r = acceptCoffeeV3Narrative(plan(), out(
      'Yakın zamanda bir haber var. Önümüzdeki dönemde hayatının yönü değişebilir.',
      'Önümüzdeki dönemde bir fırsat var. Daha uzun vadede uzak çevrelerde gönlün kıpırdayabilir.',
    ));
    expect(r.ok).toBe(false);
  });
});

describe('two clearly identified signs carry a reading of their own (they used to fall below the 3-claim floor)', () => {
  const LOVE = 'Aşk ve ilişkilerim hakkında';
  const CAREER = 'İşim ve kariyerim hakkında';
  const one = (plan: ReturnType<typeof planOf>, text: string) =>
    acceptCoffeeV3Narrative(plan, JSON.stringify({ paragraphs: [{ claims: plan.paragraphs[0].claims, text }] }));
  /** Human-authored (synthetic) readings — not AI output, not photo evidence. */
  const KEY_PATH = 'İş tarafında önümüzdeki dönemde kapalı görünen bir kapının aralandığını hissedebilirsin; eline yeni bir çıkış yolu geçiyor gibi. Bu açılımla birlikte daha uzun vadede bir yolculuk ya da hayatının yönünü belirleyen bir adım da gündeme geliyor sanki; o kapıdan geçtikçe önünde başka bir gidişat beliriyor.';
  const RING_HEART = 'İlişkiler tarafında önümüzdeki dönemde güvenin ve verilen sözün önem kazandığı, derinleşen bir bağ seziliyor. Aynı dönemde yakın çevrende, kendi dünyanda gönlünü kıpırdatan bir duygu da beliriyor gibi; içinde ılık bir kıpırtı hissedebilirsin.';

  it.each([
    ['money_fish_tree', ['balık', 'ağaç'], []],
    ['love_ring_heart', ['yüzük', 'kalp'], []],
    ['career_key_path', ['anahtar', 'yol'], [{ a: 'c1', b: 'c2', kind: 'linked' }]],
  ] as const)('%s: planned with its two signs; only a visual connection becomes a link', (cup, symbols, links) => {
    const p = planOf(M1_QA_CUPS[cup].spec, GENERAL);
    expect(p.status).toBe('planned');
    expect(p.claims.map((c) => c.symbol)).toEqual(symbols);
    expect(p.claims.every((c) => c.certainty === 'clear')).toBe(true);
    expect(p.links).toEqual(links);
    // No artificial length: the floor follows the evidence (8 × 2 + 16).
    expect(p.budget).toEqual({ minWords: 32, maxWords: 110 });
  });

  it.each([
    ['a lone sign', M1_QA_CUPS.person_bird.spec],
    ['two of the same sign (one meaning)', M1_QA_CUPS.general_two_birds.spec],
    ['two of the same written sign', M1_QA_CUPS.general_letter_broken.spec],
    ['a sign beside an unmapped shape and a saucer flow', M1_QA_CUPS.sparse_unmapped_saucer_flow.spec],
    ['a strong sign beside a WEAK resemblance', {
      marks: [
        { id: 'M1', label: 'a plain band ring', form: { openness: 'closed', grouping: 'isolated' } },
        { id: 'M2', label: null, resemblances: [{ label: 'a heart', strength: 'weak' }], hours: 0 },
      ],
    } as M1FixtureSpec],
    ['two signs whose identity is ambiguous (possibly one mark)', { ...M1_QA_CUPS.love_ring_heart.spec, ambiguities: [['M1', 'M2']] } as M1FixtureSpec],
  ])('NEGATIVE: %s stays insufficient', (_label, spec) => {
    expect(planOf(spec, GENERAL)).toMatchObject({ status: 'insufficient', reason: expect.stringMatching(/below_min_claims|no_grounded_claims/) });
  });

  it('the connected key → path is told as one thread and passes every gate (42 words, no padding)', () => {
    const r = one(planOf(M1_QA_CUPS.career_key_path.spec, CAREER), KEY_PATH);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('the unlinked ring and heart are told side by side, without an invented cause, and pass', () => {
    const r = one(planOf(M1_QA_CUPS.love_ring_heart.spec, LOVE), RING_HEART);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: a thin two-line telling is still refused', () => {
    const r = one(planOf(M1_QA_CUPS.career_key_path.spec, CAREER), 'Önümüzdeki dönemde bir kapı açılabilir. Daha uzun vadede yönün değişebilir.');
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toEqual(expect.arrayContaining(['too_thin', 'claim_underdeveloped']));
  });

  it('NEGATIVE: an invented cause between the two signs is still refused', () => {
    const r = one(planOf(M1_QA_CUPS.love_ring_heart.spec, LOVE), 'İlişkiler tarafında önümüzdeki dönemde güvenin ve verilen sözün önem kazandığı, derinleşen bir bağ seziliyor. Bu bağ sayesinde yakın çevrende, kendi dünyanda gönlünü kıpırdatan bir duygu da beliriyor gibi; içinde ılık bir kıpırtı hissedebilirsin.');
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('causal_link');
  });

  it('end to end: a two-sign cup is delivered as v3_narrative_v1 (scripted writer, zero real calls)', async () => {
    const store = createReadingStageStore();
    const plan = planOf(M1_QA_CUPS.love_ring_heart.spec, LOVE);
    const fake = fakeTransport(three(M1_QA_CUPS.love_ring_heart.spec), [JSON.stringify({ paragraphs: [{ claims: plan.paragraphs[0].claims, text: RING_HEART }] })]);
    const result = await runCoffeeV3NarrativeReading({
      config: testConfig(), transport: fake.transport, stageStore: store,
      images: STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) })),
      intention: LOVE, language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:two-signs',
    });
    expect(result.coffeeResultContract).toBe('v3_narrative_v1');
    expect(result.overall).toBe(RING_HEART);
    expect(fake.observerCalls()).toHaveLength(1);
    expect(fake.writerCalls()).toHaveLength(1);
  });
});

describe('fortune-teller contract: concrete life scenes, licensed events, linked meanings as one development', () => {
  /** SYNTHETIC cups (not photo evidence). Bird CONNECTED to heart; then the same two signs apart. */
  const BIRD_HEART: M1FixtureSpec = {
    marks: [
      { id: 'K', label: 'a bird in flight', band: 'rim_upper', form: { motion: 'moving', openness: 'open' } },
      { id: 'H', label: 'a heart', band: 'middle', hours: 3 },
    ],
    relations: [{ a: 'K', b: 'H', kind: 'connected' }],
  };
  const APART: M1FixtureSpec = { ...BIRD_HEART, relations: [] };
  const LOVE = 'Aşk ve ilişkilerim hakkında';
  const one = (spec: M1FixtureSpec, text: string, intention = LOVE) => {
    const p = planOf(spec, intention);
    return acceptCoffeeV3Narrative(p, JSON.stringify({ paragraphs: [{ claims: p.paragraphs[0].claims, text }] }));
  };
  /** Human-authored (synthetic) telling in the owner's target style — not AI output. */
  const LINKED_STORY =
    'Yakın zamanda beklenmedik bir haberin gönül tarafında bir kıpırtı yaratabileceği hissi var; yarım kalmış bir konuşmanın yeniden açılması ihtimali öne çıkıyor. Önümüzdeki dönemde ilk başta mesafeli ilerleyen bu iletişim, zamanla bir yakınlaşmaya dönüşebilir gibi; gönlünde ılık bir hareket seziliyor.';

  it('the writer receives life scenes for every meaning; licenses and evidence stay server-side', () => {
    const p = planOf(BIRD_HEART, LOVE);
    const payload = coffeeV3NWriterPayload(p);
    expect(payload.claims.map((c) => c.lifeScenes.length > 0)).toEqual([true, true]);
    expect(payload.claims[0].lifeScenes).toContain('yarım kalmış bir konuşmanın yeniden başlaması');
    expect(JSON.stringify(payload)).not.toContain('licensedEvents');
    expect(coffeeV3NPayloadLeaks(payload)).toEqual([]);
  });

  it('a linked bird → heart is told as one development (the news stirs the heart) and passes', () => {
    expect(planOf(BIRD_HEART, LOVE).links).toEqual([{ a: 'c1', b: 'c2', kind: 'linked' }]);
    const r = one(BIRD_HEART, LINKED_STORY);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: the same influence between UNLINKED signs is refused (no invented relation)', () => {
    const r = one(APART, LINKED_STORY);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details.some((d) => d.startsWith('causal_link:unlinked_influence:'))).toBe(true);
  });

  it('POSITIVE: unlinked signs told side by side in the same period pass', () => {
    const r = one(APART, 'Yakın zamanda bir mesaj ya da uzaktan gelen bir haber seziliyor; yarım kalmış bir konuşmanın yeniden başlaması olası. Önümüzdeki dönemde gönül tarafında da bir yakınlaşma, ılık bir kıpırdanma hissedebilirsin; bu ayrı bir sıcaklık gibi duruyor.');
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: even linked meanings never get a certain cause ("sayesinde")', () => {
    const r = one(BIRD_HEART, LINKED_STORY.replace('gönül tarafında bir kıpırtı yaratabileceği hissi var', 'sayesinde gönül tarafında bir kıpırtı olabileceği hissi var'));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('causal_link');
  });

  /** SYNTHETIC: a road sign beside a fish (licenses a trip and an offer). */
  const ROAD_FISH: M1FixtureSpec = {
    marks: [
      { id: 'Y', label: 'a winding path', band: 'rim_upper', form: { course: 'bending' } },
      { id: 'B', label: 'a fish', band: 'middle', hours: 8, form: { motion: 'moving' } },
    ],
  };
  const ROAD_FISH_TEXT = 'Yakın zamanda kısa bir yolculuk ya da hayatının yönünü belirleyen bir adım gündeme gelebilir gibi. Önümüzdeki dönemde iş tarafında bir teklif, umulmadık bir yerden gelen bir kısmet de seziliyor; bereketli bir imkân yaklaşıyor gibi.';

  /** Options + settling + release + turn: no road, fish or fork sign licenses a trip. */
  const FOUR_FIXTURE: M1FixtureSpec = {
    marks: [
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };

  it('licensed events: a trip with a road sign, an offer with a fish', () => {
    const r = one(ROAD_FISH, ROAD_FISH_TEXT, GENERAL);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: the same trip / offer without a licensing meaning stays unsupported', () => {
    const p = planOf(FOUR_FIXTURE, GENERAL);
    const r = acceptCoffeeV3Narrative(p, JSON.stringify({ paragraphs: p.paragraphs.map((x, i) => ({ claims: x.claims, text: i === 0
      ? 'Yakın zamanda önünde iki teklif ya da birden fazla seçenek beliriyor, ara ara netleşiyor gibi; kısa bir yolculuk da gündemde olabilir. Bu arada zihnini yoran telaş yavaş yavaş duruluyor, işlerin sakinleşiyor gibi.'
      : 'İçinde tuttuklarını dile dökme ihtiyacı uyanabilir; dertleştikçe hafiflediğini fark edebilirsin. Aynı günlerde planlarında beklenmedik bir dönüş de olası; alışık olduğun düzen değişiyor gibi.' })) }));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toContain('unsupported_specific:yolculuk');
  });

  it.each([
    ['a health scare', 'hastalık'],
    ['a pregnancy', 'hamilelik'],
    ['an accident', 'kaza'],
    ['a marriage', 'evlilik'],
    ['an assumed spouse', 'eşinle'],
    ['an assumed partner', 'sevgilinle'],
    ['a breakup stated as fact', 'ayrılık'],
  ])('NEGATIVE: %s is never allowed, whatever the signs (%s)', (_label, word) => {
    const r = one(BIRD_HEART, `${LINKED_STORY} Bu dönemde ${word} konusu da gündeme gelebilir gibi.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('unsupported_specific');
  });

  it('NEGATIVE: a definite future stays refused', () => {
    const r = one(BIRD_HEART, LINKED_STORY.replace('zamanla bir yakınlaşmaya dönüşebilir gibi', 'zamanla bir yakınlaşmaya dönüşecek ve barışacaksın'));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('certain_prediction');
  });

  /** The real six-meaning plan shape (synthetic marks): abstract vs concrete telling of the SAME meanings. */
  const SIX: M1FixtureSpec = {
    marks: [
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'O', label: null, kind: 'clear_area', band: 'lower_base', hours: 3 },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open', continuity: 'continuous' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'], hours: 4 },
      { id: 'P', label: null, topology: 'patch', form: { grouping: 'clustered', continuity: 'broken' }, band: 'rim_upper', hours: 9 },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
    ],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const six = (a: string, b: string, c: string) => {
    const p = planAllOf(SIX, GENERAL);
    return acceptCoffeeV3Narrative(p, JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: a }, { claims: ['c3', 'c4'], text: b }, { claims: ['c5', 'c6'], text: c }] }));
  };
  const ABSTRACT = [
    'Yakın zamanda önünde birkaç seçenek beliriyor gibi; bunlar ara ara netleşiyor ve her biri farklı bir ihtimal taşıyor. Daha ileride hareket alanın genişliyor, içini ferahlatan bir genişlik seziliyor; nefes alacak bir alan açılıyor gibi.',
    'Yakın günlerde zihnini yoran telaş yavaş yavaş duruluyor, içindeki dalgalanma yatışıyor gibi. Aynı dönemde ayrıntılar ve küçük uğraşlar ara ara yoğunlaşıyor; canlı ama dağınık olmayan bir tempo hissediliyor.',
    'İçinde tuttuklarını dışa vurma ihtiyacı uyanabilir; omuzlarındaki yükün hafiflediğini fark edebilirsin. Aynı günlerde alışık olduğun düzen beklenmedik biçimde değişiyor gibi; bir dönüş seziliyor.',
  ] as const;
  /** Human-authored (synthetic) fortune-teller telling of the same six meanings — not AI output. */
  const CONCRETE = [
    'Yakın zamanda kendini iki teklif ya da iki yol arasında bulabilirsin; hangisinin sana iyi geleceği ara ara netleşiyor gibi. Daha ileride ise sıkışan bir işin çözülmeye başladığı, içini ferahlatan bir cevabın geldiği seziliyor.',
    'Yakın günlerde araların düzelmesi, bir gerginliğin yavaş yavaş durulması olası; telaşın yerini dinginlik alıyor gibi. Aynı dönemde günlerin telefonlar, küçük işler ve ayak işleriyle ara ara yoğunlaşıyor; koşuşturmalı ama dağınık olmayan bir tempo bu.',
    'İçini dökeceğin, dertleşeceğin bir sohbet seni hafifletebilir; paylaştıkça omuzlarındaki yük azalıyor gibi. Aynı günlerde planların son anda değişebilir; beklenmedik bir dönüş alışık olduğun düzeni biraz değiştiriyor gibi.',
  ] as const;

  it('NEGATIVE: the abstract telling ("seçenekler belirebilir, hareket alanın genişleyebilir") is refused as abstract_only', () => {
    const r = six(...ABSTRACT);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details.some((d) => d.startsWith('generic_filler:abstract_only:'))).toBe(true);
  });

  it('POSITIVE: the same six meanings told as lived developments pass', () => {
    const r = six(...CONCRETE);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });
});

describe('story contract: one development at the centre, support beside it, minor meanings optional', () => {
  /**
   * SYNTHETIC cup with the real cup's structure: branching + descending trail
   * running into the base pool (linked), a clear area with a saucer turn
   * inside it (within), clustered details and a saucer flow (unlinked).
   */
  const REAL_SHAPE: M1FixtureSpec = {
    marks: [
      { id: 'P', label: null, topology: 'pool', surface: 'cup_base', band: 'lower_base' },
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken', openness: 'open' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'] },
      { id: 'O', label: null, kind: 'clear_area', band: 'lower_base', hours: 3 },
      { id: 'S', label: null, topology: 'line', form: { verticalDirection: 'descending', openness: 'open', continuity: 'continuous' }, band: 'rim_upper', bandCoverage: ['rim_upper', 'middle'], hours: 4 },
      { id: 'D', label: null, topology: 'patch', form: { grouping: 'clustered', continuity: 'broken' }, band: 'rim_upper', hours: 9 },
      { id: 'T', label: null, saucer: true, topology: 'line', form: { course: 'bending' } },
      { id: 'Q', label: null, saucer: true, kind: 'clear_area' },
    ],
    relations: [{ a: 'P', b: 'B', kind: 'connected' }, { a: 'P', b: 'S', kind: 'connected' }, { a: 'T', b: 'Q', kind: 'contained_by' }],
    saucer: { surfaceState: 'flow', flow: { present: true, direction: 'toward_edge' } },
  };
  const plan = () => planOf(REAL_SHAPE, GENERAL);
  const weights = (p: ReturnType<typeof plan>) => Object.fromEntries(p.claims.map((c) => [c.theme, c.weight]));
  const raw = (...ps: Array<[string[], string]>) => JSON.stringify({ paragraphs: ps.map(([claims, text]) => ({ claims, text })) });

  it('weights follow the evidence: the visually tied pair is the core, the other tie supports it, unlinked traces are optional', () => {
    const p = plan();
    expect(weights(p)).toEqual({ opening: 'core', turn: 'core', options: 'support', settling: 'support', many_details: 'minor', release: 'minor' });
    // Length follows the four told meanings, not all six.
    expect(p.budget).toEqual({ minWords: 48, maxWords: 160 });
  });

  it('the writer receives the story outline (core / support / minor, max three paragraphs), not a paragraph grid', () => {
    const payload = coffeeV3NWriterPayload(plan());
    expect(payload.outline).toEqual({ core: ['c1', 'c6'], support: ['c2', 'c3'], minor: ['c4', 'c5'], maxParagraphs: 3 });
    expect(payload.claims.map((c) => c.weight)).toEqual(['core', 'support', 'support', 'minor', 'minor', 'core']);
    expect(payload).not.toHaveProperty('paragraphs');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('weight core: falın MERKEZİ');
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('Kısa ve yoğun yaz');
  });

  /** Human-authored (synthetic) story — NOT AI output: one development, support inside it, minors left out. */
  const STORY = raw(
    [['c1', 'c6'], 'Daha ileride sıkışan bir işin çözülmeye başladığı, beklenen bir cevabın gelip içini rahatlattığı bir dönem seziliyor; ama o rahatlamanın tam içinde planların son anda değişebilir. İlk anda şaşırtan bu dönüş, sonunda sana daha geniş bir alan bırakıyor gibi.'],
    [['c2', 'c3'], 'Oraya varmadan, yakın zamanda iki teklif arasında kalabilirsin; biri öne çıktıkça seni yoran gerginlik de yavaş yavaş duruluyor, araların düzeliyor gibi.'],
  );

  it('POSITIVE: a short story with the centre developed and the optional meanings left out passes', () => {
    const r = acceptCoffeeV3Narrative(plan(), STORY);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
    if (r.ok) expect(r.metrics.words).toBeLessThan(90);
  });

  it('POSITIVE: a minor meaning may join as a short touch; one paragraph is a valid story too', () => {
    const touched = raw(
      [['c1', 'c6', 'c5'], 'Daha ileride sıkışan bir işin çözülmeye başladığı, beklenen bir cevabın gelip içini rahatlattığı bir dönem seziliyor; ama o rahatlamanın tam içinde planların son anda değişebilir. İlk anda şaşırtan bu dönüş, sonunda sana daha geniş bir alan bırakıyor gibi. İçini dökeceğin bir sohbet de bu dönemi hafifletebilir.'],
      [['c2', 'c3'], 'Oraya varmadan, yakın zamanda iki teklif arasında kalabilirsin; biri öne çıktıkça seni yoran gerginlik de yavaş yavaş duruluyor, araların düzeliyor gibi.'],
    );
    const r = acceptCoffeeV3Narrative(plan(), touched);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: every meaning explained in turn (the real 174-word report pattern) loses the focus', () => {
    const report = raw(
      [['c1', 'c6'], 'Daha ileride sıkışan bir işin çözülmeye başladığı, beklenen bir cevabın gelip içini rahatlattığı bir dönem seziliyor. Planların da son anda değişebilir gibi.'],
      [['c2', 'c3', 'c4'], 'Yakın zamanda iki teklif arasında kalabilirsin; hangisinin sana iyi geleceği zamanla netleşiyor gibi. Seni yoran gerginlik de yavaş yavaş duruluyor, araların düzeliyor gibi. Aynı dönemde küçük işler, ayak işleri, telefonlar ve kısa koşuşturmalar günlerini dolduruyor; tempo ara ara yükselse de dağınık değil, ayrıntılar birbiri ardına tamamlanıyor gibi.'],
      [['c5'], 'İçinde tuttuklarını dile getireceğin içten bir sohbet de görünüyor; içini döktükçe omuzlarındaki ağırlığın hafiflediğini, günlerinin rahatladığını fark edebilirsin.'],
    );
    const r = acceptCoffeeV3Narrative(plan(), report);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('focus_lost');
  });

  it('NEGATIVE: leaving a core meaning untold is refused', () => {
    const r = acceptCoffeeV3Narrative(plan(), raw([['c2', 'c3'], 'Yakın zamanda iki teklif arasında kalabilirsin; biri öne çıktıkça seni yoran gerginlik de yavaş yavaş duruluyor, araların düzeliyor gibi. Bu karar anı içini rahatlatan bir netlik getirebilir gibi görünüyor.']));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details).toEqual(expect.arrayContaining(['ungrounded_claim:c1:untold_core', 'ungrounded_claim:c6:untold_core']));
  });

  it('NEGATIVE: an enumerated list ("ayrıca … bunun yanı sıra …") is a report, not a story', () => {
    const listed = raw(
      [['c1', 'c6'], 'Daha ileride sıkışan bir işin çözülmeye başladığı, beklenen bir cevabın gelip içini rahatlattığı bir dönem seziliyor. Ayrıca planların son anda değişebilir; bu dönüş sana yeni bir alan bırakıyor gibi.'],
      [['c2', 'c3'], 'Bunun yanı sıra yakın zamanda iki teklif arasında kalabilirsin; seni yoran gerginlik de yavaş yavaş duruluyor, araların düzeliyor gibi.'],
    );
    const r = acceptCoffeeV3Narrative(plan(), listed);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.details.some((d) => d.startsWith('mechanical_style:list_connectors='))).toBe(true);
  });

  it('NEGATIVE: a padded reading beyond the story budget is refused', () => {
    const padded = raw(
      [['c1', 'c6'], `${JSON.parse(STORY).paragraphs[0].text} ${'Bu dönem sana yeni bir bakış kazandırabilir gibi görünüyor ve sen de bunu hissedebilirsin. '.repeat(8)}`],
      [['c2', 'c3'], JSON.parse(STORY).paragraphs[1].text],
    );
    const r = acceptCoffeeV3Narrative(plan(), padded);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('padded');
  });

  it('"olası" carries a sentence and "araların düzelmesi" is a concrete development', () => {
    const r = acceptCoffeeV3Narrative(plan(), raw(
      [['c1', 'c6'], 'Daha ileride sıkışan bir işin çözülmeye başlaması, beklenen bir cevabın gelip içini rahatlatması olası. O rahatlamanın içinde planların son anda değişebilir; bu dönüş sonunda sana daha geniş bir alan bırakıyor gibi.'],
      [['c2', 'c3'], 'Oraya varmadan, yakın zamanda iki teklif arasında kalabilirsin; aynı günlerde seni yoran gerginliğin yatışması, araların düzelmesi de olası.'],
    ));
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });
});

describe('live V3 routing: the internal entry runs V3N; the retired M2/W4 path can never run', () => {
  const src = resolve(process.cwd(), 'src');
  const walk = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
    });
  const rel = (p: string) => p.slice(src.length + 1).replace(/\\/g, '/');

  it('AiProxyService.coffeeV3 runs the direct engine by default and V3N only when configured (never the retired M2 chain)', () => {
    const service = readFileSync(join(src, 'ai/service.ts'), 'utf8');
    const entry = service.slice(service.indexOf('async coffeeV3('), service.indexOf('private async resolveCoffeeV2Images'));
    expect(entry).toMatch(/this\.config\.coffeeV3Engine === 'narrative' \? runCoffeeV3NarrativeReading : runCoffeeV3DirectReading/);
    expect(entry).not.toMatch(/runCoffeeV3Reading\(/);
  });

  it('no source file calls the retired runCoffeeV3Reading (kept, exported and tested, but unreachable)', () => {
    const callers = walk(src).filter((p) => /(?<!function )\brunCoffeeV3Reading\s*\(/.test(readFileSync(p, 'utf8'))).map(rel);
    expect(callers).toEqual([]);
    // The only V3 AI entry the worker can call is ai.coffeeV3.
    const exec = readFileSync(join(src, 'reading/reading-processor-execute.ts'), 'utf8');
    expect(exec).toMatch(/input\.ai\.coffeeV3\(/);
    expect(exec).not.toMatch(/runCoffeeV3(Narrative)?Reading/);
  });
});

describe('V3N pipeline: pins, privacy, budgets, result contract', () => {
  it('the V3N writer contract is separately pinned; the frozen W4 prompt sha is unchanged', () => {
    expect(coffeeV3NWriterPromptSha256()).toBe(FROZEN_COFFEE_V3N_PROMPT_SHA256);
    expect(FROZEN_COFFEE_V3N_PROMPT_SHA256).toBe('dbe5e3e2aa48fdf10047036bab26f1d1ba4c52f400d59508049e8b69227bbc5f');
    expect(coffeeM2WriterPromptSha256()).toBe(FROZEN_COFFEE_M2_PROMPT_SHA256);
    expect(FROZEN_COFFEE_M2_PROMPT_SHA256).toBe('bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48');
  });

  it('success: one observer call with three images, one writer call, v3_narrative_v1 with paragraphs verbatim', async () => {
    const r = await run(three(coffeeV3PremiumSpec()), [COFFEE_V3N_PREMIUM_WRITER_OUTPUT]);
    expect(r.error).toBeNull();
    expect(r.observerCalls()).toHaveLength(1);
    const parts = r.observerCalls()[0].messages[1].content as Array<{ type: string }>;
    expect(parts.filter((p) => p.type === 'image_url')).toHaveLength(3);
    expect(r.writerCalls()).toHaveLength(1);
    expect(r.writerCalls()[0]).toMatchObject({ model: 'gpt-5.6-sol', reasoningEffort: 'low', jsonMode: true });
    expect(r.writerCalls()[0].messages[0].content).toBe(COFFEE_V3N_WRITER_PROMPT);
    const out = JSON.parse(COFFEE_V3N_PREMIUM_WRITER_OUTPUT) as { paragraphs: Array<{ text: string }> };
    expect(r.result).toEqual({
      coffeeResultContract: COFFEE_V3N_RESULT_CONTRACT, visualObservation: '', overall: out.paragraphs.map((p) => p.text).join('\n\n'),
      love: '', career: '', money: '', nearFuture: '', takeaway: '', symbols: [],
    });
  });

  it('the writer never sees observer prose, provenance or machine ids', async () => {
    const obs = three(coffeeV3PremiumSpec());
    const r = await run(obs, [COFFEE_V3N_PREMIUM_WRITER_OUTPUT]);
    const user = String(r.writerCalls()[0].messages[1].content);
    for (const s of obs.sightings) expect(user).not.toContain(s.description);
    for (const s of obs.sightings) expect(user).not.toContain(`"${s.id}"`);
    expect(user).not.toMatch(/provenance|salience|identityGroup|sighting|cup_view_|"P\d"|"seen"|"symbol"|"anchors"|"theme"/);
    // No cup / shape / position vocabulary reaches the writer at all.
    expect(user.replace(/"userDeclaredIntention": "[^"]*"/u, '')).not.toMatch(VISUAL_WORDS);
    expect(VISUAL_WORDS.test('Fincanın dibinden ağzına doğru yükselen bir çizgi görüyorum.')).toBe(true);
    expect(VISUAL_WORDS.test('çizgi')).toBe(true);
    expect(VISUAL_WORDS.test('izin verirsen')).toBe(false);
    expect(coffeeV3NPayloadLeaks(coffeeV3NWriterPayload(planOf(coffeeV3PremiumSpec())))).toEqual([]);
  });

  it('two gate failures are terminal unavailable — exactly two byte-identical writer requests, no result', async () => {
    const thin = JSON.stringify({ paragraphs: planOf(coffeeV3PremiumSpec()).paragraphs.map((p) => ({ claims: p.claims, text: 'Bir yol beliriyor gibi.' })) });
    const r = await run(three(coffeeV3PremiumSpec()), [thin, thin, COFFEE_V3N_PREMIUM_WRITER_OUTPUT]);
    // The terminal reason now names the refused codes per attempt.
    expect(failure(r.error)).toMatch(/^unavailable:v3n_quality_gates_failed:a1=[a-z_+]*too_thin[a-z_+]*;a2=[a-z_+]*too_thin/);
    expect(r.writerCalls()).toHaveLength(2);
    expect(JSON.stringify(r.writerCalls()[1])).toBe(JSON.stringify(r.writerCalls()[0]));
    expect(r.result).toBeNull();
  });

  it('a failed first sample followed by a good one succeeds on the blind re-sample', async () => {
    const r = await run(three(coffeeV3PremiumSpec()), ['not json', COFFEE_V3N_PREMIUM_WRITER_OUTPUT]);
    expect(r.error).toBeNull();
    expect(r.writerCalls()).toHaveLength(2);
  });

  it('pins and language fail closed before ANY provider call', async () => {
    const wrong = await run(three(coffeeV3PremiumSpec()), [COFFEE_V3N_PREMIUM_WRITER_OUTPUT], { expectedPromptSha256: '0'.repeat(64) });
    expect(failure(wrong.error)).toBe('unavailable:v3n_prompt_hash_mismatch');
    const en = await run(three(coffeeV3PremiumSpec()), [COFFEE_V3N_PREMIUM_WRITER_OUTPUT], { language: 'en' });
    expect(failure(en.error)).toBe('unavailable:language_not_supported');
    for (const r of [wrong, en]) expect(r.calls).toHaveLength(0);
  });
});
