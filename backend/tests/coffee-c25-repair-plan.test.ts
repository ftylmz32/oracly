import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';
import { repairWriterSystem, repairWriterUser } from '../src/ai/reading/writer-prompts.js';
import { testConfig } from './helpers.js';

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const item = (id: string, resemblance: string): ReadingEvidenceItem => ({
  id, region: 'middle_wall', description: `private ${resemblance} geometry`, resemblance,
  confidence: 'high', visibility: 'clear',
});
const observation = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const packet = () => {
  const result = buildCoffeeWriterPacketV2(observation(item('e1', 'bird'), item('e2', 'road')), 'tr');
  if ('status' in result) throw new Error('expected ready');
  return result;
};
const section = (text: string, evidenceIds = ['e1']) => ({ text, evidenceIds });
const rejected = (overall: string, takeaway: string, extras: Partial<Record<'love' | 'career' | 'money' | 'nearFuture', string>> = {}): CoffeeNarrative => ({
  visualObservation: section('Kısa bir anlam köprüsü burada duruyor.'), overall: section(overall),
  love: section(extras.love ?? '', extras.love ? ['e1'] : []),
  career: section(extras.career ?? '', extras.career ? ['e1'] : []),
  money: section(extras.money ?? '', extras.money ? ['e1'] : []),
  nearFuture: section(extras.nearFuture ?? '', extras.nearFuture ? ['e1'] : []),
  takeaway: section(takeaway),
});

describe('C2.5 structured Coffee Repair Plan V2', () => {
  it('reports exact too_short section deficits without rejected text', () => {
    const narrative = rejected('Bir iki üç dört beş.', 'Bir iki üç.');
    const plan = buildCoffeeRepairPlan(narrative, 'too_short', packet().storyPlan, 'tr');
    expect(plan.locale).toBe('tr');
    expect(plan.defect.kind).toBe('structural_deficit');
    expect(plan.sectionDeficits).toEqual([
      { section: 'overall', minimumWords: 40, actualWords: 5, additionalWordsNeeded: 35, needsAdditionalGroundedDevelopment: true },
      { section: 'takeaway', minimumWords: 10, actualWords: 3, additionalWordsNeeded: 7, needsAdditionalGroundedDevelopment: true },
    ]);
    expect(plan.lengthDeficits).toEqual(expect.arrayContaining([
      expect.objectContaining({ target: 'lead', unit: 'words', minimum: 42 }),
      expect.objectContaining({ target: 'overall', unit: 'words', minimum: 40, actual: 5, additionalNeeded: 35 }),
      expect.objectContaining({ target: 'takeaway', unit: 'words', minimum: 10, actual: 3, additionalNeeded: 7 }),
    ]));
    expect(JSON.stringify(plan)).not.toContain(narrative.overall.text);
  });

  it('preserves explicit TR and EN locales without forwarding rejected prose', () => {
    const narrative = rejected('Kısa anlam.', 'Kısa sonuç.');
    const tr = buildCoffeeRepairPlan(narrative, 'too_short', packet().storyPlan, 'tr');
    const en = buildCoffeeRepairPlan(narrative, 'too_short', packet().storyPlan, 'en');
    expect(JSON.parse(JSON.stringify(tr)).locale).toBe('tr');
    expect(JSON.parse(JSON.stringify(en)).locale).toBe('en');
    expect(JSON.stringify(en)).not.toContain(narrative.overall.text);
  });

  it('identifies every unauthorized section that repair must clear', () => {
    const plan = buildCoffeeRepairPlan(
      rejected('Yeterince uzun olmayan ama ayrı bir ana anlatım.', 'Kısa bir sonuç.', { love: 'İzinsiz aşk.', money: 'İzinsiz para.' }),
      'unauthorized_section',
      packet().storyPlan,
    );
    expect(plan.unauthorizedSectionsToClear).toEqual(['love', 'money']);
  });

  it('targets all proposition kinds for abstract realization repair', () => {
    const plan = buildCoffeeRepairPlan(rejected('Soyut bir anlatım.', 'Soyut sonuç.'), 'abstract_reading', packet().storyPlan);
    expect(plan.defect).toEqual({
      kind: 'abstract_realization',
      propositionKinds: ['exchange_emergence', 'directional_change'],
    });
    expect(plan.requiredPropositionCoverage).toEqual(['exchange_emergence', 'directional_change']);
  });

  it('identifies forbidden claim categories for unsupported user state', () => {
    const plan = buildCoffeeRepairPlan(rejected('Beklediğin konu hareket kazanıyor.', 'Sonuç geliyor.'), 'presumed_user_state', packet().storyPlan);
    expect(plan.defect.kind).toBe('unsupported_concretization');
    expect(plan.forbiddenClaimCategoriesTriggered).toEqual(expect.arrayContaining([
      'awaited_topic', 'prior_stagnation', 'current_major_decision', 'options_assumption',
    ]));
  });

  it('turns possibility_menu into one-rendering work, not blind regeneration', () => {
    const plan = buildCoffeeRepairPlan(rejected('Haber ya da mesaj gelebilir.', 'Bir gelişme var.'), 'possibility_menu', packet().storyPlan);
    expect(plan.defect.kind).toBe('multiple_renderings');
    expect(plan.requiredPropositionCoverage).toEqual(['exchange_emergence', 'directional_change']);
  });

  it('gives section redundancy a dedicated synthesis repair operation', () => {
    const plan = buildCoffeeRepairPlan(rejected(
      'Aynı anlam farklı sözlerle birkaç kez yeniden anlatılıyor ve bölümler yeni bir içgörü eklemiyor.',
      'Aynı anlam yeniden söyleniyor.',
    ), 'section_redundancy', packet().storyPlan, 'tr');
    expect(plan.defect).toEqual({ kind: 'synthesis_redundancy', propositionKinds: [] });
    expect(plan).not.toHaveProperty('lengthDeficits');
  });

  it('reports an actionable observation or combined-lead deficit even when section word floors pass', () => {
    const narrative = rejected(
      Array.from({ length: 40 }, (_, i) => `anlam${i}`).join(' '),
      'Bu sonuç gündelik yaşamında kendine özgü ve sakin bir karşılık bulabilir.',
    );
    narrative.visualObservation.text = 'Kısa.';
    const plan = buildCoffeeRepairPlan(narrative, 'too_short', packet().storyPlan, 'tr');
    expect(plan.sectionDeficits).toEqual([]);
    expect(plan.lengthDeficits).toEqual([
      { target: 'visualObservation', unit: 'characters', minimum: 40, actual: 5, additionalNeeded: 35 },
      { target: 'lead', unit: 'words', minimum: 42, actual: 41, additionalNeeded: 1 },
    ]);
  });

  it.each([
    ['unsupported_source_causation', 'causation'],
    ['unsupported_chronology', 'chronology'],
  ] as const)('%s repair names the exact forbidden relation', (violation, relation) => {
    const plan = buildCoffeeRepairPlan(rejected('Yeterli ana anlatım burada korunuyor.', 'Yeterli sonuç burada korunuyor.'), violation, packet().storyPlan, 'tr');
    expect(plan.defect.kind).toBe('unsupported_concretization');
    expect(plan.forbiddenClaimCategoriesTriggered).toContain(relation);
  });

  it('contains only safe plan metadata and evidence IDs, never raw evidence or rejected prose', () => {
    const narrative = rejected('Beklediğin özel kuş haberi geliyor.', 'Telve yol gösteriyor.');
    const plan = buildCoffeeRepairPlan(narrative, 'evidence_leak', packet().storyPlan);
    const serialized = JSON.stringify(plan);
    expect(serialized).not.toContain(narrative.overall.text);
    expect(serialized).not.toContain(narrative.takeaway.text);
    expect(serialized).not.toMatch(/description|resemblance|region|sourceSlot|confidence|visibility|bird|road/);
    expect(plan.evidenceIds).toEqual(['e1', 'e2']);
  });

  it('serializes the structured repair plan without rejected prose or raw evidence', () => {
    const narrative = rejected('Beklediğin haber geliyor.', 'Kısa sonuç.');
    const plan = buildCoffeeRepairPlan(narrative, 'presumed_user_state', packet().storyPlan);
    const request = repairWriterUser({ evidenceJson: JSON.stringify(plan), violations: [plan.violation] });
    expect(request).toContain('Private structured Coffee repair plan:');
    expect(request).toContain('sectionDeficits');
    expect(request).toContain('forbiddenClaimCategoriesTriggered');
    expect(request).not.toContain('Rejected narrative JSON');
    expect(request).not.toContain(narrative.overall.text);
    expect(request).not.toMatch(/description|resemblance|region|sourceSlot|confidence|visibility/);
  });

  it('keeps the one-repair contract and complete required schema instruction explicit', () => {
    const prompt = repairWriterSystem('coffee');
    expect(repairWriterSystem('coffee', 'tr')).toContain('TARGET LOCALE IS tr');
    expect(repairWriterSystem('coffee', 'en')).toContain('TARGET LOCALE IS en');
    expect(prompt).toContain('ALL user-visible narrative text MUST be written only in this exact supplied locale');
    expect(prompt).toContain('PRIVATE STRUCTURED REPAIR PLAN');
    expect(prompt).toContain('sectionDeficits');
    expect(prompt).toContain('Return every schema field');
    expect(prompt).toContain('rejected narrative is deliberately unavailable');
    expect(prompt).not.toContain('try again until');
  });

  it('production pipeline sends one structured repair plan and never rejected/raw prose', async () => {
    readingStageStore.clear();
    const failed = rejected('Bir iki üç dört beş.', 'Bir iki üç.');
    const requests: Array<Record<string, unknown>> = [];
    const transport = {
      complete: async (request: Record<string, unknown>) => {
        requests.push(request);
        return JSON.stringify(failed);
      },
    };
    const pipeline = new ReadingPipeline(testConfig(), transport as never) as unknown as {
      runCoffeeWriter: (obs: CoffeeObservation, ctx: Record<string, unknown>, model: string, stages: unknown[]) => Promise<unknown>;
    };
    await expect(pipeline.runCoffeeWriter(
      observation(item('e1', 'bird'), item('e2', 'road')),
      { identity: 'c25-repair', parentKey: 'structured', language: 'tr' },
      'test',
      [],
    )).rejects.toBeDefined();
    expect(requests).toHaveLength(2);
    const messages = requests[1].messages as Array<{ role: string; content: unknown }>;
    const repairRequest = String(messages.find((message) => message.role === 'user')?.content);
    expect(repairRequest).toContain('"locale":"tr"');
    expect(messages.find((message) => message.role === 'system')?.content).toContain('TARGET LOCALE IS tr');
    expect(repairRequest).toContain('sectionDeficits');
    expect(repairRequest).toContain('requiredPropositionCoverage');
    expect(repairRequest).not.toContain(failed.overall.text);
    expect(repairRequest).not.toMatch(/private bird geometry|private road geometry|resemblance|region|confidence|visibility/);
  });
});
