/**
 * BATCH 3A.1 — Coffee/Palm personalization context + fake-memory guard.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  bindCoffeeNarrative,
  bindPalmNarrative,
} from '../src/ai/reading/evidence-bind.js';
import { evaluateCoffeeQuality, evaluatePalmQuality } from '../src/ai/human-quality.js';
import {
  buildCoffeeWriterPacket,
  buildPalmWriterPacket,
} from '../src/ai/reading/locale-vocab.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { coffeeWriterSystem, palmWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  PalmNarrative,
  PalmObservation,
} from '../src/ai/reading/types.js';

// Reuse the already-validated BATCH 3A fixtures — known to clear every
// length/quality/grounding bar on their own, so any failure here is
// specifically about personalization/fake-memory, not fixture length.
const coffeeGood = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_good.json', 'utf8'),
) as { observation: CoffeeObservation; narrative: CoffeeNarrative };
const palmGood = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/palm_good.json', 'utf8'),
) as { observation: PalmObservation; narrative: PalmNarrative };

const coffeeObs = coffeeGood.observation;
const goodCoffeeNarrative = coffeeGood.narrative;
const palmObs = palmGood.observation;
const goodPalmNarrative = palmGood.narrative;

describe('BATCH 3A.1 — personalization parsing', () => {
  it('parses a bounded, valid personalization object', () => {
    const p = personalizationFromUnknown({
      personalization: {
        firstName: 'Ayşe',
        intention: 'İş değişikliği hakkında netlik arıyorum.',
        relevantThemes: ['karar verme', 'iş değişikliği'],
        memorySummary: 'Geçen ay kariyer konusunda kararsızlık ifade etmişti.',
      },
    });
    expect(p).toBeDefined();
    expect(p?.firstName).toBe('Ayşe');
    expect(p?.relevantThemes).toEqual(['karar verme', 'iş değişikliği']);
  });

  it('returns undefined when no personalization is supplied (missing context never blocks a reading)', () => {
    expect(personalizationFromUnknown({})).toBeUndefined();
    expect(personalizationFromUnknown({ personalization: {} })).toBeUndefined();
    expect(personalizationFromUnknown(null)).toBeUndefined();
  });

  it('caps oversized fields instead of rejecting the request', () => {
    const p = personalizationFromUnknown({
      personalization: {
        firstName: 'x'.repeat(500),
        intention: 'y'.repeat(5000),
        relevantThemes: ['a'.repeat(200), 'b', 'c', 'd', 'e', 'f'],
        memorySummary: 'z'.repeat(5000),
      },
    });
    expect(p?.firstName!.length).toBeLessThanOrEqual(40);
    expect(p?.intention!.length).toBeLessThanOrEqual(200);
    expect(p?.memorySummary!.length).toBeLessThanOrEqual(220);
    expect(p?.relevantThemes!.length).toBeLessThanOrEqual(3);
    expect(p?.relevantThemes![0].length).toBeLessThanOrEqual(40);
  });

  it('never stores anything resembling a raw Journal dump — a huge unrelated payload stays bounded', () => {
    const p = personalizationFromUnknown({
      personalization: { memorySummary: 'A'.repeat(100000) },
    });
    expect(JSON.stringify(p).length).toBeLessThan(300);
  });
});

describe('BATCH 3A.1 — writer packet includes/omits personalization correctly', () => {
  it('includes personalization when present', () => {
    const packet = buildCoffeeWriterPacket(coffeeObs, 'tr', {
      firstName: 'Deniz',
      intention: 'Bir konuda netlik arıyorum.',
    });
    expect(packet.personalization?.firstName).toBe('Deniz');
  });

  it('omits personalization entirely when absent — no empty object noise for the model', () => {
    const packet = buildCoffeeWriterPacket(coffeeObs, 'tr');
    expect(packet.personalization).toBeUndefined();
    expect(JSON.stringify(packet)).not.toContain('personalization');
  });

  it('same contract holds for palm', () => {
    const withP = buildPalmWriterPacket(palmObs, 'tr', null, { firstName: 'Kaya' });
    const withoutP = buildPalmWriterPacket(palmObs, 'tr', null);
    expect(withP.personalization?.firstName).toBe('Kaya');
    expect(withoutP.personalization).toBeUndefined();
  });
});

describe('BATCH 3A.1 — no personalization still produces a valid contract', () => {
  it('coffee narrative binds successfully with zero personalization', () => {
    expect(bindCoffeeNarrative(goodCoffeeNarrative, coffeeObs, 'tr')).toBeNull();
    expect(bindCoffeeNarrative(goodCoffeeNarrative, coffeeObs, 'tr', undefined)).toBeNull();
  });

  it('palm narrative binds successfully with zero personalization', () => {
    expect(bindPalmNarrative(goodPalmNarrative, palmObs, 'tr', false)).toBeNull();
  });
});

describe('BATCH 3A.1 — fake-memory guard', () => {
  it('rejects a coffee narrative that implies memory when none was supplied', () => {
    const withFakeMemory = {
      ...goodCoffeeNarrative,
      takeaway: {
        text: goodCoffeeNarrative.takeaway.text + ' Geçen okumanda da benzer bir şey görmüştük.',
        evidenceIds: goodCoffeeNarrative.takeaway.evidenceIds,
      },
    };
    expect(evaluateCoffeeQuality({
      visualObservation: withFakeMemory.visualObservation.text,
      overall: withFakeMemory.overall.text,
      love: withFakeMemory.love.text,
      career: withFakeMemory.career.text,
      money: withFakeMemory.money.text,
      nearFuture: withFakeMemory.nearFuture.text,
      takeaway: withFakeMemory.takeaway.text,
      language: 'tr',
    })).toBe('fake_memory');
    expect(bindCoffeeNarrative(withFakeMemory, coffeeObs, 'tr')).toBe('human_quality');
  });

  it('allows the same memory phrase ONLY when memorySummary was actually supplied', () => {
    const withFakeMemory = {
      ...goodCoffeeNarrative,
      takeaway: {
        text: goodCoffeeNarrative.takeaway.text + ' Geçen okumanda da benzer bir şey görmüştük.',
        evidenceIds: goodCoffeeNarrative.takeaway.evidenceIds,
      },
    };
    expect(
      bindCoffeeNarrative(withFakeMemory, coffeeObs, 'tr', {
        memorySummary: 'Bir önceki okumada da benzer bir kararsızlık öne çıkmıştı.',
      }),
    ).toBeNull();
  });

  it('rejects a palm narrative implying memory when none was supplied', () => {
    const withFakeMemory = {
      ...goodPalmNarrative,
      takeaway: {
        text: goodPalmNarrative.takeaway.text + ' Last time we spoke about this same pattern.',
        evidenceIds: goodPalmNarrative.takeaway.evidenceIds,
      },
    };
    expect(evaluatePalmQuality({
      visualObservation: withFakeMemory.visualObservation.text,
      overall: withFakeMemory.overall.text,
      lifeLine: '',
      headLine: '',
      heartLine: '',
      fateLine: '',
      takeaway: withFakeMemory.takeaway.text,
      language: 'tr',
      trustedHandSide: false,
    })).toBe('fake_memory');
  });

  it('a reading with no personalization at all never contains memory phrasing (good fixtures stay clean)', () => {
    expect(evaluateCoffeeQuality({
      visualObservation: goodCoffeeNarrative.visualObservation.text,
      overall: goodCoffeeNarrative.overall.text,
      love: goodCoffeeNarrative.love.text,
      career: goodCoffeeNarrative.career.text,
      money: goodCoffeeNarrative.money.text,
      nearFuture: goodCoffeeNarrative.nearFuture.text,
      takeaway: goodCoffeeNarrative.takeaway.text,
      language: 'tr',
    })).toBeNull();
  });
});

describe('BATCH 3A.1 — writer prompt personalization contract', () => {
  it('explains optional personalization usage without forcing it', () => {
    const c = coffeeWriterSystem('tr');
    expect(c).toContain('personalization');
    expect(c.toLowerCase()).toContain('firstname');
    expect(c.toLowerCase()).toContain('memorysummary');
    const p = palmWriterSystem('tr');
    expect(p).toContain('personalization');
  });

  it('still bans raw field names appearing as literal prose', () => {
    const c = coffeeWriterSystem('tr');
    expect(c).toContain('never as literal words in the reading');
  });
});
