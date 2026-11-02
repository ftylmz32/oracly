/**
 * Aşama 4L — the reconcile tool must name its database and bucket
 * explicitly: QA and production share one project, so a missing or
 * mismatched database must never fall back to `(default)`.
 */
import { describe, expect, it } from 'vitest';
import { resolveReconcileTarget } from '../src/account/deletion-reconcile-cli.js';

const QA = {
  FIREBASE_PROJECT_ID: 'oracly-7f613',
  FIRESTORE_DATABASE_ID: 'oracly-play-qa',
  READING_STAGING_BUCKET: 'oracly-7f613-reading-staging-qa-ew1',
};
const flags = ['--project=oracly-7f613', '--database=oracly-play-qa', '--bucket=oracly-7f613-reading-staging-qa-ew1'];

describe('4L reconcile target guard', () => {
  it('accepts an explicit, matching QA target (dry run by default)', () => {
    expect(resolveReconcileTarget(flags, QA)).toEqual({
      project: 'oracly-7f613', database: 'oracly-play-qa', bucket: 'oracly-7f613-reading-staging-qa-ew1',
      apply: false, maxIdentities: 25,
    });
  });

  it('refuses a missing database instead of falling back to (default) — also for a dry run', () => {
    const { FIRESTORE_DATABASE_ID: _omit, ...env } = QA;
    expect(() => resolveReconcileTarget(flags, env)).toThrow(/firestore_database_id_not_explicit/);
    expect(() => resolveReconcileTarget(flags, { ...QA, FIRESTORE_DATABASE_ID: '  ' })).toThrow(/not_explicit/);
  });

  it('refuses a missing bucket or project', () => {
    const { READING_STAGING_BUCKET: _b, ...noBucket } = QA;
    expect(() => resolveReconcileTarget(flags, noBucket)).toThrow(/reading_staging_bucket_not_explicit/);
    const { FIREBASE_PROJECT_ID: _p, ...noProject } = QA;
    expect(() => resolveReconcileTarget(flags, noProject)).toThrow(/firebase_project_id_not_explicit/);
  });

  it('refuses a wrong or missing --database / --bucket / --project flag', () => {
    const swap = (i: number, v: string) => flags.map((f, j) => (j === i ? v : f));
    expect(() => resolveReconcileTarget(swap(1, '--database=(default)'), QA)).toThrow(/database_mismatch/);
    expect(() => resolveReconcileTarget(swap(2, '--bucket=oracly-7f613-reading-staging-ew1'), QA)).toThrow(/bucket_mismatch/);
    expect(() => resolveReconcileTarget(swap(0, '--project=other'), QA)).toThrow(/project_mismatch/);
    expect(() => resolveReconcileTarget(flags.slice(0, 2), QA)).toThrow(/bucket_mismatch/);
  });

  it('a production environment needs production flags: QA flags against it are refused', () => {
    const prod = { ...QA, FIRESTORE_DATABASE_ID: '(default)', READING_STAGING_BUCKET: 'oracly-7f613-reading-staging-ew1' };
    expect(() => resolveReconcileTarget(flags, prod)).toThrow(/database_mismatch/);
  });

  it('apply needs the approval variable; the cap is validated', () => {
    expect(() => resolveReconcileTarget([...flags, '--apply'], QA)).toThrow(/not_approved/);
    expect(resolveReconcileTarget([...flags, '--apply', '--max-identities=3'], { ...QA, ORACLY_DELETION_RECONCILE_APPROVED: 'yes' }))
      .toMatchObject({ apply: true, maxIdentities: 3 });
    expect(() => resolveReconcileTarget([...flags, '--max-identities=-1'], QA)).toThrow(/bad_cap/);
  });
});
