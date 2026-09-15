import { describe, expect, it, vi } from 'vitest';
import { MemoryDocumentStore } from '../src/reading/memory-document-store.js';
import {
  FirebaseReadingCompletionNotifier,
  ReadingNotificationTokens,
} from '../src/reading/reading-notifications.js';
import { testConfig } from './helpers.js';

const config = testConfig({ FIREBASE_PROJECT_ID: 'oracly-test' });

describe('reading completion notifications', () => {
  it('missing token is a successful no-op', async () => {
    const request = vi.fn();
    const notifier = new FirebaseReadingCompletionNotifier(
      config,
      new ReadingNotificationTokens(new MemoryDocumentStore()),
      { request },
    );

    await expect(notifier.notifyCompleted({
      operationId: '00000000000000000000000000000001',
      ownerUserId: 'owner-without-token',
      readingType: 'coffee',
    })).resolves.toBeUndefined();
    expect(request).not.toHaveBeenCalled();
  });

  it('stale-token provider rejection is surfaced for the processor to contain', async () => {
    const store = new MemoryDocumentStore();
    const tokens = new ReadingNotificationTokens(store);
    await tokens.register('owner-stale-token', 'stale-fcm-token');
    const request = vi.fn().mockRejectedValue(new Error('UNREGISTERED'));
    const notifier = new FirebaseReadingCompletionNotifier(config, tokens, { request });

    await expect(notifier.notifyCompleted({
      operationId: '00000000000000000000000000000002',
      ownerUserId: 'owner-stale-token',
      readingType: 'palm',
    })).rejects.toThrow('UNREGISTERED');
    expect(request).toHaveBeenCalledOnce();
    await expect(tokens.get('owner-stale-token')).resolves.toBeNull();
  });

  it('moves a token between authenticated owners without leaving a cross-account target', async () => {
    const tokens = new ReadingNotificationTokens(new MemoryDocumentStore());
    await tokens.register('owner-a', 'same-device-token');
    await tokens.register('owner-b', 'same-device-token');
    await expect(tokens.get('owner-a')).resolves.toBeNull();
    await expect(tokens.get('owner-b')).resolves.toBe('same-device-token');
  });

  it('R2.1 — an ambiguous/transient provider failure never purges a valid token', async () => {
    const store = new MemoryDocumentStore();
    const tokens = new ReadingNotificationTokens(store);
    await tokens.register('owner-ambiguous', 'still-valid-token');
    const request = vi.fn().mockRejectedValue(new Error('network_timeout'));
    const notifier = new FirebaseReadingCompletionNotifier(config, tokens, { request });

    await expect(notifier.notifyCompleted({
      operationId: '00000000000000000000000000000003',
      ownerUserId: 'owner-ambiguous',
      readingType: 'coffee',
    })).rejects.toThrow('network_timeout');
    expect(request).toHaveBeenCalledOnce();
    // Unlike the definite UNREGISTERED case above, an ambiguous transport
    // failure must leave the registration exactly as it was.
    await expect(tokens.get('owner-ambiguous')).resolves.toBe('still-valid-token');
  });

  it('logout unregister is idempotent and expected-token guarded', async () => {
    const tokens = new ReadingNotificationTokens(new MemoryDocumentStore());
    await tokens.register('owner', 'fresh-token');
    await expect(tokens.unregister('owner', 'stale-token')).resolves.toBe(false);
    await expect(tokens.get('owner')).resolves.toBe('fresh-token');
    await expect(tokens.unregister('owner', 'fresh-token')).resolves.toBe(true);
    await expect(tokens.unregister('owner')).resolves.toBe(false);
  });
});
