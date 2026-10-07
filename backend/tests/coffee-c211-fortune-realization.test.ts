import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { mapCoffeeSemanticCues } from '../src/ai/reading/coffee-semantic-cues.js';
import { planCoffeeFortuneBeats } from '../src/ai/reading/coffee-fortune-beat.js';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import {
  coffeeClaimEnvelopeFailure,
  coffeeClaimSafetyFailure,
  coffeeIntentionParroting,
  coffeeMetaNarration,
  coffeeSemanticRestatement,
} from '../src/ai/reading/coffee-claim-envelope.js';
import { classifyCoffeeIntention } from '../src/ai/reading/coffee-intention-context.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { coffeeLengthRequirements } from '../src/ai/reading/coffee-length-contract.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { coffeeWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeWriterPacketV2 } from '../src/ai/reading/coffee-story-plan.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const checks = {
  cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true,
  milkFoamObstruction: false, usefulRegionsVisible: true,
};
const ev = (id: string, resemblance: string | null, region = 'middle_wall', description = 'A compact clear mark with a stable outline.'): ReadingEvidenceItem => ({
  id, region, description, resemblance, confidence: 'high', visibility: 'clear',
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
const section = (text: string) => ({ text, evidenceIds: text ? ['e1'] : [] });
const narrativeOf = (parts: Partial<Record<keyof CoffeeNarrative, string>>): CoffeeNarrative => ({
  visualObservation: section(parts.visualObservation ?? ''),
  overall: section(parts.overall ?? ''),
  love: section(parts.love ?? ''),
  career: section(parts.career ?? ''),
  money: section(parts.money ?? ''),
  nearFuture: section(parts.nearFuture ?? ''),
  takeaway: section(parts.takeaway ?? ''),
} as CoffeeNarrative);
/**
 * Raw source labels that must never reach a writer or repair packet (whole
 * tokens). "person" is excluded: it is part of the pre-existing machine
 * contract tokens specific_other_person / exact_person, not a source label.
 */
const RAW_SOURCE = /(^|[^a-z])(bird|kus|letter|mektup|message|mesaj|envelope|zarf|fish|balik|ring|yuzuk|heart|kalp|key|anahtar|road|path|route|tree|agac|fork|crossroads?|diverg\w*|figure|face)(?=[^a-z]|$)/i;
const tokens = (value: unknown) => JSON.stringify(value).toLowerCase().split(/[^a-z]+/).filter(Boolean);
const leaksRawSource = (value: unknown) => tokens(value).some((token) => RAW_SOURCE.test(token));

// ---------------------------------------------------------------------------
// PART 17 — private semantic cue matrix
// ---------------------------------------------------------------------------
const SOURCES = [
  ['bird', 'may resemble a small bird', 'incoming_contact', 'communication', 'contact_emergence'],
  ['letter', 'may resemble a folded letter', 'written_contact', 'communication', 'written_exchange'],
  ['message/envelope', 'may resemble a message envelope', 'written_contact', 'communication', 'written_exchange'],
  ['fish', 'may resemble a fish', 'available_opening', 'opportunity', 'opening_emerges'],
  ['ring', 'may resemble a ring', 'commitment_bond', 'bond', 'commitment_forms'],
  ['heart', 'may resemble a heart', 'emotional_weight', 'emotional_relevance', 'feeling_deepens'],
  ['key', 'may resemble a key', 'access_answer', 'solution', 'way_through_appears'],
  ['road/path', 'may resemble a winding path', 'directional_progress', 'movement', 'direction_shifts'],
  ['tree', 'may resemble a tree', 'gradual_growth', 'growth', 'gradual_accumulation'],
  ['person', 'may resemble a standing person', 'people_presence', 'social_relevance', 'people_gather'],
  ['fork/crossroads', 'may resemble a crossroads', 'alternative_split', 'choice', 'alternatives_clarify'],
] as const;

describe('C2.11 — private semantic cues (every currently recognized source class)', () => {
  it.each(SOURCES)('%s → private cue %s', (_label, resemblance, cue, family) => {
    const cues = mapCoffeeSemanticCues(obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3')));
    expect(cues).toEqual([{ kind: cue, family, evidenceIds: ['e1', 'e2'], context: 'general', timing: 'unspecified', support: 'independent_repeat' }]);
    expect(leaksRawSource(cues.map(({ kind }) => kind))).toBe(false);
  });

  it('preserves context and timing (handle side, upper wall) and keeps low-quality evidence out', () => {
    const cues = mapCoffeeSemanticCues(obsOf(ev('e1', 'may resemble a small bird', 'upper_wall'), ev('e2', null, 'near_handle'), neutral('e3')));
    expect(cues).toEqual([
      { kind: 'incoming_contact', family: 'communication', evidenceIds: ['e1'], context: 'general', timing: 'nearer_term', support: 'single' },
      { kind: 'proximate_context', family: 'home_close_circle', evidenceIds: ['e2'], context: 'home_close_circle', timing: 'unspecified', support: 'single' },
    ]);
  });

  it('keeps distinct cues of one family distinct, and duplicates only add support', () => {
    const distinct = mapCoffeeSemanticCues(obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3')));
    expect(distinct.map((cue) => cue.kind)).toEqual(['incoming_contact', 'written_contact']);
    const duplicate = mapCoffeeSemanticCues(obsOf(ev('e1', 'may resemble a letter'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3')));
    expect(duplicate).toHaveLength(1);
    expect(duplicate[0].support).toBe('independent_repeat');
  });
});

// ---------------------------------------------------------------------------
// PART 18 — controlled fortune beats
// ---------------------------------------------------------------------------
describe('C2.11 — controlled fortune beats', () => {
  it.each(SOURCES)('%s → permitted development %s (probable, bounded, subject-composed)', (_label, resemblance, _cue, _family, beat) => {
    const packet = packetFor(obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3')), 'İşim ve kariyerim hakkında');
    const lead = packet.storyPlan.fortune!.lead;
    expect(lead).toMatchObject({ kind: beat, subject: 'career_work', modality: 'probable', role: 'main_development', evidenceIds: ['e1', 'e2'] });
    expect(lead.forbiddenSpecifics).toEqual(expect.arrayContaining([
      'exact_person', 'employer_or_company', 'monetary_amount', 'salary_or_debt', 'exact_event',
      'other_person_feelings', 'other_person_intent', 'guaranteed_outcome', 'date', 'chronology', 'unsupported_causation',
    ]));
    expect(packet.storyPlan.fortune!.supporting).toEqual([]);
  });

  it('forbids beat-specific escalation', () => {
    const beatOf = (resemblance: string) =>
      packetFor(obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3'))).storyPlan.fortune!.lead;
    expect(beatOf('may resemble a bird').forbiddenSpecifics).toEqual(expect.arrayContaining(['sender_identity', 'guaranteed_contact']));
    expect(beatOf('may resemble a key').forbiddenSpecifics).toContain('prior_problem');
    expect(beatOf('may resemble a winding path').forbiddenSpecifics).toContain('travel_or_relocation');
    expect(beatOf('may resemble a crossroads').forbiddenSpecifics).toContain('invented_options');
    expect(beatOf('may resemble a fish').forbiddenSpecifics).toEqual(expect.arrayContaining(['monetary_amount', 'salary_or_debt']));
    expect(beatOf('may resemble a ring').forbiddenSpecifics).toContain('relationship_history');
    expect(beatOf('may resemble a heart').forbiddenSpecifics).toContain('other_person_feelings');
    expect(beatOf('may resemble a tree').forbiddenSpecifics).toContain('guaranteed_outcome');
  });

  it('forbidden escalation is enforced by the envelope where a deterministic detector exists', () => {
    const plain = (resemblance: string, intention?: string) =>
      packetFor(obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3')), intention).storyPlan;
    // communication: no awaited topic unless declared
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Beklediğin haber yolda.' }), plain('may resemble a bird'))).toBe('presumed_user_state');
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Beklediğin haber yolda.' }), plain('may resemble a bird', 'Dönüş bekliyorum'))).not.toBe('presumed_user_state');
    // bond: not an existing relationship unless declared
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Bir bağın korunması mümkün görünüyor.' }), plain('may resemble a ring', 'Aşk ve ilişkilerim hakkında'))).toBe('unsupported_existing_fact');
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Bir bağın korunması mümkün görünüyor.' }), plain('may resemble a ring', 'Eşimle olan ilişkim hakkında'))).toBeNull();
    // solution: no invented prior search/problem
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Aradığın çözüm yaklaşıyor.' }), plain('may resemble a key'))).toBe('unsupported_existing_fact');
    // movement: no travel or relocation
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Bir yolculuk kapıda.' }), plain('may resemble a winding path'))).toBe('unsupported_existing_fact');
    // choice: no invented options unless a decision was declared
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Seçenekler arasında bir fark netleşiyor.' }), plain('may resemble a crossroads'))).toBe('presumed_user_state');
    expect(coffeeClaimSafetyFailure(narrative('Seçenekler arasında bir fark netleşiyor.'), plain('may resemble a crossroads', 'Vermem gereken bir kararla ilgili'))).toBeNull();
    // emotional: never another person's feelings (person subject)
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Onun duyguları değişiyor.' }), plain('may resemble a heart', 'Aklımdaki kişiyle ilgili'))).toBe('unsupported_other_agency');
    // any beat: no guaranteed outcome
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Bu iş kesinlikle olacak.' }), plain('may resemble a tree'))).toBe('unsupported_certainty');
  });

  it('distinct cues become lead + second angle; duplicates never manufacture a second beat', () => {
    const two = packetFor(obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3'))).storyPlan;
    expect(two.semanticCapacity).toBe('modest');
    expect(two.fortune!.lead.role).toBe('main_development');
    expect(two.fortune!.supporting.map((beat) => [beat.kind, beat.role])).toEqual([['contact_emergence', 'second_angle']]);
    const same = packetFor(obsOf(ev('e1', 'may resemble a letter'), ev('e2', 'may resemble a letter', 'lower_wall'), neutral('e3'))).storyPlan;
    expect(same.fortune!.supporting).toEqual([]);
    const rich = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')), 'Maddi durumum hakkında').storyPlan;
    expect(rich.fortune!.lead.kind).toBe('opening_emerges');
    expect(rich.fortune!.supporting.map((beat) => beat.kind)).toEqual(['gradual_accumulation']);
    expect(rich.fortune!.lead.subject).toBe('money_finance');
  });

  it('a context-only cue never becomes a beat', () => {
    expect(planCoffeeFortuneBeats([
      { kind: 'proximate_context', family: 'home_close_circle', evidenceIds: ['e1'], context: 'home_close_circle', timing: 'unspecified', support: 'single' },
    ], 'proximate_context', null)).toBeNull();
  });
});

function narrative(overall: string): CoffeeNarrative {
  return narrativeOf({ overall });
}

// ---------------------------------------------------------------------------
// PART 19 — privacy firewall
// ---------------------------------------------------------------------------
describe('C2.11 — privacy firewall (writer and repair)', () => {
  it.each(SOURCES)('%s: no raw source identity, description, or mechanics in writer or repair packets', (_label, resemblance) => {
    const obs = obsOf(
      ev('e1', resemblance, 'middle_wall', 'A private compact deposit description.'),
      ev('e2', resemblance, 'lower_wall', 'Another private deposit description.'),
      neutral('e3'),
    );
    const packet = packetFor(obs, 'Maddi durumum hakkında');
    const repair = buildCoffeeRepairPlan(narrativeOf({ overall: 'Kısa.', takeaway: 'Kısa.' }), 'semantic_restatement', packet.storyPlan, 'tr', packet.lengthRequirements);
    for (const value of [packet, repair]) {
      const text = JSON.stringify(value);
      expect(leaksRawSource(value)).toBe(false);
      expect(text).not.toContain(resemblance);
      expect(text).not.toContain('private');
      expect(text).not.toMatch(/"(description|resemblance|region|sourceSlot|observationSource|confidence|visibility|family)"/);
      expect(text).not.toMatch(/middle_wall|lower_wall/);
    }
    expect(JSON.stringify(repair)).not.toContain('Kısa.');
  });

  it('public source-metaphor reconstruction is still rejected', () => {
    const obs = obsOf(ev('e1', 'may resemble a small bird'), ev('e2', 'may resemble a small bird', 'lower_wall'), neutral('e3'));
    const plan = packetFor(obs).storyPlan;
    const leaked = narrativeOf({ visualObservation: 'Fincanda bir kuş figürü belirmiş ve sana yöneliyor.', overall: 'Fincanda kuş çıkmış, yakında bir ses sana ulaşacak gibi.', takeaway: 'Bir ses yaklaşıyor.' });
    expect(coffeeQualityFailure(leaked, 'tr', undefined, obs.evidence, plan)).toBe('evidence_leak');
  });
});

// ---------------------------------------------------------------------------
// PART 8 / 20 — parroting and restatement (exact C2.10 failure shapes)
// ---------------------------------------------------------------------------
const qa = resolve(process.cwd(), 'docs/qa');
const manifest = JSON.parse(readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.manifest.json'), 'utf8')) as {
  checks: CoffeeObservation['checks'];
  cases: Array<{ id: string; intention: string; evidence: Array<ReadingEvidenceItem & { observationSource: string }>; expectedOutcome?: unknown }>;
};
const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.raw.json'), 'utf8')) as {
  results: Array<{ caseId: string; providerCallCount: number; attempts: Array<{ parsed: CoffeeNarrative }> }>;
};
const c210 = (id: string) => {
  const testCase = manifest.cases.find((item) => item.id === id)!;
  const obs: CoffeeObservation = { usable: true, reason: '', checks: manifest.checks, evidence: testCase.evidence.map(({ observationSource: _s, ...item }) => item) };
  const personalization = personalizationFromUnknown({ personalization: { intention: testCase.intention } });
  const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalization);
  const result = corpus.results.find((item) => item.caseId === id)!;
  return { testCase, obs, personalization, packet, result };
};
const verdict = (id: string, attempt: number) => {
  const { obs, personalization, packet, result } = c210(id);
  if ('status' in packet) throw new Error('policy case');
  return coffeeQualityFailure(result.attempts[attempt].parsed, 'tr', personalization, obs.evidence, packet.storyPlan);
};

describe('C2.11 — intention parroting and semantic restatement', () => {
  it('flags subject-label + abstract-noun prose (C2.10 C04 repair) as intention_parroting', () => {
    const { packet, result } = c210('C04');
    if ('status' in packet) throw new Error('policy');
    expect(coffeeIntentionParroting(result.attempts[1].parsed, packet.storyPlan).length).toBeGreaterThanOrEqual(3);
    expect(verdict('C04', 1)).toBe('intention_parroting');
  });

  it('flags definition-only prose (C2.10 C13) as semantic_restatement while the declared relationship stays legal', () => {
    const { packet, result } = c210('C13');
    if ('status' in packet) throw new Error('policy');
    expect(coffeeClaimSafetyFailure(result.attempts[0].parsed, packet.storyPlan)).toBeNull();
    expect(coffeeSemanticRestatement(result.attempts[0].parsed, packet.storyPlan).length).toBeGreaterThanOrEqual(3);
    expect(verdict('C13', 0)).toBe('semantic_restatement');
  });

  it('does not fail a natural mention of the subject or a told development', () => {
    const plan = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3')), 'İşim ve kariyerim hakkında').storyPlan;
    const told = narrativeOf({
      visualObservation: 'Önümüzdeki günlerde masana beklemediğin bir teklif dosyası gelecek gibi duruyor.',
      overall: 'Bir görüşmede adın geçecek ve kapı aralanacak. Kısa bir telefon, yeni bir işe başlama hevesini canlandıracak.',
      career: 'İşinde elini güçlendirecek bir davet kapına gelecek.',
      takeaway: 'Gelen daveti küçümseme, arkasından başka kapılar açılacak.',
    });
    expect(coffeeIntentionParroting(told, plan).length).toBeLessThan(3);
    expect(coffeeSemanticRestatement(told, plan)).toEqual([]);
  });

  it('maps the new diagnostics to dedicated repair defects', () => {
    const packet = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a fish', 'lower_wall'), neutral('e3')), 'İşim ve kariyerim hakkında');
    const rejected = narrativeOf({ overall: 'Kısa.', takeaway: 'Kısa.' });
    expect(buildCoffeeRepairPlan(rejected, 'intention_parroting', packet.storyPlan, 'tr').defect)
      .toEqual({ kind: 'subject_realization', propositionKinds: ['opening_availability'] });
    expect(buildCoffeeRepairPlan(rejected, 'semantic_restatement', packet.storyPlan, 'tr').defect)
      .toEqual({ kind: 'fortune_realization', propositionKinds: ['opening_availability'] });
    const repair = buildCoffeeRepairPlan(rejected, 'semantic_restatement', packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(repair.storyPlan.fortune?.lead.kind).toBe('opening_emerges');
    expect(repair.subject?.kind).toBe('career_work');
    expect(repair.lengthRequirements).toEqual(packet.lengthRequirements);
  });
});

// ---------------------------------------------------------------------------
// PART 9 — gate precedence
// ---------------------------------------------------------------------------
describe('C2.11 — gate precedence: serious claims are never hidden by style or length', () => {
  it('C07: unsupported relationship/agency wins over section_redundancy and too_short', () => {
    expect(verdict('C07', 0)).toBe('unsupported_existing_fact');
    expect(verdict('C07', 1)).toBe('unsupported_other_agency');
  });

  it('C11: unsupported causation wins', () => {
    expect(verdict('C11', 0)).toBe('unsupported_source_causation');
  });

  it('a short reading with an invented existing bond reports the bond, not too_short', () => {
    const plan = packetFor(obsOf(ev('e1', 'may resemble a ring'), ev('e2', 'may resemble a ring', 'lower_wall'), neutral('e3')), 'Aşk ve ilişkilerim hakkında').storyPlan;
    const short = narrativeOf({ visualObservation: 'Kısa.', overall: 'Bağın korunması mümkün.', love: 'Aşk tarafında bir yer var.', takeaway: 'Kısa.' });
    expect(coffeeQualityFailure(short, 'tr', undefined, undefined, plan)).toBe('unsupported_existing_fact');
  });
});

// ---------------------------------------------------------------------------
// PART 10 — trusted state
// ---------------------------------------------------------------------------
describe('C2.11 — granular trusted state', () => {
  it('replaces the broad stated_condition with awaiting_response that lifts ONLY awaited_topic', () => {
    expect(classifyCoffeeIntention('İş görüşmesinden sonra dönüş bekliyorum')).toMatchObject({
      declaredFacts: ['awaiting_response'], allowedAssumptionExceptions: ['awaited_topic'],
    });
    expect(classifyCoffeeIntention('Bu aralar çok yoruluyorum')?.declaredFacts).toEqual([]);
    expect(classifyCoffeeIntention('Bu aralar çok yoruluyorum')?.allowedAssumptionExceptions).toEqual([]);
  });

  it('keeps current_relationship, decision_exists, and person_in_mind unchanged', () => {
    expect(classifyCoffeeIntention('Eşimle olan ilişkim hakkında')?.declaredFacts).toEqual(['current_relationship']);
    expect(classifyCoffeeIntention('Vermem gereken bir kararla ilgili')?.declaredFacts).toEqual(['decision_exists']);
    expect(classifyCoffeeIntention('Aklımdaki kişiyle ilgili')?.declaredFacts).toEqual(['person_in_mind']);
  });

  it('an unmapped first-person condition relaxes nothing (fail conservative)', () => {
    const obs = obsOf(ev('e1', 'may resemble a bird'), ev('e2', 'may resemble a bird', 'lower_wall'), neutral('e3'));
    const n = narrativeOf({
      visualObservation: 'Sesin uzun zamandır duyulmayan bir yerden sana dönecek.',
      overall: 'Uzun zamandır süren o sessizlik bozulacak, kapına bir haber gelecek ve günlerin hareketlenecek gibi.',
      takeaway: 'Gelen haber gününü değiştirecek gibi duruyor, kulağın kapıda olsun.',
    });
    const plan = packetFor(obs, 'Bu aralar çok yoruluyorum').storyPlan;
    expect(coffeeQualityFailure(n, 'tr', { intention: 'Bu aralar çok yoruluyorum' }, obs.evidence, plan)).toBe('unsupported_existing_fact');
  });
});

// ---------------------------------------------------------------------------
// PART 11 / 12 — meta-narration closure and implied existing bond
// ---------------------------------------------------------------------------
describe('C2.11 — meta-narration closure (exact frozen C2.10 constructions)', () => {
  it.each([
    'Önündeki dönemin ana sonucu, hayatında karşılıklı alışverişin belirginleşmesi.',
    'İş ve kariyer niyetinde, mesleki alanının sabit bir çerçeveyle sınırlı kalmadığı vurgulanıyor.',
    'Duygusal açıklığın ile bir bağı önemseyebilme gücün aynı yerde buluşuyor.',
    'Aşk alanında duygusal erişilebilirlik ile bir yakınlığı içtenlikle önemli bulabilme hâli birbirinden ayrılmıyor.',
    'Bu, herhangi bir ilişki vaadinden çok, bağ kurma ihtimalini ciddiye alabildiğin bir hâli anlatıyor.',
    'Kesin bir sonuç vaat etmese de bu gelişme, kariyer odağında hem çıkış imkânını hem de yön yenilenmesini aynı bütün içinde taşıyor.',
    'Aşk alanında bu kişi, karşılıklılığa dair bir anlam taşımadan, senin duygusal dünyanda özel bir önem kazanıyor.',
  ])('catches "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).not.toBeNull();
  });

  it.each([
    'Arkadaşınla akşam aynı yerde buluşuyorsunuz ve güzel bir haber konuşuluyor.',
    'Bu da sana yeni bir yol gösteriyor.',
    'Önemli bir sonuç almak için acele etmene gerek kalmayacak.',
    'İki seçenek arasındaki fark sende netleşiyor.',
  ])('leaves ordinary language alone: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).toBeNull();
  });
});

describe('C2.11 — implied existing bond under the Love CATEGORY', () => {
  const love = () => packetFor(obsOf(ev('e1', 'may resemble a ring'), ev('e2', 'may resemble a ring', 'lower_wall'), neutral('e3')), 'Aşk ve ilişkilerim hakkında').storyPlan;
  it.each([
    'Aşk ve ilişkilerinde güçlü bir bağın korunması ihtimali belirgin.',
    'Bağın sürmesi senin elinde.',
    'İlişkinin devamı için güzel bir dönem.',
    'Hayatındaki önemli bir bağ özünü kaybetmeden varlığını koruyor.',
  ])('rejects "%s"', (sentence) => {
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: sentence }), love())).toBe('unsupported_existing_fact');
  });

  it('allows a bond FORMING', () => {
    expect(coffeeClaimSafetyFailure(narrativeOf({ overall: 'Yakında kalbine dokunacak yeni bir bağ kurulacak gibi.' }), love())).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// PART 13 — length, PART 7 — writer contract
// ---------------------------------------------------------------------------
describe('C2.11 — length contract and writer contract', () => {
  it('keeps every accepted floor', () => {
    expect(coffeeLengthRequirements()).toMatchObject({ visualObservationMinChars: 40, combinedLeadMinWords: 42, overallMinChars: 80, overallMinWords: 22, takeawayMinWords: 10 });
    expect(coffeeLengthRequirements({ narrativelySparse: true })).toMatchObject({ combinedLeadMinWords: 35, overallMinWords: 20, takeawayMinWords: 8 });
  });

  it('the writer is told to realize fortune beats, never to define them, and to clear minimums with margin', () => {
    const prompt = coffeeWriterSystem('tr');
    expect(prompt).toContain('FORTUNE REALIZATION');
    expect(prompt).toContain('CONTROLLED CONJECTURE');
    expect(prompt).toContain('beat.forbiddenSpecifics');
    expect(prompt).toContain('Never define a beat, a proposition or a category');
    expect(prompt).toContain('reasonable margin rather than aiming exactly at the threshold');
    expect(prompt).toContain('awaiting_response');
    expect(prompt).not.toMatch(/\b42\b|\b26\b/);
    const repair = repairWriterSystem('coffee', 'tr');
    expect(repair).toContain('FORTUNE REALIZATION');
    expect(repair).toContain('fortune_realization');
    expect(repair).toContain('subject_realization');
  });
});

// ---------------------------------------------------------------------------
// PART 16 — exact C2.10 current-verdict regression
// ---------------------------------------------------------------------------
describe('C2.11 — C2.10 frozen corpus, current verdicts', () => {
  it.each([
    ['C01', 1, 'meta_narration'],
    ['C02', 1, 'semantic_restatement'],
    ['C03', 0, 'unsupported_existing_fact'],
    ['C04', 1, 'intention_parroting'],
    ['C05', 1, 'unsupported_existing_fact'],
    ['C06', 1, 'intention_parroting'],
    ['C07', 0, 'unsupported_existing_fact'],
    ['C08', 1, 'meta_narration'],
    ['C09', 0, 'intention_parroting'],
    ['C10', 0, 'meta_narration'],
    ['C11', 0, 'unsupported_source_causation'],
    ['C12', 1, 'meta_narration'],
    ['C13', 0, 'semantic_restatement'],
    ['C14', 1, 'unsupported_certainty'],
  ] as const)('%s attempt #%i is now %s', (id, attempt, expected) => {
    expect(verdict(id, attempt)).toBe(expected);
  });

  it('C06 also carries semantic restatement; C12 also carries serialization (both behind higher-precedence defects)', () => {
    const c06 = c210('C06');
    const c12 = c210('C12');
    if ('status' in c06.packet || 'status' in c12.packet) throw new Error('policy');
    expect(coffeeSemanticRestatement(c06.result.attempts[1].parsed, c06.packet.storyPlan).length).toBeGreaterThan(0);
    expect(coffeeClaimEnvelopeFailure(c12.result.attempts[1].parsed, c12.packet.storyPlan)).not.toBeNull();
  });

  it('C14: the literal waiting statement is consistent; the draft fails only on style', () => {
    expect(verdict('C14', 0)).toBe('section_redundancy');
  });

  it.each(['C15', 'C16', 'C17'])('%s: zero-call policy unchanged', (id) => {
    const { packet, testCase, result } = c210(id);
    expect(packet).toEqual(testCase.expectedOutcome);
    expect(result.providerCallCount).toBe(0);
  });
});
