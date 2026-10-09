import { describe, expect, it } from 'vitest';
import { coffeeMeaningFamily } from '../src/ai/reading/coffee-meaning-map.js';
import { mapCoffeeSemanticCues } from '../src/ai/reading/coffee-semantic-cues.js';
import type { ReadingEvidenceItem } from '../src/ai/reading/types.js';

/**
 * Written-vs-incoming contact uses the same token-boundary lexicon matcher as
 * coffeeMeaningFamily: a written term must be a whole folded token (plus a
 * plain plural), never a substring of another word.
 */
const item = (resemblance: string): ReadingEvidenceItem => ({
  id: 'e1',
  region: 'middle_wall',
  description: 'A compact dark mark with a soft edge.',
  confidence: 'high',
  visibility: 'clear',
  resemblance,
});
const cueKinds = (resemblance: string) => mapCoffeeSemanticCues({ evidence: [item(resemblance)] }).map((cue) => cue.kind);

describe('written contact — lexical terms', () => {
  it.each([
    'may resemble a folded letter',
    'may resemble two letters',
    'mektup gibi',
    'may resemble a message',
    'mesaj gibi',
    'may resemble an envelope',
    'zarf gibi',
    'may resemble a letter-like slip',
    'may resemble a message/envelope',
    'may resemble a (letter)',
    'may resemble a bird carrying a letter',
  ])('%s → written_contact', (resemblance) => {
    expect(cueKinds(resemblance)).toEqual(['written_contact']);
  });

  it.each([
    'may resemble a bird gliding',
    'may resemble a seabird with lifted wings',
    'kuş gibi',
  ])('%s → incoming_contact', (resemblance) => {
    expect(cueKinds(resemblance)).toEqual(['incoming_contact']);
  });
});

describe('written contact — no accidental substring matches', () => {
  it.each([
    'may resemble a bird above some lettering',
    'may resemble a bird on a messageboard',
    'may resemble a bird near an enveloper',
    'kuş ve zarflık gibi',
    'kuş ve mektupluk gibi',
  ])('%s → incoming_contact, not written', (resemblance) => {
    expect(cueKinds(resemblance)).toEqual(['incoming_contact']);
  });

  it('"lettering" alone is not a communication sign', () => {
    expect(coffeeMeaningFamily(item('may resemble decorative lettering'))).toBeNull();
  });
});
