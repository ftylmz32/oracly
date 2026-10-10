import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2, type CoffeeM2Meaning, type CoffeeM2Thread } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_GLOBAL_AVOID,
  COFFEE_TURKISH_RELATION_WORDING,
  toCoffeeM2TurkishWriterPayload,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import {
  COFFEE_TURKISH_DOMAIN_SURFACE,
  COFFEE_TURKISH_REFERENTS,
  COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS,
  coffeeTurkishIsDemonstrativeOpener,
  coffeeTurkishStackedNominalization,
  coffeeTurkishVerbalNouns,
  prepareCoffeeM2TurkishRealization,
} from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { c31Spec, C31_SET_IDS } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const LOVE_TEXT = 'İlişkim hakkında merak ediyorum.';
const meaningOf = (spec: M1FixtureSpec, intention: string | null) =>
  interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning;
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

const SWEEP: Array<[string, CoffeeM2Meaning, string | null]> = [
  ...C31_SET_IDS.map((id) => [id, c31Spec(id)] as const),
  ...Object.entries(M1_QA_CUPS).map(([id, cup]) => [id, cup.spec] as const),
].flatMap(([id, spec]) =>
  [null, DECISION, LOVE_TEXT, 'Bir yerden dönüş bekliyorum.', ...Object.values(CANONICAL_INTENTION_TEXT)].map(
    (intention) => [`${id}|${intention}`, meaningOf(spec, intention), intention] as [string, CoffeeM2Meaning, string | null],
  ),
);

const fold = (s: string) =>
  s.normalize('NFC').toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const CAUSAL = /\b(cunku|bu yuzden|o yuzden|bu sayede|sayesinde|boylece|dolayisiyla|sonucunda|bu nedenle|yuzunden)\b|sagla(r|yabilir|yacak|di)|neden ol|yol ac(ar|abilir|acak)\b|getir(ir|ebilir|ecek)\b|dogur(ur|abilir|acak)\b|\w+(irsen|arsan|ersen|ursan)\b/;

function synthetic(threads: CoffeeM2Thread[]): CoffeeM2Meaning {
  return {
    subject: 'general',
    declaredContext: [],
    intentReference: { kind: 'none' },
    threads,
    diagnostics: { capacity: 'multi_thread', groundedDevelopmentCount: threads.length, distinctFacetCount: 4, maxDepth: 'developed', scenarioAvailable: false },
  };
}
const thread = (p: Partial<CoffeeM2Thread> & Pick<CoffeeM2Thread, 'developments' | 'facets'>): CoffeeM2Thread => ({
  id: 'T1', lane: 'object', combination: null, horizon: 'coming_period',
  developmentHorizons: p.developments.map((development) => ({ development, horizon: 'coming_period' as const })),
  valence: 'neutral', modifiers: [], contextBindings: [], domain: null, conjecture: [],
  forbiddenSpecifics: ['unsupported_causation'], contextForbidden: [], depth: 'developed', scenario: null, ...p,
});

describe('W4C plan invariance and scenario roles (A–C)', () => {
  it('A: the W2 plan is byte-identical before and after the policy (all known cases)', () => {
    for (const id of IDS) {
      const plan = planOf(id);
      const before = JSON.stringify(plan);
      if (plan.status !== 'planned') continue;
      const r = prepareCoffeeM2TurkishRealization(plan);
      expect(JSON.stringify(plan), id).toBe(before);
      const { realization, ...rest } = r;
      expect(rest, id).toEqual(toCoffeeM2TurkishWriterPayload(plan));
      expect(realization.beats).toHaveLength(plan.beats.length);
    }
  });

  it('B: an own-beat scenario must be realized by a finite scenario clause, never a lead noun phrase alone', () => {
    for (const id of ['RITAG', 'CAREER'] as const) {
      const r = realize(id);
      const own = r.realization.beats.find((b, i) => r.beats[i].scenario?.placement === 'own_beat')!;
      expect(own.scenarioRoles).toEqual({ roles: ['scenario'], leadAsSoleRealization: false });
      expect(own.finitePredicateRequired).toBe(true);
    }
  });

  it('C: fused and shared scenarios may use lead or scenario forms', () => {
    expect(realize('MONEY_OBJECT').realization.beats[0].scenarioRoles).toEqual({ roles: ['lead', 'scenario'], leadAsSoleRealization: true });
    expect(realize('BASAK').realization.beats[0].scenarioRoles).toEqual({ roles: ['lead', 'scenario'], leadAsSoleRealization: true });
  });
});

describe('W4C referent ownership and tempo (D–G)', () => {
  it('D: MOMENTUM refers back to the OPPORTUNITY only, never the joint kısmet or the growth', () => {
    const b2 = realize('MONEY_OBJECT').realization.beats[1];
    expect(b2.referent).toMatchObject({ aboutClass: 'OPPORTUNITY', lexicalSubjectRequired: false });
    // W4C.1: under growing_kismet the opportunity entity may carry the growth, so MOMENTUM refers to its facet only.
    expect(b2.referent!.referents).toEqual(['fırsatın hareketi', 'fırsatın etrafındaki hareket', 'bu fırsattaki hareket']);
    expect(b2.referent!.forbiddenReferents).toEqual(expect.arrayContaining(['bu kısmet', 'bu büyüme', 'büyümesi', 'bu gelişme']));
  });

  it('E: growth modifiers refer back to GROWTH only, never the opportunity', () => {
    const b3 = realize('MONEY_OBJECT').realization.beats[2];
    expect(b3.referent!.aboutClass).toBe('GROWTH');
    expect(b3.referent!.referents).toEqual(expect.arrayContaining(['bu büyüme', 'büyümesi', 'bu gelişme']));
    expect(b3.referent!.referents).not.toContain('bu kısmet');
    expect(b3.referent!.forbiddenReferents).toEqual(expect.arrayContaining(['bu fırsat', 'gelen fırsat', 'bu kısmet']));
    // "bereketi" only because abundance is licensed in this plan.
    expect(b3.referent!.referents).toContain('bereketi');
    expect(JSON.stringify(realize('BASAK').realization)).not.toContain('bereketi');
  });

  it('F: an owned class with no safe referent authorizes no pronoun (lexical subject required, no generic bleed)', () => {
    const t = thread({
      developments: ['social_presence'],
      modifiers: ['gathering'],
      facets: [{ category: 'core_development', cls: 'PEOPLE' }, { category: 'scope', cls: 'GATHERING' }],
    });
    const r = prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(synthetic([t])).plan);
    expect(r.realization.beats[0].referent).toBeNull(); // GATHERING shares the PEOPLE beat
    const t2 = thread({
      developments: ['social_presence'],
      modifiers: ['gathering', 'close_circle'],
      facets: [{ category: 'core_development', cls: 'PEOPLE' }, { category: 'scope', cls: 'GATHERING' }, { category: 'scope', cls: 'CLOSE_CIRCLE' }],
    });
    const r2 = prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(synthetic([t2])).plan);
    const elaboration = r2.realization.beats[1];
    expect(elaboration.referent).toEqual({ aboutClass: 'PEOPLE', kind: 'entity', referents: [], forbiddenReferents: [], forbiddenEntityNouns: [], lexicalSubjectRequired: true });
    expect(COFFEE_TURKISH_REFERENTS.PEOPLE).toBeUndefined();
    expect(JSON.stringify(COFFEE_TURKISH_REFERENTS)).not.toMatch(/bu durum/);
  });

  it('G: gradual growth + opportunity momentum get separate public referents; the joint word is never shared', () => {
    const tempo = realize('MONEY_OBJECT').realization.crossBeat.tempo;
    expect(tempo).toHaveLength(1);
    expect(tempo[0].classes).toEqual(['GROWTH', 'MOMENTUM']);
    expect(tempo[0].neverShared).toEqual(expect.arrayContaining(['bu kısmet', 'bu fırsat', 'bu imkân', 'gelen fırsat']));
    const growth = tempo[0].separateReferents.GROWTH;
    const momentum = tempo[0].separateReferents.MOMENTUM;
    expect(growth.filter((x) => momentum.includes(x))).toEqual([]);
    for (const id of ['RITAG', 'BASAK', 'CAREER', 'LOVE'] as const) expect(realize(id).realization.crossBeat.tempo).toEqual([]);
  });
});

describe('W4C openers (H–I)', () => {
  it('H: every beat after the first must not repeat the previous opener, and has a non-demonstrative referent option', () => {
    for (const id of IDS) {
      const r = realize(id);
      r.realization.beats.forEach((b, i) => expect(b.avoidSameOpenerAsPrevious, `${id} B${i + 1}`).toBe(i > 0));
      expect(r.realization.crossBeat.noIdenticalAdjacentOpener).toBe(true);
      for (const b of r.realization.beats.filter((x) => x.referent && !x.referent.lexicalSubjectRequired)) {
        expect(b.referent!.referents.some((x) => !coffeeTurkishIsDemonstrativeOpener(x)), `${id} B${b.order}`).toBe(true);
      }
    }
  });

  it('I: a three-beat plan never authorizes a demonstrative opener on every beat', () => {
    for (const id of ['MONEY_OBJECT', 'LOVE'] as const) {
      const r = realize(id);
      expect(r.beats).toHaveLength(3);
      expect(r.realization.crossBeat.demonstrativeOpenerMax).toBe(2);
    }
    expect(coffeeTurkishIsDemonstrativeOpener('Bu kısmet giderek hız kazanıyor.')).toBe(true);
    expect(coffeeTurkishIsDemonstrativeOpener('Fırsatın hareketi hız kazanıyor.')).toBe(false);
  });
});

describe('W4C relation register (J–L)', () => {
  const relationForms = Object.entries(COFFEE_TURKISH_RELATION_WORDING).flatMap(([k, r]) => (r.forms.relational ?? []).map((f) => [k, f] as const));

  it('J: every relation wording passes the natural-register avoid list (incl. "aynı hareketin parçası")', () => {
    expect(COFFEE_TURKISH_GLOBAL_AVOID).toContain('aynı hareketin parçası');
    for (const [k, f] of relationForms) {
      for (const banned of COFFEE_TURKISH_GLOBAL_AVOID) expect(fold(f).includes(fold(banned)), `${k}: ${f}`).toBe(false);
      expect(coffeeTurkishStackedNominalization(f), `${k}: ${f}`).toBe(false);
    }
  });

  it('K: access_through_direction has no stiff "aynı hareketin parçası" and no user-action condition', () => {
    const forms = COFFEE_TURKISH_RELATION_WORDING.access_through_direction.forms.relational!;
    expect(forms.length).toBeGreaterThanOrEqual(4);
    forms.forEach((f) => {
      expect(f).not.toMatch(/aynı hareketin parçası/);
      expect(fold(f)).not.toMatch(/(irsen|ersen|arsan|ursan)\b/);
    });
  });

  it('L: no relation wording (or W4C wording) encodes causation', () => {
    for (const [k, f] of relationForms) expect(CAUSAL.test(fold(f)), `${k}: ${f}`).toBe(false);
    const w4c = [
      ...Object.values(COFFEE_TURKISH_REFERENTS).flat().map((r) => r.text),
      ...Object.values(COFFEE_TURKISH_DOMAIN_SURFACE).flatMap((d) => Object.values(d).flatMap((r) => r.forms)),
    ];
    for (const f of w4c) {
      expect(CAUSAL.test(fold(f)), f).toBe(false);
      for (const banned of COFFEE_TURKISH_GLOBAL_AVOID) expect(fold(f).includes(fold(banned)), f).toBe(false);
    }
  });
});

describe('W4C nominalization heuristic (M–O)', () => {
  it('M: catches the repeated -man/-men frame', () => {
    expect(coffeeTurkishStackedNominalization('Açılan bu yol, yeni bir sorumluluk alman ya da farklı bir rolde yer alman şeklinde karşına çıkabilir.')).toBe(true);
    expect(coffeeTurkishVerbalNouns('yeni bir sorumluluk alman ya da farklı bir rolde yer alman şeklinde')).toEqual(['alman', 'alman']);
  });

  it('N: catches the stacked -ması/-mesi list', () => {
    expect(coffeeTurkishStackedNominalization('Bu açılım, seçeneklerden birinin ağırlık kazanması, başka bir seçeneğin gündeme gelmesi ve seçeneklerin ayrışması gibi yaşanabilir.')).toBe(true);
  });

  it('O: verbal nouns are not globally banned (one is fine; zaman / imkân / hemen are not verbal nouns)', () => {
    expect(coffeeTurkishStackedNominalization('Farklı bir yöne dönmek anlam kazanabilir.')).toBe(false);
    expect(coffeeTurkishStackedNominalization('Yakın zamanda yeni bir imkân doğabilir; hemen değil, zamanla büyüyor.')).toBe(false);
    expect(coffeeTurkishStackedNominalization('Seçeneklerden biri ağır basmaya başlayabilir; başka bir seçenek de gündeme gelebilir.')).toBe(false);
  });
});

describe('W4C scenarios, overlaps, semantics (P–S)', () => {
  it('P: scenario alternatives stay 1–2 and incompatible pairs are only excluded, never chosen', () => {
    for (const id of IDS) {
      const r = realize(id);
      for (const cluster of r.wording.scenarioClusters) expect(cluster.choose.max).toBeLessThanOrEqual(2);
      r.realization.beats.forEach((b, i) => {
        const ms = r.beats[i].scenario?.manifestations ?? [];
        b.scenarioIncompatiblePairs.forEach((pair) => pair.forEach((m) => expect(ms).toContain(m)));
      });
    }
    expect(realize('RITAG').realization.beats[1].scenarioIncompatiblePairs).toEqual([['another_option_relevant', 'options_separating']]);
    for (const { pair } of COFFEE_TURKISH_SCENARIO_INCOMPATIBLE_PAIRS) expect(pair[0]).not.toBe(pair[1]);
  });

  it('Q: overlap restrictions are attached to the LOVE beats that carry the classes', () => {
    const r = realize('LOVE');
    const [b1, b2, b3] = r.realization.beats;
    expect(b1.overlap.map((o) => `${o.cls}~${o.with}`)).toEqual(['COMMITMENT~DURABLE']);
    expect(b2.overlap.map((o) => `${o.cls}~${o.with}`).sort()).toEqual(['DURABLE~COMMITMENT', 'SINGULAR~LEANING']);
    expect(b3.overlap.map((o) => `${o.cls}~${o.with}`)).toEqual(['LEANING~SINGULAR']);
    // Love idiom: the context-awkward generic wording is avoided and replaced by equivalent forms.
    expect(b2.avoidWording).toEqual(expect.arrayContaining(['tek bir yerde toplan', 'bütün duruyor']));
    const singular = b2.overlap.find((o) => o.cls === 'SINGULAR')!;
    singular.useOnly.forEach((f) => expect(f).not.toMatch(/toplan/));
    expect(b3.overlap[0].neverUse).toEqual(expect.arrayContaining(singular.useOnly));
    const durable = b2.overlap.find((o) => o.cls === 'DURABLE')!;
    durable.useOnly.forEach((f) => expect(fold(f)).not.toMatch(/kalici|saglam/));
  });

  it('R/S: the policy never changes scenario, horizon, domain or context semantics', () => {
    for (const id of IDS) {
      const plan = planOf(id);
      if (plan.status !== 'planned') continue;
      const r = prepareCoffeeM2TurkishRealization(plan);
      r.beats.forEach((b, i) => {
        expect(b.scenario).toEqual(plan.beats[i].scenario ? expect.objectContaining({ manifestations: plan.beats[i].scenario!.manifestations }) : null);
        expect(b.qualifiers).toEqual(plan.beats[i].qualifiers);
        expect(b.groups.map((g) => g.horizon)).toEqual(plan.beats[i].groups.map((g) => g.horizon));
      });
      const raw = JSON.stringify(r.realization);
      expect(raw).not.toMatch(/"(horizon|domain|context|manifestations)"\s*:/);
    }
  });
});

describe('W4C payload boundary (T–Z)', () => {
  it('T: only rows relevant to the plan (no global referent / domain dump)', () => {
    const ritag = JSON.stringify(realize('RITAG').realization);
    expect(ritag).not.toMatch(/kısmet|fırsat|büyüme|bağ|duygu|odağı/);
    expect(JSON.stringify(realize('MONEY_OBJECT').realization)).not.toMatch(/odağı|bütünlüklü|bu bağ/);
  });

  it('U/V/W: no W2 / W4C audit, no raw user text, and the meaning-only guard passes (sweep)', () => {
    for (const [name, meaning, intention] of SWEEP) {
      const plan = planCoffeeM2Writer(meaning).plan;
      if (plan.status !== 'planned') continue;
      const r = prepareCoffeeM2TurkishRealization(plan);
      expect(() => assertCoffeeV3MeaningOnly(r), name).not.toThrow();
      const raw = JSON.stringify(r);
      expect(raw, name).not.toMatch(/"(omitted|diagnostics|audit|threadId|consumedFacetClasses|omittedReasons|scenarioConsumed|relationConsumed|beatGroupCounts|contractGaps|userDeclaredIntention|intentReference|why|note_internal)"/);
      if (intention) expect(raw.includes(intention), name).toBe(false);
    }
  });

  it('X: an insufficient plan refuses the realization payload', () => {
    const unal = planCoffeeM2Writer(meaningOf(c31Spec('C3F-UNAL'), CANONICAL_INTENTION_TEXT.general)).plan;
    expect(() => prepareCoffeeM2TurkishRealization(unal)).toThrow('coffee_m2_writer_plan_insufficient');
  });

  it('Y: same input → byte-identical realization payload', () => {
    for (const id of IDS) {
      const a = JSON.stringify(prepareCoffeeM2TurkishRealization(JSON.parse(JSON.stringify(planOf(id)))));
      const b = JSON.stringify(prepareCoffeeM2TurkishRealization(JSON.parse(JSON.stringify(planOf(id)))));
      expect(a, id).toBe(b);
    }
  });

  it('Z: nothing live imports the realization policy; only the dark W4C.1 QA checker does', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    expect(
      walk(src)
        .filter((p) => /coffee-m2-turkish-realization-policy/.test(readFileSync(p, 'utf8')))
        .map((p) => p.slice(src.length + 1).split(String.fromCharCode(92)).join('/')),
    ).toEqual(['ai/reading/coffee-m2-turkish-realization-check.ts', 'ai/reading/coffee-m2-writer-prompt.ts', 'ai/reading/coffee-v3-live-pipeline.ts']); // LIS2 — the dark V3 live bridge is the one sanctioned integration importer of the frozen stack.
  });
});
