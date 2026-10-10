import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2, type CoffeeM2Meaning, type CoffeeM2Thread } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_ENTITY_NOUNS,
  COFFEE_TURKISH_FACET_REFERENTS,
  prepareCoffeeM2TurkishRealization,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import {
  assembleCoffeeM2PublicReading,
  checkCoffeeM2TurkishRealization,
  parseCoffeeM2QaWriterOutput,
  validateCoffeeM2ScenarioSelection,
} from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const LOVE_TEXT = 'İlişkim hakkında merak ediyorum.';
const meaningOf = (spec: M1FixtureSpec, intention: string) => interpretCoffeeM2(m1Map(spec), classifyCoffeeIntention(intention)).meaning;
const CASES = {
  RITAG: [c31Spec('C3F-RITAG'), DECISION],
  BASAK: [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance],
  MONEY_OBJECT: [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance],
  CAREER: [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work],
  LOVE: [M1_QA_CUPS.love_ring_heart.spec, LOVE_TEXT],
  PERSON: [M1_QA_CUPS.person_bird.spec, CANONICAL_INTENTION_TEXT.person_of_interest],
  HALIL: [c31Spec('C3F-HALIL'), CANONICAL_INTENTION_TEXT.career_work],
} as const;
type CaseId = keyof typeof CASES;
const IDS = Object.keys(CASES) as CaseId[];
const planOf = (id: CaseId) => planCoffeeM2Writer(meaningOf(CASES[id][0], CASES[id][1])).plan;
const realize = (id: CaseId) => prepareCoffeeM2TurkishRealization(planOf(id));
const codes = (id: CaseId, texts: string[]) => checkCoffeeM2TurkishRealization(realize(id), texts).map((v) => `${v.beat}:${v.code}`);

/** Exact saved provider outputs (W4B / W4D scratchpad QA runs). */
const W4D = {
  RITAG: [
    'Önündeki karar, yaklaşan dönemde kendi akışında ilerlerken birkaç ayrı ihtimale açılıyor.',
    'Bu seçeneklerden biri gözünde ağırlık kazanabilir ya da başka bir seçenek de gündeme gelebilir.',
  ],
  BASAK: [
    'Yakın zamanda maddi tarafta önünde birkaç ayrı ihtimal beliriyor; para düzenini değiştirebilecek bir seçenek de çıkabilir.',
    'Açılan bu yollar ise bir ilerleyip bir duruyor.',
  ],
  MONEY_OBJECT: [
    'Maddi tarafta yakın zamanda yeni bir kazanç fırsatı çıkabilir ve bu fırsat önümüzdeki dönemde yavaş yavaş genişliyor.',
    'Gelen fırsat giderek hız kazanıyor.',
    'Bu büyüme birkaç ayrı koldan kendi akışında ilerliyor.',
  ],
  CAREER: [
    'İş tarafında önündeki yol önümüzdeki dönemde açılırken, biraz daha ileride yeni bir yöne de kıvrılıyor.',
    'Açılan bu yolda farklı bir rol üstlenebilirsin ya da çalışma biçimin değişebilir.',
  ],
  PERSON: ['Önümüzdeki dönemde aklındaki kişiyle ilgili, henüz açılmamış bir haberleşme kıpırdanabilir.'],
  HALIL: ['İş ve kariyer tarafında önümüzdeki dönemde adım adım ilerleyen bir yol görünüyor.'],
};
const W4B_MONEY = [
  'Maddi tarafta yakın zamanda yeni bir kazanç fırsatı çıkabilir; bu kısmet önümüzdeki dönemde yavaş yavaş bereketleniyor.',
  'Bu kısmet giderek hız kazanıyor.',
  'Bu büyüme birkaç ayrı koldan, kendi akışında adım adım ilerliyor.',
];
const SAFE_MONEY = [
  'Maddi tarafta yakın zamanda güzel bir kısmet var; yeni bir kazanç fırsatı ya da başka bir gelir kapısı gibi görünebilecek bu kısmet, önümüzdeki dönemde zamanla büyüyüp bereketleniyor.',
  'Fırsatın etrafındaki hareket ise giderek hız kazanıyor.',
  'Büyümesi de tek bir koldan değil, birkaç ayrı koldan ve istikrarla oluyor.',
];

function synthetic(threads: CoffeeM2Thread[]): CoffeeM2Meaning {
  return {
    subject: 'general', declaredContext: [], intentReference: { kind: 'none' }, threads,
    diagnostics: { capacity: 'multi_thread', groundedDevelopmentCount: 2, distinctFacetCount: 4, maxDepth: 'developed', scenarioAvailable: true },
  };
}
const thread = (p: Partial<CoffeeM2Thread> & Pick<CoffeeM2Thread, 'developments' | 'facets'>): CoffeeM2Thread => ({
  id: 'T1', lane: 'object', combination: null, horizon: 'coming_period',
  developmentHorizons: p.developments.map((development) => ({ development, horizon: 'coming_period' as const })),
  valence: 'positive', modifiers: [], contextBindings: [], domain: null, conjecture: [],
  forbiddenSpecifics: ['unsupported_causation'], contextForbidden: [], depth: 'developed', scenario: null, ...p,
});

describe('W4C.1 tempo-referent collision (A–F)', () => {
  it('A: the exact W4D MONEY output fails with TEMPO_REFERENT_COLLISION on B2', () => {
    expect(codes('MONEY_OBJECT', W4D.MONEY_OBJECT)).toContain('B2:TEMPO_REFERENT_COLLISION');
  });

  it('B: the old W4B MONEY output still fails ("Bu kısmet" speeding up)', () => {
    const c = codes('MONEY_OBJECT', W4B_MONEY);
    expect(c).toEqual(expect.arrayContaining(['B2:TEMPO_REFERENT_COLLISION', 'B2:FORBIDDEN_REFERENT']));
  });

  it('A/B: every same-entity speed subject fails, whatever the inflection', () => {
    for (const b2 of ['Bu fırsat hız kazanıyor.', 'Gelen fırsat giderek hızlanıyor.', 'Bu imkânın hızı artıyor.', 'Kısmet giderek hızlanıyor.']) {
      expect(codes('MONEY_OBJECT', [SAFE_MONEY[0], b2, SAFE_MONEY[2]]), b2).toContain('B2:TEMPO_REFERENT_COLLISION');
    }
  });

  it('C: the safe motion-specific MOMENTUM version passes every rule', () => {
    expect(codes('MONEY_OBJECT', SAFE_MONEY)).toEqual([]);
    for (const facet of COFFEE_TURKISH_FACET_REFERENTS.MOMENTUM.OPPORTUNITY) {
      const b2 = `${facet[0].toLocaleUpperCase('tr-TR')}${facet.slice(1)} giderek hız kazanıyor.`;
      expect(codes('MONEY_OBJECT', [SAFE_MONEY[0], b2, SAFE_MONEY[2]]), b2).toEqual([]);
    }
  });

  it('D/E: under growing_kismet, MOMENTUM gets facet referents only; entity referents and nouns are forbidden', () => {
    const b2 = realize('MONEY_OBJECT').realization.beats[1].referent!;
    expect(b2).toMatchObject({ aboutClass: 'OPPORTUNITY', kind: 'facet', lexicalSubjectRequired: false });
    expect(b2.referents).toEqual(['fırsatın hareketi', 'fırsatın etrafındaki hareket', 'bu fırsattaki hareket']);
    expect(b2.forbiddenReferents).toEqual(expect.arrayContaining(['bu fırsat', 'bu imkân', 'gelen fırsat', 'bu kısmet']));
    expect(b2.forbiddenEntityNouns).toEqual([...COFFEE_TURKISH_ENTITY_NOUNS.OPPORTUNITY]);
    const tempo = realize('MONEY_OBJECT').realization.crossBeat.tempo[0];
    expect(tempo.separateReferents.MOMENTUM).toEqual(b2.referents);
    expect(tempo.neverShared).toEqual(expect.arrayContaining(['bu kısmet', 'bu fırsat', 'gelen fırsat']));
  });

  it('E: "hareket" is only MOMENTUM\'s public realization — no other class, no new fact', () => {
    expect(Object.keys(COFFEE_TURKISH_FACET_REFERENTS)).toEqual(['MOMENTUM']);
    for (const id of ['RITAG', 'BASAK', 'CAREER', 'LOVE', 'PERSON', 'HALIL'] as const) {
      expect(JSON.stringify(realize(id).realization)).not.toMatch(/hareketi"|etrafındaki hareket|fırsattaki hareket/);
    }
    const plan = planOf('MONEY_OBJECT');
    const r = prepareCoffeeM2TurkishRealization(plan);
    expect(r.beats).toEqual(prepareCoffeeM2TurkishRealization(plan).beats);
    expect(r.beats[1].groups.map((g) => g.cls)).toEqual(['MOMENTUM']); // no new group, development or event
  });

  it('F: GROWTH elaboration stays growth-specific (entity kind, never the opportunity)', () => {
    const b3 = realize('MONEY_OBJECT').realization.beats[2].referent!;
    expect(b3).toMatchObject({ aboutClass: 'GROWTH', kind: 'entity', forbiddenEntityNouns: [] });
    expect(b3.referents).toEqual(expect.arrayContaining(['bu büyüme', 'büyümesi', 'bu gelişme']));
    expect(b3.forbiddenReferents).toEqual(expect.arrayContaining(['bu fırsat', 'gelen fırsat', 'bu kısmet']));
  });
});

describe('W4C.1 invariance and regressions (G–L)', () => {
  it('G/H: W2 plan and M2 meaning are byte-identical after the policy', () => {
    for (const id of IDS) {
      const meaning = meaningOf(CASES[id][0], CASES[id][1]);
      const m = JSON.stringify(meaning);
      const plan = planCoffeeM2Writer(meaning).plan;
      const p = JSON.stringify(plan);
      prepareCoffeeM2TurkishRealization(plan);
      expect(JSON.stringify(plan), id).toBe(p);
      expect(JSON.stringify(meaning), id).toBe(m);
    }
  });

  it('I/J/K: the passing W4D RITAG, BASAK and CAREER outputs remain valid', () => {
    expect(codes('RITAG', W4D.RITAG)).toEqual([]);
    expect(codes('BASAK', W4D.BASAK)).toEqual([]);
    expect(codes('CAREER', W4D.CAREER)).toEqual([]);
    expect(codes('PERSON', W4D.PERSON)).toEqual([]);
    expect(codes('HALIL', W4D.HALIL)).toEqual([]);
  });

  it('L: keyed by relation + classes, not fixture: same shape binds; no growth relation leaves entity referents', () => {
    const bound = thread({
      developments: ['opportunity', 'gradual_growth'],
      combination: 'opportunity_with_gradual_growth',
      modifiers: ['active'],
      conjecture: ['kismet', 'opportunity', 'gradual_development', 'growing_kismet'],
      facets: [
        { category: 'core_development', cls: 'OPPORTUNITY' },
        { category: 'core_development', cls: 'GROWTH' },
        { category: 'trajectory', cls: 'MOMENTUM' },
        { category: 'relational', cls: 'RELATION_opportunity_with_gradual_growth' },
      ],
    });
    const r1 = prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(synthetic([bound])).plan);
    expect(r1.realization.beats[1].referent).toMatchObject({ aboutClass: 'OPPORTUNITY', kind: 'facet' });

    const free = thread({
      developments: ['opportunity'],
      modifiers: ['active'],
      conjecture: ['kismet', 'opportunity'],
      scenario: { context: 'general', specificity: 'S1', manifestations: ['matter_opening'], forbidden: [] },
      facets: [{ category: 'core_development', cls: 'OPPORTUNITY' }, { category: 'trajectory', cls: 'MOMENTUM' }],
    });
    const r2 = prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(synthetic([free])).plan);
    expect(r2.realization.beats[1].referent).toMatchObject({ aboutClass: 'OPPORTUNITY', kind: 'entity', referents: ['bu fırsat', 'bu imkân', 'gelen fırsat', 'bu kısmet'] });
    const src = readFileSync(resolve(process.cwd(), 'src/ai/reading/coffee-m2-turkish-realization-policy.ts'), 'utf8');
    expect(src).not.toMatch(/MONEY_OBJECT|money_fish_tree|C3F-/);
  });
});

describe('W4C.1 exact scenario selection (M–U)', () => {
  const money = () => realize('MONEY_OBJECT');
  const v = (sel: string[][]) => validateCoffeeM2ScenarioSelection(money(), sel).map((x) => `${x.beat}:${x.code}`);

  it('M: exact allowed IDs pass', () => {
    expect(v([['new_financial_opportunity'], [], []])).toEqual([]);
    expect(v([['new_financial_opportunity', 'another_earning_channel'], [], []])).toEqual([]);
    expect(validateCoffeeM2ScenarioSelection(realize('CAREER'), [[], ['different_role', 'different_way_of_working']])).toEqual([]);
  });

  it('N/O/P/Q/R/S: foreign, duplicate, too many, too few, incompatible pair, scenario on a non-scenario beat', () => {
    expect(v([['additional_financial_possibility'], [], []])).toContain('B1:SCENARIO_UNKNOWN_ID');
    expect(v([['new_financial_opportunity', 'new_financial_opportunity'], [], []])).toContain('B1:SCENARIO_DUPLICATE_ID');
    expect(v([['new_financial_opportunity', 'another_earning_channel', 'financial_side_strengthened'], [], []])).toContain('B1:SCENARIO_TOO_MANY');
    expect(v([[], [], []])).toContain('B1:SCENARIO_TOO_FEW');
    expect(v([['new_financial_opportunity', 'financial_side_strengthened'], [], []])).toContain('B1:SCENARIO_INCOMPATIBLE_PAIR');
    expect(v([['new_financial_opportunity'], ['another_earning_channel'], []])).toContain('B2:SCENARIO_ON_NON_SCENARIO_BEAT');
  });

  it('T: prose wording can no longer create a selection false positive (W4D MONEY / PERSON replays)', () => {
    // The W4D text detector flagged these from shared words ("maddi tarafta", "kişiyle ilgili"); IDs decide now.
    expect(v([['new_financial_opportunity'], [], []])).toEqual([]);
    expect(validateCoffeeM2ScenarioSelection(realize('PERSON'), [['communication_around_chosen_person']])).toEqual([]);
    const src = readFileSync(resolve(process.cwd(), 'src/ai/reading/coffee-m2-turkish-realization-check.ts'), 'utf8');
    const validator = src.slice(src.indexOf('export function validateCoffeeM2ScenarioSelection'), src.indexOf('export type CoffeeM2QaBeat'));
    expect(validator).not.toMatch(/text|fold\(|includes\(fold/);
  });

  it('U: QA scenarioItems never enter the public reading; the strict QA contract is enforced', () => {
    const raw = JSON.stringify({ beats: SAFE_MONEY.map((text, i) => ({ id: `B${i + 1}`, scenarioItems: i === 0 ? ['new_financial_opportunity'] : [], text })) });
    const parsed = parseCoffeeM2QaWriterOutput(raw, 3, { requireScenarioItems: true });
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;
    const reading = assembleCoffeeM2PublicReading(parsed.beats);
    expect(reading).toBe(SAFE_MONEY.join(' '));
    expect(reading).not.toMatch(/new_financial_opportunity|scenarioItems/);
    expect(parseCoffeeM2QaWriterOutput(raw, 3, { requireScenarioItems: false }).ok).toBe(false); // extra field without the QA contract
    expect(parseCoffeeM2QaWriterOutput(JSON.stringify({ beats: [{ id: 'B1', text: 'x' }] }), 3, { requireScenarioItems: false }).ok).toBe(false);
    expect(parseCoffeeM2QaWriterOutput('```json\n{}\n```', 1, { requireScenarioItems: false }).ok).toBe(false);
  });
});

describe('W4C.1 boundary (V–Z)', () => {
  it('V/W: raw user text absent and the meaning-only guard passes', () => {
    for (const id of IDS) {
      const r = realize(id);
      expect(() => assertCoffeeV3MeaningOnly(r)).not.toThrow();
      expect(JSON.stringify(r).includes(CASES[id][1])).toBe(false);
    }
  });

  it('X: an insufficient plan still refuses the realization payload', () => {
    const unal = planCoffeeM2Writer(meaningOf(c31Spec('C3F-UNAL'), CANONICAL_INTENTION_TEXT.general)).plan;
    expect(() => prepareCoffeeM2TurkishRealization(unal)).toThrow('coffee_m2_writer_plan_insufficient');
  });

  it('Y: same input → byte-identical payload', () => {
    for (const id of IDS) {
      expect(JSON.stringify(prepareCoffeeM2TurkishRealization(JSON.parse(JSON.stringify(planOf(id)))))).toBe(JSON.stringify(realize(id)));
    }
  });

  it('Z: nothing in src imports the QA checker; only it and nothing live imports the policy', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    const users = (re: RegExp) => walk(src).filter((p) => re.test(readFileSync(p, 'utf8'))).map((p) => p.slice(src.length + 1).replace(/\\/g, '/')).sort();
    // LIS2 — the dark V3 live bridge is the one sanctioned integration importer of the frozen stack.
    expect(users(/coffee-m2-turkish-realization-check/)).toEqual(['ai/reading/coffee-v3-live-pipeline.ts']);
    expect(users(/coffee-m2-turkish-realization-policy/)).toEqual(['ai/reading/coffee-m2-turkish-realization-check.ts', 'ai/reading/coffee-m2-writer-prompt.ts', 'ai/reading/coffee-v3-live-pipeline.ts']);
  });
});
