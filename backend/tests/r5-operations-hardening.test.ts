import { describe, expect, it } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import { FirestoreProviderStageRepository, type ReadingGenerationTrace } from '../src/reading/provider-stage-repository.js';
import { ReadingResultRepository } from '../src/reading/reading-result-repository.js';

const trace: ReadingGenerationTrace = {
  pipelineVersion: 'reading-pipeline-r5',
  interpretationContractVersion: 'coffee-palm-contract-v2',
  promptRulesVersion: 'reading-prompts-r4',
  modelIdentifier: 'model-a',
};

describe('R5 operations hardening', () => {
  it('pins generation identity on first provider attempt and preserves it across restart/retry', async () => {
    const store = new MemoryDocumentStore();
    const first = new FirestoreProviderStageRepository(store);
    const claimed = await first.claimAttempt('operation-trace', 'owner-trace', trace);
    expect(claimed.generationTrace).toEqual(trace);

    const restarted = new FirestoreProviderStageRepository(store);
    const changedConfig = { ...trace, modelIdentifier: 'model-b' };
    const retry = await restarted.claimAttempt('operation-trace', 'owner-trace', changedConfig);
    expect(retry.state).toBe('provider_outcome_unknown');
    expect(retry.generationTrace).toEqual(trace);
  });

  it('keeps old result records readable while new records carry safe trace identity', async () => {
    const store = new MemoryDocumentStore();
    const results = new ReadingResultRepository(store);
    const base = {
      schemaVersion: 1 as const,
      operationId: 'operation-result',
      ownerUserId: 'owner-result',
      readingType: 'coffee' as const,
      resultId: 'coffee_operation-result',
      data: { overall: 'safe output' },
      persistedAtMs: Date.now(),
      notificationSentAtMs: null,
    };
    await results.persistOnce(base);
    await expect(results.get(base.operationId)).resolves.toMatchObject({ generationTrace: undefined });

    const traced = { ...base, operationId: 'operation-result-2', resultId: 'coffee_operation-result-2', generationTrace: trace };
    await results.persistOnce(traced);
    await expect(results.get(traced.operationId)).resolves.toMatchObject({ generationTrace: trace });
  });

  it('rejects raw binary and base64 fields at the generic provider checkpoint boundary', async () => {
    const store = new MemoryDocumentStore();
    const repository = new FirestoreProviderStageRepository(store);
    await expect(repository.markCompleted('raw-base64', 'owner', {
      imageBase64: Buffer.alloc(64).toString('base64'),
    })).rejects.toThrow('provider_checkpoint_base64_forbidden');
    await expect(repository.markCompleted('raw-buffer', 'owner', {
      image: Buffer.alloc(64),
    })).rejects.toThrow('provider_checkpoint_binary_forbidden');
    expect(await repository.get('raw-base64')).toEqual({ state: 'not_started' });
    expect(await repository.get('raw-buffer')).toEqual({ state: 'not_started' });
  });
});
