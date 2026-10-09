import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import {
  COFFEE_M2_CONSEQUENCE_FACET,
  COFFEE_M2_CORE_CLASS,
  COFFEE_M2_MODIFIER_FACET,
  coffeeM2Scenario,
  interpretCoffeeM2,
  type CoffeeM2Meaning,
  type CoffeeM2Thread,
} from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer, toCoffeeM2WriterPayload } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_CLASS_WORDING,
  COFFEE_TURKISH_CONTEXT_WORDING,
  COFFEE_TURKISH_DOMAIN_WORDING,
  COFFEE_TURKISH_GLOBAL_AVOID,
  COFFEE_TURKISH_HORIZON_WORDING,
  COFFEE_TURKISH_RELATION_WORDING,
  COFFEE_TURKISH_SCENARIO_CLUSTERS,
  COFFEE_TURKISH_SCENARIO_WORDING,
  COFFEE_TURKISH_SURFACE_OVERLAPS,
  COFFEE_TURKISH_TOKEN_WORDING,
  toCoffeeM2TurkishWriterPayload,
  type CoffeeTurkishSurfaceRow,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
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
const planOf = (id: keyof typeof CASES) => planCoffeeM2Writer(meaningOf(CASES[id][0], CASES[id][1])).plan;
const enriched = (id: keyof typeof CASES) => toCoffeeM2TurkishWriterPayload(planOf(id));

const SWEEP: Array<[string, CoffeeM2Meaning, string | null]> = [
  ...C31_SET_IDS.map((id) => [id, c31Spec(id)] as const),
  ...Object.entries(M1_QA_CUPS).map(([id, cup]) => [id, cup.spec] as const),
].flatMap(([id, spec]) =>
  [null, DECISION, LOVE_TEXT, 'Bir yerden dönüş bekliyorum.', ...Object.values(CANONICAL_INTENTION_TEXT)].map(
    (intention) => [`${id}|${intention}`, meaningOf(spec, intention), intention] as [string, CoffeeM2Meaning, string | null],
  ),
);

// ---------------------------------------------------------------------------
// Turkish text helpers (folded, whole-token where it matters)
// ---------------------------------------------------------------------------

const fold = (s: string) =>
  s.normalize('NFC').toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const SUF = '(lar|ler)?(i|u|si|su|im|um|in|un|imiz|umuz|iniz|unuz|lari|leri)?(n?in|n?un|[ny]?i|[ny]?u|[ny]?a|[ny]?e|n?da|n?de|n?ta|n?te|n?dan|n?den|n?tan|n?ten|y?la|y?le|n?daki|n?deki|ki)?(dir|dur|tir|tur)?';
const VISUAL = new RegExp(`\\b(fincan|telve|tabak|tabag|kulp|kulb|iz|leke|sekil|figur|sembol|cizgi|ag|dal|damla|akinti|havuz|bant|isaret)${SUF}\\b`);
const JARGON = /\b(thread|beat|facet|scenario|relation|development|horizon|valence|domain|binding|modifier|token|qualifier|cls|m1|m2|w2|v3|json)\b/i;
const DIGIT_OR_DATE = /\d|\b(ocak|subat|mart|nisan|mayis|haziran|temmuz|agustos|eylul|ekim|kasim|aralik|pazartesi|sali|carsamba|persembe|cuma|cumartesi|pazar)\b/;
const AMOUNT = /\b(lira|tl|dolar|euro|bin|milyon|maas|zam|ikramiye|borc|miras|piyango)\b/;
const CAUSAL = /\b(cunku|bu yuzden|o yuzden|bu sayede|sayesinde|boylece|dolayisiyla|sonucunda|bu nedenle|yuzunden)\b|sagla(r|yabilir|yacak|di)|neden ol|yol ac(ar|abilir|acak)\b|getir(ir|ebilir|ecek)\b|dogur(ur|abilir|acak)\b/;
const ADVICE = /(^|\s)(bekle|acele etme|sabirli ol|dikkat et|sakin ol|unutma|kendine iyi bak)\b|m[ae]l[iı]s[iı]n\b|\bsakin\b/;
const PRESUPPOSITION = /\b(yeniden|tekrar|hala|alistigin|eskiden|simdilik|uzun zamandir|ikinci planda|bekleyen|sikismis|zorlandigin)\b/;
const NOMINAL_CHAIN = /\w+(ma|me)s[iı]\b/g;

const allRows: Array<[string, CoffeeTurkishSurfaceRow]> = [
  ...Object.entries(COFFEE_TURKISH_CLASS_WORDING).map(([k, r]) => [`class:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_TOKEN_WORDING).map(([k, r]) => [`token:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_RELATION_WORDING).map(([k, r]) => [`relation:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_SCENARIO_WORDING).map(([k, r]) => [`scenario:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_DOMAIN_WORDING).map(([k, r]) => [`domain:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_CONTEXT_WORDING).map(([k, r]) => [`context:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
  ...Object.entries(COFFEE_TURKISH_HORIZON_WORDING).map(([k, r]) => [`horizon:${k}`, r] as [string, CoffeeTurkishSurfaceRow]),
];
const formsOf = (row: CoffeeTurkishSurfaceRow) => Object.values(row.forms).flatMap((list) => [...(list ?? [])]);
const allForms = allRows.flatMap(([name, row]) => formsOf(row).map((f) => [name, f] as const));
const overlapForms = COFFEE_TURKISH_SURFACE_OVERLAPS.flatMap((o) => Object.values(o.distinct).flat().map((f) => [`overlap:${o.classes.join('/')}`, f] as const));
const everyPublicString = [...allForms, ...overlapForms];

/** Every scenario cluster M2's own palette can emit (single development × each context source). */
function allScenarioClusters(): string[][] {
  const developments = Object.keys(COFFEE_M2_CORE_CLASS);
  const bindings = [[], ['chosen_person'], ['awaited_topic'], ['user_decision'], ['current_relationship']] as CoffeeM2Thread['contextBindings'][];
  const domains = [null, 'career', 'financial', 'love'] as CoffeeM2Thread['domain'][];
  const seen = new Map<string, string[]>();
  for (const development of developments) {
    for (const contextBindings of bindings) {
      for (const domain of domains) {
        const s = coffeeM2Scenario({ developments: [development], contextBindings, domain });
        if (s) seen.set(s.manifestations.join('|'), s.manifestations);
      }
    }
  }
  return [...seen.values()];
}

// ---------------------------------------------------------------------------
// Bank coverage and register (A–N)
// ---------------------------------------------------------------------------

describe('W4A bank coverage (A–E)', () => {
  it('A: every M2 equivalence class has a wording row', () => {
    const classes = new Set([
      ...Object.values(COFFEE_M2_CORE_CLASS),
      ...Object.values(COFFEE_M2_MODIFIER_FACET).map((f) => f.cls),
      ...Object.values(COFFEE_M2_CONSEQUENCE_FACET),
    ]);
    for (const cls of classes) expect(COFFEE_TURKISH_CLASS_WORDING[cls], cls).toBeDefined();
    expect(Object.keys(COFFEE_TURKISH_CLASS_WORDING).sort()).toEqual([...classes].sort());
  });

  it('A: every distinct W2 relation has a relational wording row', () => {
    const distinct = [
      'opportunity_with_gradual_growth', 'commitment_with_emotion', 'access_through_direction', 'choice_with_direction',
      'direction_with_growth', 'contact_with_opportunity', 'written_contact_with_opportunity', 'course_opens_into_alternatives',
      'stalled_course_finds_room', 'opening_moves_forward', 'possibilities_become_visible',
    ];
    expect(Object.keys(COFFEE_TURKISH_RELATION_WORDING).sort()).toEqual([...distinct].sort());
    for (const key of distinct) expect(COFFEE_TURKISH_RELATION_WORDING[key].forms.relational?.length, key).toBeGreaterThanOrEqual(4);
  });

  it('B/C: high-value rows have >= 4 alternatives, narrow rows >= 3, unless an exception is documented', () => {
    for (const [name, row] of allRows) {
      const n = new Set(formsOf(row).map(fold)).size;
      if (row.exception) continue;
      expect(n, name).toBeGreaterThanOrEqual(row.tier === 'high_value' ? 4 : 3);
    }
    for (const cls of ['FORWARD', 'MULTIPLICITY', 'UNEVEN', 'OPENING', 'CHANGE', 'OPPORTUNITY', 'GROWTH', 'COMMITMENT', 'FEELING']) {
      expect(COFFEE_TURKISH_CLASS_WORDING[cls].tier, cls).toBe('high_value');
    }
  });

  it('B: the primary targets have several finite predicate alternatives (no single canonical gloss)', () => {
    for (const cls of ['FORWARD', 'MULTIPLICITY', 'UNEVEN', 'OPENING', 'CHANGE', 'GROWTH', 'FEELING']) {
      expect(COFFEE_TURKISH_CLASS_WORDING[cls].forms.predicate?.length, cls).toBeGreaterThanOrEqual(4);
    }
    // RITAG relation: not always "ilerlerken … açılıyor".
    const ritag = COFFEE_TURKISH_RELATION_WORDING.course_opens_into_alternatives.forms.relational!;
    expect(ritag.filter((f) => /ilerlerken/.test(f)).length).toBeLessThanOrEqual(1);
    // BASAK UNEVEN: never one canned phrase.
    const uneven = COFFEE_TURKISH_CLASS_WORDING.UNEVEN.forms.predicate!;
    expect(uneven.filter((f) => /bir ilerleyip bir dur/.test(f)).length).toBeLessThanOrEqual(1);
  });

  it('D/E: no empty alternative and no duplicate alternative after Turkish folding', () => {
    for (const [name, row] of allRows) {
      const forms = formsOf(row);
      forms.forEach((f) => expect(f.trim().length, name).toBeGreaterThan(0));
      for (const list of Object.values(row.forms)) {
        const folded = (list ?? []).map((f) => fold(f).replace(/\s+/g, ' ').trim());
        expect(new Set(folded).size, name).toBe(folded.length);
      }
    }
  });
});

describe('W4A register guards (F–K)', () => {
  it('F: no global-avoid report language or cliché appears in any public wording', () => {
    for (const [name, form] of everyPublicString) {
      for (const banned of COFFEE_TURKISH_GLOBAL_AVOID) expect(fold(form).includes(fold(banned)), `${name}: ${form} ~ ${banned}`).toBe(false);
    }
    for (const required of ['seyir taşıyor', 'nitelik taşıyor', 'bir durum mevcut', 'tema', 'hareket dinamiği', 'olasılık alanı', 'iki yüzü olarak duruyor', 'belirgin bir tablo sunuyor', 'enerjin çok yüksek', 'evren sana', 'güzel şeyler olacak', 'şans senden yana', 'her şey yoluna girecek']) {
      expect(COFFEE_TURKISH_GLOBAL_AVOID).toContain(required);
    }
  });

  it('F: no row wording uses its own avoid list, and no nominalization chain (max one -ması/-mesi)', () => {
    for (const [name, row] of allRows) {
      for (const form of formsOf(row)) {
        for (const a of row.avoid ?? []) expect(fold(form).includes(fold(a)), `${name}: ${form} ~ ${a}`).toBe(false);
        expect((fold(form).match(NOMINAL_CHAIN) ?? []).length, `${name}: ${form}`).toBeLessThanOrEqual(1);
      }
    }
  });

  it('G/H/I: no private visual vocabulary, implementation jargon, digits, dates or amounts', () => {
    for (const [name, form] of everyPublicString) {
      expect(VISUAL.test(fold(form)), `${name}: ${form}`).toBe(false);
      expect(JARGON.test(form), `${name}: ${form}`).toBe(false);
      expect(DIGIT_OR_DATE.test(fold(form)), `${name}: ${form}`).toBe(false);
      expect(AMOUNT.test(fold(form)), `${name}: ${form}`).toBe(false);
    }
  });

  it('J: relation wording is co-development, never causal', () => {
    for (const [key, row] of Object.entries(COFFEE_TURKISH_RELATION_WORDING)) {
      for (const form of formsOf(row)) expect(CAUSAL.test(fold(form)), `${key}: ${form}`).toBe(false);
    }
    for (const [name, form] of everyPublicString) expect(CAUSAL.test(fold(form)), `${name}: ${form}`).toBe(false);
  });

  it('K: no advice wording and no biographical presupposition anywhere in the bank', () => {
    for (const [name, form] of everyPublicString) {
      expect(ADVICE.test(fold(form)), `${name}: ${form}`).toBe(false);
      expect(PRESUPPOSITION.test(fold(form)), `${name}: ${form}`).toBe(false);
    }
  });
});

describe('W4A scenarios and overlaps (L–O)', () => {
  it('L: every manifestation M2 can emit has natural wording (lead + finite possibility clause)', () => {
    const manifestations = new Set(allScenarioClusters().flat());
    expect(Object.keys(COFFEE_TURKISH_SCENARIO_WORDING).sort()).toEqual([...manifestations].sort());
    for (const m of manifestations) {
      const row = COFFEE_TURKISH_SCENARIO_WORDING[m];
      expect(row.forms.scenario?.length, m).toBeGreaterThanOrEqual(3);
      row.forms.scenario!.forEach((clause) => expect(fold(clause), `${m}: ${clause}`).toMatch(/(abilir|ebilir|abilirsin|ebilirsin)\b/));
    }
  });

  it('M: every emitted cluster has valid alternative / complementary / single metadata', () => {
    const clusters = allScenarioClusters();
    expect(Object.keys(COFFEE_TURKISH_SCENARIO_CLUSTERS).sort()).toEqual(clusters.map((c) => c.join('|')).sort());
    for (const cluster of clusters) {
      const meta = COFFEE_TURKISH_SCENARIO_CLUSTERS[cluster.join('|')];
      expect(['alternatives', 'complementary', 'single']).toContain(meta.mode);
      expect(meta.choose.min).toBeGreaterThanOrEqual(1);
      expect(meta.choose.max).toBeLessThanOrEqual(cluster.length);
      expect(meta.choose.min).toBeLessThanOrEqual(meta.choose.max);
      if (cluster.length === 1) expect(meta.mode).toBe('single');
      else expect(meta.choose.max, cluster.join('|')).toBeLessThan(3); // never a shopping list of three
    }
    expect(COFFEE_TURKISH_SCENARIO_CLUSTERS['secondary_option_gaining_weight|another_option_relevant|options_separating']).toEqual({ mode: 'alternatives', choose: { min: 1, max: 2 } });
  });

  it('N: overlap pairs are sorted, unique, distinct known classes, with distinct wording for both', () => {
    const keys = COFFEE_TURKISH_SURFACE_OVERLAPS.map((o) => o.classes.join('|'));
    expect(new Set(keys).size).toBe(keys.length);
    for (const o of COFFEE_TURKISH_SURFACE_OVERLAPS) {
      expect([...o.classes].sort()).toEqual([...o.classes]);
      expect(o.classes[0]).not.toBe(o.classes[1]);
      for (const cls of o.classes) {
        expect(COFFEE_TURKISH_CLASS_WORDING[cls], cls).toBeDefined();
        expect(o.distinct[cls]?.length, cls).toBeGreaterThanOrEqual(2);
      }
    }
  });

  it('O: COMMITMENT ↔ DURABLE is a pinned overlap; DURABLE keeps only its wholeness facet next to COMMITMENT', () => {
    const pair = COFFEE_TURKISH_SURFACE_OVERLAPS.find((o) => o.classes.join('|') === 'COMMITMENT|DURABLE')!;
    expect(pair).toBeDefined();
    pair.distinct.DURABLE.forEach((f) => expect(fold(f)).not.toMatch(/kalici|saglam/));
    expect(COFFEE_TURKISH_SURFACE_OVERLAPS.map((o) => o.classes.join('|'))).toEqual(['COMMITMENT|DURABLE', 'LEANING|SINGULAR']);
    const love = enriched('LOVE');
    expect(love.wording.overlaps.map((o) => o.classes.join('|'))).toEqual(['COMMITMENT|DURABLE', 'LEANING|SINGULAR']);
  });
});

// ---------------------------------------------------------------------------
// Enriched payload (P–W)
// ---------------------------------------------------------------------------

describe('W4A enriched writer payload (P–W)', () => {
  it('P: only the rows a plan actually uses enter the payload (RITAG)', () => {
    const p = enriched('RITAG');
    expect(Object.keys(p.wording.classes).sort()).toEqual(['FORWARD', 'MULTIPLICITY']);
    expect(Object.keys(p.wording.relations)).toEqual(['course_opens_into_alternatives']);
    expect(Object.keys(p.wording.scenarios)).toEqual(['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating']);
    expect(p.wording.scenarioClusters).toEqual([{ manifestations: ['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating'], mode: 'alternatives', choose: { min: 1, max: 2 } }]);
    expect(Object.keys(p.wording.horizons)).toEqual(['coming_period']);
    expect(p.wording.domains).toEqual({});
    expect(Object.keys(p.wording.contexts)).toEqual(['user_decision']);
    expect(p.wording.overlaps).toEqual([]);
    const { avoid: _globalAvoid, ...used } = p.wording;
    expect(JSON.stringify(used)).not.toMatch(/kısmet|maddi|ilişkin|gönül/);
  });

  it('P: token nuance rows appear only when the token is licensed (güzel / bereket only for MONEY_OBJECT)', () => {
    const money = enriched('MONEY_OBJECT');
    expect(Object.keys(money.wording.tokens).sort()).toEqual(['abundance', 'beautiful_kismet']);
    expect(Object.keys(money.wording.classes).sort()).toEqual(['FORWARD', 'GROWTH', 'MOMENTUM', 'MULTI_STREAM', 'OPPORTUNITY']);
    expect(Object.keys(money.wording.horizons).sort()).toEqual(['coming_period', 'nearer_term']);
    expect(JSON.stringify(enriched('BASAK').wording)).not.toMatch(/bereket|güzel bir kısmet/);
    // The OPPORTUNITY class row itself never claims "güzel" or "bereket".
    expect(JSON.stringify(COFFEE_TURKISH_CLASS_WORDING.OPPORTUNITY.forms)).not.toMatch(/güzel|bereket|hayırlı/);
  });

  it('Q/R/S: no W2 audit, no raw user text, and the meaning-only guard passes (sweep)', () => {
    for (const [name, meaning, intention] of SWEEP) {
      const plan = planCoffeeM2Writer(meaning).plan;
      if (plan.status !== 'planned') continue;
      const p = toCoffeeM2TurkishWriterPayload(plan);
      const raw = JSON.stringify(p);
      expect(() => assertCoffeeV3MeaningOnly(p), name).not.toThrow();
      expect(raw, name).not.toMatch(/"(omitted|diagnostics|audit|threadId|consumedFacetClasses|omittedReasons|scenarioConsumed|relationConsumed|beatGroupCounts|contractGaps|userDeclaredIntention|intentReference|meaning|tier|exception)"/);
      if (intention) expect(raw.includes(intention), name).toBe(false);
    }
  });

  it('T: an insufficient plan refuses the enriched payload', () => {
    const unal = planCoffeeM2Writer(meaningOf(c31Spec('C3F-UNAL'), CANONICAL_INTENTION_TEXT.general)).plan;
    expect(() => toCoffeeM2TurkishWriterPayload(unal)).toThrow('coffee_m2_writer_plan_insufficient');
  });

  it('U: same input → byte-identical enriched payload', () => {
    for (const id of Object.keys(CASES) as Array<keyof typeof CASES>) {
      const a = JSON.stringify(toCoffeeM2TurkishWriterPayload(JSON.parse(JSON.stringify(planOf(id)))));
      const b = JSON.stringify(toCoffeeM2TurkishWriterPayload(JSON.parse(JSON.stringify(planOf(id)))));
      expect(a, id).toBe(b);
    }
  });

  it('V: the W2 plan shape is unchanged — the enriched payload is the W2 payload plus `wording` only', () => {
    for (const id of Object.keys(CASES) as Array<keyof typeof CASES>) {
      const plan = planOf(id);
      const before = JSON.stringify(plan);
      const { wording, ...rest } = toCoffeeM2TurkishWriterPayload(plan);
      expect(rest, id).toEqual(toCoffeeM2WriterPayload(plan));
      expect(wording).toBeDefined();
      expect(JSON.stringify(plan), id).toBe(before);
    }
  });

  it('W: M2 semantics untouched — the bank never reads M2 meaning, only the W2 plan', () => {
    const src = readFileSync(resolve(process.cwd(), 'src/ai/reading/coffee-m2-turkish-surface-bank.ts'), 'utf8');
    expect(src).not.toMatch(/coffee-m2-semantic-engine|coffee-m1-interpretation|interpretCoffeeM2|planCoffeeM2Writer\(/);
    const meaning = meaningOf(CASES.LOVE[0], CASES.LOVE[1]);
    const before = JSON.stringify(meaning);
    toCoffeeM2TurkishWriterPayload(planCoffeeM2Writer(meaning).plan);
    expect(JSON.stringify(meaning)).toBe(before);
  });
});

describe('W4A dark path', () => {
  it('nothing live imports the surface bank; only the dark W4C realization policy does', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    expect(
      walk(src)
        .filter((p) => /coffee-m2-turkish-surface-bank/.test(readFileSync(p, 'utf8')))
        .map((p) => p.slice(src.length + 1).replace(/\\/g, '/')),
    ).toEqual(['ai/reading/coffee-m2-turkish-realization-policy.ts']);
  });
});
