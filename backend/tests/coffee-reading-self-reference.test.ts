/**
 * Story-first closure — READING SELF-REFERENCE (concept-level, folded into
 * the Coffee-only cup_meta_talk code). A sentence whose subject is the
 * reading itself (the story / fal / narrative, the cup as storyteller, what
 * "here" contains or lacks) describes the reading instead of the person's
 * life. Calibrated on every saved real run (1763 unique sentences): 46
 * catches, 0 GOOD-fixture hits after one fixture sentence was rewritten.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeCupMetaTalk, coffeeReadingSelfReference, foldTr } from '../src/ai/human-quality.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const load = (name: string) =>
  JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8')) as { cases: Record<string, Case> };
const t13 = load('coffee_qa_targeted13');
const t12 = load('coffee_qa_targeted12');
const t11 = load('coffee_qa_targeted11');
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const selfRef = (s: string) => coffeeReadingSelfReference(foldTr(s));
const empty = { text: '', evidenceIds: [] as string[] };

describe('the reading describing itself fails', () => {
  it('1. BIRD (targeted13): "Fincandaki hikâye esas olarak … üzerine kurulmuş"', () => {
    const BIRD = t13.cases.case2;
    expect(last(BIRD).overall.text).toContain('Fincandaki hikâye esas olarak bu haberin sende yaratacağı hareket üzerine kurulmuş.');
    expect(selfRef('Fincandaki hikâye esas olarak bu haberin sende yaratacağı hareket üzerine kurulmuş.')).toBe(true);
    expect(coffeeQualityFailure(last(BIRD), 'tr', undefined, BIRD.evidence)).toBe('cup_meta_talk');
    expect(bindCoffeeNarrative(last(BIRD), observation(BIRD.evidence), 'tr')).toBe('human_quality');
  });

  it('2. HANDLE (targeted13): "Burada belirgin bir olay şekli yok"', () => {
    const HANDLE = t13.cases.case5;
    expect(last(HANDLE).overall.text).toContain('Burada belirgin bir olay şekli yok');
    expect(selfRef('Burada belirgin bir olay şekli yok; daha çok yakın çevren dikkat çekiyor.')).toBe(true);
    expect(coffeeQualityFailure(last(HANDLE), 'tr', undefined, HANDLE.evidence)).toBe('cup_meta_talk');
  });

  it('3. old DOTS (targeted12): "Bu fincan kalabalık bir hikâye anlatmıyor"', () => {
    expect(coffeeCupMetaTalk(['Bu fincan kalabalık bir hikâye anlatmıyor.'])).not.toBeNull();
    expect(coffeeCupMetaTalk([t12.cases.case9.stages[0].narrative.overall.text])).not.toBeNull();
  });

  it('the concept, not a list: what the reading is about / emphasizes / its size / its mood', () => {
    for (const s of [
      'Fincan burada sonucu büyütmüyor.',
      'Fincan fazla ayrıntı vermiyor.',
      'Falın ev ve sana en yakın insanlar çevresinde duruyor.',
      'Ev ve sana en yakın insanlar bu falda öne çıkıyor.',
      'Falın sözü tek bir sevindirici noktada toplanmış.',
      'Burada asıl vurgu hareketten çok bağlantıda.',
      'Şimdilik hikâye kısa, ama olduğu yerde de kalmıyor.',
      'Fincan burada büyük laflar etmiyor.',
      'Bu yüzden falın sessiz, kendi halinde bir havası var.',
      'Fincanda başka belirgin şekillerin öne çıkmaması da bu haberi daha özel kılıyor.',
    ]) {
      expect(coffeeCupMetaTalk([s])).not.toBeNull();
    }
  });
});

describe('legitimate cup and evidence references pass', () => {
  it('4. a specific timing limit', () => {
    expect(coffeeCupMetaTalk(['Ne zaman olacağını fincan göstermiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Haberin ne yönde olduğunu fincan tam göstermiyor.'])).toBeNull();
  });

  it('5. normal evidence references and traditional phrasing', () => {
    for (const s of [
      'Kuş fincanın ağzına yakın.',
      'Köprünün vardığı kulp tarafı, bu bağlantının evine dokunacağını anlatıyor.',
      'Fincanın dibinin temiz kalması önünde açık bir kısmet bırakıyor.',
      'Falında bir yol var; kıvrılarak yukarı çıkıyor.',
      'Uzun uzun anlatılan bir şeyden çok, kısa ve net bir söz bu.',
      'Burada önemli olan, yolun yarıda kesilmemesi.',
      'Burada büyük bir sıçrama yok; adım adım bir geçiş var.',
    ]) {
      expect(coffeeCupMetaTalk([s])).toBeNull();
    }
  });
});

describe('sparse cups stay concise, told directly', () => {
  it('6. concise HANDLE (home / close circle only) passes', () => {
    const HANDLE = t13.cases.case5;
    const n: CoffeeNarrative = {
      visualObservation: last(HANDLE).visualObservation,
      overall: {
        text: 'Ev ve sana en yakın insanlar şu sıralar hayatının merkezinde duruyor. Yaşanacakların yönü uzaklardan çok, bildiğin ve sık temas ettiğin çevrede kalıyor; günlük hayatında en çok yer tutan yine yakınların.',
        evidenceIds: ['e1'],
      },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Telvenin kulp yanında toplanması, önündeki günlerin ağırlık merkezini evine ve en yakın halkana çekiyor.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, HANDLE.evidence)).toBeNull();
    expect(bindCoffeeNarrative(n, observation(HANDLE.evidence), 'tr')).toBeNull();
  });

  it('7. concise DOTS (several small details only) passes — the delivered targeted13 DOTS', () => {
    const DOTS = t13.cases.case9;
    expect(coffeeQualityFailure(last(DOTS), 'tr', undefined, DOTS.evidence)).toBeNull();
    expect(bindCoffeeNarrative(last(DOTS), observation(DOTS.evidence), 'tr')).toBeNull();
  });
});

describe('8. current good topology outputs still pass', () => {
  it('ROAD, BRIDGE (targeted13) and NO-SIGN (targeted11) bind', () => {
    for (const c of [t13.cases.case4, t13.cases.case8, t11.cases.case12]) {
      expect(coffeeQualityFailure(last(c), 'tr', undefined, c.evidence)).toBeNull();
      expect(bindCoffeeNarrative(last(c), observation(c.evidence), 'tr')).toBeNull();
    }
  });
});

describe('prompt rule and 9. Palm untouched', () => {
  it('writer and repair carry the rule', () => {
    expect(coffeeWriterSystem('tr')).toContain('NEVER DESCRIBE THE READING ITSELF');
    expect(repairWriterSystem('coffee')).toContain('Never repair by describing the reading itself');
  });

  it('Palm prompts do not', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('NEVER DESCRIBE THE READING ITSELF');
      expect(text).not.toContain('describing the reading itself');
    }
  });
});
