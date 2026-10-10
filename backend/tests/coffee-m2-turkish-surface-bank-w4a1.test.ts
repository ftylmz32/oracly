import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { interpretCoffeeM2 } from '../src/ai/reading/coffee-m2-semantic-engine.js';
import { planCoffeeM2Writer } from '../src/ai/reading/coffee-m2-writer-beat-plan.js';
import {
  COFFEE_TURKISH_CLASS_WORDING,
  COFFEE_TURKISH_GLOBAL_AVOID,
  COFFEE_TURKISH_HORIZON_WORDING,
  COFFEE_TURKISH_RELATION_WORDING,
} from '../src/ai/reading/coffee-m2-turkish-surface-bank.js';
import { prepareCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-policy.js';
import { checkCoffeeM2TurkishRealization } from '../src/ai/reading/coffee-m2-turkish-realization-check.js';
import { assertCoffeeV3MeaningOnly } from '../src/ai/reading/coffee-v3-mark-map.js';
import { c31Spec } from './fixtures/coffee-c31-fixtures.js';
import { CANONICAL_INTENTION_TEXT, M1_QA_CUPS, m1Map, type M1FixtureSpec } from './fixtures/coffee-m1-fixtures.js';

/**
 * W4A.1 — surgical lexical repair of the rows V3G1 made reachable (PHASE,
 * stalled_course_finds_room, opening_moves_forward, one form of
 * possibilities_become_visible). Language data only: M2 / W2 / W4C.1 frozen.
 */

const DECISION = 'Bir karar vermem gerekiyor, önümde birkaç seçenek var.';
const fold = (s: string) =>
  s.normalize('NFC').toLocaleLowerCase('tr-TR')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const CAUSAL = /\b(cunku|bu yuzden|o yuzden|bu sayede|sayesinde|boylece|dolayisiyla|sonucunda|bu nedenle|yuzunden)\b|sagla(r|yabilir|yacak|di)|neden ol|yol ac(ar|abilir|acak)\b|getir(ir|ebilir|ecek)\b|dogur(ur|abilir|acak)\b|\b\w+(dikca|dikce|dukca|dukce|tikca|tikce)\b/;
const HORIZON_WORD = /\b(yakin|yakinda|ileride|ileriki|ilerleyen|donem\w*|zaman\w*|gunler\w*|gecmeden|sure\w*|simdi|bugun|yarin)\b/;
// "-ken" (while) on a finite stem (açılırken / ilerlerken / ilerliyorken), never the participle "gereken".
const SIMULTANEITY = /\w+(ir|ur|ar|er|yor)ken\b|\b(ayni anda|eszamanli|tam o sirada|o sirada|birlikte)\b/;
const PHYSICAL = /\b(alan\w*|bosluk\w*|aciklik\w*|acik bir|yer bul\w*|kendine yer|acilan yer\w*)\b/;
const RELIEF = /\b(nihayet|sonunda|ragmen|rahatla\w*|ferahla\w*|cozul\w*|cozum\w*|kurtul\w*|engel\w*|sorun\w*|sikinti\w*|duzel\w*|toparla\w*|basari\w*)\b/;
const UNEVEN_MARK = /bir ilerleyip bir dur|tek solukta|ara ara|kesik kesik|araliklarla|bazen hizlanip/;
const OPENING_MARK = /\b(onun|onunu acan|bir yol|yolun)\b.*\b(acil|belir)|acil(iyor|an)/;
const FORWARD_MARK = /yoluna devam|ilerl|yerinde saymi|yolunda yuru/;

const PHASE = COFFEE_TURKISH_CLASS_WORDING.PHASE;
const phaseForms = PHASE.forms.modifier!;
const stalled = COFFEE_TURKISH_RELATION_WORDING.stalled_course_finds_room.forms.relational!;
const movesForward = COFFEE_TURKISH_RELATION_WORDING.opening_moves_forward.forms.relational!;
const possibilities = COFFEE_TURKISH_RELATION_WORDING.possibilities_become_visible.forms.relational!;

const realizeSpec = (spec: M1FixtureSpec, intention: string | null) =>
  prepareCoffeeM2TurkishRealization(planCoffeeM2Writer(interpretCoffeeM2(m1Map(spec), intention ? classifyCoffeeIntention(intention) : null).meaning).plan);

/** The four V3G2 shapes, rebuilt from the frozen M2 / W2 path. */
const V3G2 = {
  RITAG_V3G1: () => realizeSpec(c31Spec('C3F-RITAG', { clearAreas: true }), DECISION),
  GAZETA_V3G1: () => realizeSpec(c31Spec('C3F-GAZETA', { clearAreas: true }), DECISION),
  STALLED_ROOM: () => realizeSpec({ marks: [
    { id: 'T1', label: null, band: 'middle', form: { continuity: 'broken' }, bandCoverage: ['middle', 'lower_base'] },
    { id: 'C1', label: null, kind: 'clear_area', band: 'middle' },
  ] } as M1FixtureSpec, null),
  WALL_LOOP_PHASE: () => realizeSpec({ marks: [
    { id: 'L1', label: null, band: 'middle', topology: 'closed_loop', form: { continuity: 'continuous', course: 'bending', openness: 'closed' } },
  ] } as M1FixtureSpec, null),
};

/**
 * Manual zero-provider readings (W4A.1 re-proof). Every phrase is a bank form,
 * an inflection of one, or a horizon / context qualifier of the beat it sits in.
 */
const MANUAL = {
  GAZETA_V3G1: [
    'Önündeki karar konusunda yaklaşan dönemde önün açılırken birden fazla yol da beliriyor.',
    'Bu seçeneklerden biri gözünde ağırlık kazanabilir, aralarındaki fark da daha net görünebilir.',
  ],
  STALLED_ROOM: ['Önümüzdeki dönemde konu aralıklarla ilerliyor; önün de açılıyor.'],
  WALL_LOOP_PHASE: ['Önümüzdeki dönemde yönün tek bir aşamada değişiyor.'],
  RITAG_V3G1: [
    // Updated by W4A.2 / W4C.2: the decision-framed relation no longer rides on a generic "konu".
    'Vermen gereken kararda yolun yaklaşan dönemde yerinde saymıyor; biraz daha ileride açılıyor da.',
    'Önündeki günlerde birkaç seçenek birden ortaya çıkıyor; aralarındaki fark daha net görünebilir, biri de gözünde ağır basmaya başlayabilir.',
  ],
} as const;

/** The exact failing V3G2 provider sentences (scratchpad v3g2/). */
const V3G2_BAD = {
  STALLED_ROOM: 'Önümüzdeki dönemde bir ilerleyip bir duran konu kendine açık bir alan buluyor.',
  WALL_LOOP_PHASE: 'Önümüzdeki dönemde yönün tek bir dönem içinde değişiyor.',
  RITAG_B1: 'Önün biraz daha ileride açılırken konu da önümüzdeki dönemde kendi akışında ilerliyor.',
};

describe('W4A.1 PHASE (A–F)', () => {
  it('A/B/C: PHASE wording uses no dönem, no zaman, no globally banned süreç', () => {
    for (const f of phaseForms) {
      expect(fold(f), f).not.toMatch(/donem/);
      expect(fold(f), f).not.toMatch(/zaman/);
      expect(fold(f), f).not.toMatch(/surec/);
      for (const banned of COFFEE_TURKISH_GLOBAL_AVOID) expect(fold(f).includes(fold(banned)), `${f} ~ ${banned}`).toBe(false);
    }
    // Two honest forms; the shortfall is documented, not padded.
    expect(phaseForms).toEqual(['tek bir aşamada', 'tek bir aşamanın içinde']);
    expect(PHASE.exception).toBeTruthy();
    for (const old of ['aynı dönemin içinde', 'tek bir dönem içinde', 'aynı zaman diliminde']) expect(phaseForms).not.toContain(old);
  });

  // D/E/F: the real W2 shape is CHANGE + PHASE with an ordinary horizon qualifier.
  for (const [label, horizon] of [['D', 'nearer_term'], ['E', 'coming_period'], ['F', 'further_out']] as const) {
    it(`${label}: PHASE composes with every ${horizon} form without repetition or time-inside-time`, () => {
      for (const h of COFFEE_TURKISH_HORIZON_WORDING[horizon].forms.modifier!) {
        for (const p of phaseForms) {
          const sentence = fold(`${h} yönün ${p} değişiyor`);
          const timeNouns = sentence.match(/\b(donem|zaman|sure|asama|evre)\w*/g) ?? [];
          const stems = timeNouns.map((w) => w.slice(0, 4));
          expect(new Set(stems).size, sentence).toBe(stems.length); // no lexical repetition
          expect(stems.filter((s) => s === 'asam'), sentence).toHaveLength(1); // the scope stays a stage, not a time
          expect(sentence, sentence).not.toMatch(/\d|\b(gun|hafta|ay|yil)\b/); // no exact timing
          for (const a of PHASE.avoid ?? []) expect(sentence.includes(fold(a)), `${sentence} ~ ${a}`).toBe(false);
        }
      }
    });
  }

  it('the frozen WALL_LOOP_PHASE payload carries PHASE next to a coming_period horizon, and the old collision is gone', () => {
    const p = V3G2.WALL_LOOP_PHASE();
    expect(p.beats.map((b) => b.groups.map((g) => `${g.cls}:${g.horizon}`))).toEqual([['CHANGE:coming_period', 'PHASE:null']]);
    expect(p.wording.classes.PHASE.modifier).toEqual(phaseForms);
    expect(JSON.stringify(p.wording.classes.PHASE.modifier)).not.toMatch(/dönem|zaman/);
    expect(fold(V3G2_BAD.WALL_LOOP_PHASE).match(/donem/g)).toHaveLength(2); // the defect being fixed
  });
});

describe('W4A.1 stalled_course_finds_room (G–J)', () => {
  it('G: no physical clear-area wording (alan / boşluk / açıklık / kendine yer)', () => {
    for (const f of stalled) expect(fold(f), f).not.toMatch(PHYSICAL);
    expect(fold(V3G2_BAD.STALLED_ROOM)).toMatch(PHYSICAL); // the defect being fixed
    for (const a of ['açık bir alan', 'alan bul', 'boşluk', 'açıklık', 'kendine yer']) {
      expect(COFFEE_TURKISH_RELATION_WORDING.stalled_course_finds_room.avoid).toContain(a);
    }
  });

  it('H: every form expresses both UNEVEN and OPENING', () => {
    expect(stalled.length).toBeGreaterThanOrEqual(4);
    for (const f of stalled) {
      expect(fold(f), `${f}: UNEVEN`).toMatch(UNEVEN_MARK);
      expect(fold(f), `${f}: OPENING`).toMatch(OPENING_MARK);
    }
  });

  it('I/J: no causal connective, no relief / solution / problem language', () => {
    for (const f of stalled) {
      expect(fold(f), f).not.toMatch(CAUSAL);
      expect(fold(f), f).not.toMatch(RELIEF);
    }
  });
});

describe('W4A.1 opening_moves_forward (K–M)', () => {
  it('K: no horizon word inside the relation phrase (horizons belong to qualifiers)', () => {
    for (const f of movesForward) expect(fold(f), f).not.toMatch(HORIZON_WORD);
  });

  it('L: no hard-coded simultaneity (-ken, aynı anda, eşzamanlı, o sırada, birlikte)', () => {
    for (const f of movesForward) expect(fold(f), f).not.toMatch(SIMULTANEITY);
    expect(fold(V3G2_BAD.RITAG_B1)).toMatch(SIMULTANEITY); // the defect being fixed
  });

  it('M: co-development, not causation — both components, two finite clauses, no causal link', () => {
    expect(movesForward.length).toBeGreaterThanOrEqual(4);
    for (const f of movesForward) {
      expect(fold(f), f).not.toMatch(CAUSAL);
      expect(fold(f), `${f}: OPENING`).toMatch(OPENING_MARK);
      expect(fold(f), `${f}: FORWARD`).toMatch(FORWARD_MARK);
      expect(f.split(';'), f).toHaveLength(2);
      expect(fold(f), f).not.toMatch(PHYSICAL);
    }
  });

  it('no decision binding is smuggled into the relation wording (it comes only from the M2.1 context qualifier)', () => {
    for (const f of movesForward) expect(fold(f), f).not.toMatch(/karar|secenek/);
    const p = V3G2.RITAG_V3G1();
    expect(p.beats[0].relation?.combination).toBe('opening_moves_forward');
    expect(p.beats[0].qualifiers.context).toEqual([{ binding: 'user_decision', mention: 'introduce' }]);
    expect(p.beats[0].groups.map((g) => `${g.cls}:${g.horizon}`)).toEqual(['OPENING:further_out', 'FORWARD:coming_period']);
  });
});

describe('W4A.1 GAZETA / possibilities_become_visible / OPENING (N–O)', () => {
  it('N: the GAZETA_V3G1 payload is valid and keeps its provider-passing shape', () => {
    const p = V3G2.GAZETA_V3G1();
    expect(() => assertCoffeeV3MeaningOnly(p)).not.toThrow();
    expect(Object.keys(p.wording.relations)).toEqual(['possibilities_become_visible']);
    expect(p.beats.map((b) => b.purpose)).toEqual(['relation', 'scenario']);
    expect(p.wording.relations.possibilities_become_visible.relational).toContain('önün açılırken birden fazla yol da beliriyor');
  });

  it('O: possibilities_become_visible changed only where justified (one physical-echo locative replaced)', () => {
    expect(possibilities).toEqual([
      'önün açılıyor, birkaç ihtimal de görünür hâle geliyor',
      'önün açılırken birden fazla yol da beliriyor',
      'açılan konuda birkaç seçenek birden ortaya çıkıyor',
      'açıldıkça birkaç ayrı ihtimal de görünüyor',
    ]);
    for (const f of possibilities) expect(fold(f), f).not.toMatch(PHYSICAL);
  });

  it('the core OPENING row is unchanged', () => {
    expect(COFFEE_TURKISH_CLASS_WORDING.OPENING.forms).toEqual({
      predicate: ['önün açılıyor', 'yolun açılıyor', 'bir yol açılıyor', 'önünü açan bir gelişme beliriyor'],
      lead: ['önünü açan bir gelişme', 'açılan bir yol', 'önünde açılan bir yol'],
      continuation: ['açılan bu yol', 'bu açılan yol'],
    });
  });
});

describe('W4A.1 W4E primary freeze (P)', () => {
  // sha256 of the full W4C.1 realization payload, taken at 6d26f0de before W4A.1.
  const PINNED = {
    RITAG: [c31Spec('C3F-RITAG'), DECISION, '58df7a0325d3c775cba7054c7a940bbe8f9defd2fd7334f78498c7bbd5feb7fd'],
    BASAK: [c31Spec('C3F-BASAK'), CANONICAL_INTENTION_TEXT.money_finance, 'fa1eb6d78358d94806e40a555ae8023418e02c0a7c07158e8e8b840268e3b1cc'],
    MONEY_OBJECT: [M1_QA_CUPS.money_fish_tree.spec, CANONICAL_INTENTION_TEXT.money_finance, 'add92bb5a61e4fc54c7587601fd7d43c669fce9d83ae95755c3d88f4539233d1'],
    CAREER: [M1_QA_CUPS.career_key_path.spec, CANONICAL_INTENTION_TEXT.career_work, 'd421b7f9006e707086edc8ff6e8fad5963a228e6130946b5d4c60caa1ae59992'],
  } as const;
  for (const [id, [spec, intention, hash]] of Object.entries(PINNED)) {
    it(`P: ${id} W4E payload is byte-equivalent`, () => {
      const raw = JSON.stringify(realizeSpec(spec, intention));
      expect(createHash('sha256').update(raw).digest('hex')).toBe(hash);
    });
  }
});

describe('W4A.1 manual re-proof replay (zero provider)', () => {
  for (const [id, texts] of Object.entries(MANUAL)) {
    it(`${id}: manual reading passes the frozen W4C.1 checker and carries no physical echo`, () => {
      const p = V3G2[id as keyof typeof V3G2]();
      expect(checkCoffeeM2TurkishRealization(p, [...texts])).toEqual([]);
      for (const t of texts) {
        expect(fold(t), t).not.toMatch(PHYSICAL);
        expect(fold(t), t).not.toMatch(CAUSAL);
        expect(fold(t), t).not.toMatch(RELIEF);
      }
    });
  }

  it('the WALL_LOOP_PHASE manual reading has one time noun and one stage noun', () => {
    const t = fold(MANUAL.WALL_LOOP_PHASE[0]);
    expect(t.match(/donem/g)).toHaveLength(1);
    expect(t.match(/asama/g)).toHaveLength(1);
  });

  it('the RITAG B1 manual beat keeps its two horizons in separate clauses', () => {
    const [forward, opening] = MANUAL.RITAG_V3G1[0].split(';').map(fold);
    expect(forward).toMatch(/yaklasan donemde/); // FORWARD: coming_period
    expect(opening).toMatch(/biraz daha ileride/); // OPENING: further_out
    expect(fold(MANUAL.RITAG_V3G1[0])).not.toMatch(SIMULTANEITY);
  });
});

describe('W4A.1 dark path (S–T)', () => {
  it('S: the meaning-only guard passes for every V3G2 shape', () => {
    for (const [id, build] of Object.entries(V3G2)) expect(() => assertCoffeeV3MeaningOnly(build()), id).not.toThrow();
  });

  it('T: nothing live imports the surface bank', () => {
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
