import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeV3MarkMap } from '../src/ai/reading/coffee-m1-interpretation.js';
import { interpretCoffeeM2, type CoffeeM2Thread } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import { prepareCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import type { CoffeeV3Form } from '../src/ai/reading/types.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec, type M1MarkSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * M2.1 — structural decision parity: opening_clarity → decision_clarity, the
 * analogue of M1 access_opening → decision_clarity. Trusted declared context
 * only; never evidence. steady_course / stop_start_course stay unbound.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const AWAITED = 'Bir yerden dönüş bekliyorum.';
const m2 = (spec: M1FixtureSpec, intention: string | null) =>
  interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null);
const threads = (spec: M1FixtureSpec, intention: string | null) => m2(spec, intention).meaning.threads;
const only = (spec: M1FixtureSpec, intention: string | null): CoffeeM2Thread => {
  const t = threads(spec, intention);
  expect(t).toHaveLength(1);
  return t[0];
};
const residue = (id: string, form: Partial<CoffeeV3Form>, extra: Partial<M1MarkSpec> = {}): M1MarkSpec => ({ id, label: null, band: 'middle', form, ...extra });
const clear = (id: string): M1MarkSpec => ({ id, label: null, kind: 'clear_area', band: 'middle' });

const OPENING = { marks: [clear('C1')] };
const STEADY = { marks: [residue('T1', { continuity: 'continuous', course: 'straight' })] };
const STOP_START = { marks: [residue('T1', { continuity: 'broken' }, { bandCoverage: ['middle', 'lower_base'] })] };
const BRANCHING = { marks: [residue('W1', { course: 'branching' })] };
const TURN = { marks: [residue('L1', { continuity: 'continuous', course: 'bending' })] };

const RITAG_V3G1 = () => c31Spec('C3F-RITAG', { clearAreas: true });
const realize = (spec: M1FixtureSpec, intention: string | null) => prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(m2(spec, intention).meaning).plan);
const sha = (value: unknown) => createHash('sha256').update(JSON.stringify(value)).digest('hex');

describe('M2.1 decision binding is closed and compatibility-based (A–J)', () => {
  it('A/B/C: decision + opening_clarity → user_decision, decision_clarity, option_identity / correct_option forbidden', () => {
    const t = only(OPENING, DECISION);
    expect(t.developments).toEqual(['opening_clarity']);
    expect(t.contextBindings).toEqual(['user_decision']);
    expect(t.conjecture).toContain('decision_clarity');
    expect(t.contextForbidden).toEqual(['option_identity', 'correct_option']);
  });

  it('D: decision + steady_course alone → no decision binding', () => {
    const t = only(STEADY, DECISION);
    expect(t.developments).toEqual(['steady_course']);
    expect(t.contextBindings).toEqual([]);
    expect(t.conjecture.filter((c) => c.startsWith('decision_'))).toEqual([]);
  });

  it('E: decision + stop_start_course alone → no decision binding', () => {
    const t = only(STOP_START, DECISION);
    expect(t.developments).toEqual(['stop_start_course']);
    expect(t.contextBindings).toEqual([]);
    expect(t.conjecture.filter((c) => c.startsWith('decision_'))).toEqual([]);
  });

  it('F: decision + course_turn still → decision_direction', () => {
    const t = only(TURN, DECISION);
    expect(t.developments).toEqual(['course_turn']);
    expect(t.contextBindings).toEqual(['user_decision']);
    expect(t.conjecture).toContain('decision_direction');
    expect(t.conjecture).not.toContain('decision_clarity');
  });

  it('G: decision + possibilities_branch still → decision_options', () => {
    const t = only(BRANCHING, DECISION);
    expect(t.contextBindings).toEqual(['user_decision']);
    expect(t.conjecture).toContain('decision_options');
    expect(t.conjecture).not.toContain('decision_clarity');
  });

  it('H: no declaration (null or a general intention) + opening → unbound', () => {
    for (const intention of [null, CANONICAL_INTENTION_TEXT.general]) {
      const t = only(OPENING, intention);
      expect(t.contextBindings, String(intention)).toEqual([]);
      expect(t.conjecture, String(intention)).not.toContain('decision_clarity');
    }
  });

  it('I: person-of-interest + opening → never user_decision', () => {
    expect(classifyCoffeeIntention(CANONICAL_INTENTION_TEXT.person_of_interest).declaredFacts).not.toContain('decision_exists');
    const t = only(OPENING, CANONICAL_INTENTION_TEXT.person_of_interest);
    expect(t.contextBindings).not.toContain('user_decision');
    expect(t.conjecture).not.toContain('decision_clarity');
  });

  it('J: awaited topic + opening → never awaited_topic (nor user_decision)', () => {
    expect(classifyCoffeeIntention(AWAITED).declaredFacts).toContain('awaiting_response');
    const t = only(OPENING, AWAITED);
    expect(t.contextBindings).toEqual([]);
  });
});

describe('M2.1 M1 parity (V)', () => {
  it('V: M1 access_opening and M2 opening_clarity reach the same decision_clarity / user_decision', () => {
    const m1 = interpretCoffeeV3MarkMap(m1Map({ marks: [{ id: 'K1', label: 'a key' }] }), classifyCoffeeIntention(DECISION)).meaning;
    expect(m1.threads).toHaveLength(1);
    expect(m1.threads[0].developments).toEqual(['access_opening']);
    expect(m1.threads[0].contextBindings).toEqual(['user_decision']);
    expect(m1.threads[0].conjecture).toContain('decision_clarity');
    const structural = only(OPENING, DECISION);
    expect(structural.contextBindings).toEqual(m1.threads[0].contextBindings);
    expect(structural.contextForbidden).toEqual(m1.threads[0].contextForbidden);
    expect(structural.conjecture).toContain('decision_clarity');
  });
});

describe('M2.1 RITAG V3G1 (K–Q)', () => {
  const result = () => m2(RITAG_V3G1(), DECISION);

  it('K/L/M: T1 stays opening_moves_forward and now carries user_decision; still two threads', () => {
    const { threads: [t1, t2], diagnostics } = result().meaning;
    expect(result().meaning.threads).toHaveLength(2);
    expect(t1).toMatchObject({ developments: ['opening_clarity', 'steady_course'], combination: 'opening_moves_forward', contextBindings: ['user_decision'], depth: 'deep' });
    expect(t1.modifiers).toContain('room_within');
    expect(t1.conjecture).toEqual(['opening_clarity', 'steady_course', 'opening_moves_forward', 'decision_clarity']);
    expect(t1.contextForbidden).toEqual(['option_identity', 'correct_option']);
    expect(t1.facets.map((f) => f.cls)).toEqual(['OPENING', 'FORWARD', 'HORIZON', 'CONTEXT_user_decision', 'RELATION_opening_moves_forward']);
    expect(t2).toMatchObject({ developments: ['possibilities_branch'], contextBindings: ['user_decision'] });
    expect(result().meaning.threads.some((t) => t.combination === 'course_opens_into_alternatives')).toBe(false);
    expect(diagnostics).toMatchObject({ capacity: 'rich', groundedDevelopmentCount: 3, maxDepth: 'deep' });
  });

  it('N/O: context is not evidence — the same grounded families and physical evidence as with no declaration', () => {
    const withDecision = result();
    const without = m2(RITAG_V3G1(), CANONICAL_INTENTION_TEXT.general);
    expect(withDecision.meaning.diagnostics.groundedDevelopmentCount).toBe(without.meaning.diagnostics.groundedDevelopmentCount);
    expect(withDecision.meaning.diagnostics.capacity).toBe(without.meaning.diagnostics.capacity);
    const physical = (r: typeof withDecision) => r.meaning.threads.map((t) => ({ developments: t.developments, combination: t.combination, modifiers: t.modifiers, evidence: (t as Record<string, unknown>).evidence ?? null }));
    expect(physical(withDecision)).toEqual(physical(without));
    expect(withDecision.audit).toEqual(without.audit);
  });

  it('P/Q: the frozen W2 plan introduces the decision on B1; B2 keeps it implied; no new scenario', () => {
    const p = realize(RITAG_V3G1(), DECISION);
    expect(p.beats).toHaveLength(2);
    const [b1, b2] = p.beats;
    expect(b1.relation?.combination).toBe('opening_moves_forward');
    expect(b1.groups.map((g) => `${g.cls}:${g.horizon}`)).toEqual(['OPENING:further_out', 'FORWARD:coming_period']);
    expect(b1.qualifiers.context).toEqual([{ binding: 'user_decision', mention: 'introduce' }]);
    expect(b1.scenario).toBeNull();
    expect(b2.qualifiers.context).toEqual([{ binding: 'user_decision', mention: 'implied' }]);
    expect(b2.scenario?.manifestations).toEqual(['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating']);
    expect(Object.keys(p.wording.scenarios)).toEqual(['secondary_option_gaining_weight', 'another_option_relevant', 'options_separating']);
    expect(Object.keys(p.wording.contexts)).toEqual(['user_decision']);
  });
});

describe('M2.1 frozen payload pins (R–U)', () => {
  // sha256 of the full W4C.1 realization payload at 829da164 (before M2.1).
  const PINNED = {
    GAZETA_V3G1: [c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION, 'ec28aae74989481586b6bf8512391f5b364ab14448592db1615375ec0038e4d3'],
    RITAG_OLD: [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
    BASAK: [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
    MONEY_OBJECT: [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
    CAREER: [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
    STALLED_NULL: [{ marks: [residue('T1', { continuity: 'broken' }, { bandCoverage: ['middle', 'lower_base'] }), clear('C1')] }, null, '11f18ff287e32e54d5db8260968720977cabb42c454bf04cfae6f89c6b2c06b1'],
    WALL_LOOP_NULL: [{ marks: [residue('L1', { continuity: 'continuous', course: 'bending', openness: 'closed' }, { topology: 'closed_loop' })] }, null, 'cf45b1efb6b0510456337d73f4bc97c3223e8d15b8fb782cba89b24978b7b085'],
  } as const;
  for (const [id, [spec, intention, hash]] of Object.entries(PINNED)) {
    it(`${id}: provider payload is byte-identical`, () => {
      expect(sha(realize(spec as M1FixtureSpec, intention))).toBe(hash);
    });
  }

  it('R: GAZETA gains decision_clarity only inside M2 (internal), not in its public payload', () => {
    const [t] = m2(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION).meaning.threads;
    expect(t.contextBindings).toEqual(['user_decision']); // one binding, not duplicated
    expect(t.conjecture).toEqual(['opening_clarity', 'possibilities_branch', 'possibilities_become_visible', 'decision_clarity', 'decision_options']);
  });
});

describe('M2.1 manual RITAG re-proof (zero provider)', () => {
  /** Every phrase: a context modifier, a horizon, or a W4A.1 bank form (inflected) of its own beat. */
  const MANUAL = [
    // Updated by W4A.2 / W4C.2 (no generic carrier, no shared "ön-", two scenario items).
    'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
    'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
  ];
  const fold = (s: string) => s.toLocaleLowerCase('tr-TR');

  it('passes the frozen W4C.1 checker and carries no inflated decision claim', () => {
    expect(checkCoffeeM2TurkishRealization(realize(RITAG_V3G1(), DECISION), MANUAL)).toEqual([]);
    for (const t of MANUAL) {
      expect(fold(t), t).not.toMatch(/doğru (karar|seçenek)|kesinleş|kararın ilerl|önünü açacak|yaklaşıyorsun/);
    }
    expect(fold(MANUAL[0])).toMatch(/^vermen gereken kararda/); // decision introduced on B1
    // separate horizons, no forced simultaneity ("-ken" on a finite stem; "gereken" is a participle)
    expect(fold(MANUAL[0])).not.toMatch(/(ır|ir|ur|ür|ar|er|yor)ken(\s|[.,;]|$)/);
  });
});

describe('M2.1 guards (W–Z)', () => {
  it('W/X: meaning-only guard passes and no raw user text reaches the writer payload', () => {
    const p = realize(RITAG_V3G1(), DECISION);
    expect(() => assertCoffeeV3MeaningOnly(p)).not.toThrow();
    const raw = JSON.stringify(p);
    expect(raw.includes(DECISION)).toBe(false);
    expect(raw).not.toMatch(/"(omitted|diagnostics|audit|threadId|consumedFacetClasses|omittedReasons|contextGaps|contractGaps|declaredContext|userDeclaredIntention|intentReference|evidence)"/);
    // decision_clarity is consumed by W2 as the context qualifier; it never travels as a raw token.
    expect(raw).not.toContain('decision_clarity');
  });

  it('Y: nothing live imports the M2 engine change path', () => {
    const src = resolve(process.cwd(), 'src');
    const walk = (dir: string): string[] =>
      readdirSync(dir).flatMap((name) => {
        const path = join(dir, name);
        return statSync(path).isDirectory() ? walk(path) : path.endsWith('.ts') ? [path] : [];
      });
    const importers = walk(src)
      .filter((p) => /coffee-m2-semantic-engine/.test(readFileSync(p, 'utf8')))
      .map((p) => p.slice(src.length + 1).replace(/\\/g, '/'))
      .sort();
    // LIS2 — the dark V3 live bridge is the one sanctioned integration importer of the frozen stack.
    expect(importers.every((p) => p.startsWith('ai/reading/coffee-m2-') || p === 'ai/reading/coffee-v3-live-pipeline.ts')).toBe(true);
  });

  it('Z: same input → byte-identical M2 meaning and payload', () => {
    expect(JSON.stringify(m2(RITAG_V3G1(), DECISION))).toBe(JSON.stringify(m2(RITAG_V3G1(), DECISION)));
    expect(sha(realize(RITAG_V3G1(), DECISION))).toBe(sha(realize(RITAG_V3G1(), DECISION)));
  });
});
