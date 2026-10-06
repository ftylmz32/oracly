/**
 * Story-first closure — topology homogenization. Real targeted9: ROAD,
 * BRIDGE, LOW-SYMBOL and NO-SIGN all fell into one frame ("being carried
 * from where you are", "distance closing") with no trace of that wording in
 * the prompt — the generic "movement / distance closing" rule itself was the
 * engine. Each topology type now has its own affordance; "yorulur" is a
 * gate; base -> stability and handle -> status are explicit prompt rules.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeDictionaryVoice } from '../src/ai/human-quality.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { buildCoffeeWriterPacket, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Packet = { label: string; evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const t9 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted9.json', 'utf8'),
) as { cases: Record<string, Packet> };
const BIRD = t9.cases.case2;
const ROAD = t9.cases.case4;
const HANDLE = t9.cases.case5;
const BRIDGE = t9.cases.case8;
const DOTS = t9.cases.case9;
const LOW = t9.cases.case10;
const NO_SIGN = t9.cases.case12;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const writer = coffeeWriterSystem('tr');
const repair = repairWriterSystem('coffee');

/** The single frame the four topology cups converged on. */
const SHARED_FRAME = /bulundu[gğ]un (noktadan|yerden)|mesafe\w* (belirgin biçimde )?kapan|uzaklık kapan|aradaki mesafe/i;

describe('the homogenization was real (targeted9 evidence)', () => {
  it('four different topology structures converged on one frame', () => {
    for (const c of [ROAD, BRIDGE, LOW, NO_SIGN]) expect(meaning(c.narrative).join(' ')).toMatch(SHARED_FRAME);
  });

  it('the generic "movement / distance closing" rule that produced it is gone', () => {
    expect(writer).not.toContain('TOPOLOGY IS MOVEMENT');
    expect(writer).not.toContain('carries movement, connection, transition, direction, or distance closing or opening');
    expect(writer).not.toContain('it is news that does not leave the person where they are');
    expect(writer).not.toContain('a road cup with the movement');
    expect(coffeeVoiceRepairFocus('invented_plan')).not.toContain('distance closing');
  });
});

describe('1. ROAD and BRIDGE have different affordances', () => {
  it('a road is a course; a bridge is a link between two sides', () => {
    expect(mapCoffeeMeanings(observation(ROAD.evidence), 'tr').map((f) => f.family)).toContain('movement');
    expect(mapCoffeeMeanings(observation(BRIDGE.evidence), 'tr').map((f) => f.family)).not.toContain('movement');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
  });

  it('each cup is read from its own geometric distinction', () => {
    expect(JSON.stringify(buildCoffeeWriterPacket(observation(ROAD.evidence), 'tr'))).not.toMatch(/description|resemblance|region/);
    expect(JSON.stringify(buildCoffeeWriterPacket(observation(BRIDGE.evidence), 'tr'))).not.toMatch(/description|resemblance|region/);
  });
});

describe('2. BRIDGE never implies a prior separation', () => {
  it('writer and repair forbid an invented separation / estrangement', () => {
    expect(BRIDGE.narrative.overall.text).toContain('araya mesafe girmiş');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(repair).toContain('Never infer chronology, backstory, causation');
  });
});

describe('3. LOW-SYMBOL never becomes relocation or travel', () => {
  it('a plain connecting line is only a link between two visible regions', () => {
    expect(LOW.narrative.overall.text).toMatch(/başka bir tarafa taşıyan/);
    expect(writer).not.toContain(
      'PLAIN CONNECTING LINE between two otherwise plain regions (low-symbol cup): only a thin connection or directional link between those two visible regions — not relocation, travel, one side approaching the other socially, easier conditions or who moves first',
    );
    const lowFacets = mapCoffeeMeanings(observation(LOW.evidence), 'tr');
    expect(lowFacets).toEqual([]);
    expect(lowFacets.map((facet) => facet.family)).not.toContain('movement');
    expect(bindCoffeeNarrative(LOW.narrative, observation(LOW.evidence), 'tr')).not.toBeNull();
  });
});

describe('4. NO-SIGN does not default to distance closing', () => {
  it('handle-side origin + stopping short is the distinction, not distance closing', () => {
    expect(NO_SIGN.narrative.overall.text).toContain('aradaki mesafe belirgin biçimde kapanıyor');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(writer).not.toContain('if it stops short, that open, unfinished reach is the distinction — do not turn it into physical relocation, travel or distance closing');
    const noSignFacets = mapCoffeeMeanings(observation(NO_SIGN.evidence), 'tr');
    expect(noSignFacets.map((facet) => facet.family)).toEqual(['home_close_circle']);
    expect(noSignFacets.map((facet) => facet.family)).not.toContain('movement');
    expect(bindCoffeeNarrative(NO_SIGN.narrative, observation(NO_SIGN.evidence), 'tr')).not.toBeNull();
  });
});

describe('5/6. no "yorulur" dictionary voice (BIRD, BRIDGE)', () => {
  it('BIRD nearFuture "… erişeceğine yorulur" is rejected', () => {
    expect(coffeeDictionaryVoice([BIRD.narrative.nearFuture.text])).toContain('yorulur');
    expect(coffeeQualityFailure(BIRD.narrative, 'tr', undefined, BIRD.evidence)).toBe('dictionary_voice');
    expect(bindCoffeeNarrative(BIRD.narrative, observation(BIRD.evidence), 'tr')).toBe('human_quality');
  });

  it('BRIDGE overall "… temas kurulmasına yorulur" is caught (alongside its other defects)', () => {
    expect(coffeeDictionaryVoice(meaning(BRIDGE.narrative))).toContain('yorulur');
    const g = coffeeRepairGuidance('section_redundancy', BRIDGE.narrative, BRIDGE.evidence, 'tr')!;
    expect(g).toContain('dictionary_voice');
  });

  it('a falcı attribution ("derler", "diye okunur derler") is not the dictionary verb', () => {
    expect(coffeeDictionaryVoice(['Kuş haber diye okunur derler; ağza yakın durduğu için haber uzakta değil.'])).toBeNull();
    expect(coffeeDictionaryVoice(['Balık kısmettir derler.'])).toBeNull();
  });

  it('writer and repair focus ask for direct telling', () => {
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(coffeeVoiceRepairFocus('dictionary_voice')).toContain('direct fortune telling');
  });
});

describe('7. DOTS — base context never becomes stability / established order', () => {
  it('the rule is explicit in writer and repair', () => {
    expect(DOTS.narrative.overall.text).toContain('asıl düzenin aynı yerde duruyor');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(repair).not.toContain('A dense or dark base never becomes stability, an established order or things staying in place');
    const dotFacets = mapCoffeeMeanings(observation(DOTS.evidence), 'tr');
    expect(dotFacets).toEqual([]);
    expect(JSON.stringify(dotFacets)).not.toMatch(/stability|established|düzen/);
    expect(bindCoffeeNarrative(DOTS.narrative, observation(DOTS.evidence), 'tr')).not.toBeNull();
  });
});

describe('8. HANDLE — a location cue is not a status cue', () => {
  it('the handle side never proves standing / influence / the weight of a word', () => {
    expect(HANDLE.narrative.takeaway.text).toContain('sözüne verilen değer');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(repair).not.toContain("it never proves the person's standing, influence or the weight of their word");
    const handleFacets = mapCoffeeMeanings(observation(HANDLE.evidence), 'tr');
    expect(handleFacets.map((facet) => facet.family)).toEqual(['home_close_circle']);
    expect(JSON.stringify(handleFacets)).not.toMatch(/standing|influence|status|agency|sözünün ağırlığı/);
    expect(bindCoffeeNarrative(HANDLE.narrative, observation(HANDLE.evidence), 'tr')).not.toBeNull();
  });
});

describe('Palm untouched', () => {
  it('no topology / dictionary rule reaches Palm', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('EACH TOPOLOGY TYPE HAS ITS OWN AFFORDANCE');
      expect(text).not.toContain('TOPOLOGY AND LOCATION IN REPAIR');
      expect(text).not.toContain('yorulur');
    }
  });
});
