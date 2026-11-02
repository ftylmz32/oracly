#!/usr/bin/env -S npx tsx
/**
 * Aşama 4K/4L — thin wrapper. All logic and the explicit target checks live
 * in `src/account/deletion-reconcile-cli.ts` (also shipped in the image):
 *
 *   FIREBASE_PROJECT_ID=<p> FIRESTORE_DATABASE_ID=<db> READING_STAGING_BUCKET=<b> \
 *     npx tsx scripts/deletion-reconcile.ts --project=<p> --database=<db> --bucket=<b> [--apply]
 *
 * Dry run by default; never falls back to the `(default)` database.
 */
import { runDeletionReconcile } from '../src/account/deletion-reconcile-cli.js';

runDeletionReconcile(process.argv.slice(2), process.env).catch((error) => {
  console.error(error instanceof Error ? error.message : 'deletion_reconcile_failed');
  process.exitCode = 1;
});
