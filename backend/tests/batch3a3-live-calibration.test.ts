/**
 * BATCH 3A.3 — real Batch 3A.2 QA outputs as calibration fixtures.
 * Texts are the exact live user-visible fields. Not rewritten.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  evaluateCoffeeQuality,
  evaluatePalmQuality,
  hasStockAdvice,
  ideaClusterRepeats,
  palmLineAttributeReuse,
  themeDominates,
} from '../src/ai/human-quality.js';
import { coffeeWriterSystem, palmWriterSystem } from '../src/ai/reading/writer-prompts.js';
import { bindCoffeeNarrative, bindPalmNarrative } from '../src/ai/reading/evidence-bind.js';
import type { CoffeeNarrative, PalmNarrative } from '../src/ai/reading/types.js';

const theme = ['karar verme'];

function load(name: string) {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8'));
}

function coffeeInput(n: CoffeeNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    language: 'tr' as const,
    relevantThemes: theme,
  };
}

function palmInput(n: PalmNarrative) {
  return {
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    lifeLine: n.lifeLine.text,
    headLine: n.headLine.text,
    heartLine: n.heartLine.text,
    fateLine: n.fateLine.text,
    takeaway: n.takeaway.text,
    language: 'tr' as const,
    trustedHandSide: true,
    relevantThemes: theme,
  };
}

describe('BATCH 3A.3 — live QA coffee must fail for structural defects', () => {
  const live = load('coffee_live_3a2');
  const n = live.narrative as CoffeeNarrative;
  const input = coffeeInput(n);

  it('detects theme domination, repeated advice, and stock coaching — not a hash match', () => {
    expect(themeDominates(theme, [n.overall.text, n.nearFuture.text, n.takeaway.text])).toBe(true);
    expect(ideaClusterRepeats([n.overall.text, n.nearFuture.text, n.takeaway.text])).toBe(true);
    expect(hasStockAdvice([n.nearFuture.text, n.takeaway.text])).toBe(true);
    const quality = evaluateCoffeeQuality(input);
    expect(['theme_domination', 'section_redundancy', 'stock_advice']).toContain(quality);
  });

  it('keeps visualObservation available internally while the paid lead is overall', () => {
    expect(n.visualObservation.text.startsWith('Fincanın dibindeki yoğun tortu')).toBe(true);
    expect(n.overall.text.startsWith('Fatih')).toBe(true);
    expect(n.overall.text.startsWith('Fincanın')).toBe(false);
  });
});

describe('BATCH 3A.3 — live QA palm must fail for structural defects', () => {
  const live = load('palm_live_3a2');
  const n = live.narrative as PalmNarrative;
  const input = palmInput(n);

  it('detects head-line attribute reuse, decision repetition, and stock coaching', () => {
    expect(palmLineAttributeReuse(input)).toBe(true);
    expect(ideaClusterRepeats([n.overall.text, n.headLine.text, n.takeaway.text])).toBe(true);
    expect(hasStockAdvice([n.takeaway.text])).toBe(true);
    const quality = evaluatePalmQuality(input);
    expect(['evidence_reuse', 'section_redundancy', 'stock_advice', 'theme_domination']).toContain(
      quality,
    );
  });
});

describe('BATCH 3A.3 — same evidence and theme can still pass when additive', () => {
  const coffee = load('coffee_good_3a3');
  const palm = load('palm_good_3a3');

  it('GOOD coffee stays grounded, ignores theme domination, and binds', () => {
    expect(evaluateCoffeeQuality(coffeeInput(coffee.narrative))).toBeNull();
    expect(bindCoffeeNarrative(coffee.narrative, coffee.observation, 'tr', {
      firstName: 'Fatih',
      relevantThemes: theme,
    })).toBeNull();
  });

  it('GOOD palm does not restate head-line morphology in both synthesis sections', () => {
    expect(evaluatePalmQuality(palmInput(palm.narrative))).toBeNull();
    expect(bindPalmNarrative(palm.narrative, palm.observation, 'tr', true, {
      firstName: 'Fatih',
      relevantThemes: theme,
    })).toBeNull();
  });

  it('writer contract treats theme as optional lens and bans stock closings', () => {
    const coffeePrompt = coffeeWriterSystem('tr');
    const palm = palmWriterSystem('tr');
    expect(coffeePrompt).toContain('subtle contextual lens');
    expect(coffeePrompt).toContain('ignore it entirely');
    expect(palm).toContain('must not re-describe the same length');
    expect(coffeePrompt).toContain('generic coaching formulas');
  });

  it('same weak theme does not force Coffee and Palm onto the same coaching close', () => {
    const coffeeLive = load('coffee_live_3a2').narrative as CoffeeNarrative;
    const palmLive = load('palm_live_3a2').narrative as PalmNarrative;
    expect(hasStockAdvice([coffeeLive.takeaway.text, coffeeLive.nearFuture.text])).toBe(true);
    expect(hasStockAdvice([palmLive.takeaway.text])).toBe(true);
    expect(hasStockAdvice([coffee.narrative.takeaway.text])).toBe(false);
    expect(hasStockAdvice([palm.narrative.takeaway.text])).toBe(false);
    expect(themeDominates(theme, [coffee.narrative.overall.text, coffee.narrative.takeaway.text])).toBe(
      false,
    );
  });
});
