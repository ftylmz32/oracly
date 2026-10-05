// Dream Phase 4C.2a — the independent semantic review of the 27 immutable
// 4C.2 outputs: one bounded invented-scene finding, and a corpus-scoped
// model verdict that changes nothing in production.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { PHASE4C2_ARTIFACT_PATH } from '../scripts/dream-phase4c2/artifact.js';
import { evidenceSha256 } from '../scripts/dream-phase4c2a/artifact.js';

const REVIEW = fileURLToPath(new URL('../../docs/product/dream/evals/DREAM_PHASE4C2_INDEPENDENT_REVIEW_20260928.json', import.meta.url));
const review = JSON.parse(readFileSync(REVIEW, 'utf8'));
const frozenText = readFileSync(PHASE4C2_ARTIFACT_PATH, 'utf8');
const frozen = JSON.parse(frozenText).attempts as Array<{ attemptId: string; candidateModel: string; narrative: string; rawProviderText: string }>;

describe('Phase 4C.2 independent review', () => {
  it('reviews exactly the 27 frozen attempts, in order', () => {
    expect(review.source.artifactSha256).toBe(evidenceSha256(frozenText));
    expect(review.attempts.map((a: { attemptId: string }) => a.attemptId)).toEqual(frozen.map((a) => a.attemptId));
    expect(review.attempts.map((a: { model: string }) => a.model)).toEqual(frozen.map((a) => a.candidateModel));
  });

  it('one invented physical action; every other attempt NONE', () => {
    const present = review.attempts.filter((a: { inventedConcreteSceneContent: string }) => a.inventedConcreteSceneContent === 'PRESENT');
    expect(present.map((a: { attemptId: string }) => a.attemptId)).toEqual(['tr-negated-fear::gpt-4o']);
    const [finding] = present[0].inventedConcreteSceneItems;
    expect(finding.type).toBe('physical_action');
    const attempt = frozen.find((a) => a.attemptId === 'tr-negated-fear::gpt-4o')!;
    expect(JSON.parse(attempt.rawProviderText).summary).toContain(finding.item);
    expect(attempt.narrative).not.toMatch(/takip/);
    for (const a of review.attempts) {
      if (a.inventedConcreteSceneContent === 'NONE') expect(a.inventedConcreteSceneItems).toEqual([]);
    }
    expect(review.inventedSceneScope).toMatch(/does not mean every interpretation is perfect/);
  });

  it('selects Astra on this corpus only; production is unchanged', () => {
    expect(review.verdict).toMatchObject({
      selectedProductionCandidate: 'gpt-6-astra',
      runnerUp: 'gpt-6-sol',
      notSelected: ['gpt-4o'],
      generalClaim: false,
      productionModelChanged: false,
      claim: 'On the frozen ORACLY Dream Phase 4C.2 corpus under writer revision 4c1, independent semantic review selects gpt-6-astra as the production candidate.',
    });
    expect(review.costContext.note).toMatch(/not a quality score/);
    expect(review.reviewer).toMatch(/No model was called/);
  });
});
