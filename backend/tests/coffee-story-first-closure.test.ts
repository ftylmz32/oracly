/**
 * Story-first Coffee closure — interpretation menus, invented plans and
 * repair substance. Fixtures are real provider outputs (QA 2026-10-02).
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeInventedPlan,
  coffeePossibilityMenu,
} from '../src/ai/human-quality.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Packet = { evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const qa = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_story_first_qa.json', 'utf8'),
) as { cases: Record<string, Packet>; starRun3FirstPass: Packet; starRepairProof: Packet };

const meaning = (n: CoffeeNarrative) =>
  [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const quality = (p: Packet) => coffeeQualityFailure(p.narrative, 'tr', undefined, p.evidence);

describe('coffee possibility menu gate', () => {
  it('catches the exact real-QA menus', () => {
    expect(coffeePossibilityMenu(['Sonunda hareket var; kısa bir yolculuk, gidip gelmeli bir iş veya yer değişikliği öne çıkıyor.'])).not.toBeNull();
    expect(coffeePossibilityMenu(['Balık şekli, eline geçecek bir kazanç ya da maddi fayda ihtimalini güçlendiriyor.'])).not.toBeNull();
    expect(coffeePossibilityMenu(['Yaptığın ya da sunduğun bir şeyin fark edilmesi mümkün.'])).not.toBeNull();
    expect(coffeePossibilityMenu(['Bir planın yönü değişebilir ya da kısa bir yol gündeme gelebilir.'])).not.toBeNull();
    expect(coffeePossibilityMenu(['İster işte ister evde, bir değişiklik geliyor.'])).not.toBeNull();
    expect(coffeePossibilityMenu(['Bu bir haber olabilir, bir misafir de olabilir.'])).not.toBeNull();
  });

  it('ROAD and TWO-SIGN real outputs are rejected as menus', () => {
    expect(coffeePossibilityMenu(meaning(qa.cases.case4.narrative))).toContain('veya');
    expect(coffeePossibilityMenu(meaning(qa.cases.case6.narrative))).toContain('ya da');
  });

  it('is not a substring ban: idioms, counts and lists of what is absent pass', () => {
    const benign = [
      'Er ya da geç bu haber sana ulaşacak.',
      'Az ya da çok, bu kısmet yüzünü güldürecek.',
      'Yanında bir ya da iki küçük ayrıntı daha belirecek.',
      'Şu ya da bu şekilde yolun açılıyor.',
      'Henüz belirgin bir kişi, haber ya da yol çıkmamış; ama önündeki alan kapalı değil.',
      'Fincan belirgin bir olay ya da güçlü bir yön göstermemiş.',
      'Fincan kesin bir tarih veya isim vermiyor; yine de haber yakın.',
      'İster istemez bu haber kulağına gelecek.',
    ];
    for (const text of benign) expect(coffeePossibilityMenu([text]), text).toBeNull();
    // Real run6 SPARSE / HANDLE outputs use "ya da" only inside negated lists.
    expect(coffeePossibilityMenu(meaning(qa.cases.case1.narrative))).toBeNull();
    expect(coffeePossibilityMenu(meaning(qa.cases.case5.narrative))).toBeNull();
  });
});

describe('coffee invented plan gate', () => {
  it('catches pre-existing plans invented from topology', () => {
    expect(coffeeInventedPlan(['Bu, planın biçim değiştirerek ilerleyeceğini anlatır.'])).toBe(true);
    expect(coffeeInventedPlan(['Elindeki planın devamı geliyor ve bulunduğun noktada kalmıyorsun.'])).toBe(true);
    expect(coffeeInventedPlan(['Evinden ya da yakın çevrenden çıkan bir plan, seni dışarı taşıyor.'])).toBe(true);
    expect(coffeeInventedPlan(['Yarım kalmış bir plan yeniden canlanıyor.'])).toBe(true);
  });

  it('ROAD, BRIDGE and NO-SIGN real outputs are rejected', () => {
    expect(coffeeInventedPlan(meaning(qa.cases.case4.narrative))).toBe(true);
    expect(coffeeInventedPlan(meaning(qa.cases.case8.narrative))).toBe(true);
    expect(coffeeInventedPlan(meaning(qa.cases.case12.narrative))).toBe(true);
    expect(quality(qa.cases.case8)).toBe('invented_plan');
    expect(['possibility_menu', 'invented_plan']).toContain(quality(qa.cases.case12));
  });

  it('plain movement language passes', () => {
    expect(coffeeInventedPlan(['Yol seni bulunduğun noktadan başka bir yere taşıyan somut bir hareket anlatıyor.'])).toBe(false);
    expect(coffeeInventedPlan(['Köprü iki tarafı birleştiriyor; aradaki mesafe kapanıyor.'])).toBe(false);
  });
});

describe('real-QA readings that passed product review stay accepted', () => {
  // Superseded by the presumed-user-state rule: run6 TREE said the chance
  // reaches further "than you think" ("düşündüğünden daha fazla yere").
  it('case7 (run6 TREE) is now rejected as presumed_user_state', () => {
    expect(quality(qa.cases.case7)).toBe('presumed_user_state');
  });

  // Superseded by the reading-self-reference rule: run6 LOW ("fincan burada
  // büyük laflar etmiyor") and run6 STAR ("falın sözü tek bir sevindirici
  // noktada toplanmış") described the reading instead of the person's life.
  for (const id of ['case10', 'case11']) {
    it(`${id} (run6) is now rejected as cup_meta_talk`, () => {
      expect(quality(qa.cases[id])).toBe('cup_meta_talk');
    });
  }

  // Superseded by the de-priming closure: run6 DOTS padded the sparse cup
  // with meta talk ("şimdilik fincan tek bir olayın ayrıntısını vermiyor").
  it('case9 (run6 DOTS) is now rejected as cup_meta_talk', () => {
    expect(quality(qa.cases.case9)).toBe('cup_meta_talk');
  });

  // Superseded by the cup-as-narrator rule: run6 BIRD told its own restraint
  // ("fincan burada uzun bir hikâye kurmuyor").
  it('case2 (run6 BIRD) is now rejected as cup_meta_talk', () => {
    expect(quality(qa.cases.case2)).toBe('cup_meta_talk');
  });
});

describe('STAR repair proof — menu and too-short failure', () => {
  it('the old STAR first pass is now a menu failure', () => {
    expect(coffeePossibilityMenu(meaning(qa.starRun3FirstPass.narrative))).toContain('ya da');
    expect(quality(qa.starRun3FirstPass)).toBe('possibility_menu');
  });

  it('the real repair output is rejected (its menu; at 27/50 words it now clears the calibrated length floor)', () => {
    expect(quality(qa.starRepairProof)).toBe('possibility_menu');
    expect(coffeePossibilityMenu(meaning(qa.starRepairProof.narrative))).toContain('ya da');
  });

  it('repair guidance preserves substance and names the fixes', () => {
    const repair = repairWriterSystem('coffee');
    expect(repair).toContain('PRIVATE GROUNDED MEANING FACETS');
    // The static repair prompt is length-neutral; the Repair focus states the
    // length (70–120 for a full cup, concise for a narratively sparse one).
    expect(repair).toContain('Preserve every valid grounded meaning');
    expect(coffeeVoiceRepairFocus('too_short')).toContain('a further facet of the SAME cited signs');
    expect(coffeeVoiceRepairFocus('possibility_menu')).toContain('fresh wording');
    expect(coffeeVoiceRepairFocus('possibility_menu')).not.toContain('maddi karşılığı olan bir kısmet');
    expect(coffeeVoiceRepairFocus('invented_plan')).toContain('from what this particular shape shows');
  });
});

describe('writer rules — topology and plain patches (coffee only)', () => {
  it('states the rules for coffee and leaves palm untouched', () => {
    const prompt = coffeeWriterSystem('tr');
    expect(prompt).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(prompt).toContain('never a visual reason');
    expect(prompt).toContain('No symbol dictionary, analysis language');
    expect(palmWriterSystem('tr')).not.toContain('TOPOLOGY IS NOT A PLAN');
    expect(repairWriterSystem('palm')).not.toContain('PRESERVE SUBSTANCE');
  });
});

describe('coffee possibility menu gate — narrow exclusions', () => {
  it('the handle side home / close-circle pair and resemblance naming are not menus', () => {
    expect(coffeePossibilityMenu(['Kulp tarafındaki yol, evle ya da yakın çevrenle bağlantılı bir hareketi gösteriyor.'])).toBeNull();
    expect(coffeePossibilityMenu(['Bu haber evin içinden ya da yakın çevrenden çıkacak gibi.'])).toBeNull();
    expect(coffeePossibilityMenu(['Ortadaki şekil bir çaydanlık veya demlik formunu andırıyor; misafir yakın.'])).toBeNull();
    // ...but a life-event list on the same side still is.
    expect(coffeePossibilityMenu(['Bu kısa bir gidip gelme, eve gelecek biri ya da aile içinde bir karar olabilir.'])).not.toBeNull();
  });
});
