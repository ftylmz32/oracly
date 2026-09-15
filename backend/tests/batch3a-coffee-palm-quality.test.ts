/**
 * BATCH 3A — Coffee/Palm interpretation quality.
 *
 * Root cause fixed: the writer's `visualObservation` section (and, before
 * this batch, an anchor-forcing check in human-quality.ts) pushed cup
 * position / residue / line-shape vocabulary into the FINAL narrative,
 * which evidence-bind.ts's toPublicCoffee/toPublicPalm then return
 * verbatim to the client. These tests prove: (1) genuinely
 * observation-heavy output is now rejected, (2) grounded-but-meaningful
 * output is accepted, (3) real grounding (evidenceId binding against the
 * private observer evidence) is unaffected — an unbound/invented claim
 * still fails even when the prose reads well.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  bindCoffeeNarrative,
  bindPalmNarrative,
  toPublicCoffee,
  toPublicPalm,
} from '../src/ai/reading/evidence-bind.js';
import { evaluateCoffeeQuality, evaluatePalmQuality } from '../src/ai/human-quality.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  PalmNarrative,
  PalmObservation,
} from '../src/ai/reading/types.js';

type CoffeeFixture = { observation: CoffeeObservation; narrative: CoffeeNarrative };
type PalmFixture = { observation: PalmObservation; narrative: PalmNarrative };

function loadCoffee(name: string): CoffeeFixture {
  return JSON.parse(
    readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8'),
  ) as CoffeeFixture;
}

function loadPalm(name: string): PalmFixture {
  return JSON.parse(
    readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8'),
  ) as PalmFixture;
}

function coffeeQualityInput(n: CoffeeNarrative, language: 'tr' | 'en' | 'ru' = 'tr') {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    language,
  };
}

function palmQualityInput(n: PalmNarrative, language: 'tr' | 'en' | 'ru' = 'tr') {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    lifeLine: n.lifeLine.text,
    headLine: n.headLine.text,
    heartLine: n.heartLine.text,
    fateLine: n.fateLine.text,
    takeaway: n.takeaway.text,
    language,
    trustedHandSide: false,
  };
}

describe('BATCH 3A — Coffee quality gate', () => {
  const good = loadCoffee('coffee_good');

  it('GOOD: grounded evidence transformed into coherent personal meaning is accepted', () => {
    expect(evaluateCoffeeQuality(coffeeQualityInput(good.narrative))).toBeNull();
    expect(bindCoffeeNarrative(good.narrative, good.observation, 'tr')).toBeNull();
  });

  it('BAD 1: observation-heavy / residue report is rejected', () => {
    const bad = loadCoffee('coffee_bad_observation_heavy');
    expect(evaluateCoffeeQuality(coffeeQualityInput(bad.narrative))).toBe('observation_heavy');
    expect(bindCoffeeNarrative(bad.narrative, bad.observation, 'tr')).toBe('human_quality');
  });

  it('BAD 2: generic cliché reading with almost no evidence transformation is rejected', () => {
    const bad = loadCoffee('coffee_bad_generic_cliche');
    expect(evaluateCoffeeQuality(coffeeQualityInput(bad.narrative))).not.toBeNull();
    expect(bindCoffeeNarrative(bad.narrative, bad.observation, 'tr')).not.toBeNull();
  });

  it('BAD 3: repetitive interpretation (same idea restated with no new meaning) is rejected', () => {
    const bad = loadCoffee('coffee_bad_repetitive');
    expect(evaluateCoffeeQuality(coffeeQualityInput(bad.narrative))).toBe('duplicate_sections');
    expect(bindCoffeeNarrative(bad.narrative, bad.observation, 'tr')).toBe('human_quality');
  });

  it('raw evidence ids leaking into prose are rejected even when quality would pass', () => {
    const leaked: CoffeeNarrative = {
      ...good.narrative,
      takeaway: {
        text: `${good.narrative.takeaway.text} (bkz. e2)`,
        evidenceIds: good.narrative.takeaway.evidenceIds,
      },
    };
    expect(bindCoffeeNarrative(leaked, good.observation, 'tr')).toBe('evidence_id_in_prose');
  });

  it('unbound / invented evidence is still rejected — grounding is not weakened', () => {
    const invented: CoffeeNarrative = {
      ...good.narrative,
      overall: {
        text: good.narrative.overall.text,
        evidenceIds: ['e1', 'not_a_real_id'],
      },
    };
    expect(bindCoffeeNarrative(invented, good.observation, 'tr')).toBe('unknown_evidence_id');
  });

  it('a section with visual wording but no evidenceIds is still rejected', () => {
    const missing: CoffeeNarrative = {
      ...good.narrative,
      overall: { text: good.narrative.overall.text, evidenceIds: [] },
    };
    expect(bindCoffeeNarrative(missing, good.observation, 'tr')).toBe('missing_evidence_ids');
  });

  it('the persisted/public payload is the interpretation, not an observer report', () => {
    const pub = toPublicCoffee(good.narrative);
    expect(pub.overall).toBe(good.narrative.overall.text);
    // No raw evidence array, no schema/observer vocabulary anywhere in the
    // fields a client (and therefore Journal/memory) actually receives.
    expect(JSON.stringify(pub)).not.toMatch(/evidenceId|"confidence"|"visibility"|\bobserver\b/i);
    expect(pub.symbols).toEqual([]);
  });
});

describe('BATCH 3A — Palm quality gate', () => {
  const good = loadPalm('palm_good');

  it('GOOD: grounded palm evidence transformed into nuanced interpretation is accepted', () => {
    expect(evaluatePalmQuality(palmQualityInput(good.narrative))).toBeNull();
    expect(bindPalmNarrative(good.narrative, good.observation, 'tr', false)).toBeNull();
  });

  it('BAD 1: line-description-heavy output ("heart line is...", "the line is long") is rejected', () => {
    const bad = loadPalm('palm_bad_line_description');
    expect(evaluatePalmQuality(palmQualityInput(bad.narrative))).toBe('observation_heavy');
    expect(bindPalmNarrative(bad.narrative, bad.observation, 'tr', false)).toBe('human_quality');
  });

  it('BAD 2: generic personality clichés are rejected', () => {
    const bad = loadPalm('palm_bad_generic_cliche');
    expect(evaluatePalmQuality(palmQualityInput(bad.narrative))).toBe('repeated_stock');
    expect(bindPalmNarrative(bad.narrative, bad.observation, 'tr', false)).toBe('human_quality');
  });

  it('BAD 3: unsupported deterministic claim (lifespan/death) is rejected', () => {
    const bad = loadPalm('palm_bad_unsafe_claim');
    expect(['unsupported_certainty', 'prohibited_claim']).toContain(
      evaluatePalmQuality(palmQualityInput(bad.narrative)),
    );
    expect(bindPalmNarrative(bad.narrative, bad.observation, 'tr', false)).toBe('human_quality');
  });

  it('repetition (a palm line section restated elsewhere) is rejected', () => {
    const repeated: PalmNarrative = {
      ...good.narrative,
      fateLine: good.narrative.heartLine,
    };
    expect(evaluatePalmQuality(palmQualityInput(repeated))).toBe('duplicate_sections');
  });

  it('unbound / invented palm evidence is still rejected — grounding is not weakened', () => {
    const invented: PalmNarrative = {
      ...good.narrative,
      overall: {
        text: good.narrative.overall.text,
        evidenceIds: ['p1', 'not_a_real_id'],
      },
    };
    expect(bindPalmNarrative(invented, good.observation, 'tr', false)).toBe('unknown_evidence_id');
  });

  it('the persisted/public payload is the interpretation, not a line-property report', () => {
    const pub = toPublicPalm(good.narrative);
    expect(pub.overall).toBe(good.narrative.overall.text);
    expect(JSON.stringify(pub)).not.toMatch(/evidenceId|"confidence"|"visibility"|\bobserver\b/i);
    expect(pub.symbols).toEqual([]);
  });
});
