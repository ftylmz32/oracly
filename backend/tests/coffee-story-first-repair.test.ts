/**
 * Story-first Coffee — repair / diversity semantics.
 * Density-only context is never mandatory new material, and a valid
 * single-sign cup is not "collapsed" just because every section cites it.
 */

import { describe, expect, it } from 'vitest';
import {
  coffeeEvidenceConcentration,
  coffeeRepairFocus,
  coffeeSemanticEvidence,
} from '../src/ai/reading/coffee-diversity.js';
import { coffeeWriterSystem, palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { ReadingEvidenceItem } from '../src/ai/reading/types.js';

function ev(id: string, region: string, description: string, resemblance: string | null = null): ReadingEvidenceItem {
  return { id, region, description, confidence: 'medium', visibility: 'clear', resemblance };
}

function sections(overall: string[], nearFuture: string[], takeaway: string[]) {
  return {
    overall: { text: 'Yıldız seni öne çıkaracak bir kısmete işaret ediyor.', evidenceIds: overall },
    nearFuture: { text: nearFuture.length ? 'Üst tarafta olması bunun yakında geleceğini söylüyor.' : '', evidenceIds: nearFuture },
    takeaway: { text: 'Yıldızın beş ucu bu takdirin birden fazla yerden geleceğini anlatıyor.', evidenceIds: takeaway },
  };
}

const STAR = [
  ev('e1', 'upper_wall', 'A small compact shape with five short points radiating from a centre, high on the upper wall.', 'may resemble a small star'),
  ev('e2', 'base', 'A thick dark mass of grounds covering most of the base.'),
  ev('e3', 'middle_wall', 'Light uneven smears across the middle wall.'),
];

describe('coffee semantic evidence', () => {
  it('separates signs with their own meaning from density-only context', () => {
    expect(STAR.map(coffeeSemanticEvidence)).toEqual([true, false, false]);
    expect(coffeeSemanticEvidence(ev('e1', 'base', 'Dense grounds gathered at the base.'))).toBe(false);
    expect(coffeeSemanticEvidence(ev('e1', 'upper_wall', 'Many small scattered dots and specks across the upper wall.'))).toBe(false);
    expect(coffeeSemanticEvidence(ev('e1', 'middle_wall', 'A long thin line winding up toward the rim.'))).toBe(true);
    expect(coffeeSemanticEvidence(ev('e1', 'rim', 'A clean open band just below the rim.'))).toBe(true);
    expect(coffeeSemanticEvidence(ev('e1', 'handle_side', 'A medium patch of grounds next to the handle.'))).toBe(true);
  });
});

describe('coffee concentration — single-sign cups', () => {
  it('a one-sign cup may cite the same sign in every meaning section', () => {
    expect(coffeeEvidenceConcentration(sections(['e1'], ['e1'], ['e1']), STAR)).toBe(false);
  });

  it('a rim-led reading may add same-region dots as small details', () => {
    const dots = [
      ev('e1', 'rim', 'A thin clean band just below the mouth of the cup.'),
      ev('e2', 'upper_wall', 'Many small scattered dots and specks across the upper wall.'),
      ev('e3', 'base', 'A moderately dense layer of grounds at the base.'),
    ];
    expect(coffeeEvidenceConcentration(sections(['e1'], ['e1'], ['e2']), dots)).toBe(false);
    // Led by the dots alone (context), it is still concentration.
    expect(coffeeEvidenceConcentration(sections(['e2'], ['e2'], ['e2']), dots)).toBe(true);
  });

  it('still flags concentration when another semantic sign is left unused', () => {
    const road = [
      ev('e1', 'middle_wall', 'A long thin line of grounds winding up toward the rim.', 'may resemble a road'),
      ev('e2', 'base', 'A small dense cluster at the base.'),
      ev('e3', 'rim', 'A clean open band just below the rim.'),
    ];
    expect(coffeeEvidenceConcentration(sections(['e1'], ['e1'], ['e1']), road)).toBe(true);
  });

  it('still flags a reading stretched over density-only context', () => {
    const thin = [ev('e1', 'base', 'A single dense mass at the base.'), ev('e2', 'upper_wall', 'Sparse marks.')];
    expect(coffeeEvidenceConcentration(sections(['e1'], ['e1'], ['e1']), thin)).toBe(true);
  });
});

describe('coffee repair focus — no backstory from the base', () => {
  it('never offers a dark base or smears as new material', () => {
    const focus = coffeeRepairFocus(sections(['e1'], ['e1'], ['e1']), STAR);
    expect(focus).not.toMatch(/clusters not already carrying overall: .*base/);
    expect(focus).toContain('No unused grounded evidence with its own meaning remains');
    expect(focus).toContain('Evidence e2, e3 is density/residue context only');
    expect(focus).toContain('never creates backstory');
    expect(focus).not.toContain('materially new claim from unused grounded evidence');
  });

  it('points at an unused semantic sign when one exists', () => {
    const road = [
      ev('e1', 'middle_wall', 'A long thin line winding up toward the rim.', 'may resemble a road'),
      ev('e2', 'base', 'A small dense cluster at the base.'),
      ev('e3', 'rim', 'A clean open band just below the rim.'),
    ];
    const focus = coffeeRepairFocus(sections(['e1'], ['e1'], ['e1']), road);
    expect(focus).toContain('not already carrying overall: upper.');
    expect(focus).toContain('Evidence e2 is density/residue context only');
  });

  it('coffee repair inherits the writer rule; palm repair does not carry it', () => {
    expect(repairWriterSystem('coffee')).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(repairWriterSystem('palm')).not.toContain('DENSE/DARK BASE');
  });
});

describe('coffee writer — plain context is not a story engine', () => {
  it('bounds what context evidence may say and forbids ya-da menus (coffee only)', () => {
    const prompt = coffeeWriterSystem('tr');
    expect(prompt).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(prompt).toContain('Tell the life consequence, never a visual reason');
    expect(prompt).toContain('possibility menu');
    expect(palmWriterSystem('tr')).not.toContain('PLAIN CONTEXT');
  });
});
