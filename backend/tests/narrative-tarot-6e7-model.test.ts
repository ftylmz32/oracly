/**
 * Phase 6E.7 — Narrative Tarot dedicated writer model isolation (offline).
 * REAL PROVIDER CALLS = 0.
 */
import { describe, expect, it } from 'vitest';
import { loadConfig, resolveModel } from '../src/config.js';
import { buildChatCompletionBody } from '../src/ai/openai-transport.js';
import {
  buildNarrativeTarotCompleteOptions,
  isGpt56Family,
  narrativeModelQaMetadata,
  resolveNarrativeTarotModel,
  supportsReasoningEffort,
} from '../src/ai/narrative-tarot-model.js';
import type { OpenAiMessage } from '../src/types.js';

const msgs: OpenAiMessage[] = [
  { role: 'system', content: 'test' },
  { role: 'user', content: '{}' },
];

describe('Phase 6E.7 Narrative dedicated writer model config', () => {
  it('unset dedicated model falls back to OPENAI_MODEL (gpt-4o)', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    });
    expect(cfg.openaiTarotNarrativeModel).toBeNull();
    expect(cfg.openaiTarotNarrativeReasoningEffort).toBe('none');
    expect(resolveNarrativeTarotModel(cfg, cfg.openaiModel)).toBe('gpt-4o');
  });

  it('allowlisted dedicated Narrative model resolves to gpt-5.6-sol', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
    });
    expect(cfg.openaiTarotNarrativeModel).toBe('gpt-5.6-sol');
    expect(resolveNarrativeTarotModel(cfg, cfg.openaiModel)).toBe('gpt-5.6-sol');
    expect(cfg.openaiModel).toBe('gpt-4o');
  });

  it('non-allowlisted dedicated Narrative model is rejected (null)', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
    });
    expect(cfg.openaiTarotNarrativeModel).toBeNull();
    expect(resolveNarrativeTarotModel(cfg, cfg.openaiModel)).toBe('gpt-4o');
  });

  it('blank dedicated model is null; invalid reasoning effort becomes none', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_TAROT_NARRATIVE_MODEL: '   ',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'high',
    });
    expect(cfg.openaiTarotNarrativeModel).toBeNull();
    expect(cfg.openaiTarotNarrativeReasoningEffort).toBe('none');
  });

  it('reasoning effort accepts none|low|medium', () => {
    expect(
      loadConfig({
        OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'low',
      }).openaiTarotNarrativeReasoningEffort,
    ).toBe('low');
    expect(
      loadConfig({
        OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'medium',
      }).openaiTarotNarrativeReasoningEffort,
    ).toBe('medium');
  });
});

describe('Phase 6E.7 GPT-5.6-sol Narrative request body (offline)', () => {
  it('sends reasoning_effort and omits temperature', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
    });
    expect(isGpt56Family('gpt-5.6-sol')).toBe(true);
    expect(supportsReasoningEffort('gpt-5.6-sol')).toBe(true);

    const opts = buildNarrativeTarotCompleteOptions(cfg, cfg.openaiModel, msgs);
    expect(opts.model).toBe('gpt-5.6-sol');
    expect(opts.reasoningEffort).toBe('none');
    expect(opts.temperature).toBeUndefined();
    expect(opts.jsonSchema?.name).toBe('oracly_tarot_narrative_v2');

    const body = buildChatCompletionBody(opts);
    expect(body.model).toBe('gpt-5.6-sol');
    expect(body.reasoning_effort).toBe('none');
    expect(body).not.toHaveProperty('temperature');
    const rf = body.response_format as {
      type: string;
      json_schema: { name: string; strict: boolean };
    };
    expect(rf.type).toBe('json_schema');
    expect(rf.json_schema.name).toBe('oracly_tarot_narrative_v2');
    expect(rf.json_schema.strict).toBe(true);
  });
});

describe('Phase 6E.7 gpt-4o Narrative fallback request body (offline)', () => {
  it('preserves temperature 0.55 and Narrative schema', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
    });
    expect(supportsReasoningEffort('gpt-4o')).toBe(false);
    const opts = buildNarrativeTarotCompleteOptions(cfg, cfg.openaiModel, msgs);
    expect(opts.model).toBe('gpt-4o');
    expect(opts.temperature).toBe(0.55);
    expect(opts.reasoningEffort).toBeUndefined();

    const body = buildChatCompletionBody(opts);
    expect(body.model).toBe('gpt-4o');
    expect(body.temperature).toBe(0.55);
    expect(body).not.toHaveProperty('reasoning_effort');
    const rf = body.response_format as {
      json_schema: { name: string; strict: boolean };
    };
    expect(rf.json_schema.name).toBe('oracly_tarot_narrative_v2');
    expect(rf.json_schema.strict).toBe(true);
  });
});

describe('Phase 6E.7 feature firewalls', () => {
  it('legacy Tarot / generic resolveModel ignore dedicated Narrative model', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
    });
    expect(resolveModel(cfg, undefined)).toBe('gpt-4o');
    expect(resolveModel(cfg, 'gpt-4o')).toBe('gpt-4o');
    // Dedicated Narrative path is separate:
    expect(resolveNarrativeTarotModel(cfg, resolveModel(cfg, undefined))).toBe(
      'gpt-5.6-sol',
    );
  });

  it('QA metadata exposes safe model fields only', () => {
    const cfg = loadConfig({
      APP_ENV: 'development',
      OPENAI_MODEL: 'gpt-4o',
      OPENAI_ALLOWED_MODELS: 'gpt-4o,gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_MODEL: 'gpt-5.6-sol',
      OPENAI_TAROT_NARRATIVE_REASONING_EFFORT: 'none',
      OPENAI_API_KEY: 'sk-test-should-never-appear-in-metadata',
    });
    const meta = narrativeModelQaMetadata(cfg);
    expect(meta).toEqual({
      configuredGenericModel: 'gpt-4o',
      configuredNarrativeModel: 'gpt-5.6-sol',
      resolvedNarrativeModel: 'gpt-5.6-sol',
      narrativeReasoningEffort: 'none',
      // Phase 6F froze the writer contract into the same QA metadata block.
      frozenNarrativeWriterModel: 'gpt-5.6-sol',
      frozenNarrativeReasoningEffort: 'none',
    });
    expect(JSON.stringify(meta)).not.toMatch(/sk-|API_KEY|Bearer/i);
  });
});
