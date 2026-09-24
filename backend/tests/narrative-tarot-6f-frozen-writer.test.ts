/**
 * Phase 6F — frozen Narrative V2 writer contract (gpt-5.6-sol / effort none).
 * Locked envs fail closed before any provider call. REAL PROVIDER CALLS = 0.
 */
import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';
import { ErrorCode, ProxyError } from '../src/errors.js';
import {
  assertFrozenNarrativeWriter,
  buildNarrativeTarotCompleteOptions,
  FROZEN_NARRATIVE_REASONING_EFFORT,
  FROZEN_NARRATIVE_WRITER_MODEL,
  isLockedAppEnv,
  narrativeModelQaMetadata,
  resolveNarrativeTarotModel,
} from '../src/ai/narrative-tarot-model.js';
import type { OpenAiMessage } from '../src/types.js';

const msgs: OpenAiMessage[] = [
  { role: 'system', content: 'test' },
  { role: 'user', content: '{}' },
];

const LOCKED = ['production', 'staging'] as const;

function cfg(env: Record<string, string>) {
  return loadConfig(env as NodeJS.ProcessEnv);
}

function frozenEnv(appEnv: string) {
  return {
    APP_ENV: appEnv,
    OPENAI_MODEL: 'gpt-4o',
    OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    OPENAI_TAROT_NARRATIVE_MODEL: FROZEN_NARRATIVE_WRITER_MODEL,
    OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: FROZEN_NARRATIVE_REASONING_EFFORT,
  };
}

function expectNoConfiguration(run: () => unknown) {
  expect(run).toThrow(ProxyError);
  try {
    run();
    throw new Error('expected ProxyError');
  } catch (error) {
    expect((error as ProxyError).code).toBe(ErrorCode.noConfiguration);
  }
}

describe('Phase 6F frozen writer constants', () => {
  it('names gpt-5.6-sol with reasoning effort none', () => {
    expect(FROZEN_NARRATIVE_WRITER_MODEL).toBe('gpt-5.6-sol');
    expect(FROZEN_NARRATIVE_REASONING_EFFORT).toBe('none');
  });

  it('locks only production and staging', () => {
    expect(isLockedAppEnv(cfg({ APP_ENV: 'production' }))).toBe(true);
    expect(isLockedAppEnv(cfg({ APP_ENV: 'staging' }))).toBe(true);
    expect(isLockedAppEnv(cfg({ APP_ENV: 'development' }))).toBe(false);
  });
});

describe.each(LOCKED)('Phase 6F locked env: %s', (appEnv) => {
  it('unset dedicated writer fails closed with no_configuration', () => {
    const config = cfg({
      APP_ENV: appEnv,
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    });
    expect(config.openaiTarotNarrativeModel).toBeNull();
    expectNoConfiguration(() => assertFrozenNarrativeWriter(config));
    expectNoConfiguration(() =>
      buildNarrativeTarotCompleteOptions(config, config.openaiModel, msgs),
    );
  });

  it('a different allowlisted writer is rejected', () => {
    const config = cfg({
      APP_ENV: appEnv,
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-4o',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
    });
    expect(config.openaiTarotNarrativeModel).toBe('gpt-4o');
    expectNoConfiguration(() => assertFrozenNarrativeWriter(config));
    expectNoConfiguration(() =>
      buildNarrativeTarotCompleteOptions(config, config.openaiModel, msgs),
    );
  });

  it('the frozen writer outside the allowlist is rejected', () => {
    const config = cfg({
      APP_ENV: appEnv,
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o',
      OPENAI_TAROT_NARRATIVE_MODEL: FROZEN_NARRATIVE_WRITER_MODEL,
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
    });
    expect(config.openaiTarotNarrativeModel).toBeNull();
    expect(config.openaiAllowedModels).not.toContain(
      FROZEN_NARRATIVE_WRITER_MODEL,
    );
    expectNoConfiguration(() => assertFrozenNarrativeWriter(config));
  });

  it('a non-frozen reasoning effort is rejected', () => {
    const config = cfg({
      ...frozenEnv(appEnv),
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'medium',
    });
    expect(config.openaiTarotNarrativeReasoningEffort).toBe('medium');
    expectNoConfiguration(() => assertFrozenNarrativeWriter(config));
  });

  it('frozen sol + none + allowlisted passes and builds options', () => {
    const config = cfg(frozenEnv(appEnv));
    expect(() => assertFrozenNarrativeWriter(config)).not.toThrow();

    const opts = buildNarrativeTarotCompleteOptions(
      config,
      config.openaiModel,
      msgs,
    );
    expect(opts.model).toBe(FROZEN_NARRATIVE_WRITER_MODEL);
    expect(opts.reasoningEffort).toBe(FROZEN_NARRATIVE_REASONING_EFFORT);
    expect(opts.temperature).toBeUndefined();
    expect(opts.jsonSchema?.name).toBe('oracly_tarot_narrative_v2');
    expect(config.openaiModel).toBe('gpt-4o');
  });
});

describe('Phase 6F development stays on the 6E.7 fallback', () => {
  it('unset dedicated writer still resolves the generic model', () => {
    const config = cfg({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    });
    expect(() => assertFrozenNarrativeWriter(config)).not.toThrow();
    expect(resolveNarrativeTarotModel(config, config.openaiModel)).toBe(
      'gpt-4o',
    );

    const opts = buildNarrativeTarotCompleteOptions(
      config,
      config.openaiModel,
      msgs,
    );
    expect(opts.model).toBe('gpt-4o');
    expect(opts.temperature).toBe(0.55);
    expect(opts.reasoningEffort).toBeUndefined();
  });

  it('QA metadata publishes the frozen contract without secrets', () => {
    const config = cfg({
      ...frozenEnv('production'),
      OPENAI_API_KEY: 'sk-test-should-never-appear-in-metadata',
    });
    const meta = narrativeModelQaMetadata(config);
    expect(meta.frozenNarrativeWriterModel).toBe(FROZEN_NARRATIVE_WRITER_MODEL);
    expect(meta.frozenNarrativeReasoningEffort).toBe(
      FROZEN_NARRATIVE_REASONING_EFFORT,
    );
    expect(meta.resolvedNarrativeModel).toBe(FROZEN_NARRATIVE_WRITER_MODEL);
    expect(JSON.stringify(meta)).not.toMatch(/sk-|API_KEY|Bearer/i);
  });
});
