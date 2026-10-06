/**
 * Story-first final closure — real full12_run10 (gpt-5.6-sol, low):
 *   1. DOTS repair rewrote dots as "küçük ayrıntılar" (as the repair focus
 *      asks) and lost its sparse anchor -> abstract_reading. Anchor alias only.
 *   2. TREE invented home / close circle with no handle cue.
 *   3. RING attributed a specific other person's agency.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeHomeDomainClaim, coffeeOtherAgency, coffeeVoiceProfile } from '../src/ai/human-quality.js';
import { coffeeContextEventPromotion, coffeeSparseContextAnchored } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeHomeAffordance, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { coffeeVoiceRepairFocus, palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const run10 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_full12_run10.json', 'utf8'),
) as { cases: Record<string, Case> };
const c = run10.cases;
const last = (x: Case) => x.stages[x.stages.length - 1].narrative;
const DOTS = c.case9;
const TREE = c.case7;
const RING = c.case3;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const empty = { text: '', evidenceIds: [] as string[] };

describe('1/2. DOTS anchor alias ("küçük ayrıntılar" naming the cited dots)', () => {
  it('1. the full12_run10 DOTS repair no longer fails abstract_reading', () => {
    const repair = DOTS.stages[1].narrative;
    expect(DOTS.stages[1].quality).toBe('abstract_reading');
    expect(coffeeVoiceProfile(meaning(repair)).signKinds).toBe(0); // still not a semantic sign
    expect(coffeeSparseContextAnchored([repair.overall, repair.takeaway], DOTS.evidence)).toBe(true);
    expect(coffeeQualityFailure(repair, 'tr', undefined, DOTS.evidence)).toBe('evidence_leak');
  });

  it('"küçük ayrıntılar" without a cited dots item is NOT an anchor', () => {
    const clean = DOTS.evidence.find((e) => /clean/.test(e.description))!;
    expect(coffeeSparseContextAnchored([{ text: 'Birkaç küçük ayrıntı ayrı ayrı duruyor.', evidenceIds: [clean.id] }], DOTS.evidence)).toBe(false);
  });

  it('2. floating sparse abstraction without a cited anchor still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: last(DOTS).visualObservation,
      overall: { text: 'Şu sıralar hafif bir hava var. Her şey daha ferah olacak ve önünde güzel, sakin bir dönem açılacak; içinde de hafif bir rahatlık hissedeceksin.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Yakında içini ferahlatan sakin bir hava daha da belirginleşecek gibi.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBe('abstract_reading');
  });

  it('"ayrıntılar" turned into errands / topics still fails context_event', () => {
    const dots = DOTS.evidence.find((e) => /dots/.test(e.description))!;
    expect(coffeeContextEventPromotion([{ text: 'Küçük ayrıntılar gününü ufak uğraşlarla dolduracak.', evidenceIds: [dots.id] }], DOTS.evidence)).not.toBeNull();
    expect(coffeeContextEventPromotion([{ text: 'Küçük ayrıntılar ayrı başlıklar halinde gündemine girecek.', evidenceIds: [dots.id] }], DOTS.evidence)).not.toBeNull();
  });

  it('the context_event repair keeps an explicit evidence anchor', () => {
    expect(coffeeVoiceRepairFocus('context_event')).toContain('keeps an explicit anchor to that evidence');
  });
});

describe('3/4. home needs a home cue', () => {
  it('3. TREE (no handle) "ev ve yakın çevrene" fails unsupported_home_domain', () => {
    expect(coffeeHomeAffordance(TREE.evidence)).toBe(false);
    expect(coffeeHomeDomainClaim(meaning(last(TREE)))).toContain('ev ve yakin cevrene');
    expect(coffeeQualityFailure(last(TREE), 'tr', undefined, TREE.evidence)).toBe('unsupported_home_domain');
  });

  it('4. TREE told as growth / branching only passes', () => {
    const n = structuredClone(last(TREE));
    n.overall.text = 'Ağaç şekli hayatında kök salacak bir gelişmeye bakıyor. Ortada duran tek gövde, dağılmadan büyüyen sağlam bir başlangıcı anlatıyor; dallar bunun zamanla birkaç yöne uzanacağını gösteriyor. Bir anda parlayıp sönen bir heves değil, yerini buldukça güçlenen ve çevresini genişleten bir durum var.';
    expect(coffeeQualityFailure(n, 'tr', undefined, TREE.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(TREE.evidence), 'tr')).toBe('evidence_leak');
  });

  it('7. HANDLE/HOME and 8. BRIDGE landing toward the handle keep their home domain', () => {
    for (const x of [c.case5, c.case8]) {
      expect(coffeeHomeAffordance(x.evidence)).toBe(true);
      expect(bindCoffeeNarrative(last(x), observation(x.evidence), 'tr')).toBe('evidence_leak');
    }
  });

  it('home personalization still allows home language on a cup without a handle', () => {
    expect(coffeeHomeAffordance(TREE.evidence, { relevantThemes: ['aile'] })).toBe(true);
    expect(coffeeQualityFailure(last(TREE), 'tr', { relevantThemes: ['aile'] }, TREE.evidence)).not.toBe('unsupported_home_domain');
  });
});

describe('5/6. no specific other-person agency', () => {
  it('5. RING "karşındaki kişinin tavrı … belirleyecek" fails', () => {
    expect(coffeeOtherAgency(meaning(last(RING)))).toContain('karsindaki kisinin tavri');
    expect(coffeeQualityFailure(last(RING), 'tr', undefined, RING.evidence)).toBe('unsupported_other_agency');
  });

  it('6. RING commitment / reciprocal language passes', () => {
    const n = structuredClone(last(RING));
    n.overall.text = n.overall.text.replace('karşındaki kişinin tavrı, aranızdaki bağın yerini belirleyecek', 'aranızdaki bağ karşılıklı ve adı konmuş bir hâl alacak');
    expect(coffeeOtherAgency(meaning(n))).toBeNull();
    expect(coffeeQualityFailure(n, 'tr', undefined, RING.evidence)).toBe('evidence_leak');
  });

  it('generic reciprocity and BRIDGE "iki taraf" are not agency', () => {
    for (const s of ['Karşılıklı bir bağ kuruluyor.', 'İki tarafı birleştiren bir bağ var.', 'Karşılığı olan bir yakınlık görünüyor.', 'Birbirinden ayrı duran iki taraf arasında bağ kuruluyor.']) {
      expect(coffeeOtherAgency([s])).toBeNull();
    }
  });
});

describe('9. current good outputs still pass; 10. Palm untouched', () => {
  it('BIRD, ROAD, LOW-SYMBOL, STAR (full12_run10 delivered) bind', () => {
    for (const x of [c.case2, c.case4, c.case10, c.case11]) {
      expect(bindCoffeeNarrative(last(x), observation(x.evidence), 'tr')).toBe('evidence_leak');
    }
  });

  it('Palm prompts carry no new Coffee rule', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('HOME NEEDS A HOME CUE');
      expect(text).not.toContain("NO OTHER PERSON'S AGENCY");
    }
  });
});
