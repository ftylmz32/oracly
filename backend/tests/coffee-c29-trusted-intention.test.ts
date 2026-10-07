import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  classifyCoffeeIntention,
  coffeePersonalizationSections,
} from '../src/ai/reading/coffee-intention-context.js';
import {
  coffeeClaimEnvelopeFailure,
  coffeeMetaNarration,
  coffeePersonIntentionClaim,
  coffeeSubjectAlignmentFailure,
} from '../src/ai/reading/coffee-claim-envelope.js';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { coffeeLengthDeficits, coffeeLengthRequirements } from '../src/ai/reading/coffee-length-contract.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
import { coffeeWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeWriterPacketV2 } from '../src/ai/reading/coffee-story-plan.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';
import { testConfig } from './helpers.js';

const INTENTION = {
  general: 'Önümüzdeki dönem genel olarak',
  love: 'Aşk ve ilişkilerim hakkında',
  career: 'İşim ve kariyerim hakkında',
  money: 'Maddi durumum hakkında',
  person: 'Aklımdaki kişiyle ilgili',
  decision: 'Önümdeki karar hakkında',
};

const checks = {
  cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true,
  milkFoamObstruction: false, usefulRegionsVisible: true,
};
const ev = (id: string, resemblance: string, region = 'middle_wall'): ReadingEvidenceItem => ({
  id, region, description: 'A compact clear mark with a stable outline.', resemblance, confidence: 'high', visibility: 'clear',
});
const neutral = (id: string): ReadingEvidenceItem => ({
  id, region: 'base', description: 'A faint film.', resemblance: null, confidence: 'low', visibility: 'uncertain',
});
const obsOf = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const packetFor = (obs: CoffeeObservation, intention?: string): CoffeeWriterPacketV2 => {
  const packet = buildCoffeeWriterPacketV2(obs, 'tr', intention ? personalizationFromUnknown({ personalization: { intention } }) : undefined);
  if ('status' in packet) throw new Error('expected writer-eligible packet');
  return packet;
};
const section = (text: string, ids: string[] = ['e1']) => ({ text, evidenceIds: text ? ids : [] });
const narrativeOf = (parts: Partial<Record<keyof CoffeeNarrative, string>>): CoffeeNarrative => ({
  visualObservation: section(parts.visualObservation ?? ''),
  overall: section(parts.overall ?? ''),
  love: section(parts.love ?? ''),
  career: section(parts.career ?? ''),
  money: section(parts.money ?? ''),
  nearFuture: section(parts.nearFuture ?? ''),
  takeaway: section(parts.takeaway ?? ''),
} as CoffeeNarrative);

describe('C2.9 — ONE trusted-intention contract', () => {
  it('classifies every shipped product choice deterministically', () => {
    expect(classifyCoffeeIntention(INTENTION.general)).toEqual({
      intention: INTENTION.general, subjectKind: 'general', authorizedSections: [], requiredSection: null,
      declaredFacts: [], allowedAssumptionExceptions: [], intentionForbiddenAssumptions: [],
    });
    expect(classifyCoffeeIntention(INTENTION.love)).toMatchObject({
      subjectKind: 'love_relationships', authorizedSections: ['love'], requiredSection: 'love',
      declaredFacts: [], allowedAssumptionExceptions: [],
    });
    expect(classifyCoffeeIntention(INTENTION.career)).toMatchObject({
      subjectKind: 'career_work', authorizedSections: ['career'], requiredSection: 'career',
      declaredFacts: [], allowedAssumptionExceptions: [],
    });
    expect(classifyCoffeeIntention(INTENTION.money)).toMatchObject({
      subjectKind: 'money_finance', authorizedSections: ['money'], requiredSection: 'money',
      declaredFacts: [], allowedAssumptionExceptions: [],
    });
    expect(classifyCoffeeIntention(INTENTION.person)).toEqual({
      intention: INTENTION.person, subjectKind: 'person_of_interest', authorizedSections: ['love'], requiredSection: 'love',
      declaredFacts: ['person_in_mind'], allowedAssumptionExceptions: [],
      intentionForbiddenAssumptions: ['existing_relationship', 'reciprocal_feeling'],
    });
    expect(classifyCoffeeIntention(INTENTION.decision)).toMatchObject({
      subjectKind: 'custom_decision', authorizedSections: [], requiredSection: null,
      declaredFacts: ['decision_exists'], allowedAssumptionExceptions: ['current_major_decision', 'options_assumption'],
    });
  });

  it('classifies custom text only by what it literally supplies', () => {
    expect(classifyCoffeeIntention('Bu yaz ne olacak')).toMatchObject({ subjectKind: 'custom_other', declaredFacts: [], allowedAssumptionExceptions: [] });
    expect(classifyCoffeeIntention('Sevgilimle ilişkimiz hakkında')).toMatchObject({
      declaredFacts: ['current_relationship'], allowedAssumptionExceptions: ['existing_relationship'],
    });
    // A category ("ilişkilerim") and look-alike words never declare a relationship.
    for (const text of ['İlişkilerim nasıl gidecek', 'Kocaman bir değişim olacak mı']) {
      expect(classifyCoffeeIntention(text)?.declaredFacts).not.toContain('current_relationship');
    }
    // C2.11 replaced the broad stated_condition with the granular awaiting_response.
    expect(classifyCoffeeIntention('İş başvurumdan haber bekliyorum')?.declaredFacts).toContain('awaiting_response');
    expect(classifyCoffeeIntention(INTENTION.general)?.declaredFacts).toEqual([]);
    expect(classifyCoffeeIntention(undefined)).toBeNull();
    expect(classifyCoffeeIntention('   ')).toBeNull();
  });

  it('never infers from memory or themes: they open legacy lanes but no facts or exceptions', () => {
    expect(coffeePersonalizationSections({ relevantThemes: ['career'] })).toEqual(['career']);
    const packet = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3')), undefined);
    expect(packet.storyPlan.subject).toBeUndefined();
    const themed = buildCoffeeWriterPacketV2(
      obsOf(ev('e1', 'may resemble a fork in the road'), ev('e2', 'may resemble a fork', 'lower_wall'), neutral('e3')),
      'tr',
      { relevantThemes: ['decision'], memorySummary: 'Bir karar konuşulmuştu.' },
    );
    if ('status' in themed) throw new Error('expected ready');
    expect(themed.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining(['current_major_decision', 'options_assumption']));
  });
});

describe('C2.9 — plan policy from the contract', () => {
  const heart = obsOf(ev('e1', 'may resemble a heart'), ev('e2', 'may resemble a heart', 'lower_wall'), neutral('e3'));
  const bird = obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3'));

  it('the Love CATEGORY does not authorize an existing relationship', () => {
    const plan = packetFor(heart, INTENTION.love).storyPlan;
    expect(plan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining(['existing_relationship', 'reciprocal_feeling', 'specific_other_person']));
    expect(plan.subject).toMatchObject({ kind: 'love_relationships', requiredSection: 'love', declaredFacts: [] });
  });

  it('only literal current-relationship wording lifts the existing-relationship ban', () => {
    const plan = packetFor(heart, 'Sevgilimle ilişkimiz hakkında').storyPlan;
    expect(plan.claimEnvelope.forbiddenAssumptions).not.toContain('existing_relationship');
    expect(plan.claimEnvelope.forbiddenAssumptions).toContain('reciprocal_feeling');
  });

  it('the person intention ADDS relationship and reciprocity bans even to communication', () => {
    const plan = packetFor(bird, INTENTION.person).storyPlan;
    expect(plan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining([
      'existing_relationship', 'reciprocal_feeling', 'specific_other_person', 'awaited_topic',
    ]));
    expect(plan.authorizedSections).toContain('love');
  });

  it('career and money never authorize job or money events', () => {
    for (const intention of [INTENTION.career, INTENTION.money]) {
      expect(packetFor(bird, intention).storyPlan.claimEnvelope.forbiddenAssumptions)
        .toEqual(expect.arrayContaining(['current_job_issue', 'money_event', 'guaranteed_outcome']));
    }
  });

  it('general authorizes no domain and no exception', () => {
    const plan = packetFor(bird, INTENTION.general).storyPlan;
    expect(plan.authorizedSections).toEqual(['visualObservation', 'overall', 'takeaway']);
    expect(plan.subject).toMatchObject({ kind: 'general', requiredSection: null, declaredFacts: [] });
  });

  it('the writer packet carries the subject and the person-intention contract', () => {
    const packet = packetFor(bird, INTENTION.person);
    expect(packet.storyPlan.subject).toEqual({
      kind: 'person_of_interest', intention: INTENTION.person, requiredSection: 'love',
      declaredFacts: ['person_in_mind'], intentionForbiddenAssumptions: ['existing_relationship', 'reciprocal_feeling'],
    });
    expect(packet.personalization).toEqual({ intention: INTENTION.person });
  });
});

describe('C2.9 — person-of-interest safety (C2.8 C07 failure class)', () => {
  const plan = packetFor(obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3')), INTENTION.person).storyPlan;
  const generalPlan = packetFor(obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3')), INTENTION.general).storyPlan;
  const fails = [
    'Aranızdaki ilişki yeni bir canlılık kazanıyor.',
    'Aranızdaki bağ güçleniyor.',
    'İki tarafın da kendini ifade edebildiği bir paylaşım beliriyor.',
    'O da seni düşünüyor olabilir.',
    'Bu karşılıklı bir yakınlaşma.',
    'Aklındaki kişi sana yaklaşacak.',
    'Aklındaki kişi sana mesaj atacak.',
    'Onun duyguları netleşiyor.',
    'Aklındaki kişi ilk adımı atmaya hazırlanıyor.',
  ];

  it.each(fails)('rejects "%s" under the person intention', (sentence) => {
    expect(coffeePersonIntentionClaim([sentence])).not.toBeNull();
    expect(coffeeClaimEnvelopeFailure(narrativeOf({ overall: sentence }), plan)).toMatch(/unsupported_(other_agency|existing_fact)/);
  });

  it('allows the user having someone in mind and a communication possibility around that subject', () => {
    const safe = 'Aklındaki kişiyle ilgili bir konuşma ihtimali senin için daha görünür hâle gelebilir.';
    expect(coffeePersonIntentionClaim([safe])).toBeNull();
  });

  it('is subject-aware: ordinary mutual language is not globally forbidden', () => {
    const general = narrativeOf({ overall: 'Karşılıklı bir paylaşım gündelik akışına daha çok karışıyor.' });
    expect(coffeeClaimEnvelopeFailure(general, generalPlan)).not.toBe('unsupported_other_agency');
  });
});

describe('C2.9 — meta-narration gate', () => {
  it.each([
    'Bu yorumun odağında, değerini yitirmeden süren bir yakınlık bulunuyor.',
    'Genel izlenim, hayatında ferahlık taşıyan bir yönün ağırlık kazandığını anlatıyor.',
    'Bu okuma senin için açılan bir kapıya odaklanıyor.',
  ])('catches reading self-reference: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).not.toBeNull();
  });

  it.each([
    'Biri diğerini yaratmadan, ikisi aynı bütün içinde yan yana duruyor.',
    'Bu iki eğilim birbirini zorlamadan yan yana duruyor.',
    'Farklı bir doğrultuyla çözüm alanının yan yana durduğunu gösteriyor.',
    'Çözüm ihtimali ile yeni yön tek bir anlamda buluşuyor.',
    'İki anlam aynı bütünün parçası olarak bir arada duruyor.',
  ])('catches synthesis-constraint explanation: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).not.toBeNull();
  });

  it.each([
    'Arkadaşlarınla yan yana yürüdüğün bir akşam sana iyi gelecek.',
    'Bu konudaki yorumun önemli bir yer tutuyor.',
    'İyi bir izlenim bırakacağın bir görüşme var.',
    'İki seçenek arasındaki fark sende netleşiyor.',
  ])('leaves ordinary language alone: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).toBeNull();
  });

  it('checks visualObservation too (where C2.8 C03/C12 hid it) and repairs toward natural realization', () => {
    const plan = packetFor(obsOf(ev('e1', 'may resemble a ring'), ev('e2', 'may resemble a ring', 'lower_wall'), neutral('e3'))).storyPlan;
    const n = narrativeOf({ visualObservation: 'Bu yorumun odağında süren bir yakınlık var.', overall: 'Hayatındaki yakınlık sürüyor.' });
    expect(coffeeClaimEnvelopeFailure(n, plan)).toBe('meta_narration');
    const repair = buildCoffeeRepairPlan(n, 'meta_narration', plan, 'tr');
    expect(repair.defect).toEqual({ kind: 'natural_realization', propositionKinds: ['connection_continuity'] });
  });
});

describe('C2.9 — required subject section and subject alignment', () => {
  const fish = obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3'));

  it('an empty required subject section is missing_intention_subject', () => {
    const plan = packetFor(fish, INTENTION.career).storyPlan;
    const n = narrativeOf({ overall: 'İşinde değerlendirebileceğin yeni bir imkân beliriyor.', takeaway: 'İşinde bir imkân var.' });
    expect(coffeeSubjectAlignmentFailure(n, plan)).toBe('missing_intention_subject');
  });

  it('denying or dropping the subject is intention_subject_drift', () => {
    const plan = packetFor(fish, INTENTION.money).storyPlan;
    const denial = narrativeOf({
      overall: 'Hayatında tek bir alana bağlanmadan yeni bir imkân beliriyor; maddi tarafı da var.',
      money: 'Maddi açıdan nefes alacağın bir imkân var.',
      takeaway: 'Para konusunda bir imkân görünüyor.',
    });
    expect(coffeeSubjectAlignmentFailure(denial, plan)).toBe('intention_subject_drift');
    const generic = narrativeOf({
      overall: 'Hayatında yeni olana yer açan bir imkân beliriyor.',
      money: 'Maddi açıdan nefes alacağın bir imkân var.',
      takeaway: 'Sana açık bir imkân var.',
    });
    expect(coffeeSubjectAlignmentFailure(generic, plan)).toBe('intention_subject_drift');
  });

  it('a subject-aligned reading passes without exact intention wording', () => {
    const plan = packetFor(fish, INTENTION.money).storyPlan;
    const n = narrativeOf({
      overall: 'Bütçende nefes aldıracak yeni bir imkân beliriyor.',
      money: 'Kazanç tarafında değerlendirebileceğin bir kapı aralanıyor.',
      takeaway: 'Paranla ilgili bu imkân senin elinde.',
    });
    expect(coffeeSubjectAlignmentFailure(n, plan)).toBeNull();
  });

  it('general has no required section; decision keeps overall as subject carrier', () => {
    expect(coffeeSubjectAlignmentFailure(narrativeOf({ overall: 'Yeni bir imkân beliriyor.', takeaway: 'Bir imkân var.' }), packetFor(fish, INTENTION.general).storyPlan)).toBeNull();
    const decision = packetFor(fish, INTENTION.decision).storyPlan;
    expect(decision.subject?.requiredSection).toBeNull();
    expect(coffeeSubjectAlignmentFailure(narrativeOf({ overall: 'Yeni bir imkân beliriyor.', takeaway: 'Bir imkân var.' }), decision)).toBe('intention_subject_drift');
    expect(coffeeSubjectAlignmentFailure(narrativeOf({ overall: 'Kararında yeni bir imkân beliriyor.', takeaway: 'Bir imkân var.' }), decision)).toBeNull();
  });
});

describe('C2.9 — repair receives the same trusted subject', () => {
  const fish = obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3'));

  it('carries intention, kind, required section, declared facts, intention bans, locale, and the length contract', () => {
    const packet = packetFor(fish, INTENTION.career);
    const rejected = narrativeOf({ overall: 'Kısa bir anlatım.', takeaway: 'Kısa.' });
    const plan = buildCoffeeRepairPlan(rejected, 'missing_intention_subject', packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(plan.locale).toBe('tr');
    expect(plan.subject).toEqual({
      kind: 'career_work', intention: INTENTION.career, requiredSection: 'career',
      declaredFacts: [], intentionForbiddenAssumptions: [], issue: 'missing_subject_section',
    });
    expect(plan.defect.kind).toBe('subject_alignment');
    expect(buildCoffeeRepairPlan(rejected, 'intention_subject_drift', packet.storyPlan, 'tr').subject?.issue).toBe('subject_drift');
    expect(buildCoffeeRepairPlan(rejected, 'too_short', packet.storyPlan, 'tr').defect.kind).toBe('structural_deficit');
    expect(plan.lengthRequirements).toEqual(packet.lengthRequirements);
    const text = JSON.stringify(plan);
    expect(text).not.toContain('Kısa bir anlatım');
    expect(text).not.toMatch(/description|resemblance|sourceSlot|region|confidence|visibility/);
  });

  it('the repair system prompt forbids subject loss and keeps the target locale', () => {
    const prompt = repairWriterSystem('coffee', 'tr');
    expect(prompt).toContain('TARGET LOCALE IS tr');
    expect(prompt).toContain('TRUSTED SUBJECT');
    expect(prompt).toContain('subject loss is itself a failure');
    expect(prompt).toContain('lengthRequirements');
    expect(prompt).toContain('natural_realization');
  });

  it('production repair transports the subject and never the rejected prose or raw evidence', async () => {
    const draft = narrativeOf({
      visualObservation: 'İşinde sana kapalı olmayan bir imkânın hissi var.',
      overall: 'İşinde değerlendirebileceğin bir imkân var.',
      career: 'Kariyerinde bir imkân var.',
      takeaway: 'İşinde bir imkân.',
    });
    const requests: Array<{ messages: Array<{ content: unknown }> }> = [];
    const pipeline = new ReadingPipeline(testConfig(), {
      complete: async (options: { messages: Array<{ content: unknown }> }) => {
        requests.push(options);
        return JSON.stringify(draft);
      },
    } as never);
    const run = (pipeline as unknown as {
      runCoffeeWriter: (obs: CoffeeObservation, ctx: unknown, model: string, stages: unknown[]) => Promise<unknown>;
    }).runCoffeeWriter.bind(pipeline);
    await expect(run(fish, {
      identity: 'c29', parentKey: `c29-${Date.now()}`, language: 'tr',
      personalization: { intention: INTENTION.career },
    }, 'test-model', [])).rejects.toBeTruthy();
    expect(requests).toHaveLength(2);
    const repair = JSON.stringify(requests[1].messages);
    expect(repair).toContain(INTENTION.career);
    expect(repair).toContain('career_work');
    expect(repair).toContain('lengthRequirements');
    expect(repair).not.toContain(draft.overall.text);
    expect(repair).not.toContain('may resemble a fish');
    expect(repair).not.toContain('middle_wall');
  });
});

describe('C2.9 — ONE authoritative length contract', () => {
  it('keeps every accepted floor (no lowering)', () => {
    expect(coffeeLengthRequirements()).toEqual({
      visualObservationMinChars: 40, combinedLeadMinWords: 42, overallMinChars: 80, overallMinWords: 22,
      overallMaxWords: null, takeawayMinWords: 10, takeawayMaxWords: null,
    });
    expect(coffeeLengthRequirements({ narrativelySparse: true })).toMatchObject({ combinedLeadMinWords: 35, overallMinWords: 20, takeawayMinWords: 8 });
  });

  it('the writer packet exposes the same values acceptance and repair use, including the combined lead floor', () => {
    const modest = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3')), INTENTION.career);
    expect(modest.lengthRequirements).toEqual(coffeeLengthRequirements({ storyPlan: modest.storyPlan }));
    expect(modest.lengthRequirements).toEqual({
      visualObservationMinChars: 40, combinedLeadMinWords: 42, overallMinChars: 80, overallMinWords: 26,
      overallMaxWords: 45, takeawayMinWords: 10, takeawayMaxWords: 16,
    });
    const rich = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')), INTENTION.money);
    expect(rich.lengthRequirements).toMatchObject({ overallMinWords: 40, overallMaxWords: 70, takeawayMinWords: 10, takeawayMaxWords: 18 });
    const prompt = coffeeWriterSystem('tr');
    expect(prompt).toContain('lengthRequirements is the ONE authoritative length contract');
    expect(prompt).toContain('combinedLeadMinWords');
    expect(prompt).not.toMatch(/\b42\b|\b26\b/);
  });

  it('INVARIANT: too_short => non-empty actionable lengthDeficits on every Coffee V2 path', () => {
    const plans = [
      packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3')), INTENTION.career),
      packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')), INTENTION.money),
      packetFor(obsOf(ev('e1', 'may resemble a key'), ev('e2', 'may resemble a key', 'lower_wall'), neutral('e3'))),
    ];
    // C2.11A.1: development-neutral filler, so no plan rejects it for importing
    // another beat's development before the length invariant is measured.
    const sentence = 'Önümüzdeki günlerde içini ısıtacak tatlı bir kıpırtı sana doğru yaklaşıyor';
    let tooShort = 0;
    for (const packet of plans) {
      for (let words = 4; words <= 80; words += 3) {
        for (let take = 3; take <= 20; take += 4) {
          const body = Array.from({ length: words }, (_, i) => sentence.split(' ')[i % 10]).join(' ');
          const n = narrativeOf({
            visualObservation: 'Önümüzdeki günlerde içini ısıtan tatlı bir kıpırtının hissi sana eşlik ediyor.',
            overall: `${body}.`,
            takeaway: `${Array.from({ length: take }, () => 'kıpırtı').join(' ')}.`,
          });
          const q = coffeeQualityFailure(n, 'tr', undefined, undefined, packet.storyPlan);
          if (q !== 'too_short') continue;
          tooShort += 1;
          const repair = buildCoffeeRepairPlan(n, 'too_short', packet.storyPlan, 'tr', packet.lengthRequirements);
          expect(repair.lengthDeficits?.length).toBeGreaterThan(0);
          expect(repair.lengthDeficits).toEqual(coffeeLengthDeficits(n, packet.lengthRequirements));
        }
      }
    }
    expect(tooShort).toBeGreaterThan(20);
  });
});

// ---------------------------------------------------------------------------
// Deterministic C2.8 regression (frozen corpus; ZERO provider calls).
// ---------------------------------------------------------------------------
const qa = resolve(process.cwd(), 'docs/qa');
const manifest = JSON.parse(readFileSync(resolve(qa, 'coffee-c28-intention-blind-20261007.manifest.json'), 'utf8')) as {
  checks: CoffeeObservation['checks'];
  cases: Array<{ id: string; intention: string; evidence: Array<ReadingEvidenceItem & { observationSource: string }>; expectedOutcome?: unknown }>;
};
const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c28-intention-blind-20261007.raw.json'), 'utf8')) as {
  results: Array<{ caseId: string; attempts: Array<{ parsed: CoffeeNarrative; qualityFailure: string | null; bindFailure: string | null }> }>;
};
const c28 = (id: string) => {
  const testCase = manifest.cases.find((item) => item.id === id)!;
  const obs: CoffeeObservation = { usable: true, reason: '', checks: manifest.checks, evidence: testCase.evidence.map(({ observationSource: _s, ...item }) => item) };
  const personalization = personalizationFromUnknown({ personalization: { intention: testCase.intention } });
  const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalization);
  const attempts = corpus.results.find((item) => item.caseId === id)!.attempts;
  return { testCase, obs, personalization, packet, attempts };
};
const ready = (id: string) => {
  const value = c28(id);
  if ('status' in value.packet) throw new Error('expected writer case');
  return { ...value, packet: value.packet };
};
const firstViolation = (attempt: { qualityFailure: string | null; bindFailure: string | null }) =>
  attempt.bindFailure === 'human_quality' ? (attempt.qualityFailure ?? 'human_quality') : attempt.bindFailure!;

describe('C2.9 — C2.8 deterministic regression', () => {
  it('C01 general stays no-domain with no authorization', () => {
    const { packet } = ready('C01');
    expect(packet.storyPlan.subject).toMatchObject({ kind: 'general', requiredSection: null, declaredFacts: [] });
    expect(packet.storyPlan.authorizedSections).toEqual(['visualObservation', 'overall', 'takeaway']);
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining(['awaited_topic', 'specific_other_person']));
  });

  it.each([
    ['C02', 'love', 'love_relationships'],
    ['C04', 'career', 'career_work'],
    ['C05', 'career', 'career_work'],
    ['C06', 'money', 'money_finance'],
    ['C10', 'love', 'love_relationships'],
    ['C11', 'career', 'career_work'],
    ['C12', 'money', 'money_finance'],
  ] as const)('%s: required %s subject, repair retains it, and the recorded subject-less repair now fails', (id, lane, kind) => {
    const { packet, attempts } = ready(id);
    expect(packet.storyPlan.subject).toMatchObject({ kind, requiredSection: lane });
    const repair = buildCoffeeRepairPlan(attempts[0].parsed, firstViolation(attempts[0]), packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(repair.subject).toMatchObject({ kind, requiredSection: lane, intention: ready(id).testCase.intention });
    expect(repair.locale).toBe('tr');
    expect(attempts[1].parsed[lane].text).toBe('');
    expect(coffeeSubjectAlignmentFailure(attempts[1].parsed, packet.storyPlan)).toBe('missing_intention_subject');
  });

  it('C03: the love category no longer authorizes an existing relationship; the delivered repair is rejected', () => {
    const { packet, attempts, obs, personalization } = ready('C03');
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toContain('existing_relationship');
    // C2.11: the implied existing bond ("Hayatındaki önemli bir bağ … varlığını koruyor")
    // is an unsupported claim and outranks the meta-narration it also contains.
    expect(coffeeQualityFailure(attempts[1].parsed, 'tr', personalization, obs.evidence, packet.storyPlan)).toBe('unsupported_existing_fact');
    expect(bindCoffeeNarrative(attempts[1].parsed, obs, 'tr', personalization, packet.storyPlan)).toBe('human_quality');
  });

  it.each(['C07', 'C08'])('%s: person intention forbids existing relationship and reciprocity', (id) => {
    const { packet } = ready(id);
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toEqual(expect.arrayContaining(['existing_relationship', 'reciprocal_feeling', 'specific_other_person']));
    expect(packet.storyPlan.subject).toMatchObject({ kind: 'person_of_interest', requiredSection: 'love', declaredFacts: ['person_in_mind'] });
  });

  it('C07: the invented mutual bond in the writer draft is now caught by the person gate', () => {
    const { packet, attempts } = ready('C07');
    expect(attempts[0].parsed.overall.text).toContain('Aranızdaki');
    expect(coffeeClaimEnvelopeFailure(attempts[0].parsed, packet.storyPlan)).toBe('unsupported_existing_fact');
    expect(coffeePersonIntentionClaim([attempts[0].parsed.love.text])).toBe('unsupported_other_agency');
  });

  it('C09: the user-declared decision exception remains valid and the decision stays the subject', () => {
    const { packet, attempts } = ready('C09');
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).not.toContain('current_major_decision');
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).not.toContain('options_assumption');
    expect(packet.storyPlan.subject).toMatchObject({ kind: 'custom_decision', requiredSection: null, declaredFacts: ['decision_exists'] });
    expect(coffeeSubjectAlignmentFailure(attempts[1].parsed, packet.storyPlan)).toBeNull();
  });

  it('C10: repair keeps the love subject and the unified synthesis task; the delivered reading is rejected', () => {
    const { packet, attempts } = ready('C10');
    const repair = buildCoffeeRepairPlan(attempts[0].parsed, firstViolation(attempts[0]), packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(repair.defect.kind).toBe('synthesis_redundancy');
    expect(repair.storyPlan.synthesis.mode).toBe('unified_cooccurrence');
    expect(repair.subject?.requiredSection).toBe('love');
    expect(coffeeMetaNarration([attempts[1].parsed.overall.text])).not.toBeNull();
  });

  it('C11: career subject kept, causation still forbidden, recorded causation still caught', () => {
    const { packet, attempts, obs, personalization } = ready('C11');
    expect(packet.storyPlan.claimEnvelope.forbiddenAssumptions).toContain('causation');
    expect(coffeeQualityFailure(attempts[1].parsed, 'tr', personalization, obs.evidence, packet.storyPlan)).toBe('unsupported_source_causation');
  });

  it('C12: the delivered reading narrated synthesis and dropped money; both are now caught', () => {
    const { packet, attempts } = ready('C12');
    expect(coffeeMetaNarration([attempts[1].parsed.overall.text])).not.toBeNull();
    expect(coffeeSubjectAlignmentFailure(attempts[1].parsed, packet.storyPlan)).toBe('missing_intention_subject');
  });

  it.each(['C13', 'C14', 'C15'])('%s: semantic-capacity policy unchanged (zero provider calls)', (id) => {
    const { packet, testCase, attempts } = c28(id);
    expect(packet).toEqual(testCase.expectedOutcome);
    expect(attempts).toHaveLength(0);
  });

  it('every recorded C2.8 too_short attempt yields actionable deficits under the current contract', () => {
    let count = 0;
    for (const id of ['C01', 'C02', 'C03', 'C04', 'C05', 'C06', 'C07', 'C08', 'C09', 'C10', 'C11', 'C12']) {
      const { packet, attempts, obs, personalization } = ready(id);
      for (const attempt of attempts) {
        if (coffeeQualityFailure(attempt.parsed, 'tr', personalization, obs.evidence, packet.storyPlan) !== 'too_short') continue;
        count += 1;
        expect(buildCoffeeRepairPlan(attempt.parsed, 'too_short', packet.storyPlan, 'tr', packet.lengthRequirements).lengthDeficits?.length).toBeGreaterThan(0);
      }
    }
    // C2.11 precedence surfaces more serious defects first on most of these.
    expect(count).toBeGreaterThanOrEqual(1);
  });
});
