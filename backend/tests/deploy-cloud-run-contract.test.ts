/**
 * G2B0 — the Cloud Run deploy script must bind every current frozen model
 * contract and must never use a replace-semantics env/secret mechanism that
 * could silently delete reading-durability, billing/Apple IAP or
 * review-access configuration it never lists. A prior version omitted the
 * Coffee/Palm/Tarot/Yıldızname bindings and used --env-vars-file/--set-secrets
 * (full replace), which would have wiped those keys on the next real update.
 */
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const script = readFileSync(
  new URL('../scripts/deploy-cloud-run.sh', import.meta.url),
  'utf8',
);

describe('deploy-cloud-run.sh contract', () => {
  it('adds gpt-5.6-sol to the allowed-models list', () => {
    expect(script).toMatch(/OPENAI_ALLOWED_MODELS=gpt-4o,gpt-4o-mini,gpt-5\.6-sol/);
  });

  it('binds the Coffee/Palm reading model contract', () => {
    expect(script).toMatch(/OPENAI_READING_VISION_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_READING_WRITER_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_READING_REASONING_EFFORT=low/);
  });

  it('binds the frozen Tarot Narrative V2 writer contract', () => {
    expect(script).toMatch(/OPENAI_TAROT_NARRATIVE_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_TAROT_NARRATIVE_REASONING_EFFORT=none/);
  });

  it('binds the frozen Yıldızname narrative writer contract', () => {
    expect(script).toMatch(/OPENAI_YILDIZNAME_NARRATIVE_MODEL=gpt-5\.6-sol/);
    expect(script).toMatch(/OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT=none/);
  });

  it('binds the frozen Dream writer contract', () => {
    expect(script).toMatch(/OPENAI_DREAM_MODEL=gpt-6-astra/);
    expect(script).toMatch(/OPENAI_DREAM_REASONING_EFFORT=medium/);
  });

  it('defaults to no-traffic for an update deploy', () => {
    expect(script).toMatch(/NO_TRAFFIC="\$\{NO_TRAFFIC:-true\}"/);
    expect(script).toContain('DEPLOY_ARGS+=(--no-traffic)');
  });

  it('never uses a replace-semantics env/secret mechanism', () => {
    // These would silently delete any existing key this script doesn't list
    // (reading durability, billing/Apple IAP, review access). Only the
    // merge-semantics flags may be used as actual gcloud arguments — the
    // replace-semantics flag names may still appear in prose explaining why
    // they were replaced, so this checks for `=` (real usage), not the bare
    // substring.
    expect(script).not.toMatch(/--set-env-vars=/);
    expect(script).not.toMatch(/--env-vars-file=/);
    expect(script).not.toMatch(/--set-secrets=/);
    expect(script).toMatch(/--update-env-vars="\$ENV_UPDATES"/);
    expect(script).toMatch(/--update-secrets="OPENAI_API_KEY=\$\{SECRET_NAME\}:latest"/);
  });

  it('embeds no plaintext provider secret', () => {
    expect(script).not.toMatch(/sk-[A-Za-z0-9_-]{10,}/);
    // The key is sourced from Secret Manager only, and the script actively
    // refuses to run if OPENAI_API_KEY is exported into its own environment.
    expect(script).toMatch(/Do not export OPENAI_API_KEY into deploy; use Secret Manager/);
    expect(script).toMatch(/\[\[ -n "\$\{OPENAI_API_KEY:-\}" \]\] && fail/);
  });

  it('never echoes or logs a secret value', () => {
    expect(script).toMatch(/Never echo secrets/);
  });
});
