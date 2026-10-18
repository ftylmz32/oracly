import { describe, expect, it, vi } from 'vitest';
import { getCoffeeRuntime, MockCoffeeService, type CoffeeFlowPhase } from './service';

const files = {
  'cup-primary': new File(['a'], 'a.jpg', { type: 'image/jpeg' }),
  'cup-secondary': new File(['b'], 'b.jpg', { type: 'image/jpeg' }),
  saucer: new File(['c'], 'c.jpg', { type: 'image/jpeg' }),
};

describe('MockCoffeeService', () => {
  it('runs preparation, upload, wait, processing and clearly demo-only ready states', async () => {
    const phases: CoffeeFlowPhase[] = [];
    const result = await new MockCoffeeService('success', 0).run({ files, intention: 'Genel olarak', onUpdate: (update) => phases.push(update.phase) });
    expect(phases).toEqual(['preparing', 'uploading', 'uploading', 'uploading', 'waiting', 'processing', 'ready']);
    expect(result).toEqual({ kind: 'demo', resultId: 'demo_coffee_result' });
  });
  it('supports a retry after a simulated failure', async () => {
    const service = new MockCoffeeService('fail-once', 0);
    const onUpdate = vi.fn();
    await expect(service.run({ files, intention: 'Genel olarak', onUpdate })).rejects.toThrow('network');
    await expect(service.run({ files, intention: 'Genel olarak', onUpdate })).resolves.toMatchObject({ kind: 'demo' });
  });
  it('never enables the mock provider in production', () => {
    vi.stubEnv('NODE_ENV', 'production');
    vi.stubEnv('NEXT_PUBLIC_ORACLY_COFFEE_SERVICE', 'mock');
    expect(getCoffeeRuntime().mode).not.toBe('mock');
    vi.unstubAllEnvs();
  });
});
