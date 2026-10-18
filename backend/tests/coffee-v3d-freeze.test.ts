/**
 * COFFEE V3D FREEZE GUARD — the product owner approved the direct
 * fortune-teller engine (prompt sha 519c6421…) and froze it: no prompt edit,
 * no new creative restriction, no meaning table, no refactor, no behaviour
 * change. This test fails on ANY change to the frozen files or to the routing
 * and dark-launch defaults, so an accidental edit in a later task is caught.
 *
 * Changing coffee on purpose requires an explicit owner decision; only then
 * are the pins below updated, in the same reviewed change.
 */
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { coffeeV3DPromptSha256, FROZEN_COFFEE_V3D_PROMPT_SHA256 } from '../src/ai/reading/coffee-v3d-direct-pipeline.js';
import { testConfig } from './helpers.js';

const root = resolve(process.cwd());
/** Content hash with line endings normalised (Windows checkouts convert to CRLF). */
const fileSha = (path: string) => createHash('sha256').update(readFileSync(resolve(root, path), 'utf8').replace(/\r\n/g, '\n'), 'utf8').digest('hex');

/** The engine and the two modules its behaviour depends on (pins / terminal / slots; the public result shape). */
const FROZEN_FILES: Record<string, string> = {
  'src/ai/reading/coffee-v3d-direct-pipeline.ts': '26d08cbae49c89754fc4b3e5074adc3011bd1d7c016b3e93255482fab92d5540',
  'src/ai/reading/coffee-v3-live-pipeline.ts': 'b2e6da557e4af9f4a6838911e9752c074a56211e238a51c10ef7a8f9465b1665',
  'src/ai/reading/coffee-v3n-narrative-pipeline.ts': 'aa7471c9f3ce39fec877fb1440e57b29a49aa4d0a686b7e1e5af4f4db2fd7849',
};

describe('COFFEE V3D FREEZE (owner-approved engine — do not edit)', () => {
  it('the approved writer prompt is unchanged (519c6421…)', () => {
    expect(FROZEN_COFFEE_V3D_PROMPT_SHA256).toBe('519c6421a9cb5aadc65352ff27025d56abe6364ceded2c0b6a6bcd26e4904ba4');
    expect(coffeeV3DPromptSha256()).toBe(FROZEN_COFFEE_V3D_PROMPT_SHA256);
  });

  it.each(Object.entries(FROZEN_FILES))('%s is byte-identical to the approved version', (path, sha) => {
    expect(fileSha(path), `${path} changed — the coffee engine is frozen`).toBe(sha);
  });

  it('routing: the V3 entry runs the direct engine by default (V3N only on explicit config)', () => {
    expect(testConfig().coffeeV3Engine).toBe('direct');
    const service = readFileSync(resolve(root, 'src/ai/service.ts'), 'utf8');
    expect(service).toContain("const engine = this.config.coffeeV3Engine === 'narrative' ? runCoffeeV3NarrativeReading : runCoffeeV3DirectReading;");
  });

  it('dark launch is unchanged: V3 creation is off by default on the server and the client', () => {
    for (const env of ['development', 'staging', 'production']) expect(testConfig({ APP_ENV: env }).coffeeV3CreationEnabled).toBe(false);
    const flags = readFileSync(resolve(root, '../lib/core/feature_flags/product_feature_flags.dart'), 'utf8');
    expect(flags).toMatch(/key: 'coffee_v3_three_view',\s*type: FeatureFlagType\.boolean,\s*defaultValue: false,/);
  });
});
