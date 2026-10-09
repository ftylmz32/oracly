import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { CoffeeV3Band, CoffeeV3Form, CoffeeV3RelationKind } from '../../src/ai/reading/types.js';
import type { M1FixtureSpec, M1MarkSpec } from './coffee-m1-fixtures.js';

/**
 * Deterministic QA fixtures built ONLY from the committed C3.1 annotations
 * (backend/docs/qa/coffee-c31-fixed-public-corpus-20261009.json). No image is
 * fetched or re-interpreted. Annotated cup structures become V3 marks with
 * their recorded band and form; ambiguous resemblances are NOT given as
 * candidates (C3.1 did not accept them). Saucer structures are kept as saucer
 * marks so tests can prove the saucer is ignored.
 */
type C31Structure = { id: string; band: CoffeeV3Band | 'uncertain'; form: Partial<CoffeeV3Form> };
type C31Set = {
  id: string;
  structures: C31Structure[];
  saucerStructureList?: Array<{ id: string; form: Partial<CoffeeV3Form> }>;
  relations: Array<{ a: string; b: string; kind: CoffeeV3RelationKind }>;
};

const manifest = JSON.parse(
  readFileSync(resolve(process.cwd(), 'docs/qa/coffee-c31-fixed-public-corpus-20261009.json'), 'utf8'),
) as { sets: C31Set[] };

export const C31_SET_IDS = manifest.sets.map((s) => s.id);

export function c31Spec(setId: string): M1FixtureSpec {
  const set = manifest.sets.find((s) => s.id === setId);
  if (!set) throw new Error(`unknown C3.1 set ${setId}`);
  const cup: M1MarkSpec[] = set.structures.map((p) => ({
    id: p.id,
    label: null,
    band: p.band === 'uncertain' ? 'unknown' : p.band,
    form: { ...p.form },
  }));
  const saucer: M1MarkSpec[] = (set.saucerStructureList ?? []).map((s) => ({ id: s.id, label: null, saucer: true, form: { ...s.form } }));
  return {
    marks: [...cup, ...saucer],
    // Annotated relations are between cup structures only.
    relations: set.relations.map((r) => ({ a: r.a, b: r.b, kind: r.kind })),
  };
}
