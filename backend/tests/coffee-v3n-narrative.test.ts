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
import { COFFEE_V3N_MIN_CLAIMS, planCoffeeV3Narrative } from '../src/ai/reading/coffee-v3n-narrative-plan.js';
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
  coffeeV3NWriterPayload,
  coffeeV3NWriterPromptSha256,
} from '../src/ai/reading/coffee-v3n-narrative-writer.js';
import type { OpenAiCompleteOptions } from '../src/ai/openai-transport.js';
import type { CoffeeMultiViewObservationV3 } from '../src/ai/reading/types.js';
import { C31_SET_IDS, c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { m1Observation, type M1FixtureSpec, type M1MarkSpec } from './fixtures/coffee-m1-fixtures.js';
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
    expect(words(accepted.reading)).toBeGreaterThan(4 * words(LIVE_THIN_READING));
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
    ['contradiction with a claim', withText(0, good.paragraphs[0].text.replace('kesintisiz ama', 'kesik kesik ama')), 'contradiction'],
    ['repetition', appended(1, good.paragraphs[1].text), 'repetitive'],
    ['no tentative language', withText(1, 'Önümüzdeki dönemde önünde birden fazla seçenek beliriyor. Bu seçenekler birbirinden ayrışıyor ve kararın netleşiyor.'), 'not_tentative'],
    ['padding beyond the evidence budget', appended(1, Array.from({ length: 50 }, (_, i) => `Seçeneklerin ${['biri', 'öteki', 'bir başkası', 'hepsi', 'çoğu'][i % 5]} ${['yarın', 'sonra', 'bir gün', 'zamanla', 'yavaşça'][Math.floor(i / 5) % 5]} ${['belirebilir', 'netleşebilir', 'ayrışabilir', 'çoğalabilir', 'değişebilir', 'durulabilir', 'güçlenebilir', 'şekillenebilir', 'yönlenebilir', 'olgunlaşabilir'][Math.floor(i / 5)]}.`).join(' ')), 'padded'],
    ['fluent but generic, not anchored to the claim', withText(1, 'Önümüzdeki dönem senin için oldukça anlamlı olabilir. İçindeki ses sana yol gösterebilir ve hissettiklerin daha da derinleşebilir. Zaman sana kendi cevabını getirebilir gibi görünüyor.'), 'ungrounded_claim'],
  ])('rejects %s', (_label, raw, expected) => expect(failuresOf(raw)).toContain(expected));

  it('rejects a reading that drops, reorders or invents paragraphs / claims', () => {
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[0]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf(JSON.stringify({ paragraphs: [good.paragraphs[1], good.paragraphs[0]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf(JSON.stringify({ paragraphs: [{ ...good.paragraphs[0], claims: ['c1', 'c2', 'c9'] }, good.paragraphs[1]] }))).toEqual(['paragraph_structure']);
    expect(failuresOf('not json')).toEqual(['malformed_json']);
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
    expect(failuresOf(appended(1, 'Bu açılım sana ve çevrene ferah bir aralık bırakabilir.'))).toEqual([]);
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
  const P1 = 'Yakın zamanda bir konunun önünün açılabileceği, sana nefes aldıran ferah bir alan oluşabileceği hissediliyor. Bu ferahlıkla birlikte hareketli bir meselenin yavaş yavaş durulup sakinleşebileceği de seziliyor; telaşın yerini daha dingin bir ritim alıyor ve günlerin biraz daha hafif akıyor gibi. Kendi temponu yeniden bulman için bu rahatlama sana alan bırakabilir.';
  const P2 = 'Aynı dönemde dışarıdaki, daha uzak çevrelerde beklenmedik bir dönüş belirebilir. Planladığından biraz farklı bir yöne doğru bir değişim, sanki kendiliğinden gelişebilir gibi görünüyor; bu yön değişimi seni yormadan yeni bir yol açıyor gibi.';
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3'], text: p2 }] });
  const plan = () => planOf(LIVE_SHAPE, GENERAL);
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
    ['echoing the question words "genel olarak" inside a sentence', P1.replace('Yakın zamanda bir konunun', 'Yakın zamanda, genel olarak bakınca, bir konunun')],
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
  const plan = () => planOf(LIVE_SHAPE, GENERAL);
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3'], text: p2 }] });
  const GOOD_P1 = 'Yakın zamanda bir konunun önünün açılabileceği, sana nefes aldıran ferah bir alan oluşabileceği hissediliyor. Bu ferahlıkla birlikte hareketli bir meselenin yavaş yavaş durulup sakinleşebileceği de seziliyor; telaşın yerini daha dingin bir ritim alabilir.';
  const GOOD_P2 = 'Aynı dönemde dışarıdaki, daha uzak çevrelerde beklenmedik bir dönüş belirebilir. Planladığından biraz farklı bir yöne doğru bir değişim, sanki kendiliğinden gelişebilir gibi görünüyor.';

  /** SIMULATED, authored offline — comparable length; only meaning differs. */
  const POSITIVE: Array<[string, string]> = [
    ['all three claims told naturally', out(GOOD_P1, GOOD_P2)],
    ['different natural wording', out(
      'Kısa süre içinde nefesinin biraz açılabileceği, bir konunun önünün ferahlayabileceği seziliyor. Hareketli bir mesele de yavaş yavaş sakinleşip yerine oturabilir ve günlerin daha dengeli akıyor gibi görünüyor.',
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
    const noEarlierHorizon = out(GOOD_P1.replace('Yakın zamanda bir', 'Bir'), GOOD_P2);
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
  /** Same shared-paragraph shape as the real run: a continuous opening and a broken branching course told together. */
  const SHARED: M1FixtureSpec = {
    marks: [
      { id: 'O', label: null, kind: 'clear_area', band: 'middle', form: { continuity: 'continuous' } },
      { id: 'B', label: null, topology: 'line', form: { course: 'branching', continuity: 'broken' }, band: 'rim_upper' },
      { id: 'T', label: null, topology: 'line', form: { course: 'bending' }, band: 'lower_base' },
    ],
  };
  const P2 = 'Daha uzun vadede beklenmedik bir dönüş, planladığından farklı bir yöne değişim belirebilir gibi; bu yön değişimi sana yeni bir bakış kazandırıyor.';
  const P1_OPENING = 'Önümüzdeki dönemde bir konunun önünün açılabileceği, sana ferah bir alan bırakabileceği seziliyor.';
  const shared = () => {
    const p = planOf(SHARED, GENERAL);
    const opening = p.claims.find((c) => c.theme === 'opening')!;
    const options = p.claims.find((c) => c.theme === 'options')!;
    return { p, opening, options };
  };
  const outFor = (p1: string) => {
    const { p } = shared();
    return JSON.stringify({ paragraphs: p.paragraphs.map((para, i) => ({ claims: para.claims, text: i === 0 ? p1 : P2 })) });
  };
  const check = (p1: string) => acceptCoffeeV3Narrative(shared().p, outFor(p1));

  it('the fixture reproduces the real conflict: one paragraph, c-opening forbids "ara ara", c-options licenses it', () => {
    const { p, opening, options } = shared();
    expect(p.paragraphs[0].claims).toEqual(expect.arrayContaining([opening.id, options.id]));
    expect(opening.avoid).toContain('ara ara');
    expect(options.qualities).toContain('kesik kesik, ara ara ilerleyen');
  });

  it('POSITIVE: "ara ara" in a sentence that tells ONLY the options claim is accepted', () => {
    const r = check(`${P1_OPENING} Yakın zamanda önünde birden fazla seçenek belirebilir; bu seçenekler ara ara, kendi temposunda netleşebilir gibi görünüyor.`);
    expect(r.ok, r.ok ? '' : r.details.join(',')).toBe(true);
  });

  it('NEGATIVE: "ara ara" describing the opening claim itself is still a contradiction', () => {
    const { opening } = shared();
    const r = check('Önümüzdeki dönemde bir konunun önü ara ara açılabilir, sana ferah bir alan bırakabilir gibi. Yakın zamanda önünde birden fazla seçenek belirebilir; bu seçenekler kendi temposunda netleşebilir.');
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.findings).toEqual(expect.arrayContaining([expect.objectContaining({ code: 'contradiction', paragraph: 1, claim: opening.id, term: 'ara ara' })]));
  });

  it('AMBIGUOUS: a sentence telling both claims with "ara ara" is refused (ownership cannot be established)', () => {
    const r = check(`${P1_OPENING} Yakın zamanda önün açılırken seçenekler de ara ara belirebilir gibi görünüyor; bu da sana yeni bir yol gösterebilir.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('contradiction');
  });

  it('AMBIGUOUS: "ara ara" in a sentence that tells no claim at all is refused, never assumed to be the licensing one', () => {
    const { opening } = shared();
    const r = check(`${P1_OPENING} Yakın zamanda önünde birden fazla seçenek belirebilir gibi görünüyor. Bu süreç de ara ara ilerleyebilir.`);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.findings).toEqual(expect.arrayContaining([expect.objectContaining({ code: 'contradiction', claim: opening.id, term: 'ara ara' })]));
  });

  it('the refusal stays visible in writerRejections-style findings (code, paragraph, claim, term)', () => {
    const r = check('Önümüzdeki dönemde bir konunun önü ara ara açılabilir, sana ferah bir alan bırakabilir gibi. Yakın zamanda önünde birden fazla seçenek belirebilir; bu seçenekler kendi temposunda netleşebilir.');
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
  const plan = () => planOf(FOUR, GENERAL);
  const out = (p1: string, p2: string) => JSON.stringify({ paragraphs: [{ claims: ['c1', 'c2'], text: p1 }, { claims: ['c3', 'c4'], text: p2 }] });

  /** SIMULATED "before": the accepted real reading's style (copied notes, placeholders, a hedge in every clause). */
  const BEFORE = out(
    'Yakın zamanda önünde birden fazla seçenek ya da yön belirebilir. Bunlar zamanla birbirinden ayrışırken süreç ara ara ilerleyebilir; ucu açık ve uzun soluklu bir dönem hissi verebilir. Aynı zamanda hareketli bir konu da yavaş yavaş yerine oturabilir ve telaşın azaldığı bir akış başlayabilir.',
    'İçinde tuttuğun bir şeyin dışarı akması, paylaşma isteğiyle birlikte bir hafifleme getirebilir. Bunun yanı sıra bir konuda farklı bir yöne dönebilirsin; yeni bir yön belirdiğinde gidişat beklenmedik biçimde değişebilir.',
  );
  /** SIMULATED "after": the same four meanings as one connected, personal story (authored offline, NOT provider output). */
  const AFTER = out(
    'Yakın zamanda önünde birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
    'Sakinliğin ortasında, içinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe hafiflediğini, omuzlarındaki yükün azaldığını fark edebilirsin. Aynı günlerde kendini planladığından biraz farklı bir yöne dönerken bulman da olası; beklenmedik ama sana yabancı gelmeyecek bir dönüş gibi.',
  );

  it('the fixture reproduces the real four-claim plan shape', () => {
    const p = plan();
    expect(p.claims.map((c) => c.theme)).toEqual(['options', 'settling', 'release', 'turn']);
    expect(p.claims.map((c) => c.horizon)).toEqual(['near', 'near', null, null]);
    expect(p.paragraphs.map((x) => x.claims)).toEqual([['c1', 'c2'], ['c3', 'c4']]);
    expect(p.claims[0].qualities).toEqual(expect.arrayContaining(['kesik kesik, ara ara ilerleyen', 'ucu açık']));
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
      'Yakın zamanda önünde birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
      'Sakinliğin ortasında, eski bir arkadaşınla içinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe hafiflediğini fark edebilirsin. Aynı günlerde kendini planladığından biraz farklı bir yöne dönerken bulman da olası; beklenmedik bir dönüş gibi.',
    ), 'unsupported_specific'],
    ['unsupported causation between two meanings', out(
      'Yakın zamanda önünde birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar tek seferde değil, ara ara ve kendi ritimleriyle netleşecek gibi görünüyor. Bu arada gündemindeki hareketlilik yavaş yavaş durulup sakinleşiyor; telaş, yerini daha dingin bir akışa bırakıyor gibi.',
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
    expect(COFFEE_V3N_WRITER_PROMPT).toContain('Asla sebep-sonuç kurma');
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
  const plan = () => planOf(SIX, GENERAL);
  const out = (p2: string) => JSON.stringify({
    paragraphs: [
      { claims: ['c1', 'c2'], text: 'Yakın zamanda önünde birden fazla seçeneğin belirdiğini hissedebilirsin; ama bunlar bir anda değil, ara ara ve kendi zamanlarında netleşecek gibi. Daha ileride ise bir konunun önü açılıyor, sana nefes aldıran ferah bir alan doğuyor gibi görünüyor.' },
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

describe('live V3 routing: the internal entry runs V3N; the retired M2/W4 path can never run', () => {
  const src = resolve(process.cwd(), 'src');
  const walk = (dir: string): string[] =>
    readdirSync(dir).flatMap((name) => {
      const path = join(dir, name);
      return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
    });
  const rel = (p: string) => p.slice(src.length + 1).replace(/\\/g, '/');

  it('AiProxyService.coffeeV3 delegates to runCoffeeV3NarrativeReading (and nothing else)', () => {
    const service = readFileSync(join(src, 'ai/service.ts'), 'utf8');
    const entry = service.slice(service.indexOf('async coffeeV3('), service.indexOf('private async resolveCoffeeV2Images'));
    expect(entry).toMatch(/return runCoffeeV3NarrativeReading\(\{/);
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
    expect(FROZEN_COFFEE_V3N_PROMPT_SHA256).toBe('b6c9b1bf8c7af54d2f2463ad510f4f19aa591e10d2d47068ca654fb13c1d4d20');
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
