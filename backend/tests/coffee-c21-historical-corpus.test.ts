import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { coffeePublicEvidenceLeak } from '../src/ai/human-quality.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingPersonalization } from '../src/ai/reading/types.js';

type HistoricalFixture = {
  productJudgement?: 'PASS' | 'WEAK';
  humanProductJudgement?: 'PASS' | 'WEAK';
  observation: CoffeeObservation;
  narrative: CoffeeNarrative;
  personalization?: ReadingPersonalization;
};

function load(name: string): HistoricalFixture {
  return JSON.parse(fs.readFileSync(path.join(process.cwd(), 'tests', 'fixtures', 'batch3a', name), 'utf8')) as HistoricalFixture;
}

describe('C2.1 historical real-provider Coffee corpus', () => {
  it('records previously passing outputs now rejected without editing fixtures', () => {
    const names = [
      ...Array.from({ length: 6 }, (_, i) => `coffee_qa_c14_case${i + 1}.json`),
      ...Array.from({ length: 8 }, (_, i) => `coffee_qa_c16_case${i + 1}.json`),
    ];
    const fixtures = names.map(load);
    const previouslyPass = fixtures.filter((fixture) =>
      (fixture.humanProductJudgement ?? fixture.productJudgement) === 'PASS',
    );
    const rejected = previouslyPass.filter((fixture) => coffeePublicEvidenceLeak([
      fixture.narrative.visualObservation.text,
      fixture.narrative.overall.text,
      fixture.narrative.love.text,
      fixture.narrative.career.text,
      fixture.narrative.money.text,
      fixture.narrative.nearFuture.text,
      fixture.narrative.takeaway.text,
    ], fixture.observation.evidence.map((item) => item.resemblance ?? '').filter(Boolean)));

    expect(fixtures).toHaveLength(14);
    expect(previouslyPass).toHaveLength(8);
    expect(rejected).toHaveLength(8);
  });
});
