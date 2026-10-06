import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeUnsupportedExistingFact, coffeeUnsupportedSourceCausation } from '../src/ai/human-quality.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Case = { evidence: ReadingEvidenceItem[]; stages: Array<{ narrative: CoffeeNarrative }> };
const saved = JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_qa_full12_run10.json', 'utf8')) as { cases: Record<string, Case> };
const c = saved.cases;
const last = (x: Case) => x.stages[x.stages.length - 1].narrative;
const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const obs = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });

describe('Coffee unsupported existing fact / source closure', () => {
  it('rejects BIRD silent history and allows direct incoming news', () => {
    expect(coffeeUnsupportedExistingFact(['Bir süredir sessiz duran bir bağlantıdan ses çıkması mümkün.'])).not.toBeNull();
    expect(coffeeUnsupportedExistingFact(['Sana doğru gelen kısa ve sevindirici bir haber var.'])).toBeNull();
  });
  it('rejects TREE prior undertaking and allows branching growth', () => {
    expect(coffeeUnsupportedExistingFact(['Başladığın bir uğraş kendi içinde farklı sonuçlar verecek.'])).not.toBeNull();
    expect(coffeeUnsupportedExistingFact(['Bir gelişme zamanla birkaç kola ayrılacak.'])).toBeNull();
  });
  it('rejects close-circle causation while allowing its supported domain', () => {
    expect(coffeeUnsupportedSourceCausation(['Yakınlarından kaynaklanan bir gelişme karşı tarafa yöneliyor.'])).not.toBeNull();
    expect(coffeeUnsupportedSourceCausation(['Ev ve en yakın çevrenle bağlantılı bir gelişme var.'])).toBeNull();
  });
  it('keeps HANDLE, BRIDGE, RING and STAR symbolism', () => {
    for (const x of [c.case5, c.case8]) expect(bindCoffeeNarrative(last(x), obs(x.evidence), 'tr')).toBe('evidence_leak');
    const ring = structuredClone(last(c.case3));
    ring.overall.text = ring.overall.text.replace('karşındaki kişinin tavrı, aranızdaki bağın yerini belirleyecek', 'aranızdaki bağ karşılıklı ve adı konmuş bir hâl alacak');
    expect(coffeeQualityFailure(ring, 'tr', undefined, c.case3.evidence)).toBe('evidence_leak');
    for (const text of ['Yaptığın bir şeyin fark edilmesi görünüyor.', 'Emeğinin fark edilmesi yakında yüzünü güldürecek.']) {
      expect(coffeeUnsupportedExistingFact([text])).toBeNull();
    }
  });
  it('keeps current BIRD, ROAD and LOW-SYMBOL controls', () => {
    for (const x of [c.case2, c.case4, c.case10]) expect(bindCoffeeNarrative(last(x), obs(x.evidence), 'tr')).toBe('evidence_leak');
  });
  it('allows supplied personalization and leaves Palm untouched', () => {
    const bird = structuredClone(last(c.case2));
    bird.overall.text = `Bir süredir sessiz duran bir bağlantıdan ses çıkabilir. ${bird.overall.text}`;
    expect(coffeeQualityFailure(bird, 'tr', undefined, c.case2.evidence)).toBe('unsupported_existing_fact');
    expect(coffeeQualityFailure(bird, 'tr', { memorySummary: 'Bir süredir sessiz kalan bir bağlantım var.' }, c.case2.evidence)).not.toBe('unsupported_existing_fact');
    expect(palmWriterSystem('tr')).not.toContain('EVIDENCE MAY PREDICT, NOT INVENT HISTORY OR CAUSE');
    expect(repairWriterSystem('palm')).not.toContain('unsupported_existing_fact');
  });
});
