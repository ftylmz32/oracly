import { describe, expect, it } from 'vitest';
import { coffeeClaimEnvelopeFailure } from '../src/ai/reading/coffee-claim-envelope.js';
import { buildCoffeeWriterPacketV2, mapCoffeeMeanings } from '../src/ai/reading/coffee-meaning-map.js';
import {
  coffeeSemanticCapacity,
  mapCoffeePropositions,
  type CoffeePropositionKind,
} from '../src/ai/reading/coffee-semantic-propositions.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
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
  id, region, description: resemblance ? `clear ${resemblance} form` : 'plain contextual residue',
  resemblance, confidence: 'high', visibility: 'clear',
});
const obs = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const props = (...evidence: ReadingEvidenceItem[]) => mapCoffeePropositions(mapCoffeeMeanings(obs(...evidence), 'tr'));
const ready = (...evidence: ReadingEvidenceItem[]) => {
  const packet = buildCoffeeWriterPacketV2(obs(...evidence), 'tr');
  if ('status' in packet) throw new Error(`expected ready, got ${packet.reason}`);
  return packet;
};
const section = (text: string, evidenceIds = ['e1']) => ({ text, evidenceIds });
const narrative = (overall: string, takeaway = 'Bu anlam günlük hayatında kendine özgü bir karşılık bulabilir.'): CoffeeNarrative => ({
  visualObservation: section('Anlamın iki yönü aynı çerçevede birleşiyor.'), overall: section(overall),
  love: section('', []), career: section('', []), money: section('', []), nearFuture: section('', []),
  takeaway: section(takeaway),
});

describe('C2.5 grounded Coffee semantic propositions', () => {
  it.each([
    ['bird', 'exchange_emergence', 'awaited_topic'],
    ['fish', 'opening_availability', 'money_event'],
    ['ring', 'connection_continuity', 'existing_relationship'],
    ['heart', 'felt_significance', 'reciprocal_feeling'],
    ['key', 'resolution_availability', 'prior_problem'],
    ['road', 'directional_change', 'travel'],
    ['fork', 'alternative_distinction', 'current_major_decision'],
    ['tree', 'gradual_expansion', 'prior_stagnation'],
    ['person', 'social_presence', 'specific_other_person'],
  ] as const)('%s maps to one %s proposition with %s forbidden', (source, kind, forbidden) => {
    const mapped = props(item('e1', source));
    expect(mapped).toHaveLength(1);
    expect(mapped[0]).toMatchObject({ kind, evidenceIds: ['e1'], support: 'single' });
    expect(mapped[0].forbiddenAssumptions).toContain(forbidden);
  });

  it('maps handle context to proximate_context without family/event escalation', () => {
    const mapped = props(item('e1', null, 'handle_side'));
    expect(mapped[0]).toMatchObject({ kind: 'proximate_context', context: 'home_close_circle' });
    expect(mapped[0].forbiddenAssumptions).toEqual(expect.arrayContaining([
      'family_event', 'specific_other_person', 'reciprocal_feeling',
    ]));
  });

  it('uses only proposition count and independent support for semantic capacity', () => {
    expect(coffeeSemanticCapacity([])).toBe('insufficient');
    expect(coffeeSemanticCapacity(props(item('e1', 'bird')))).toBe('insufficient');
    expect(coffeeSemanticCapacity(props(item('e1', 'bird'), item('e2', 'bird')))).toBe('modest');
    expect(coffeeSemanticCapacity(props(item('e1', 'bird'), item('e2', 'road')))).toBe('rich');
    expect(coffeeSemanticCapacity(props(item('e1', null, 'handle_side'), item('e2', null, 'handle_side')))).toBe('insufficient');
  });

  it('distinguishes visual validity from semantic sufficiency for one-off and home-only meaning', () => {
    expect(buildCoffeeWriterPacketV2(obs(item('e1', 'bird')), 'tr')).toEqual({
      status: 'insufficient_semantic_signal', reason: 'insufficient_semantic_capacity',
    });
    expect(buildCoffeeWriterPacketV2(obs(item('e1', null, 'handle_side')), 'tr')).toEqual({
      status: 'insufficient_semantic_signal', reason: 'insufficient_semantic_capacity',
    });
  });

  it('keeps a repeated independently supported direct proposition writer-eligible', () => {
    const packet = ready(item('e1', 'bird'), item('e2', 'bird'));
    expect(packet.storyPlan).toMatchObject({
      version: 2, semanticCapacity: 'modest',
      lead: { kind: 'exchange_emergence', evidenceIds: ['e1', 'e2'], support: 'independent_repeat' },
      synthesis: { mode: 'single_realization', required: true },
    });
  });

  it('C08 requires unified communication+movement synthesis and forbids causation', () => {
    const packet = ready(item('e1', 'bird'), item('e2', 'road'));
    expect(packet.storyPlan.lead.kind).toBe('exchange_emergence');
    expect(packet.storyPlan.supporting).toEqual([expect.objectContaining({ kind: 'directional_change', relation: 'co_occurring' })]);
    expect(packet.storyPlan.synthesis).toEqual({
      mode: 'unified_cooccurrence', required: true,
      forbiddenRelations: ['causation', 'chronology', 'component_serialization'],
    });
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toContain('causation');
  });

  it('C09 forms one synthesis with no decision/options, money, or love authorization', () => {
    const packet = ready(item('e1', 'fish'), item('e2', 'heart'));
    expect(packet.storyPlan.synthesis.mode).toBe('unified_cooccurrence');
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining([
      'current_major_decision', 'options_assumption', 'money_event', 'existing_relationship',
    ]));
    expect(packet.storyPlan.authorizedSections).not.toContain('money');
    expect(packet.storyPlan.authorizedSections).not.toContain('love');
  });

  it('explicit decision personalization narrowly authorizes that context without opening money/love', () => {
    const result = buildCoffeeWriterPacketV2(
      obs(item('e1', 'fish'), item('e2', 'heart')),
      'tr',
      { relevantThemes: ['decision'], memorySummary: 'Prior decision remained open.' },
    );
    if ('status' in result) throw new Error('expected ready');
    expect(result.storyPlan.claimEnvelope.forbiddenAssumptions).not.toContain('current_major_decision');
    expect(result.storyPlan.claimEnvelope.forbiddenAssumptions).not.toContain('options_assumption');
    expect(result.storyPlan.claimEnvelope.forbiddenAssumptions).toContain('money_event');
    expect(result.storyPlan.authorizedSections).not.toContain('money');
    expect(result.storyPlan.authorizedSections).not.toContain('love');
  });

  it.each([
    ['Aşk ve ilişkilerim hakkında', 'love'],
    ['İşim ve kariyerim hakkında', 'career'],
    ['Maddi durumum hakkında', 'money'],
  ] as const)('C2.7B trusted intention %s opens only %s', (intention, section) => {
    const result = buildCoffeeWriterPacketV2(obs(item('e1', 'bird'), item('e2', 'road')), 'tr', { intention });
    if ('status' in result) throw new Error('expected ready');
    expect(result.storyPlan.authorizedSections).toContain(section);
    expect(result.personalization).toEqual({ intention });
  });

  it('C2.7B general intention opens no optional domain', () => {
    const result = buildCoffeeWriterPacketV2(obs(item('e1', 'bird'), item('e2', 'road')), 'tr', {
      intention: 'Önümüzdeki dönem genel olarak',
    });
    if ('status' in result) throw new Error('expected ready');
    expect(result.storyPlan.authorizedSections).not.toEqual(expect.arrayContaining(['love', 'career', 'money']));
  });

  it('C2.7B person intention opens the subject lane but preserves relationship, reciprocity and agency bans', () => {
    const result = buildCoffeeWriterPacketV2(obs(item('e1', 'ring'), item('e2', 'heart')), 'tr', {
      intention: 'Aklımdaki kişiyle ilgili',
    });
    if ('status' in result) throw new Error('expected ready');
    expect(result.storyPlan.authorizedSections).toContain('love');
    expect(result.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining([
      'existing_relationship', 'reciprocal_feeling', 'specific_other_person',
    ]));
  });

  it('C10 gives one synthesis task rather than a sequence of components', () => {
    const packet = ready(item('e1', 'key'), item('e2', 'road'), item('e3', 'bird'));
    expect(packet.storyPlan.lead.kind).toBe('resolution_availability');
    expect(packet.storyPlan.supporting.map((value) => value.kind)).toEqual(['exchange_emergence', 'directional_change']);
    expect(JSON.stringify(packet.storyPlan)).not.toMatch(/first|then|therefore|sequence/);
    expect(packet.storyPlan.synthesis.forbiddenRelations).toContain('component_serialization');
  });

  it('does not expose family enums or ready-made public prose in the production packet', () => {
    const packet = ready(item('e1', 'fish'), item('e2', 'heart'));
    const serialized = JSON.stringify(packet);
    expect(serialized).not.toMatch(/"family"|opportunity|emotional_relevance|fırsat|duygusal/);
    expect(serialized).not.toMatch(/description|resemblance|region|confidence|visibility/);
  });

  it.each([
    ['C01 awaited importance', ['bird', 'bird'], 'Beklediğin önemli iletişim yakında açıklık kazanacak.', 'presumed_user_state'],
    ['C02 prior stagnation', ['fish', 'fish'], 'Uzun süredir aynı çerçevede kalan hayatında bir fırsat beliriyor.', 'unsupported_existing_fact'],
    ['C03 reciprocal bond', ['ring', 'ring'], 'Aranızdaki karşılıklı yakınlık ve ilişkin güçlenecek.', 'unsupported_existing_fact'],
    ['C04 personality fallback', ['heart', 'heart'], 'Duyguların günlük kararlarında belirleyici bir yer tutuyor.', 'abstract_reading'],
    ['C05 prior burden', ['key', 'key'], 'Uzun süredir zihnini meşgul eden konu artık çözülüyor.', 'unsupported_existing_fact'],
    ['C06 waiting process', ['road', 'road'], 'Bekleyen süreç hareket kazanarak durgunluğu bitiriyor.', 'unsupported_existing_fact'],
    ['C11 current choice', ['fork', 'fork'], 'Vereceğin karar için doğru seçimi yapmalısın.', 'presumed_user_state'],
    ['C12 guarantee', ['tree', 'tree'], 'Kapasiten büyüyecek ve kesinlikle genişleyeceksin.', 'unsupported_certainty'],
  ] as const)('%s is rejected by the exact claim envelope', (_label, sources, prose, failure) => {
    const packet = ready(item('e1', sources[0]), item('e2', sources[1]));
    expect(coffeeClaimEnvelopeFailure(narrative(prose), packet.storyPlan)).toBe(failure);
  });

  it('C08 rejects unsupported causal realization', () => {
    const packet = ready(item('e1', 'bird'), item('e2', 'road'));
    expect(coffeeClaimEnvelopeFailure(
      narrative('Açık bir iletişim değişime yol açacak; böylece hayatında hareket başlayacak.'),
      packet.storyPlan,
    )).toBe('unsupported_source_causation');
  });

  it('C09 rejects the blind-corpus decision/options framing', () => {
    const packet = ready(item('e1', 'fish'), item('e2', 'heart'));
    expect(coffeeClaimEnvelopeFailure(
      narrative('Kararın kuru bir hesapla sınırlı kalmayacak; seçeneklerin arasında içine sineni ayıracaksın.'),
      packet.storyPlan,
    )).toBe('presumed_user_state');
  });

  it('C10 rejects component-label serialization', () => {
    const packet = ready(item('e1', 'key'), item('e2', 'bird'), item('e3', 'road'));
    expect(coffeeClaimEnvelopeFailure(
      narrative('Çözüm öne çıkıyor. İletişim hayatında belirleyici oluyor. Hareket alanı belirginleşiyor.'),
      packet.storyPlan,
    )).toBe('abstract_reading');
  });

  it.each([
    ['C13 unknown-only', obs(item('e1', 'umbrella'), item('e2', null), item('e3', null))],
    ['C07 home-only', obs(item('e1', null, 'handle_side'), item('e2', null, 'handle_side'), item('e3', null, 'handle_side'))],
    ['C14 sparse home-only', obs(item('e1', null, 'handle_side'), item('e2', null), item('e3', null))],
  ])('%s returns insufficiency with zero provider calls', async (_label, observation) => {
    let providerCalls = 0;
    const pipeline = new ReadingPipeline(testConfig(), { complete: async () => { providerCalls += 1; throw new Error('no call'); } } as never);
    const internal = pipeline as unknown as { runCoffeeWriter: (o: CoffeeObservation, c: Record<string, unknown>, m: string, s: unknown[]) => Promise<unknown> };
    const result = await internal.runCoffeeWriter(observation, { identity: 'c25', parentKey: String(Math.random()), language: 'tr' }, 'test', []);
    expect(result).toMatchObject({ status: 'insufficient_semantic_signal' });
    expect(providerCalls).toBe(0);
  });

  it('preserves the exact C13 typed reason', () => {
    expect(buildCoffeeWriterPacketV2(obs(item('e1', 'umbrella')), 'tr')).toEqual({
      status: 'insufficient_semantic_signal', reason: 'no_safe_semantic_facets',
    });
  });
});
