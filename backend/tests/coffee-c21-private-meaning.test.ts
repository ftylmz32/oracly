import { describe, expect, it } from 'vitest';
import {
  buildCoffeeWriterPacket,
  mapCoffeeMeanings,
} from '../src/ai/reading/coffee-meaning-map.js';
import {
  adaptCoffeeV2ForWriter,
  bindCoffeeNarrative,
  coffeeQualityFailure,
  toPublicCoffee,
} from '../src/ai/reading/evidence-bind.js';
import { coffeePublicEvidenceLeak } from '../src/ai/human-quality.js';
import { buildPalmWriterPacket } from '../src/ai/reading/locale-vocab.js';
import { coffeeWriterSystem, palmWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  CoffeeV2Observation,
  PalmObservation,
  ReadingEvidenceItem,
} from '../src/ai/reading/types.js';

const checks = {
  cupInteriorVisible: true,
  adequateFocusLight: true,
  residueVisible: true,
  milkFoamObstruction: false,
  usefulRegionsVisible: true,
};

const evidence: ReadingEvidenceItem[] = [
  { id: 'e1', region: 'rim', description: 'bird-like mark', resemblance: 'bird', confidence: 'high', visibility: 'clear' },
  { id: 'e2', region: 'middle_wall', description: 'fish-like mark', resemblance: 'fish', confidence: 'high', visibility: 'clear' },
  { id: 'e3', region: 'middle_wall', description: 'ring-like mark', resemblance: 'ring', confidence: 'high', visibility: 'clear' },
  { id: 'e4', region: 'middle_wall', description: 'heart-like mark', resemblance: 'heart', confidence: 'high', visibility: 'clear' },
  { id: 'e5', region: 'middle_wall', description: 'key-like mark', resemblance: 'key', confidence: 'high', visibility: 'clear' },
  { id: 'e6', region: 'upper_wall', description: 'continuous route', resemblance: 'road', confidence: 'high', visibility: 'clear' },
  { id: 'e7', region: 'handle_side', description: 'plain cluster', resemblance: null, confidence: 'medium', visibility: 'partial' },
  { id: 'e8', region: 'base', description: 'odd silhouette', resemblance: 'purple dragon', confidence: 'high', visibility: 'clear' },
];

const observation: CoffeeObservation = { usable: true, checks, evidence };

describe('C2.1 private Coffee meaning handoff', () => {
  it('keeps raw V2 evidence internally, including source slots and raw labels', () => {
    const v2: CoffeeV2Observation = {
      usable: true,
      photoChecks: {
        cupPrimary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
        cupSecondary: { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, usefulRegionsVisible: true },
        saucer: { saucerVisible: true, adequateFocusLight: true, residueOrFlowVisible: true, usefulRegionsVisible: true },
      },
      evidence: evidence.slice(0, 3).map((item, index) => ({
        ...item,
        sourceSlot: (['cup_primary', 'cup_secondary', 'saucer'] as const)[index],
      })),
    };
    const adapted = adaptCoffeeV2ForWriter(v2);
    expect(adapted.evidence).toEqual(v2.evidence);
    expect(adapted.evidence[0]).toMatchObject({ id: 'e1', sourceSlot: 'cup_primary', description: 'bird-like mark', resemblance: 'bird' });
  });

  it('maps supported meanings with distinct evidence bindings and no raw writer fields', () => {
    const packet = buildCoffeeWriterPacket(observation, 'tr');
    expect(packet.facets.map((facet) => [facet.family, facet.evidenceIds])).toEqual([
      ['communication', ['e1']],
      ['opportunity', ['e2']],
      ['bond', ['e3']],
      ['emotional_relevance', ['e4']],
      ['solution', ['e5']],
      ['movement', ['e6']],
      ['home_close_circle', ['e7']],
    ]);
    expect(packet.facets[0].timing).toBe('nearer_term');
    expect(packet.facets[6].context).toBe('home_close_circle');
    const wire = JSON.stringify(packet);
    for (const forbidden of ['description', 'resemblance', 'region', 'regionLabel', 'regionVocabulary', 'sourceSlot', 'confidence', 'visibility', 'checks']) {
      expect(wire).not.toContain(forbidden);
    }
    for (const privateWord of ['bird', 'kuş', 'fish', 'balık', 'ring', 'yüzük', 'heart', 'kalp', 'key', 'anahtar', 'road', 'purple dragon']) {
      expect(wire.toLocaleLowerCase('tr-TR')).not.toContain(privateWord);
    }
  });

  it('omits an unknown resemblance without inventing a meaning', () => {
    const facets = mapCoffeeMeanings({ ...observation, evidence: [evidence[7]] }, 'tr');
    expect(facets).toEqual([]);
    expect(JSON.stringify(buildCoffeeWriterPacket({ ...observation, evidence: [evidence[7]] }, 'tr'))).not.toContain('purple dragon');
  });

  it('keeps strict narrative evidence-id binding', () => {
    const section = { text: 'Yakın zamanda yeni bir gelişme önüne geliyor ve yönünü değiştiriyor.', evidenceIds: ['e1'] };
    const narrative: CoffeeNarrative = {
      visualObservation: { text: 'Yakındaki gelişme günlük akışında yeni bir hareket yaratacak.', evidenceIds: ['e1'] },
      overall: section,
      love: { text: '', evidenceIds: [] },
      career: { text: '', evidenceIds: [] },
      money: { text: '', evidenceIds: [] },
      nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'Bu hareketin etkisi kısa sürede belirginleşecek.', evidenceIds: ['e1'] },
    };
    expect(bindCoffeeNarrative({ ...narrative, overall: { ...section, evidenceIds: ['invented'] } }, observation, 'tr')).toBe('unknown_evidence_id');
  });

  it('rejects evidence-analysis grammar in every narrative field without blocking life language', () => {
    expect(coffeePublicEvidenceLeak(['Bu sembol yeni bir haberi temsil eder.'])).toBe(true);
    expect(coffeePublicEvidenceLeak(['Fincanda kuş gördüm.'])).toBe(true);
    expect(coffeePublicEvidenceLeak(['Kuş çıkmış.'], ['bird', 'kuş'])).toBe(true);
    expect(coffeePublicEvidenceLeak(['Telve fincanın dibinde yoğunlaşmış.'])).toBe(true);
    expect(coffeePublicEvidenceLeak(['Önünde yeni bir yol açılıyor.'], ['road', 'yol'])).toBe(false);
    expect(coffeePublicEvidenceLeak(['Yakında beklediğin haber geliyor.'])).toBe(false);
    const safe: CoffeeNarrative = {
      visualObservation: { text: 'Yakındaki iletişim hareketi gündelik akışına kısa sürede yeni bir canlılık ve belirgin bir değişim katacak.', evidenceIds: ['e1'] },
      overall: { text: 'Yakında sana ulaşacak bir haber, önündeki sürece yeni bir yön verecek. İletişimin hız kazanması günlük akışına canlılık katarken gelişmenin etkisini de daha anlaşılır hale getirecek; konu doğal biçimde ilerleyecek. Gelen bilginin açtığı alan, sonraki adımlarında daha rahat hareket etmene ve gelişmenin farklı yönlerini zamanında görmene yardımcı olacak.', evidenceIds: ['e1'] },
      love: { text: '', evidenceIds: [] }, career: { text: '', evidenceIds: [] }, money: { text: '', evidenceIds: [] }, nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'İletişim hızlandıkça bu gelişmenin etkisi de kısa sürede açıkça belirginleşecek.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure({ ...safe, visualObservation: { ...safe.visualObservation, text: 'Fincanda kuş gördüm ve telve ağız kenarında açık biçimde duruyor.' } }, 'tr', undefined, evidence)).toBe('evidence_leak');
  });

  it('retains the public contract and empty symbol cards', () => {
    const n = {
      visualObservation: { text: 'Yakınındaki gelişme yeni bir hareket alanı açıyor.', evidenceIds: ['e1'] },
      overall: { text: 'Yakında alacağın bir haber, önündeki sürecin yönünü değiştirecek.', evidenceIds: ['e1'] },
      love: { text: '', evidenceIds: [] }, career: { text: '', evidenceIds: [] }, money: { text: '', evidenceIds: [] }, nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'Bu gelişme beklediğinden daha erken netleşecek.', evidenceIds: ['e1'] },
    } satisfies CoffeeNarrative;
    expect(Object.keys(toPublicCoffee(n)).sort()).toEqual(['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort());
    expect(toPublicCoffee(n).symbols).toEqual([]);
  });

  it('uses meaning-only Coffee prompts while Palm packet and prompt remain raw-evidence based', () => {
    const coffee = coffeeWriterSystem('tr');
    expect(coffee).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(coffee).toContain('RESULT FIRST');
    expect(coffee).not.toContain('bird cup');
    expect(coffee).not.toContain('where the telve gathered');

    const palm: PalmObservation = {
      usable: true,
      checks: { onePalmFacing: true, majorLinesVisible: true, adequateFocusLight: true, overlapOcclusion: false, dorsal: false },
      evidence: [{ id: 'p1', region: 'life_line', description: 'deep line', confidence: 'high', visibility: 'clear' }],
    };
    expect(buildPalmWriterPacket(palm, 'tr', null).evidence[0].description).toBe('deep line');
    expect(palmWriterSystem('tr')).toContain('validated visual evidence JSON');
  });
});
