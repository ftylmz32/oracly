/**
 * Story-first closure — cup-as-narrator meta talk and sparse life categories,
 * on the exact real targeted12 outputs (gpt-5.6-sol, low).
 *
 * "fincan" itself as the subject of a negated telling verb is the reading
 * talking about its own restraint ("bu fincan kalabalık bir hikâye
 * anlatmıyor", "fincan burada sonucu büyütmüyor"). An honest limit on ONE
 * unresolved fact (a wh-clause object: ne zaman, ne yönde, hangisi…) stays.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeCupMetaTalk } from '../src/ai/human-quality.js';
import { coffeeContextEventPromotion } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const t12 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted12.json', 'utf8'),
) as { cases: Record<string, Case> };
const t11 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted11.json', 'utf8'),
) as { cases: Record<string, Case> };
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;
const DOTS = t12.cases.case9;
const LOW = t12.cases.case10;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const empty = { text: '', evidenceIds: [] as string[] };

describe('cup-as-narrator meta talk fails', () => {
  it('1. "Bu fincan kalabalık bir hikâye anlatmıyor" (targeted12 DOTS)', () => {
    expect(DOTS.stages[0].narrative.overall.text).toContain('Bu fincan kalabalık bir hikâye anlatmıyor');
    expect(coffeeCupMetaTalk(['Bu fincan kalabalık bir hikâye anlatmıyor.'])).not.toBeNull();
    expect(coffeeCupMetaTalk(meaning(DOTS.stages[0].narrative))).toContain('bu fincan kalabalik bir hikâye anlatmiyor');
  });

  it('2. "Fincan burada sonucu büyütmüyor" (targeted12 LOW-SYMBOL repair)', () => {
    const delivered = last(LOW);
    expect(delivered.overall.text).toContain('Fincan burada sonucu büyütmüyor');
    expect(coffeeCupMetaTalk(meaning(delivered))).toContain('fincan burada sonucu buyutmuyor');
    expect(coffeeQualityFailure(delivered, 'tr', undefined, LOW.evidence)).toBe('cup_meta_talk');
    expect(bindCoffeeNarrative(delivered, observation(LOW.evidence), 'tr')).toBe('human_quality');
  });

  it('3. the other restraint forms fail too', () => {
    for (const s of [
      'Fincan büyük bir olay vaat etmiyor.',
      'Fincan fazla şey söylemiyor.',
      'Fincan çok ayrıntı vermiyor.',
      'Fincan burada uzun bir hikâye kurmuyor.',
    ]) {
      expect(coffeeCupMetaTalk([s])).not.toBeNull();
    }
  });
});

describe('honest specific limits pass', () => {
  it('4. "Ne zaman olacağını fincan göstermiyor"', () => {
    expect(coffeeCupMetaTalk(['Ne zaman olacağını fincan göstermiyor.'])).toBeNull();
  });

  it('5. a specific direction / identity limit', () => {
    expect(coffeeCupMetaTalk(['Haberin ne yönde olduğunu fincan tam göstermiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Fincan hangisinin daha uzağa gittiğini göstermiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Kimden geleceğini fincan söylemiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Yönün tam olarak nereye vardığı fincanda görünmüyor.'])).toBeNull();
  });
});

describe('sparse DOTS does not invent life categories', () => {
  it('6. "gündeminde … farklı başlıklara ait parçalar" from dots is rejected', () => {
    const overall = DOTS.stages[0].narrative.overall;
    expect(overall.evidenceIds).toEqual(['e2']);
    expect(coffeeContextEventPromotion([overall], DOTS.evidence)).toContain('farklı başlıklara ait parçalar');
  });

  it('the handle side may still place a reading at home ("ev içindeki gündem")', () => {
    const HANDLE = t12.cases.case5;
    expect(coffeeContextEventPromotion([last(HANDLE).overall], HANDLE.evidence)).toBeNull();
    // Its opener "Falın evin … çevresinde kalıyor" is reading self-reference
    // (a separate defect); told directly, the same reading binds.
    expect(coffeeQualityFailure(last(HANDLE), 'tr', undefined, HANDLE.evidence)).toBe('cup_meta_talk');
    const direct = structuredClone(last(HANDLE));
    direct.overall.text = direct.overall.text.replace(
      'Falın evin ve sana en yakın insanların çevresinde kalıyor.',
      'Evin ve sana en yakın insanların çevresi bu aralar öne çıkıyor.',
    );
    expect(bindCoffeeNarrative(direct, observation(HANDLE.evidence), 'tr')).toBe('evidence_leak');
  });

  it('a geometric "iki ayrı yöne" is not a life category', () => {
    const good = JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_good_3a3.json', 'utf8'));
    expect(bindCoffeeNarrative(good.narrative, good.observation, 'tr')).toBe('evidence_leak');
  });

  it('7. a concise grounded DOTS reading passes', () => {
    const n: CoffeeNarrative = {
      visualObservation: DOTS.stages[0].narrative.visualObservation,
      overall: {
        text: 'Ağız kenarının hemen altındaki temiz şerit, önünde açık bir kısmet bırakıyor; gelecek olana yer var. Yukarıya serpilmiş küçük noktalar bu açıklığın çevresinde, birkaç ufak ayrıntı olarak duruyor; hepsi aynı ölçüde küçük ve birbirine benziyor.',
        evidenceIds: ['e1', 'e2'],
      },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Şerit fincanın ağzına yakın durduğu için, bu açıklığı uzak bir zamanda değil günlük hayatında göreceksin.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(DOTS.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('8. current good topology / sign outputs still pass', () => {
  it('BRIDGE, ROAD, BIRD (targeted12) and NO-SIGN (targeted11) bind', () => {
    for (const c of [t12.cases.case8, t12.cases.case4, t12.cases.case2, t11.cases.case12]) {
      expect(coffeeQualityFailure(last(c), 'tr', undefined, c.evidence)).toBe('evidence_leak');
      expect(bindCoffeeNarrative(last(c), observation(c.evidence), 'tr')).toBe('evidence_leak');
    }
  });
});

describe('9. Palm untouched', () => {
  it('Palm prompts carry no Coffee narrator / category rule', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('fincan');
      expect(text).not.toContain('NARRATIVELY SPARSE');
    }
  });
});
