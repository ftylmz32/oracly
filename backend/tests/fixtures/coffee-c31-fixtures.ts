import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type { CoffeeV3Band, CoffeeV3CupBand, CoffeeV3Form, CoffeeV3RelationKind, CoffeeV3Topology } from '../../src/ai/reading/types.js';
import type { M1FixtureSpec, M1MarkSpec } from './coffee-m1-fixtures.js';

/**
 * Deterministic QA fixtures built ONLY from the committed C3.1 annotations
 * (backend/docs/qa/coffee-c31-fixed-public-corpus-20261009.json). No image is
 * fetched or re-interpreted. Annotated cup structures become V3 marks with
 * their recorded band and form; ambiguous resemblances are NOT given as
 * candidates (C3.1 did not accept them). Saucer structures are kept as saucer
 * marks so tests can prove the saucer is ignored.
 */
/** V3G1 machine fields, recorded only where the committed annotation already states the physical fact. */
type C31V3G1 = { topology?: CoffeeV3Topology; bandCoverage?: CoffeeV3CupBand[]; markKind?: 'clear_area' };
type C31Structure = { id: string; band: CoffeeV3Band | 'uncertain'; form: Partial<CoffeeV3Form>; v3g1?: C31V3G1 };
type C31Set = {
  id: string;
  structures: C31Structure[];
  saucerStructureList?: Array<{ id: string; form: Partial<CoffeeV3Form>; v3g1?: C31V3G1 }>;
  /** V3G1: a grouped clear-area source recorded inside another structure's annotation. */
  clearAreas?: Array<{ id: string; band: CoffeeV3CupBand; enclosedBy: string }>;
  relations: Array<{ a: string; b: string; kind: CoffeeV3RelationKind }>;
};

const manifest = JSON.parse(
  readFileSync(resolve(process.cwd(), 'docs/qa/coffee-c31-fixed-public-corpus-20261009.json'), 'utf8'),
) as { sets: C31Set[] };

export const C31_SET_IDS = manifest.sets.map((s) => s.id);

/**
 * `clearAreas` (V3G1): include the recorded clear-area features (a structure
 * annotated as a clear area, and grouped clear-area sources with their
 * explicit enclosure). Off by default: the frozen W2/W4 writer regression was
 * validated on the structure-only projection of these cups, and stays pinned
 * to it. Span and topology fields are always applied.
 */
export function c31Spec(setId: string, options: { clearAreas?: boolean } = {}): M1FixtureSpec {
  const set = manifest.sets.find((s) => s.id === setId);
  if (!set) throw new Error(`unknown C3.1 set ${setId}`);
  const withClear = options.clearAreas === true;
  const cup: M1MarkSpec[] = set.structures.map((p) => {
    const clear = withClear && p.v3g1?.markKind === 'clear_area';
    return {
      id: p.id,
      label: null,
      band: p.band === 'uncertain' ? 'unknown' : p.band,
      form: { ...p.form },
      ...(clear ? { kind: 'clear_area' as const } : {}),
      ...(!clear && p.v3g1?.topology ? { topology: p.v3g1.topology } : {}),
      ...(p.v3g1?.bandCoverage ? { bandCoverage: [...p.v3g1.bandCoverage] } : {}),
    };
  });
  const grouped: M1MarkSpec[] = withClear
    ? (set.clearAreas ?? []).map((c) => ({ id: c.id, label: null, band: c.band, kind: 'clear_area' as const }))
    : [];
  const saucer: M1MarkSpec[] = (set.saucerStructureList ?? []).map((s) => ({
    id: s.id,
    label: null,
    saucer: true,
    form: { ...s.form },
    ...(s.v3g1?.topology ? { topology: s.v3g1.topology } : {}),
  }));
  return {
    marks: [...cup, ...grouped, ...saucer],
    // Annotated relations are between cup structures only; a grouped clear area is contained by its recorded host.
    relations: [
      ...set.relations.map((r) => ({ a: r.a, b: r.b, kind: r.kind })),
      ...(withClear ? (set.clearAreas ?? []).map((c) => ({ a: c.id, b: c.enclosedBy, kind: 'contained_by' as const })) : []),
    ],
  };
}
