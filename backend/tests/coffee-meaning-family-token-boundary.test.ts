import { describe, expect, it } from 'vitest';
import { coffeeMeaningFamily } from '../src/ai/reading/coffee-meaning-map.js';
import type { ReadingEvidenceItem } from '../src/ai/reading/types.js';

/**
 * Token-boundary contract for the private resemblance → family classifier.
 * A supported term matches only a complete folded token (or the exact phrase
 * stem documented in the classifier), never a substring of another word.
 */
const item = (resemblance: string | null, description = 'A dark mark with a soft edge.'): ReadingEvidenceItem => ({
  id: 'e1',
  region: 'middle_wall',
  description,
  confidence: 'high',
  visibility: 'clear',
  resemblance,
});
const family = (resemblance: string | null, description?: string) =>
  coffeeMeaningFamily(item(resemblance, description));

describe('coffeeMeaningFamily — no accidental substring matches', () => {
  it.each([
    'may resemble a string',
    'may resemble a spring',
    'may resemble a coiled spring',
    'may resemble a loose string',
    'may resemble a meandering stream',
    'may resemble a monkey',
    'may resemble a street lamp',
    'may resemble a broad leaf',
    'may resemble a hearth',
    'may resemble a keyboard',
    'may resemble a keyhole',
    'may resemble a turkey',
    'may resemble a roadside sign',
    'may resemble a pathway marker',
    'may resemble a treetop',
    'may resemble a fishbone',
    'may resemble a surface ripple',
    'may resemble a pitchfork handle',
    'may resemble a kusur', // Turkish "defect": not "kuş"
    'yüzeyde bir dalga gibi', // Turkish "surface": not "yüz"
  ])('%s → null', (resemblance) => {
    expect(family(resemblance)).toBeNull();
  });

  it('a non-sign description never becomes a choice through a substring', () => {
    expect(family(null, 'A thin line with a forklift-like notch near the rim.')).toBeNull();
  });
});

describe('coffeeMeaningFamily — supported terms still classify', () => {
  it.each([
    ['may resemble a bird gliding', 'communication'],
    ['may resemble two birds', 'communication'],
    // Frozen C2.10 C01 evidence: a compound whose head IS the sign.
    ['may resemble a seabird with lifted wings', 'communication'],
    ['may resemble a songbird', 'communication'],
    ['kuş gibi', 'communication'],
    ['kus gibi', 'communication'],
    ['kuşlar gibi', 'communication'],
    ['may resemble a folded letter', 'communication'],
    ['mektup gibi', 'communication'],
    ['may resemble a message', 'communication'],
    ['mesaj gibi', 'communication'],
    ['may resemble an envelope', 'communication'],
    ['zarf gibi', 'communication'],
    ['may resemble a fish leaping clear', 'opportunity'],
    ['balık gibi', 'opportunity'],
    ['balik gibi', 'opportunity'],
    ['may resemble a plain band ring', 'bond'],
    ['may resemble rings', 'bond'],
    ['yüzük gibi', 'bond'],
    ['yuzuk gibi', 'bond'],
    ['may resemble a plump heart', 'emotional_relevance'],
    ['kalp gibi', 'emotional_relevance'],
    ['may resemble a small key with a square head', 'solution'],
    ['anahtar gibi', 'solution'],
    ['may resemble a road climbing uphill', 'movement'],
    ['may resemble a path bending away', 'movement'],
    ['may resemble a winding route', 'movement'],
    ['yol gibi', 'movement'],
    ['patika gibi', 'movement'],
    ['may resemble a young tree with a few branches', 'growth'],
    ['ağaç gibi', 'growth'],
    ['agac gibi', 'growth'],
    ['may resemble a standing person', 'social_relevance'],
    ['may resemble a small figure', 'social_relevance'],
    ['may resemble a face in profile', 'social_relevance'],
    ['insan gibi', 'social_relevance'],
    ['kişi gibi', 'social_relevance'],
    ['kisi gibi', 'social_relevance'],
    ['silüet gibi', 'social_relevance'],
    ['siluet gibi', 'social_relevance'],
    ['yüz gibi', 'social_relevance'],
    ['yuz gibi', 'social_relevance'],
    ['may resemble a fork in a path', 'choice'],
    ['may resemble a forked path', 'choice'],
    ['may resemble a crossroad', 'choice'],
    ['may resemble crossroads', 'choice'],
    ['may resemble two diverging paths', 'choice'],
    ['ikiye ayrılan bir yol gibi', 'choice'],
    ['yol ayrımı gibi', 'choice'],
  ] as const)('%s → %s', (resemblance, expected) => {
    expect(family(resemblance)).toBe(expected);
  });

  it('a choice signal in the description is still honoured (existing contract)', () => {
    expect(family(null, 'Two strokes diverge from one point.')).toBe('choice');
  });

  it.each([
    ['may resemble a bird-like shape', 'communication'],
    ['may resemble a bird/leaf', 'communication'],
    ['may resemble a (ring)', 'bond'],
    ['may resemble a key, perhaps', 'solution'],
    ['MAY RESEMBLE A TREE', 'growth'],
  ] as const)('separators and case: %s → %s', (resemblance, expected) => {
    expect(family(resemblance)).toBe(expected);
  });

  it('two candidates keep the existing family precedence (alternate loss is a V3 limitation)', () => {
    expect(family('may resemble a leaf or a bird')).toBe('communication');
    expect(family('may resemble a ring or a fish')).toBe('opportunity');
  });
});
