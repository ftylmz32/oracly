import { describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import { mapCoffeeMeanings, buildCoffeeWriterPacket } from '../src/ai/reading/coffee-meaning-map.js';
import { planCoffeeStory } from '../src/ai/reading/coffee-story-plan.js';
import { bindCoffeeNarrative, coffeePlanDepthFailure, coffeeSemanticSourceEcho } from '../src/ai/reading/evidence-bind.js';
import { COFFEE_WRITER_SCHEMA } from '../src/ai/reading/schemas.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
import { palmWriterSystem, repairWriterSystem, repairWriterUser } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';
import { testConfig } from './helpers.js';

const checks = {
  cupInteriorVisible: true,
  adequateFocusLight: true,
  residueVisible: true,
  milkFoamObstruction: false,
  usefulRegionsVisible: true,
};

const item = (id: string, resemblance: string | null, region = 'middle_wall'): ReadingEvidenceItem => ({
  id,
  region,
  description: resemblance ? `clear ${resemblance} form` : 'plain contextual residue',
  resemblance,
  confidence: 'high',
  visibility: 'clear',
});
const observation = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, checks, evidence });
const packet = (...evidence: ReadingEvidenceItem[]) => buildCoffeeWriterPacket(observation(...evidence), 'tr');

describe('C2.3 structured Coffee story planner', () => {
  it('maps machine atoms and sends a story plan with no localized implication prose or synonym menus', () => {
    const mapped = mapCoffeeMeanings(observation(item('e1', 'bird')), 'tr');
    expect(mapped).toEqual([{
      family: 'communication', evidenceIds: ['e1'], context: 'general', timing: 'unspecified', specificity: 'direct',
    }]);
    const ready = packet(item('e1', 'bird'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan.lead.family).toBe('communication');
    expect(ready.storyPlan.authorizedSections).not.toContain('money');
    expect(JSON.stringify(ready)).not.toMatch(/implication|haber, mesaj|fırsat, kazanç|bağ, anlaşma/);
  });

  it.each([
    ['fish', 'opportunity', 'money'],
    ['heart', 'emotional_relevance', 'love'],
    ['tree', 'growth', 'love'],
    ['ring', 'bond', 'love'],
  ] as const)('%s maps to %s without opening the %s lane', (source, family, forbidden) => {
    const ready = packet(item('e1', source));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan.lead.family).toBe(family);
    expect(ready.storyPlan.authorizedSections).not.toContain(forbidden);
  });

  it('creates one communication-led hierarchy with movement as safe co-occurrence', () => {
    const ready = packet(item('e1', 'bird'), item('e2', 'road'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan).toMatchObject({
      specificity: 'multi',
      lead: { family: 'communication', evidenceIds: ['e1'] },
      supporting: [{ family: 'movement', evidenceIds: ['e2'], relation: 'co_occurring' }],
    });
  });

  it('creates one solution-led hierarchy for solution + movement + communication', () => {
    const ready = packet(item('e1', 'key'), item('e2', 'road'), item('e3', 'bird'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan.lead.family).toBe('solution');
    expect(ready.storyPlan.supporting.map((part) => [part.family, part.relation])).toEqual([
      ['communication', 'co_occurring'],
      ['movement', 'co_occurring'],
    ]);
  });

  it('keeps opportunity + emotional as one hierarchy without money/love authorization', () => {
    const ready = packet(item('e1', 'fish'), item('e2', 'heart'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan.lead.family).toBe('opportunity');
    expect(ready.storyPlan.supporting[0]).toMatchObject({ family: 'emotional_relevance', relation: 'co_occurring' });
    expect(ready.storyPlan.authorizedSections).not.toContain('money');
    expect(ready.storyPlan.authorizedSections).not.toContain('love');
  });

  it('rejects an optional lane that the plan did not authorize', () => {
    const obs = observation(item('e1', 'fish'));
    const ready = buildCoffeeWriterPacket(obs, 'tr');
    if ('status' in ready) throw new Error('expected ready');
    const section = { text: 'Bu fırsatın etkisi hayatında daha belirgin bir alan kazanacak.', evidenceIds: ['e1'] };
    const narrative: CoffeeNarrative = {
      visualObservation: section,
      overall: { text: Array.from({ length: 30 }, (_, index) => `anlam${index}`).join(' '), evidenceIds: ['e1'] },
      love: { text: '', evidenceIds: [] }, career: { text: '', evidenceIds: [] },
      money: { text: 'Maddi kazanç kapına geliyor.', evidenceIds: ['e1'] },
      nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'Bu fırsat yaşamında kendine özgü kalıcı bir karşılık bulacak.', evidenceIds: ['e1'] },
    };
    expect(bindCoffeeNarrative(narrative, obs, 'tr', undefined, ready.storyPlan)).toBe('unauthorized_section');
  });

  it('authorizes optional domains only from explicit personalization and timing only from region state', () => {
    const facets = mapCoffeeMeanings(observation(item('e1', 'heart', 'rim')), 'tr');
    const planned = planCoffeeStory(facets, { intention: 'İlişkim hakkında merak ediyorum' });
    expect(planned.status).toBe('ready');
    if (planned.status !== 'ready') throw new Error('expected ready');
    expect(planned.plan.authorizedSections).toEqual(expect.arrayContaining(['love', 'nearFuture']));
    expect(planned.plan.authorizedSections).not.toContain('money');
  });

  it('blocks family-aware choice, growth and solution source reconstruction without a global blacklist', () => {
    expect(coffeeSemanticSourceEcho(['Önündeki iki yol ayrılıyor.'], [item('e1', 'fork')])).toBe(true);
    expect(coffeeSemanticSourceEcho(['Bu süreçte kök salacaksın.'], [item('e1', 'tree')])).toBe(true);
    expect(coffeeSemanticSourceEcho(['Kapının kilidi açılıyor.'], [item('e1', 'key')])).toBe(true);
    expect(coffeeSemanticSourceEcho(['Önünde yeni bir yol açılıyor.'], [item('e1', 'bird')])).toBe(false);
  });

  it('returns typed insufficient-semantic-signal for unknown-only before any writer packet exists', () => {
    const result = packet(item('e1', 'umbrella'));
    expect(result).toEqual({ status: 'insufficient_semantic_signal', reason: 'no_safe_semantic_facets' });
    expect(JSON.stringify(result)).not.toContain('umbrella');
  });

  it('returns unknown-only outcome from the pipeline without calling provider transport', async () => {
    let providerCalls = 0;
    const pipeline = new ReadingPipeline(testConfig(), {
      complete: async () => {
        providerCalls += 1;
        throw new Error('provider must not be called');
      },
    } as never);
    const internal = pipeline as unknown as {
      runCoffeeWriter: (
        obs: CoffeeObservation,
        ctx: { identity: string; parentKey: string; language: 'tr' },
        model: string,
        stages: unknown[],
      ) => Promise<unknown>;
    };
    await expect(internal.runCoffeeWriter(
      observation(item('e1', 'umbrella')),
      { identity: 'c23', parentKey: 'unknown-only', language: 'tr' },
      'test-writer',
      [],
    )).resolves.toEqual({ status: 'insufficient_semantic_signal', reason: 'no_safe_semantic_facets' });
    expect(providerCalls).toBe(0);
  });

  it('treats supported handle context as a sparse semantic plan without inventing an event', () => {
    const ready = packet(item('e1', null, 'handle_side'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    expect(ready.storyPlan).toMatchObject({ specificity: 'sparse', lead: { family: 'home_close_circle' } });
    expect(ready.storyPlan.authorizedSections).toEqual(['visualObservation', 'overall', 'takeaway']);
  });

  it('enforces semantic-capacity-aware depth without one global padding floor', () => {
    const single = packet(item('e1', 'bird'));
    const multi = packet(item('e1', 'bird'), item('e2', 'road'));
    if ('status' in single || 'status' in multi) throw new Error('expected ready');
    const words = Array.from({ length: 30 }, (_, index) => `söz${index}`).join(' ');
    const narrative: CoffeeNarrative = {
      visualObservation: { text: 'Kısa güvenli köprü.', evidenceIds: ['e1'] },
      overall: { text: words, evidenceIds: ['e1'] },
      love: { text: '', evidenceIds: [] }, career: { text: '', evidenceIds: [] }, money: { text: '', evidenceIds: [] }, nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'Bir iki üç dört beş altı yedi sekiz dokuz on.', evidenceIds: ['e1'] },
    };
    expect(coffeePlanDepthFailure(narrative, single.storyPlan)).toBe(false);
    expect(coffeePlanDepthFailure(narrative, multi.storyPlan)).toBe(true);
  });

  it.each(['too_short', 'possibility_menu', 'unsupported_user_state', 'evidence_leak'])('%s repair gets plan + code, never raw/rejected prose', (violation) => {
    const ready = packet(item('e1', 'bird'));
    expect('status' in ready).toBe(false);
    if ('status' in ready) throw new Error('expected ready');
    const request = repairWriterUser({ evidenceJson: JSON.stringify(ready), violations: [violation] });
    expect(request).toContain('storyPlan');
    expect(request).toContain(`Violation codes: ${violation}`);
    expect(request).not.toContain('Rejected narrative JSON');
    expect(request).not.toMatch(/description|resemblance|region|sourceSlot|confidence|visibility/);
  });

  it('requires complete evidence-bound repair fields at schema and prompt level', () => {
    const properties = COFFEE_WRITER_SCHEMA.properties;
    for (const key of ['visualObservation', 'overall', 'takeaway'] as const) {
      expect(properties[key].properties.text.minLength).toBe(1);
      expect(properties[key].properties.evidenceIds.minItems).toBe(1);
    }
    const prompt = repairWriterSystem('coffee');
    expect(prompt).toContain('Return every schema field');
    expect(prompt).toContain('MUST each contain non-empty text with valid evidenceIds');
    expect(prompt).toContain('rejected narrative is deliberately unavailable');
  });

  it('keeps Palm writer byte-for-byte unchanged', () => {
    expect(createHash('sha256').update(palmWriterSystem('tr')).digest('hex')).toBe(
      '936ce247f105af55fe5719bfef944fc03af0d96303150cb13985a653288c1a6a',
    );
  });
});
