/**
 * Story-first closure — real targeted15 (gpt-5.6-sol, low):
 *   - context_event already caught DOTS "gündeminde … konu" and LOW-SYMBOL
 *     "iki başlık", but its repair focus never said how to remove LIFE
 *     CATEGORIES, so the repairs kept them (and DOTS cut itself short);
 *   - BIRD presumed the person's expectation ("beklediğin bir cevap").
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { coffeeContextEventPromotion } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const t15 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted15.json', 'utf8'),
) as { cases: Record<string, Case> };
const BIRD = t15.cases.case2;
const ROAD = t15.cases.case4;
const HANDLE = t15.cases.case5;
const BRIDGE = t15.cases.case8;
const DOTS = t15.cases.case9;
const LOW = t15.cases.case10;
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });

describe('DOTS — no life categories from dots', () => {
  it('1. writer "gündeminde …" and repair "birkaç küçük konu" are context_event', () => {
    // Its "yakın çevrende" (no handle cue) is also rejected now; the category
    // promotion itself is still context_event:
    expect(coffeeContextEventPromotion([DOTS.stages[0].narrative.overall], DOTS.evidence)).not.toBeNull();
    expect(coffeeQualityFailure(DOTS.stages[0].narrative, 'tr', undefined, DOTS.evidence)).not.toBeNull();
    expect(coffeeContextEventPromotion([DOTS.stages[1].narrative.overall], DOTS.evidence)).toContain('birkaç küçük konu');
  });

  it('2. the same DOTS reading kept at evidence level ("small details") passes', () => {
    const n = structuredClone(DOTS.stages[0].narrative);
    n.overall.text = n.overall.text
      .replace('Gündeminde birbirine pek bağlanmayan birkaç küçük ayrıntı var.', 'Yukarıya serpilmiş birbirine pek bağlanmayan birkaç küçük ayrıntı var.')
      .replace('Bu yüzden yakın çevrende sade', 'Bu yüzden önünde sade');
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(DOTS.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('LOW-SYMBOL — no life categories from a plain line', () => {
  it('3. "iki başlık / iki konu / iki alan" are context_event', () => {
    expect(coffeeQualityFailure(LOW.stages[0].narrative, 'tr', undefined, LOW.evidence)).toBe('context_event');
    for (const words of ['iki konunun', 'iki alanın']) {
      const n = structuredClone(LOW.stages[0].narrative);
      n.overall.text = n.overall.text.replace('iki başlığın', words);
      expect(coffeeContextEventPromotion([n.overall], LOW.evidence)).not.toBeNull();
    }
  });

  it('4. a connection-only rewrite passes', () => {
    const n = structuredClone(LOW.stages[0].narrative);
    n.overall.text = n.overall.text.replace('birbirine değmeyen iki başlığın artık ortak bir noktaya ulaşması demek', 'birbirine değmeyen iki tarafın artık ortak bir noktada buluşması demek');
    expect(coffeeQualityFailure(n, 'tr', undefined, LOW.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(LOW.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('context_event repair guidance', () => {
  it('5. explicitly asks to remove life-category nouns', () => {
    const focus = coffeeVoiceRepairFocus('context_event')!;
    for (const w of ['gündem', 'konu', 'başlık', 'mesele', 'hayat alanı']) expect(focus).toContain(w);
    const g = coffeeRepairGuidance('human_quality', LOW.stages[0].narrative, LOW.evidence, 'tr')!;
    expect(g).toContain('unsupported life-category nouns');
    expect(g).toContain('two visible sides joined by one thin connection');
  });

  it('6. tells a sparse repair to rewrite, not delete, and keep the sparse minimum', () => {
    const g = coffeeRepairGuidance('human_quality', DOTS.stages[0].narrative, DOTS.evidence, 'tr')!;
    expect(g).toContain('REWRITE, DO NOT DELETE');
    expect(g).toContain('rewrite the offending sentence at evidence level instead of deleting it');
    expect(g).toContain('several small details or separate small marks');
    expect(g).not.toContain('70–120');
  });
});

describe('BIRD — the sign brings news; it does not prove the person was waiting', () => {
  it('7. "beklediğin bir cevap" fails presumed_user_state', () => {
    expect(last(BIRD).overall.text).toContain('beklediğin bir cevap');
    expect(coffeeQualityFailure(last(BIRD), 'tr', undefined, BIRD.evidence)).toBe('presumed_user_state');
    expect(bindCoffeeNarrative(last(BIRD), observation(BIRD.evidence), 'tr')).toBe('human_quality');
  });

  it('…unless the personalization supplied an intention', () => {
    expect(coffeeQualityFailure(last(BIRD), 'tr', { intention: 'İş başvurumdan haber bekliyorum' }, BIRD.evidence)).not.toBe('presumed_user_state');
  });

  it('8. a direct grounded "a reply is coming" passes', () => {
    const n = structuredClone(last(BIRD));
    n.overall.text = n.overall.text
      .replace('beklediğin bir cevap duyduğunda', 'sana bir cevap ulaştığında')
      .replace('Söylenecek birkaç kelime, tahmin ettiğinden daha fazla anlam taşıyabilir.', 'Söylenecek birkaç kelime, kısa olsa da yönü belirleyecek.');
    expect(coffeeQualityFailure(n, 'tr', undefined, BIRD.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(BIRD.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('controls', () => {
  it('9. HANDLE home / close-circle domain still passes (targeted15 delivered)', () => {
    expect(last(HANDLE).overall.text).toContain('gündeminde');
    expect(bindCoffeeNarrative(last(HANDLE), observation(HANDLE.evidence), 'tr')).toBe('evidence_leak');
  });

  it('10. ROAD and BRIDGE still pass', () => {
    for (const c of [ROAD, BRIDGE]) {
      expect(coffeeQualityFailure(last(c), 'tr', undefined, c.evidence)).toBe('evidence_leak');
      expect(bindCoffeeNarrative(last(c), observation(c.evidence), 'tr')).toBe('evidence_leak');
    }
  });

  it('writer carries both rules', () => {
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
  });

  it('11. Palm untouched', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('LOW-CAPACITY EVIDENCE');
      expect(text).not.toContain("PRESUME THE PERSON'S MIND");
    }
  });
});
