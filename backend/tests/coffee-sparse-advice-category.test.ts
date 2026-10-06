/**
 * Story-first closure — real targeted14 defects (gpt-5.6-sol, low):
 *   A  sparse cups forced above their natural length (HANDLE not delivered)
 *   B  the sparse repair still saw a "70–120 words" target
 *   C  a plain connecting line became two life categories ("iki başlık")
 *   D  advice slipped through ("gözün kulağın yakınında olsun")
 *
 * Sparse floors (coffeeNarrativelySparse only), calibrated on all 34 saved
 * real sparse-cup stages: normal 30 / 50 / 10 (overall / lead / takeaway),
 * previous sparse 30 / 45 / 10, final sparse 20 / 35 / 8.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeAdviceVoice } from '../src/ai/human-quality.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { coffeeContextEventPromotion } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { coffeeVoiceRepairFocus, palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const t14 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted14.json', 'utf8'),
) as { cases: Record<string, Case> };
const BIRD = t14.cases.case2;
const ROAD = t14.cases.case4;
const HANDLE = t14.cases.case5;
const BRIDGE = t14.cases.case8;
const DOTS = t14.cases.case9;
const LOW = t14.cases.case10;
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const empty = { text: '', evidenceIds: [] as string[] };

describe('A. sparse length floors', () => {
  it('1. targeted14 HANDLE writer passes once its advice clause is removed', () => {
    const writer = structuredClone(HANDLE.stages[0].narrative);
    expect(HANDLE.stages[0].quality).toBe('too_short');
    expect(coffeeQualityFailure(writer, 'tr', undefined, HANDLE.evidence)).toBe('advice_voice');
    writer.overall.text = writer.overall.text.replace('; gözün kulağın yakınında olsun.', '.');
    expect(writer.overall.text.split(/\s+/).length).toBe(23);
    expect(coffeeQualityFailure(writer, 'tr', undefined, HANDLE.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(writer, observation(HANDLE.evidence), 'tr')).toBe('evidence_leak');
    const publicWriter = structuredClone(writer);
    publicWriter.visualObservation = { text: 'Ev ve yakın çevrendeki bağlar günlük hayatında daha görünür hâle geliyor.', evidenceIds: ['e1'] };
    publicWriter.overall = { text: 'Ev ve sana en yakın insanlar hayatında belirgin bir yer tutuyor. Günlük düzeninde önem kazanan gelişmeler uzak çevrelerden değil, doğrudan bu tanıdık halkadan geliyor. Etkisini hemen hissedeceğin yakın bağlar ön plana çıkarken daha uzaktaki konular bir süre daha hayatının kıyısında kalıyor.', evidenceIds: ['e1', 'e3'] };
    publicWriter.takeaway = { text: 'Yakın çevrendeki hareket, günlük hayatının merkezinde sakin ama belirgin bir değişim yaratıyor.', evidenceIds: ['e1'] };
    expect(coffeeQualityFailure(publicWriter, 'tr', undefined, HANDLE.evidence)).toBeNull();
    expect(bindCoffeeNarrative(publicWriter, observation(HANDLE.evidence), 'tr')).toBeNull();
  });

  it('2. targeted14 HANDLE repair: the 9-word takeaway is no longer too_short', () => {
    const repair = HANDLE.stages[1].narrative;
    expect(HANDLE.stages[1].quality).toBe('too_short');
    expect(repair.takeaway.text.split(/\s+/).length).toBe(9);
    // Length no longer hides the next defect: the repair is built from
    // caution ("-den çok", "kalmıyor", "değil, doğrudan") — a real catch.
    expect(coffeeQualityFailure(repair, 'tr', undefined, HANDLE.evidence)).toBe('caution_voice');
    const takeawayOnly = structuredClone(HANDLE.stages[0].narrative);
    takeawayOnly.overall.text = takeawayOnly.overall.text.replace('; gözün kulağın yakınında olsun.', '.');
    takeawayOnly.takeaway = repair.takeaway;
    expect(coffeeQualityFailure(takeawayOnly, 'tr', undefined, HANDLE.evidence)).not.toBe('too_short');
  });

  it('3. trivial generic sparse prose still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: { text: 'Telve kulp tarafında toplanmış.', evidenceIds: ['e1'] },
      overall: { text: 'Evinde güzel şeyler olacak, her şey yoluna girecek.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Yakınların seni sevindirecek.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, HANDLE.evidence)).toBe('too_short');
  });

  it('the lower floors apply ONLY to narratively sparse cups', () => {
    const writer = structuredClone(HANDLE.stages[0].narrative);
    writer.overall.text = writer.overall.text.replace('; gözün kulağın yakınında olsun.', '.');
    expect(coffeeQualityFailure(writer, 'tr', undefined, BIRD.evidence)).toBe('too_short');
  });
});

describe('B. sparse repair guidance has no 70–120 target', () => {
  it('a sparse too_short repair gets the concise focus, never 70–120', () => {
    const g = coffeeRepairGuidance('human_quality', HANDLE.stages[1].narrative, HANDLE.evidence, 'tr') ?? '';
    // The repair is accepted now, so build a genuinely too-short sparse reading.
    const short = structuredClone(HANDLE.stages[0].narrative);
    short.overall.text = 'Ev ve sana en yakın kişiler öne çıkıyor.';
    const gs = coffeeRepairGuidance('human_quality', short, HANDLE.evidence, 'tr')!;
    expect(gs).toContain('slightly below the minimum length for a sparse cup');
    expect(gs).toContain('at least 35 words together, overall at least 20, takeaway at least 8');
    for (const text of [g, gs]) expect(text).not.toContain('70–120');
  });

  it('non-sparse too_short states the real minimum, with no 70–120 padding target', () => {
    const focus = coffeeVoiceRepairFocus('too_short')!;
    expect(focus).not.toContain('70–120');
    expect(focus).toContain('at least 42 words together, overall at least 22, takeaway at least 10');
    expect(focus).toContain('Do not aim for a total length and do not pad');
  });
});

describe('C. a plain line cannot create life categories', () => {
  it('4. LOW-SYMBOL "iki başlık" fails (the section also cites the diagonal line)', () => {
    const overall = LOW.stages[0].narrative.overall;
    expect(overall.text).toContain('Hayatında birbirinden bağımsız duran iki başlık');
    expect(overall.evidenceIds).toEqual(['e1', 'e2', 'e3']);
    expect(coffeeContextEventPromotion([overall], LOW.evidence)).toContain('iki başlık');
    expect(coffeeQualityFailure(LOW.stages[0].narrative, 'tr', undefined, LOW.evidence)).toBe('context_event');
  });

  it('5. LOW-SYMBOL connection-only prose passes', () => {
    const n = structuredClone(LOW.stages[0].narrative);
    n.overall.text = n.overall.text.replace(
      'Hayatında birbirinden bağımsız duran iki başlık ortak bir noktada temas edecek.',
      'Ayrı duran iki taraf ortak bir noktada birbirine dokunacak.',
    );
    expect(coffeeQualityFailure(n, 'tr', undefined, LOW.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(LOW.evidence), 'tr')).toBe('evidence_leak');
    expect(mapCoffeeMeanings(observation(LOW.evidence), 'tr')).toEqual([]);
    const publicN = structuredClone(n);
    publicN.visualObservation = { text: 'Ayrı duran iki taraf arasında sınırlı ve sakin bir temas alanı oluşuyor.', evidenceIds: ['e1', 'e2', 'e3'] };
    publicN.overall = { text: 'Birbirinden ayrı duran iki taraf ortak bir noktada temas edecek. Bu temas kendi sınırları içinde kalırken iki tarafın birbirini doğrudan etkileyebileceği dar ama belirgin bir alan oluşturacak. Gelişme geniş bir değişime dönüşmeden, yalnızca aradaki bağlantıyı daha açık hâle getirecek.', evidenceIds: ['e1', 'e2', 'e3'] };
    publicN.nearFuture = empty;
    publicN.takeaway = { text: 'Bu sınırlı temas, iki taraf arasındaki bağlantıyı kısa sürede daha anlaşılır kılacak.', evidenceIds: ['e1', 'e2', 'e3'] };
    expect(coffeeQualityFailure(publicN, 'tr', undefined, LOW.evidence)).toBeNull();
    expect(bindCoffeeNarrative(publicN, observation(LOW.evidence), 'tr')).toBeNull();
  });

  it('a real sign may still relate two areas (BRIDGE "iki ayrı alanı")', () => {
    expect(last(BRIDGE).overall.text).toContain('iki ayrı alanı');
    expect(coffeeContextEventPromotion([last(BRIDGE).overall], BRIDGE.evidence)).toBeNull();
  });
});

describe('D. advice is not fortune', () => {
  it('6. HANDLE "gözün kulağın yakınında olsun" fails advice_voice', () => {
    expect(coffeeAdviceVoice(['Gelişmeler bu tanıdık halkanın içinde şekilleniyor; gözün kulağın yakınında olsun.'])).not.toBeNull();
    expect(coffeeQualityFailure(HANDLE.stages[0].narrative, 'tr', undefined, HANDLE.evidence)).toBe('advice_voice');
  });

  it('the other advice forms fail', () => {
    for (const s of [
      'Bu fırsatı kaçırma.',
      'Önüne gelen imkânı küçümsememendir.',
      'Dikkat et, acele etme.',
      'Hazır ol; yakınlarına zaman ayırmalısın.',
    ]) {
      expect(coffeeAdviceVoice([s])).not.toBeNull();
    }
  });

  it('future statements and direct address pass', () => {
    for (const s of [
      'Sana ulaşacak bir haber var.',
      'Bak, bu bağ genişleyip dallanmıyor; tek bir yönde ilerliyor.',
      'Yakında neyin neye bağlandığını daha açık biçimde göreceksin.',
      'Kısmetin kalabalıkta kaybolmadan doğrudan sana düşecek.',
    ]) {
      expect(coffeeAdviceVoice([s])).toBeNull();
    }
  });
});

describe('sparse cups told concisely pass', () => {
  it('7. concise grounded HANDLE (targeted14 writer, told without advice)', () => {
    const n = structuredClone(HANDLE.stages[0].narrative);
    n.overall.text = n.overall.text.replace('; gözün kulağın yakınında olsun.', '.');
    expect(bindCoffeeNarrative(n, observation(HANDLE.evidence), 'tr')).toBe('evidence_leak');
  });

  it('8. concise grounded DOTS (targeted14 delivered)', () => {
    expect(bindCoffeeNarrative(last(DOTS), observation(DOTS.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('9. current good ROAD / BRIDGE / BIRD still pass', () => {
  it('targeted14 delivered outputs bind', () => {
    for (const c of [ROAD, BRIDGE, BIRD]) {
      expect(coffeeQualityFailure(last(c), 'tr', undefined, c.evidence)).toBe('evidence_leak');
      expect(bindCoffeeNarrative(last(c), observation(c.evidence), 'tr')).toBe('evidence_leak');
    }

    const road = structuredClone(last(ROAD));
    road.visualObservation = { text: 'Önündeki süreç kesilmeden ilerliyor ve yakın zamanda görünür hâle geliyor.', evidenceIds: ['e1'] };
    road.overall = { text: 'Hayatındaki gelişmeler birkaç aşamadan geçerek kendi yönünü bulacak. Önündeki süreç kesilmeden ilerliyor ve gerçek bir devam alanı kazanıyor. Aradaki değişimler sonucu bozmayacak; ilerleyişin farklı biçimde şekillenmesine ve yeni bir açılım kazanmasına yardım edecek. Her aşama bir sonrakini daha anlaşılır hâle getirecek.', evidenceIds: ['e1'] };
    road.nearFuture = { text: 'Bu gelişme yakın zamanda görünür hâle gelecek ve önündeki aşamalardan biri kısa sürede netleşecek.', evidenceIds: ['e1'] };
    road.takeaway = { text: 'Sürecin sonunda önünde daha geniş ve kullanışlı bir fırsat alanı açılacak.', evidenceIds: ['e3'] };
    expect(bindCoffeeNarrative(road, observation(ROAD.evidence), 'tr')).toBeNull();

    const bridge = structuredClone(last(BRIDGE));
    bridge.visualObservation = { text: 'Ev ve yakın çevren günlük hayatında daha belirgin bir önem kazanıyor.', evidenceIds: ['e3'] };
    bridge.overall = { text: 'Ev ve yakın çevreni ilgilendiren bir gelişme günlük hayatının merkezine yerleşiyor. Bu tanıdık halka içinde önem kazanan bağlar sana daha açık bir yakınlık ve aidiyet duygusu getirecek. Etkisi uzak alanlardan değil, doğrudan kendi çevrenden hissedilecek.', evidenceIds: ['e3'] };
    bridge.nearFuture = empty;
    bridge.takeaway = { text: 'Yakın çevrendeki bu gelişme, ev hayatındaki dengeyi kısa sürede daha görünür kılacak.', evidenceIds: ['e3'] };
    expect(bindCoffeeNarrative(bridge, observation(BRIDGE.evidence), 'tr')).toBeNull();

    const bird = structuredClone(last(BIRD));
    bird.visualObservation = { text: 'Yakın zamanda sana ulaşacak belirgin bir iletişim gelişmesi öne çıkıyor.', evidenceIds: ['e1'] };
    bird.overall = { text: 'Sana ulaşacak belirgin bir haber günlük akışında hareket yaratacak. Bu iletişim kısa ve doğrudan gelecek; taşıdığı ana fikir dikkatini hemen kendine çekecek. Ardından önündeki gelişmenin hangi yönde ilerleyeceği daha açık hâle gelecek.', evidenceIds: ['e1'] };
    bird.nearFuture = empty;
    bird.takeaway = { text: 'Yakın zamanda gelen bu haber, önündeki gelişmenin yönünü açıkça belirginleştirecek.', evidenceIds: ['e1'] };
    expect(bindCoffeeNarrative(bird, observation(BIRD.evidence), 'tr')).toBeNull();
  });
});

describe('10. Palm untouched', () => {
  it('Palm prompts carry no Coffee sparse / advice rule', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('NARRATIVELY SPARSE');
      expect(text).not.toContain('gözün kulağın');
    }
  });
});
