import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { prepareCoffeeM2TurkishRealization, type CoffeeM2TurkishRealizationPayload } from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization, validateCoffeeM2ScenarioSelection } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import {
  COFFEE_M2_PROMPT_SUPPORTED_FIELDS,
  COFFEE_M2_W4E_PROMPT,
  COFFEE_M2_W4P1_PROMPT,
  COFFEE_M2_W4E_PROMPT_SHA256,
  coffeeM2WriterPromptSha256,
  coffeeM2WriterPromptUncoveredFields,
  coffeeM2WriterSystemPrompt,
  coffeeM2WriterUserMessage,
} from '../src/ai/reading/coffee-m2-writer-prompt.js';
import { c31Spec, C31_SET_IDS } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4P1 — the dark M2 writer prompt is the frozen W4E prompt plus a W4C.2
 * contract addendum, and every writer-visible realization field is documented.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const W4P1_SHA256 = '09f22bd64832b268766908ea3f35006302b3231a00f17ea993f491a6f6733433';
const W4C4_PROMPT_SHA256 = 'bc1b618baa26e2e113e995cc3c02f9e09e5e40d844e6c6b35c6880f599cc9e48';
const sha = (v: string) => createHash('sha256').update(v, 'utf8').digest('hex');
const shaJson = (v: unknown) => sha(JSON.stringify(v));
const realize = (spec: M1FixtureSpec, intention: string | null) =>
  prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan);
const ritag = () => realize(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION);
const prompt = coffeeM2WriterSystemPrompt();
const addendum = prompt.slice(COFFEE_M2_W4E_PROMPT.length);

const W = 'secondary_option_gaining_weight';
const S = 'options_separating';
const BAD: Record<string, [string, string]> = {
  S0: ['Önündeki karar konusunda biraz daha ileride önün açılıyor; konu da yaklaşan dönemde kendi akışında ilerliyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S1: ['Önündeki karar konusunda konu yaklaşan dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S2: ['Vermen gereken kararda konu önümüzdeki dönemde kendi akışında ilerliyor; önünü açan bir yol da daha ileride beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
  S3: ['Önündeki karar konusunda konu önümüzdeki dönemde kendi akışında ilerliyor; biraz daha ileride önünü açan bir yol da beliriyor.', 'Yaklaşan dönemde önünde birkaç ayrı ihtimal beliriyor; seçeneklerden biri gözünde ağırlık kazanabilir.'],
};
const BAD_CODES: Record<string, string[]> = {
  S0: ['B1:BEAT_AVOID', 'B1:GENERIC_CONTEXT_SUBJECT', 'B2:SAME_OPENER_AS_PREVIOUS', '-:CROSS_BEAT_LEXICAL_COLLISION', 'B2:SCENARIO_TOO_FEW'],
  S1: ['B1:BEAT_AVOID', 'B1:GENERIC_CONTEXT_SUBJECT', 'B2:SAME_OPENER_AS_PREVIOUS', '-:CROSS_BEAT_LEXICAL_COLLISION', 'B2:SCENARIO_TOO_FEW'],
  S2: ['B1:GENERIC_CONTEXT_SUBJECT', '-:CROSS_BEAT_LEXICAL_COLLISION', '-:CROSS_BEAT_LEXICAL_COLLISION', 'B2:SCENARIO_TOO_FEW'],
  S3: ['B1:BEAT_AVOID', 'B1:GENERIC_CONTEXT_SUBJECT', '-:CROSS_BEAT_LEXICAL_COLLISION', '-:CROSS_BEAT_LEXICAL_COLLISION', 'B2:SCENARIO_TOO_FEW'],
};
const MANUAL: [string, string] = [
  'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
  'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
];
const acceptance = (texts: string[], items: string[][]) => {
  const p = ritag();
  return [...checkCoffeeM2TurkishRealization(p, texts), ...validateCoffeeM2ScenarioSelection(p, items)].map((v) => `${v.beat ?? '-'}:${v.code}`);
};

describe('W4P1 base prompt preservation (A, I)', () => {
  it('A: the base is the frozen W4E prompt, byte for byte (CRLF), and the new prompt only appends to it', () => {
    expect(sha(COFFEE_M2_W4E_PROMPT)).toBe(COFFEE_M2_W4E_PROMPT_SHA256);
    expect(COFFEE_M2_W4E_PROMPT_SHA256).toBe('2abc1ac45c6463775982f3799a44be7b41756acde96421262e8a95d7830e0115');
    expect(prompt.startsWith(COFFEE_M2_W4E_PROMPT)).toBe(true);
    expect(addendum.length).toBeGreaterThan(0);
    expect(addendum.split('\r\n').length).toBeLessThanOrEqual(9); // W4C.2 addendum + one W4C.4 line
    expect(coffeeM2WriterPromptSha256()).toBe(sha(prompt));
    // W4P1 (W4E + W4C.2 addendum) stays byte-identical as the prefix of the current prompt.
    expect(sha(COFFEE_M2_W4P1_PROMPT)).toBe(W4P1_SHA256);
    expect(prompt.startsWith(COFFEE_M2_W4P1_PROMPT)).toBe(true);
    expect(coffeeM2WriterPromptSha256()).toBe(W4C4_PROMPT_SHA256);
  });

  it('I: the exact QA output contract is preserved', () => {
    expect(prompt).toContain('{"beats":[{"id":"B1","scenarioItems":[],"text":"..."},{"id":"B2","scenarioItems":["..."],"text":"..."}]}');
    expect(prompt).toContain('Her öğede TAM OLARAK "id", "scenarioItems" ve "text" alanları bulunur.');
    expect(prompt).toContain('beats dizisinde plandaki her parça için TAM OLARAK bir öğe olur; aynı sayıda, aynı sırada.');
  });
});

describe('W4P1 W4C.2 addendum (B–H)', () => {
  it('B: forbiddenGenericSubjects is a whole-word exclusion that cannot be dodged or paid for with meaning', () => {
    expect(addendum).toMatch(/forbiddenGenericSubjects: [^\r\n]*TEK BAŞINA bir kelime olarak geçemez/);
    expect(addendum).toMatch(/kelime yasağıdır/);
    expect(addendum).toMatch(/listedeki başka bir öğeye geçerek de dolanma/);
    expect(addendum).toMatch(/lisanslı bir anlamı düşürme/);
  });

  it('C/D: contextWording overrides wording.contexts for its binding only, with explicit precedence', () => {
    expect(addendum).toMatch(/contextWording: [^\r\n]*wording\.contexts yerine YALNIZCA contextWording/);
    expect(addendum).toContain('Öncelik: realization.beats[i].contextWording > wording.contexts.');
    expect(addendum).toContain('contextWording olmayan parçalarda wording.contexts her zamanki gibi geçerlidir.');
    expect(addendum).toMatch(/başka bir bağlam ifadesi uydurma/);
    expect(addendum).toMatch(/mention "introduce" ise bağlamı bu ifadelerden biriyle mutlaka an/);
  });

  it('E/F: lexicalCollisionFamilies and not_in_both are explicit; the provider never stems', () => {
    expect(addendum).toMatch(/realization\.crossBeat\.lexicalCollisionFamilies: kapalı bir kelime tekrarı yasağıdır/);
    expect(addendum).toMatch(/rule "not_in_both" ise [^\r\n]*EN FAZLA BİRİNİN metninde geçebilir; ikisinde birden geçemez/);
    expect(addendum).toMatch(/Kök çıkarma; yalnızca verilen forms listesine bak/);
  });

  it('G/H: scenario choose stays hard (exactly two when 2/2) and incompatible pairs stay hard', () => {
    expect(prompt).toContain('wording.scenarioClusters: her senaryo kümesinde "choose" sınırına uy.');
    expect(addendum).toMatch(/wording\.scenarioClusters\[\]\.choose kesindir/);
    expect(addendum).toMatch(/min ve max 2 ise TAM OLARAK iki kimlik seç/);
    expect(addendum).toMatch(/scenarioIncompatiblePairs içindeki çiftler yine kesin yasaktır/);
    expect(prompt).toContain('scenarioIncompatiblePairs: bu çiftlerdeki iki senaryo örneğini AYNI ANDA seçme.');
    expect(addendum).toMatch(/yeni bir anlam izni vermez/);
  });

  it('the precedence ladder is stated once, top to bottom', () => {
    expect(addendum).toContain('Öncelik sırası: (1) planın anlamı ve parça yapısı (groups, relation, scenario, qualifiers); (2) parçaya özgü realization kısıtları; (3) varsa parçaya özgü contextWording; (4) crossBeat kısıtları; (5) wording seçenekleri; (6) doğal Türkçe.');
  });
});

describe('W4P1 no fixture, example or answer text (J–M)', () => {
  it('J/K: no fixture IDs', () => {
    expect(prompt).not.toMatch(/RITAG|GAZETA|BASAK|HALIL|UNAL|C3F|MONEY_OBJECT|STALLED|WALL_LOOP/i);
  });

  it('L/M: no manual premium sentence and no observed provider output (whole or in clauses)', () => {
    for (const text of [...MANUAL, ...Object.values(BAD).flat()]) {
      expect(prompt.includes(text), text).toBe(false);
      for (const clause of text.split(/[;,.]/).map((c) => c.trim()).filter((c) => c.split(' ').length >= 4)) {
        expect(prompt.includes(clause), clause).toBe(false);
      }
    }
    // The addendum carries no Turkish lexical example of the restricted words.
    const words = addendum.toLocaleLowerCase('tr-TR').match(/[a-zçğıöşüâîû]+/g) ?? [];
    for (const w of ['konu', 'işler', 'gidişat', 'önündeki', 'önün', 'beliriyor', 'vermen', 'meselende']) expect(words, w).not.toContain(w);
  });
});

describe('W4P1 field manifest guard (N–O)', () => {
  const allPayloads = (): Array<[string, CoffeeM2TurkishRealizationPayload]> => {
    const specs: Array<[string, M1FixtureSpec]> = [
      ...C31_SET_IDS.flatMap((id) => [[id, c31Spec(id)], [`${id}+clear`, c31Spec(id, { clearAreas: true })]] as Array<[string, M1FixtureSpec]>),
      ...Object.entries(M1_QA_CUPS).map(([id, cup]) => [id, cup.spec] as [string, M1FixtureSpec]),
    ];
    const intentions = [null, DECISION, 'İlişkim hakkında merak ediyorum.', 'Bir yerden dönüş bekliyorum.', ...Object.values(CANONICAL_INTENTION_TEXT)];
    const out: Array<[string, CoffeeM2TurkishRealizationPayload]> = [];
    for (const [id, spec] of specs) {
      for (const intention of intentions) {
        const plan = planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan;
        if (plan.status === 'planned') out.push([`${id}|${intention}`, prepareCoffeeM2TurkishRealization(plan)]);
      }
    }
    return out;
  };

  it('N: every writer-visible realization field of the current RITAG payload (and the whole fixture sweep) is covered and documented', () => {
    const p = ritag();
    const beatKeys = [...new Set(p.realization.beats.flatMap((b) => Object.keys(b)))].sort();
    expect(beatKeys).toEqual([...COFFEE_M2_PROMPT_SUPPORTED_FIELDS.beat].sort());
    expect(Object.keys(p.realization.crossBeat).sort()).toEqual([...COFFEE_M2_PROMPT_SUPPORTED_FIELDS.crossBeat].sort());
    expect(coffeeM2WriterPromptUncoveredFields(p)).toEqual([]);
    for (const [name, payload] of allPayloads()) expect(coffeeM2WriterPromptUncoveredFields(payload), name).toEqual([]);
    // Every manifest field is actually named in the prompt text.
    for (const field of new Set(Object.values(COFFEE_M2_PROMPT_SUPPORTED_FIELDS).flat())) {
      expect(prompt.includes(field), field).toBe(true);
    }
  });

  it('O: a new, undocumented writer-facing field fails the guard', () => {
    const p = ritag() as CoffeeM2TurkishRealizationPayload & Record<string, unknown>;
    const beatExtra = JSON.parse(JSON.stringify(p));
    beatExtra.realization.beats[0].preferredRhythm = 'short';
    expect(coffeeM2WriterPromptUncoveredFields(beatExtra)).toEqual(['beat.preferredRhythm']);
    const crossExtra = JSON.parse(JSON.stringify(p));
    crossExtra.realization.crossBeat.maxSentenceLength = 20;
    expect(coffeeM2WriterPromptUncoveredFields(crossExtra)).toEqual(['crossBeat.maxSentenceLength']);
    const familyExtra = JSON.parse(JSON.stringify(p));
    familyExtra.realization.crossBeat.lexicalCollisionFamilies[0].weight = 2;
    expect(coffeeM2WriterPromptUncoveredFields(familyExtra)).toEqual(['lexicalCollisionFamily.weight']);
    const clusterExtra = JSON.parse(JSON.stringify(p));
    clusterExtra.wording.scenarioClusters[0].preferred = W;
    expect(coffeeM2WriterPromptUncoveredFields(clusterExtra)).toEqual(['scenarioCluster.preferred']);
  });
});

describe('W4P1 payloads and acceptance unchanged (P–T)', () => {
  const PINNED = {
    // W4C.3 changed only this payload's scenarioIncompatiblePairs value (was d5867f43…).
    RITAG_V3G1: [c31Spec('C3F-RITAG', { clearAreas: true }), DECISION, '44728784bb4bc6777dd34e6243eaf90f3beea6d8d4ca1d81c74a3d09c891798a'],
    GAZETA_V3G1: [c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION, 'ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3'],
    RITAG_OLD: [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
    BASAK: [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
    MONEY_OBJECT: [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
    CAREER: [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
    STALLED: [{ marks: [{ id: 'T1', label: null, band: 'middle', form: { continuity: 'broken' }, bandCoverage: ['middle', 'lower_base'] }, { id: 'C1', label: null, kind: 'clear_area', band: 'middle' }] }, null, '11f18ff287e32e54d5db8260968720977cabb42c454bf04cfae6f89c6b2c06b1'],
    WALL_LOOP_PHASE: [{ marks: [{ id: 'L1', label: null, band: 'middle', topology: 'closed_loop', form: { continuity: 'continuous', course: 'bending', openness: 'closed' } }] }, null, 'cf45b1efb6b0510456337d73f4bc97c3223e8d15b8fb782cba89b24978b7b085'],
  } as const;
  for (const [id, [spec, intention, hash]] of Object.entries(PINNED)) {
    it(`P/Q/R: ${id} realization payload is byte-identical`, () => {
      expect(shaJson(realize(spec as M1FixtureSpec, intention))).toBe(hash);
    });
  }

  for (const [id, texts] of Object.entries(BAD)) {
    it(`S: historical ${id} is still rejected exactly as before`, () => {
      expect(acceptance(texts, [[], [W]])).toEqual(BAD_CODES[id]);
    });
  }

  it('T: the manual premium reading is still accepted', () => {
    expect(acceptance(MANUAL, [[], [W, S]])).toEqual([]);
  });
});

describe('W4P1 provider user message and dark path (U–Z)', () => {
  it('U/V/W: the user message is the writer-safe payload only', () => {
    const msg = coffeeM2WriterUserMessage(ritag());
    expect(msg.startsWith('FAL PLANI:\n{')).toBe(true);
    expect(JSON.parse(msg.slice('FAL PLANI:\n'.length))).toEqual(JSON.parse(JSON.stringify(ritag())));
    expect(msg.includes(DECISION)).toBe(false);
    expect(msg.includes(DECISION.slice(0, 12))).toBe(false);
    expect(msg).not.toMatch(/"(omitted|diagnostics|audit|threadId|consumedFacetClasses|omittedReasons|scenarioConsumed|relationConsumed|beatGroupCounts|contractGaps|capacity)"/);
    expect(msg).not.toMatch(/"(userDeclaredIntention|intentReference|declaredContext|band|bandSpan|bandCoverage|topology|form|rimClock|handleClock|sightingIds|candidates|identityGroup|marks?|cupMarks|saucerMarks|evidence|label|description|resemblance|views|surface)"/);
    expect(msg).not.toMatch(/RITAG|GAZETA|C3F|fixture/i);
  });

  it('X: deterministic prompt and user message', () => {
    expect(coffeeM2WriterSystemPrompt()).toBe(coffeeM2WriterSystemPrompt());
    expect(coffeeM2WriterUserMessage(ritag())).toBe(coffeeM2WriterUserMessage(ritag()));
  });

  it('Y/Z: nothing in src imports the dark prompt, and it makes no provider call', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    // LIS2 — the dark V3 live bridge is the one sanctioned integration importer of the frozen stack.
    expect(walk(src).filter((p) => /coffee-m2-writer-prompt/.test(readFileSync(p, 'utf8'))).map((p) => p.slice(src.length + 1).replace(/\\/g, '/'))).toEqual(['ai/reading/coffee-v3-live-pipeline.ts']);
    const module = readFileSync(resolve(src, 'ai/reading/coffee-m2-writer-prompt.ts'), 'utf8');
    expect(module).not.toMatch(/openai|transport|fetch\(|complete\(|process\.env/i);
  });
});
