import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import type { CoffeeWriterPacketV2 } from '../src/ai/reading/coffee-story-plan.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

import {
  coffeeActiveDevelopmentClasses,
  coffeeForbiddenSpecificsTriggered,
  coffeeInventedCurrentState,
  coffeeUnsupportedDevelopments,
} from '../src/ai/reading/coffee-public-language.js';
import { coffeeClaimSafetyFailure } from '../src/ai/reading/coffee-claim-envelope.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import type { CoffeeForbiddenSpecific } from '../src/ai/reading/coffee-fortune-beat.js';
import { coffeeWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
const checks = {
  cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true,
  milkFoamObstruction: false, usefulRegionsVisible: true,
};
const ev = (id: string, resemblance: string | null, region = 'middle_wall'): ReadingEvidenceItem => ({
  id, region, description: 'A private compact deposit description.', resemblance, confidence: 'high', visibility: 'clear',
});
const neutral = (id: string): ReadingEvidenceItem => ({
  id, region: 'base', description: 'A faint film.', resemblance: null, confidence: 'low', visibility: 'uncertain',
});
const obsOf = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const pair = (resemblance: string) => obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3'));
const packetFor = (obs: CoffeeObservation, intention?: string): CoffeeWriterPacketV2 => {
  const packet = buildCoffeeWriterPacketV2(obs, 'tr', intention ? personalizationFromUnknown({ personalization: { intention } }) : undefined);
  if ('status' in packet) throw new Error('expected writer-eligible packet');
  return packet;
};
const section = (text: string) => ({ text, evidenceIds: text ? ['e1'] : [] });
const narrativeOf = (parts: Partial<Record<keyof CoffeeNarrative, string>>): CoffeeNarrative => ({
  visualObservation: section(parts.visualObservation ?? ''),
  overall: section(parts.overall ?? ''),
  love: section(parts.love ?? ''),
  career: section(parts.career ?? ''),
  money: section(parts.money ?? ''),
  nearFuture: section(parts.nearFuture ?? ''),
  takeaway: section(parts.takeaway ?? ''),
} as CoffeeNarrative);
const gate = (narrative: CoffeeNarrative, obs: CoffeeObservation, intention: string) =>
  coffeeQualityFailure(narrative, 'tr', { intention }, obs.evidence, packetFor(obs, intention).storyPlan);

// ---------------------------------------------------------------------------
// PART 9 — the exact C2.11A self-audit fixtures (frozen proof of the gap).
// They passed the FULL production gate at 6ad95a14 while carrying content no
// active fortune beat licenses.
// ---------------------------------------------------------------------------
const C211A_CAREER = narrativeOf({
  visualObservation: 'Önümüzdeki günlerde içini kıpırdatacak güzel bir haber sana doğru yola çıkmış gibi.',
  overall: 'Yakında işinde seni heyecanlandıracak bir kapı aralanacak; sana yakışan, emeğini gösterebileceğin yeni bir adım olacak gibi. Bu kıpırtıyı ilk duyduğunda içinden bir sevinç geçecek ve elini taşın altına koymaya hevesleneceksin.',
  career: 'Mesai arkadaşlarının arasında adının daha sık geçtiği, emeğinin fark edildiği günlere yaklaşıyorsun.',
  takeaway: 'Kapı aralandığında içindeki çekingenlik dağılacak, o heves seni gönül rahatlığıyla ileri taşıyacak.',
});
const C211A_MONEY = narrativeOf({
  visualObservation: 'Elinin biraz rahatlayacağı, nefes alacağın günler sana yaklaşıyor.',
  overall: 'Maddi tarafta kapına küçük ama sevindirici bir kısmet gelecek; ilk başta ufak görünecek, sonra yavaş yavaş büyüyüp seni şaşırtacak. Bir kenara koyduğun şeyler bereketlenecek, harcarken de içini daha az daraltacaksın, hesabını kitabını yaparken yüzün gülecek ve kendine küçük bir keyif ayırmaya gönlün razı olacak gibi.',
  money: 'Kazandığını tutabileceğin, cebine giren her şeyin biraz daha uzun dayanacağı bir döneme giriyorsun.',
  takeaway: 'Sabırla büyüyen bu bereket önümüzdeki günlerde seni epey rahatlatacak, içine tatlı bir ferahlık yayılacak.',
});
const CAREER = 'İşim ve kariyerim hakkında';
const MONEY = 'Maddi durumum hakkında';
const fish = () => pair('may resemble a fish');
const fishTree = () => obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3'));

describe('C2.11A.1 PRE-FIX RED — exact proven grounding defects', () => {
  it('A. opening-only plan + a communication/news development must fail as unsupported_fortune_development', () => {
    const onlyNews = narrativeOf({ ...Object.fromEntries(Object.entries(C211A_CAREER).map(([k, v]) => [k, v.text])), career: 'İşinde sana yakışan yeni bir adımın kapısı aralanacak gibi duruyor.' });
    expect(gate(onlyNews, fish(), CAREER)).toBe('unsupported_fortune_development');
  });

  it('B. opening-only plan + coworkers discussing / recognizing the user must fail (invented coworkers + third-party action)', () => {
    const noNews = narrativeOf({ ...Object.fromEntries(Object.entries(C211A_CAREER).map(([k, v]) => [k, v.text])), visualObservation: 'Önümüzdeki günlerde içini kıpırdatacak bir kapı aralanacak gibi.' });
    // "Mesai arkadaşların" presumes coworkers exist: invented CURRENT career state,
    // which precedes the third-party action in the safety order.
    expect(gate(noNews, fish(), CAREER)).toBe('unsupported_existing_fact');
    // Third-party recognition with no presumed coworkers still fails, as an
    // unsupported specific (other_person_action).
    const actionOnly = narrativeOf({ ...Object.fromEntries(Object.entries(C211A_CAREER).map(([k, v]) => [k, v.text])), visualObservation: 'Önümüzdeki günlerde içini kıpırdatacak bir kapı aralanacak gibi.', career: 'İnsanlar emeğini fark edecek, adın daha sık anılacak gibi duruyor.' });
    expect(gate(actionOnly, fish(), CAREER)).toBe('unsupported_specific_detail');
  });

  it('C. money opening+growth + an existing-savings claim must fail as invented existing user state', () => {
    expect(gate(C211A_MONEY, fishTree(), MONEY)).toBe('unsupported_existing_fact');
  });
});

const one = (text: string) => narrativeOf({ overall: text });
const planOf = (resemblance: string, intention?: string) => packetFor(pair(resemblance), intention).storyPlan;

// ---------------------------------------------------------------------------
// PART 10 — every beat accepts its own development and rejects an unrelated one
// ---------------------------------------------------------------------------
describe('C2.11A.1 — beat development matrix', () => {
  it.each([
    ['contact_emergence', 'may resemble a small bird', 'Yakında içini ısıtan tatlı bir haber alacaksın gibi.', 'Önüne taze bir fırsat çıkacak.', 'opening'],
    ['written_exchange', 'may resemble a folded letter', 'Seni gülümsetecek kısa bir mesajlaşma başlayacak gibi.', 'Yavaş yavaş büyüyen bir bereket geliyor.', 'growth'],
    ['opening_emerges', 'may resemble a fish', 'Önüne sana yakışan yeni bir kapı aralanacak gibi.', 'Yakında güzel bir haber alacaksın.', 'communication'],
    ['commitment_forms', 'may resemble a ring', 'Kalbine iyi gelecek yeni bir bağ kurulacak gibi.', 'Önüne taze bir fırsat çıkacak.', 'opening'],
    ['feeling_deepens', 'may resemble a heart', 'Duyguların yavaş yavaş derinleşecek gibi.', 'Bir yolculuk sana iyi gelecek.', 'direction'],
    ['way_through_appears', 'may resemble a key', 'Kafanı kurcalayan şey için bir çıkış yolu belirecek gibi.', 'Önüne taze bir fırsat çıkacak.', 'opening'],
    ['direction_shifts', 'may resemble a winding path', 'Rotanı değiştirecek bir canlanma kapıda gibi.', 'Bir çözüm kendiliğinden belirecek.', 'way_through'],
    ['gradual_accumulation', 'may resemble a tree', 'Ağır ağır büyüyen bir bereket seni bekliyor gibi.', 'Yakında güzel bir haber alacaksın.', 'communication'],
    ['alternatives_clarify', 'may resemble a crossroads', 'Hangi tercihin sana daha yakın olduğu netleşecek gibi.', 'Kalbine iyi gelecek yeni bir bağ kurulacak.', 'commitment'],
    ['people_gather', 'may resemble a standing person', 'Çevrende yeni insanlarla tanışacağın bir hareketlilik var gibi.', 'Önüne taze bir fırsat çıkacak.', 'opening'],
  ] as const)('%s allows its own development and rejects an imported %s', (beat, resemblance, own, foreign, foreignClass) => {
    const plan = planOf(resemblance);
    expect(plan.fortune?.lead.kind).toBe(beat);
    expect(coffeeUnsupportedDevelopments(one(own), plan)).toEqual([]);
    expect(coffeeUnsupportedDevelopments(one(foreign), plan)).toContain(foreignClass);
  });

  it('beat-specific escalations stay rejected inside their own class', () => {
    expect(coffeeClaimSafetyFailure(one('Aranızdaki eski bağın korunması mümkün.'), planOf('may resemble a ring', 'Aşk ve ilişkilerim hakkında'))).toBe('unsupported_existing_fact');
    expect(coffeeForbiddenSpecificsTriggered(one('Onun duyguları değişiyor.'), planOf('may resemble a heart'))).toContain('other_person_feelings');
    expect(coffeeClaimSafetyFailure(one('Aradığın çözüm yaklaşıyor.'), planOf('may resemble a key'))).toBe('unsupported_existing_fact');
    expect(coffeeClaimSafetyFailure(one('Bir yolculuk kapıda.'), planOf('may resemble a winding path'))).toBe('unsupported_existing_fact');
    expect(coffeeClaimSafetyFailure(one('Bir kenara koyduğun para bereketlenecek.'), planOf('may resemble a tree'))).toBe('unsupported_existing_fact');
    expect(coffeeClaimSafetyFailure(one('Seçenekler arasında bir fark netleşiyor.'), planOf('may resemble a crossroads'))).toBe('presumed_user_state');
    expect(coffeeForbiddenSpecificsTriggered(one('İnsanlar emeğini fark edecek.'), planOf('may resemble a standing person'))).toContain('other_person_action');
  });
});

// ---------------------------------------------------------------------------
// PART 11 — multi-beat composition: only the active classes, no third family
// ---------------------------------------------------------------------------
describe('C2.11A.1 — multi-beat composition', () => {
  const plan = () => packetFor(fishTree(), MONEY).storyPlan;
  it('opening + growth license exactly those two classes', () => {
    expect([...coffeeActiveDevelopmentClasses(plan())].sort()).toEqual(['growth', 'opening']);
    expect(coffeeUnsupportedDevelopments(one('Kapına küçük bir kısmet gelecek, sonra yavaş yavaş büyüyüp seni şaşırtacak.'), plan())).toEqual([]);
  });
  it.each([
    ['news', 'Kapına küçük bir kısmet gelecek ve güzel bir haber alacaksın.', 'communication'],
    ['solution', 'Kapına küçük bir kısmet gelecek ve bir çözüm belirecek.', 'way_through'],
    ['travel', 'Kapına küçük bir kısmet gelecek ve bir yolculuk çıkacak.', 'direction'],
    ['relationship', 'Kapına küçük bir kısmet gelecek ve yeni bir bağ kurulacak.', 'commitment'],
    ['people', 'Kapına küçük bir kısmet gelecek ve yeni insanlarla tanışacaksın.', 'people'],
  ] as const)('a third family (%s) is rejected', (_label, sentence, foreign) => {
    expect(coffeeUnsupportedDevelopments(one(sentence), plan())).toEqual([foreign]);
  });
  it('people recognition is rejected even in a multi-beat plan', () => {
    expect(coffeeForbiddenSpecificsTriggered(one('Kısmetin büyüdükçe çevrendekiler emeğini takdir edecek.'), plan())).toContain('other_person_action');
  });
});

// ---------------------------------------------------------------------------
// PART 4–6 — a trusted SUBJECT is not a trusted STATE
// ---------------------------------------------------------------------------
describe('C2.11A.1 — invented current user state', () => {
  it.each([
    ['financial', 'Bir kenara koyduğun para bereketlenecek.', MONEY, fishTree],
    ['financial', 'Birikimin yavaş yavaş artacak.', MONEY, fishTree],
    ['financial', 'Mevcut birikimin seni rahatlatacak.', MONEY, fishTree],
    ['financial', 'Zaten ayırdığın para işine yarayacak.', MONEY, fishTree],
    ['career', 'Ekibin seni yeni bir göreve hazırlıyor.', CAREER, fish],
    ['career', 'Projen sana yeni bir kapı açacak.', CAREER, fish],
    ['career', 'Mesai arkadaşların arasında yeni bir dönem başlıyor.', CAREER, fish],
    ['love', 'Hoşlandığın kişi seninle yakınlaşacak.', 'Aşk ve ilişkilerim hakkında', fish],
  ] as const)('%s state: "%s"', (kind, sentence, intention, obs) => {
    expect(coffeeInventedCurrentState(one(sentence), packetFor(obs(), intention).storyPlan)).toContain(kind);
  });

  it.each([
    ['future financial room', 'Elinde daha uzun kalan bir rahatlığın başladığı günlere yaklaşıyorsun.', MONEY, fishTree],
    ['future retention', 'Kazancını tutabileceğin daha ferah bir döneme giriyorsun.', MONEY, fishTree],
    ['career development without coworkers', 'İşinde önüne yeni bir kapı aralanacak.', CAREER, fish],
  ] as const)('a future development is not a state: %s', (_label, sentence, intention, obs) => {
    expect(coffeeInventedCurrentState(one(sentence), packetFor(obs(), intention).storyPlan)).toEqual([]);
  });

  it('a literally declared relationship may name the partner; the Love category may not', () => {
    const declared = packetFor(pair('may resemble a ring'), 'Eşimle olan ilişkim hakkında').storyPlan;
    const category = packetFor(pair('may resemble a ring'), 'Aşk ve ilişkilerim hakkında').storyPlan;
    expect(coffeeForbiddenSpecificsTriggered(one('Eşinle aranda yeni bir sıcaklık başlayacak.'), declared)).toEqual([]);
    expect(coffeeForbiddenSpecificsTriggered(one('Sevgilinle aranda yeni bir sıcaklık başlayacak.'), category)).toContain('exact_person');
  });
});

// ---------------------------------------------------------------------------
// PART 7 — exact person, relationship history, other-person intent/action
// ---------------------------------------------------------------------------
describe('C2.11A.1 — exact person, history, other-person intent and action', () => {
  const general = () => planOf('may resemble a fish', 'Önümüzdeki dönem genel olarak');
  it.each(['Sevgilin sana sürpriz yapacak.', 'Eski sevgilin aklına düşecek.', 'Arkadaşın yeni bir fikirle gelecek.', 'Patronun bir öneride bulunacak.', 'Yöneticin seni çağıracak.', 'Ailenden biri sana yardım edecek.'])(
    'exact_person: "%s"', (sentence) => {
      expect(coffeeForbiddenSpecificsTriggered(one(sentence), general())).toContain('exact_person');
    },
  );
  it.each(['Eski ilişkin yeniden gündeme gelecek.', 'Ayrıldığınız günden beri bir şey değişti.', 'Barışmanız mümkün görünüyor.', 'Yeniden bir araya gelmeniz söz konusu.'])(
    'relationship_history (even with a declared current relationship): "%s"', (sentence) => {
      expect(coffeeForbiddenSpecificsTriggered(one(sentence), planOf('may resemble a ring', 'Eşimle olan ilişkim hakkında'))).toContain('relationship_history');
    },
  );
  it.each(['Onun niyeti seni şaşırtacak.', 'Biri seni istiyor.', 'Karşı tarafın planı netleşecek.'])('other_person_intent: "%s"', (sentence) => {
    expect(coffeeForbiddenSpecificsTriggered(one(sentence), general())).toContain('other_person_intent');
  });
  it.each(['İnsanlar emeğini fark edecek.', 'Herkes başarından bahsedecek.', 'Birileri seni seçecek.', 'Emeğin takdir edilecek.', 'Adın daha sık anılacak.', 'Çevrendekiler sana destek verecek.'])(
    'other_person_action (no beat licenses it): "%s"', (sentence) => {
      expect(coffeeForbiddenSpecificsTriggered(one(sentence), general())).toContain('other_person_action');
    },
  );
  it.each(['Kendi emeğinle yeni bir kapı aralayacaksın.', 'Arkadaşça bir hava günlerine renk katacak.', 'Dostluğun değeri sende daha belirgin hissedilecek.'])(
    'ordinary language is not an invented person or action: "%s"', (sentence) => {
      expect(coffeeForbiddenSpecificsTriggered(one(sentence), general()).filter((value) => ['exact_person', 'other_person_action', 'other_person_intent'].includes(value))).toEqual([]);
    },
  );
});

// ---------------------------------------------------------------------------
// PART 7 — complete forbidden-specific coverage table
// ---------------------------------------------------------------------------
type Coverage = { enforcement: 'deterministic' | 'partial' | 'prompt_only'; where: string; probe?: string; reason?: string };
const COVERAGE: Record<CoffeeForbiddenSpecific, Coverage> = {
  exact_person: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/exact_person (roles; no arbitrary proper-name NER)', probe: 'Arkadaşın yeni bir fikirle gelecek.' },
  sender_identity: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/SENDER_RULES', probe: 'Eski sevgilinden bir mesaj gelebilir.' },
  employer_or_company: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/EMPLOYER_RULES', probe: 'İşverenin sana teklif yapacak.' },
  monetary_amount: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/AMOUNT_RULES', probe: '5 bin lira gelebilir.' },
  salary_or_debt: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/SALARY_DEBT', probe: 'Borcun kapanacak.' },
  payment_event: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/PAYMENT_RULES', probe: 'Hesabına para yatacak.' },
  exact_event: { enforcement: 'partial', where: 'prompt + beat contract; cross-beat event CLASSES rejected by coffeeFortuneDevelopmentFailure', reason: 'an open-ended event classifier has unbounded false-positive risk' },
  relationship_history: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/RELATIONSHIP_HISTORY', probe: 'Eski ilişkin yeniden gündeme gelecek.' },
  other_person_feelings: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/OTHER_FEELINGS (+ person-of-interest gate)', probe: 'Onun duyguları değişiyor.' },
  other_person_intent: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/OTHER_INTENT (+ coffeeOtherAgency, person gate)', probe: 'Onun niyeti seni şaşırtacak.' },
  other_person_action: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/OTHER_ACTION', probe: 'İnsanlar emeğini fark edecek.' },
  guaranteed_contact: { enforcement: 'partial', where: 'explicit certainty (kesinlikle / mutlaka / bare "olacak") via coffeeClaimSafetyFailure guaranteed_outcome; person-of-interest contact via coffeePersonIntentionClaim', reason: 'plain fortune-teller future tense ("bir haber alacaksın") stays stylistic: treating it as certainty would force robotic hedging' },
  guaranteed_outcome: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure (forbiddenAssumptions.guaranteed_outcome)' },
  date: { enforcement: 'deterministic', where: 'coffeeForbiddenSpecificsTriggered/DATE_RULES', probe: 'Üç gün içinde bir haber gelecek.' },
  chronology: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure (forbiddenAssumptions.chronology)' },
  unsupported_causation: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure causation (+ C2.7C.1 inter-proposition gate)' },
  prior_problem: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure (forbiddenAssumptions.prior_problem)' },
  travel_or_relocation: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure travel/relocation (movement plans) + development class "direction" elsewhere' },
  invented_options: { enforcement: 'deterministic', where: 'coffeeClaimSafetyFailure options_assumption (+ development class "alternatives")' },
};

describe('C2.11A.1 — forbidden-specific coverage table (no member forgotten)', () => {
  it('covers every CoffeeForbiddenSpecific any beat can carry', () => {
    const carried = new Set<string>();
    for (const resemblance of ['may resemble a small bird', 'may resemble a folded letter', 'may resemble a fish', 'may resemble a ring', 'may resemble a heart', 'may resemble a key', 'may resemble a winding path', 'may resemble a tree', 'may resemble a crossroads', 'may resemble a standing person']) {
      const plan = planOf(resemblance);
      for (const specific of plan.fortune!.lead.forbiddenSpecifics) carried.add(specific);
    }
    expect([...carried].sort()).toEqual(Object.keys(COVERAGE).sort());
  });

  it.each(Object.entries(COVERAGE).filter(([, value]) => value.probe))('%s is caught deterministically', (specific, value) => {
    const plan = planOf(specific === 'sender_identity' ? 'may resemble a small bird' : 'may resemble a fish');
    expect(coffeeForbiddenSpecificsTriggered(one(value.probe!), plan)).toContain(specific);
  });

  it('every non-deterministic member documents why', () => {
    for (const [, value] of Object.entries(COVERAGE)) {
      if (value.enforcement !== 'deterministic') expect(value.reason?.length).toBeGreaterThan(20);
    }
  });
});

// ---------------------------------------------------------------------------
// PART 12 / 13 — repair and precedence
// ---------------------------------------------------------------------------
describe('C2.11A.1 — repair and precedence', () => {
  it('repair gets the allowed and imported development classes, never prose or raw source', () => {
    const packet = packetFor(fish(), CAREER);
    const rejected = one('Yakında güzel bir haber alacaksın ve önüne yeni bir kapı açılacak.');
    const repair = buildCoffeeRepairPlan(rejected, 'unsupported_fortune_development', packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(repair.defect.kind).toBe('fortune_realization');
    expect(repair.allowedDevelopments).toEqual(['opening']);
    expect(repair.unsupportedDevelopmentsTriggered).toEqual(['communication']);
    expect(repair.storyPlan.fortune?.lead.kind).toBe('opening_emerges');
    expect(repair.subject?.kind).toBe('career_work');
    const text = JSON.stringify(repair);
    expect(text).not.toContain('güzel bir haber');
    expect(text).not.toMatch(/"(description|resemblance|region|sourceSlot|confidence|visibility)"|may resemble|private compact/);
  });

  it('a cross-beat import outranks meta, parroting, restatement, redundancy and length', () => {
    const plan = packetFor(fish(), CAREER).storyPlan;
    const short = narrativeOf({ visualObservation: 'Kısa.', overall: 'Yakında güzel bir haber alacaksın.', career: 'İşinde bir kıpırtı.', takeaway: 'Kısa.' });
    expect(coffeeQualityFailure(short, 'tr', { intention: CAREER }, fish().evidence, plan)).toBe('unsupported_fortune_development');
  });

  it('more specific serious codes stay ahead of the development gate', () => {
    const plan = packetFor(fish(), CAREER).storyPlan;
    expect(coffeeClaimSafetyFailure(one('İşverenin sana güzel bir haber verecek.'), plan)).toBe('unsupported_specific_detail');
  });

  it('writer and repair prompts carry beat binding', () => {
    expect(coffeeWriterSystem('tr')).toContain('BEAT BINDING');
    expect(coffeeWriterSystem('tr')).toContain('a TOPIC, not a STATE');
    expect(repairWriterSystem('coffee', 'tr')).toContain('unsupportedDevelopmentsTriggered');
  });
});
