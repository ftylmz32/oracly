import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { buildCoffeeWriterPacketV2 } from '../src/ai/reading/coffee-meaning-map.js';
import {
  coffeeActiveForbiddenSpecifics,
  coffeeForbiddenFortuneSpecificFailure,
  coffeeForbiddenSpecificsTriggered,
  coffeeInternalJargon,
  coffeeVisualReportVoice,
} from '../src/ai/reading/coffee-public-language.js';
import { coffeeClaimSafetyFailure, coffeeLabelLedOpening, coffeeMetaNarration } from '../src/ai/reading/coffee-claim-envelope.js';
import { buildCoffeeRepairPlan } from '../src/ai/reading/coffee-repair-plan.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { personalizationFromUnknown } from '../src/ai/reading/personalization.js';
import { coffeeWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeWriterPacketV2 } from '../src/ai/reading/coffee-story-plan.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

const checks = {
  cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true,
  milkFoamObstruction: false, usefulRegionsVisible: true,
};
const ev = (id: string, resemblance: string | null, region = 'middle_wall'): ReadingEvidenceItem => ({
  id, region, description: 'A private compact deposit description.', resemblance, confidence: 'high', visibility: 'clear',
});
const neutral = (id: string): ReadingEvidenceItem => ({
  id, region: 'base', description: 'A faint film.', resemblance: null, confidence: 'low', visibility: 'uncertain',
});
const obsOf = (...evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const pair = (resemblance: string) => obsOf(ev('e1', resemblance), ev('e2', resemblance, 'lower_wall'), neutral('e3'));
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
const one = (text: string) => narrativeOf({ overall: text });

const communication = () => packetFor(pair('may resemble a small bird')).storyPlan;
const career = () => packetFor(pair('may resemble a fish'), 'İşim ve kariyerim hakkında').storyPlan;
const money = () => packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')), 'Maddi durumum hakkında').storyPlan;
const triggered = (text: string, plan = communication()) => coffeeForbiddenSpecificsTriggered(one(text), plan);

// ---------------------------------------------------------------------------
// PART 21 — public visual-report gate
// ---------------------------------------------------------------------------
describe('C2.11A — public visual-report voice', () => {
  it.each([
    // A. raw cup description
    'Fincanın üst kısmında bir hareket var.',
    'Fincanda sana doğru bir haber çıkmış.',
    'Dipteki telve bir değişime işaret ediyor.',
    'Yoğun tortunun yanında bir açıklık beliriyor.',
    'Koyu alanın ortasında bir boşluk duruyor.',
    'Bu figür sana yeni bir dönem anlatıyor.',
    'Şeklin yanında küçük bir detay var.',
    // B. sanitized geometry
    'Yoğun bir alanın üzerinden geçen çizgi yeni bir yönü anlatıyor.',
    'Bir açıklığın yanında uzanan yön seni bekliyor.',
    'İki tarafı bağlayan ince bir hat var.',
    'Koyu bir alanın içinden açılan boşluk dikkat çekiyor.',
    'Yukarı doğru ilerleyen bir iz var.',
    // C. symbol-dictionary voice
    'Bu sembol bereket anlamına gelir.',
    'Bu işaret bir kısmete işaret eder.',
  ])('rejects "%s"', (sentence) => {
    expect(coffeeVisualReportVoice(one(sentence))).not.toBeNull();
  });

  it.each([
    'İş tarafında önüne yeni bir yol açılabilir.',
    'Kendi çizgini koruyarak ilerleyeceksin.',
    'Geçmişin izleri artık seni yormayacak.',
    'Karanlık bir dönem geride kalıyor.',
    'Kafandaki konu açıklığa kavuşacak.',
    'Bu deneyim üzerinde güzel bir iz bırakacak.',
    'Hayatından geçen izler seni olgunlaştırdı.',
  ])('leaves a natural life metaphor alone: "%s"', (sentence) => {
    expect(coffeeVisualReportVoice(one(sentence))).toBeNull();
  });

  it('runs before style/length in the production gate and repairs toward natural realization', () => {
    const plan = career();
    const short = narrativeOf({ visualObservation: 'Kısa.', overall: 'İki tarafı bağlayan ince bir hat var.', career: 'İşte bir kıpırtı.', takeaway: 'Kısa.' });
    expect(coffeeQualityFailure(short, 'tr', { intention: 'İşim ve kariyerim hakkında' }, pair('may resemble a fish').evidence, plan)).toBe('visual_report_voice');
    const repair = buildCoffeeRepairPlan(short, 'visual_report_voice', plan, 'tr');
    expect(repair.defect.kind).toBe('natural_realization');
    expect(JSON.stringify(repair)).not.toContain('İki tarafı bağlayan');
  });

  it('preserves the more precise privacy diagnostic when the private source itself is named', () => {
    const obs = pair('may resemble a small bird');
    const leaked = narrativeOf({ visualObservation: 'Fincanda bir kuş figürü belirmiş.', overall: 'Fincanda kuş çıkmış, haber yaklaşıyor.', takeaway: 'Bir ses geliyor.' });
    expect(coffeeQualityFailure(leaked, 'tr', undefined, obs.evidence, packetFor(obs).storyPlan)).toBe('evidence_leak');
  });
});

// ---------------------------------------------------------------------------
// PART 18 — internal jargon
// ---------------------------------------------------------------------------
describe('C2.11A — internal machinery jargon never reaches public prose', () => {
  it.each(['Bu beat sana bir proposition getiriyor.', 'Semantic olarak bir açılım var.', 'Bu önerme hayatına dokunuyor.'])('rejects "%s"', (sentence) => {
    expect(coffeeInternalJargon(one(sentence))).not.toBeNull();
    expect(coffeeQualityFailure(one(sentence), 'tr', undefined, undefined, communication())).toBe('schema_jargon_leak');
  });

  it('does not flag ordinary Turkish words like plan or aile', () => {
    expect(coffeeInternalJargon(one('Planların netleşiyor ve ailenin desteği yanında.'))).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// PART 22 — forbidden fortune specifics (plan-driven)
// ---------------------------------------------------------------------------
describe('C2.11A — forbidden fortune specifics', () => {
  it.each([
    ['sender_identity', 'Arkadaşından güzel bir haber gelecek.'],
    ['sender_identity', 'Eski sevgilinden bir mesaj gelebilir.'],
    ['sender_identity', 'Ailenden biri seni arayacak.'],
    ['sender_identity', 'Patronundan bir mesaj alacaksın.'],
    ['sender_identity', 'Bir erkekten haber alacaksın.'],
  ] as const)('%s: "%s"', (specific, sentence) => {
    expect(triggered(sentence)).toContain(specific);
  });

  it.each([
    'İşverenin sana teklif yapacak.',
    'Patronun seni terfi için çağıracak.',
    'Şirketin sana yeni bir görev verecek.',
    'Yöneticin seni takdir edecek.',
    'İnsan kaynaklarından bir dönüş gelecek.',
  ])('employer_or_company: "%s"', (sentence) => {
    expect(triggered(sentence, career())).toContain('employer_or_company');
  });

  it.each([
    'Yakında bir ödeme gelecek.',
    'Hesabına para yatacak.',
    'Bir ikramiye alabilirsin.',
    'Bir havale eline geçecek.',
  ])('payment_event: "%s"', (sentence) => {
    expect(triggered(sentence, money())).toContain('payment_event');
  });

  it.each(['10.000 TL kazanacaksın.', '10,000 TL yolda.', '5000 ₺ elinde.', '5 bin lira gelebilir.', 'Yüz bin lira kazanç var.'])(
    'monetary_amount: "%s"', (sentence) => {
      expect(triggered(sentence, money())).toContain('monetary_amount');
    },
  );

  it.each(['Maaşına zam gelecek.', 'Maaş ödemen gecikmeyecek.', 'Borcun kapanacak.', 'Borç yükün hafifleyecek.', 'Kredi borcu bitecek.'])(
    'salary_or_debt: "%s"', (sentence) => {
      expect(triggered(sentence, money())).toContain('salary_or_debt');
    },
  );

  it.each([
    ['date', 'Pazartesi güzel bir haber var.'],
    ['date', 'Üç gün içinde bir haber gelecek.'],
    ['other_person_feelings', 'Onun duyguları değişiyor.'],
  ] as const)('proactive %s: "%s"', (specific, sentence) => {
    expect(triggered(sentence)).toContain(specific);
  });

  it.each([
    ['communication with no sender', 'Bir haberleşme gündemine gelebilir.', communication],
    ['career opening with no employer actor', 'İşinde önüne yeni bir kapı açılabilir.', career],
    ['financial opening with no payment/amount', 'Maddi tarafta nefes aldıracak bir kapı aralanacak.', money],
    ['generic money language', 'Para konusunda bir rahatlama gelecek.', money],
    ['şirket outside an actor construction', 'Kendi şirketini kurma hayalin canlanabilir.', career],
    ['non-money number', 'Üç farklı konu arasında seçim yapacaksın.', money],
    ['percentage', 'Yüzde yirmi daha hafif hissedeceksin.', money],
    ['year', '2026 senin için hareketli geçecek.', money],
    ['iki seçenek', 'İki seçenek arasındaki fark netleşiyor.', money],
    ['life metaphor yol', 'İş tarafında önüne yeni bir yol açılabilir.', career],
    ['friends without contact', 'Arkadaşlarından destek görebilirsin.', communication],
    ['emotional indebtedness', 'Kendini kimseye borçlu hissetmeyeceksin.', money],
    ['zamanla', 'Zamanla her şey yerine oturacak.', money],
  ] as const)('passes %s', (_label, sentence, plan) => {
    expect(triggered(sentence, plan())).toEqual([]);
  });

  it('declared current relationship language passes the specifics gate', () => {
    const plan = packetFor(pair('may resemble a ring'), 'Eşimle olan ilişkim hakkında').storyPlan;
    expect(coffeeForbiddenFortuneSpecificFailure(one('Eşinle aranda yeni bir sıcaklık başlayacak.'), plan)).toBeNull();
  });

  it('is plan-driven: no fortune plan, no enforcement', () => {
    const plan = { ...communication(), fortune: undefined };
    expect(coffeeForbiddenSpecificsTriggered(one('Eski sevgilinden bir mesaj gelebilir.'), plan)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// PART 23 — every beat carries the right specifics
// ---------------------------------------------------------------------------
describe('C2.11A — fortune-beat forbidden-specifics matrix', () => {
  const COMMON = ['employer_or_company', 'monetary_amount', 'salary_or_debt', 'payment_event', 'exact_event', 'guaranteed_outcome', 'date', 'chronology', 'unsupported_causation'];
  it.each([
    ['contact_emergence', 'may resemble a small bird', ['sender_identity', 'guaranteed_contact']],
    ['written_exchange', 'may resemble a folded letter', ['sender_identity', 'guaranteed_contact']],
    ['opening_emerges', 'may resemble a fish', []],
    ['commitment_forms', 'may resemble a ring', ['guaranteed_contact']],
    ['feeling_deepens', 'may resemble a heart', []],
    ['way_through_appears', 'may resemble a key', ['prior_problem']],
    ['direction_shifts', 'may resemble a winding path', ['travel_or_relocation']],
    ['gradual_accumulation', 'may resemble a tree', []],
    ['alternatives_clarify', 'may resemble a crossroads', ['invented_options']],
    ['people_gather', 'may resemble a standing person', ['sender_identity']],
  ] as const)('%s carries common + beat specifics into storyPlan.fortune', (beat, resemblance, extra) => {
    const plan = packetFor(pair(resemblance)).storyPlan;
    expect(plan.fortune?.lead.kind).toBe(beat);
    expect([...coffeeActiveForbiddenSpecifics(plan)]).toEqual(expect.arrayContaining([...COMMON, ...extra]));
  });
});

// ---------------------------------------------------------------------------
// PART 13 / 19 — precedence and repair
// ---------------------------------------------------------------------------
describe('C2.11A — safety precedence and repair parity', () => {
  it('an invented employer is reported before subject, meta, parroting, restatement, redundancy, and length', () => {
    const plan = career();
    const short = narrativeOf({ visualObservation: 'Kısa.', overall: 'İşverenin sana teklif yapacak.', takeaway: 'Kısa.' });
    expect(coffeeQualityFailure(short, 'tr', { intention: 'İşim ve kariyerim hakkında' }, pair('may resemble a fish').evidence, plan)).toBe('unsupported_specific_detail');
  });

  it('more specific relationship/agency codes stay ahead of the specifics gate', () => {
    const person = packetFor(pair('may resemble a small bird'), 'Aklımdaki kişiyle ilgili').storyPlan;
    expect(coffeeClaimSafetyFailure(one('Aranızdaki bağdan, arkadaşından bir haber gelecek.'), person)).toBe('unsupported_existing_fact');
  });

  it('repair receives the exact triggered specifics, the fortune plan, subject and length contract — no prose, no raw source', () => {
    const packet = packetFor(obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')), 'Maddi durumum hakkında');
    const rejected = narrativeOf({ overall: 'Hesabına para yatacak ve 5 bin lira kazanacaksın.', takeaway: 'Maaşına zam gelecek.' });
    const repair = buildCoffeeRepairPlan(rejected, 'unsupported_specific_detail', packet.storyPlan, 'tr', packet.lengthRequirements);
    expect(repair.defect.kind).toBe('unsupported_concretization');
    expect(repair.forbiddenSpecificsTriggered).toEqual(['payment_event', 'monetary_amount', 'salary_or_debt']);
    expect(repair.forbiddenClaimCategoriesTriggered).toEqual([]);
    expect(repair.storyPlan.fortune?.lead.kind).toBe('opening_emerges');
    expect(repair.storyPlan.fortune?.supporting.map((beat) => beat.kind)).toEqual(['gradual_accumulation']);
    expect(repair.subject?.kind).toBe('money_finance');
    expect(repair.lengthRequirements).toEqual(packet.lengthRequirements);
    const text = JSON.stringify(repair);
    expect(text).not.toContain('Hesabına para');
    expect(text).not.toMatch(/"(description|resemblance|region|sourceSlot|confidence|visibility)"|may resemble|private compact/);
  });

  it('repair and writer prompts carry the boundaries', () => {
    const writer = coffeeWriterSystem('tr');
    expect(writer).toContain('HIERARCHY');
    expect(writer).toContain('NO VISUAL REPORT');
    expect(writer).toContain('disguised geometry');
    expect(writer).toContain('Never write internal machinery words');
    const repair = repairWriterSystem('coffee', 'tr');
    expect(repair).toContain('forbiddenSpecificsTriggered');
    expect(repair).toContain('visual_report_voice');
    expect(repair).toContain('never translate geometry into different geometry');
  });
});

// ---------------------------------------------------------------------------
// PART 10 / 12 — label-led openings and analyst meta phrasing
// ---------------------------------------------------------------------------
describe('C2.11A — domain-label padding and analyst meta phrasing', () => {
  it.each([
    'Mesleki alanında erişilebilir bir açılım bulunuyor.',
    'Kariyerinde bir fırsat alanı var.',
  ])('label + abstract opening with no development fails: "%s"', (sentence) => {
    expect(coffeeLabelLedOpening(narrativeOf({ overall: `${sentence} Gerisi sonra.` }), career())).toBe(true);
  });

  it('a development-first opening that mentions the subject naturally passes', () => {
    expect(coffeeLabelLedOpening(narrativeOf({ overall: 'Yakında işinde seni heyecanlandıracak bir kapı aralanacak.' }), career())).toBe(false);
    expect(coffeeLabelLedOpening(narrativeOf({ overall: 'Kariyerinde yeni bir kapı aralanacak.' }), career())).toBe(false);
  });

  it.each(['Buradaki anlam senin için önemli.', 'Bu iki anlam birlikte duruyor.', 'Bu hâl bir anlam taşıyor.'])('meta: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).not.toBeNull();
  });

  it.each(['Bu durum sana iyi gelecek.', 'Buradaki insanlar seni sevecek.'])('ordinary: "%s"', (sentence) => {
    expect(coffeeMetaNarration([sentence])).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// PART 20 — privacy firewall (unchanged guarantees)
// ---------------------------------------------------------------------------
describe('C2.11A — private source firewall', () => {
  const RAW = /(^|[^a-z])(bird|kus|letter|mektup|fish|balik|ring|yuzuk|heart|kalp|key|anahtar|road|path|route|tree|agac|fork|crossroads?|figure|face)(?=[^a-z]|$)/i;
  const tokens = (value: unknown) => JSON.stringify(value).toLowerCase().split(/[^a-z]+/).filter(Boolean);
  it.each(['may resemble a small bird', 'may resemble a folded letter', 'may resemble a fish', 'may resemble a ring', 'may resemble a heart', 'may resemble a key', 'may resemble a winding path', 'may resemble a tree', 'may resemble a crossroads'])(
    '%s never reaches writer or repair', (resemblance) => {
      const packet = packetFor(pair(resemblance), 'Maddi durumum hakkında');
      const repair = buildCoffeeRepairPlan(narrativeOf({ overall: 'Hesabına para yatacak.' }), 'unsupported_specific_detail', packet.storyPlan, 'tr', packet.lengthRequirements);
      for (const value of [packet, repair]) {
        expect(tokens(value).some((token) => RAW.test(token))).toBe(false);
        expect(JSON.stringify(value)).not.toMatch(/"(description|resemblance|region|sourceSlot|observationSource|confidence|visibility)"/);
      }
    },
  );
});

// ---------------------------------------------------------------------------
// PART 24 — C2.10 current verdicts (no previously rejected attempt accepted)
// ---------------------------------------------------------------------------
describe('C2.11A — C2.10 frozen corpus stays rejected', () => {
  const qa = resolve(process.cwd(), 'docs/qa');
  const manifest = JSON.parse(readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.manifest.json'), 'utf8')) as {
    checks: CoffeeObservation['checks'];
    cases: Array<{ id: string; intention: string; evidence: Array<ReadingEvidenceItem & { observationSource: string }> }>;
  };
  const corpus = JSON.parse(readFileSync(resolve(qa, 'coffee-c210-trusted-subject-blind-20261007.raw.json'), 'utf8')) as {
    results: Array<{ caseId: string; attempts: Array<{ parsed: CoffeeNarrative }> }>;
  };
  it('every recorded C2.10 attempt is rejected; C07, C11, C14 keep their priority verdicts', () => {
    const verdicts: Record<string, string | null> = {};
    for (const testCase of manifest.cases) {
      const obs: CoffeeObservation = { usable: true, reason: '', checks: manifest.checks, evidence: testCase.evidence.map(({ observationSource: _s, ...item }) => item) };
      const personalization = personalizationFromUnknown({ personalization: { intention: testCase.intention } });
      const packet = buildCoffeeWriterPacketV2(obs, 'tr', personalization);
      if ('status' in packet) continue;
      corpus.results.find((item) => item.caseId === testCase.id)!.attempts.forEach((attempt, index) => {
        verdicts[`${testCase.id}#${index}`] = coffeeQualityFailure(attempt.parsed, 'tr', personalization, obs.evidence, packet.storyPlan);
      });
    }
    expect(Object.values(verdicts).every((value) => value !== null)).toBe(true);
    expect(verdicts['C07#0']).toBe('unsupported_existing_fact');
    expect(verdicts['C07#1']).toBe('unsupported_other_agency');
    expect(verdicts['C11#0']).toBe('unsupported_source_causation');
    expect(verdicts['C14#0']).toBe('section_redundancy');
    expect(verdicts['C14#1']).toBe('unsupported_certainty');
  });
});

// ---------------------------------------------------------------------------
// PART 26 — product-quality self audit (test semantics, NOT golden prose)
// ---------------------------------------------------------------------------
describe('C2.11A — self audit: bounded, development-first fortune prose passes the FULL production gate', () => {
  const fixtures = [
    {
      label: 'career + opening',
      intention: 'İşim ve kariyerim hakkında',
      obs: pair('may resemble a fish'),
      narrative: narrativeOf({
        visualObservation: 'Önümüzdeki günlerde içini kıpırdatacak güzel bir haber sana doğru yola çıkmış gibi.',
        overall: 'Yakında işinde seni heyecanlandıracak bir kapı aralanacak; sana yakışan, emeğini gösterebileceğin yeni bir adım olacak gibi. Bu kıpırtıyı ilk duyduğunda içinden bir sevinç geçecek ve elini taşın altına koymaya hevesleneceksin.',
        career: 'Mesai arkadaşlarının arasında adının daha sık geçtiği, emeğinin fark edildiği günlere yaklaşıyorsun.',
        takeaway: 'Kapı aralandığında içindeki çekingenlik dağılacak, o heves seni gönül rahatlığıyla ileri taşıyacak.',
      }),
    },
    {
      label: 'money + opening + growth',
      intention: 'Maddi durumum hakkında',
      obs: obsOf(ev('e1', 'may resemble a fish'), ev('e2', 'may resemble a tree', 'lower_wall'), neutral('e3')),
      narrative: narrativeOf({
        visualObservation: 'Elinin biraz rahatlayacağı, nefes alacağın günler sana yaklaşıyor.',
        overall: 'Maddi tarafta kapına küçük ama sevindirici bir kısmet gelecek; ilk başta ufak görünecek, sonra yavaş yavaş büyüyüp seni şaşırtacak. Bir kenara koyduğun şeyler bereketlenecek, harcarken de içini daha az daraltacaksın, hesabını kitabını yaparken yüzün gülecek ve kendine küçük bir keyif ayırmaya gönlün razı olacak gibi.',
        money: 'Kazandığını tutabileceğin, cebine giren her şeyin biraz daha uzun dayanacağı bir döneme giriyorsun.',
        takeaway: 'Sabırla büyüyen bu bereket önümüzdeki günlerde seni epey rahatlatacak, içine tatlı bir ferahlık yayılacak.',
      }),
    },
  ];

  it.each(fixtures)('$label passes every new boundary AND the whole V2 gate (no vagueness forced)', ({ intention, obs, narrative }) => {
    const plan = packetFor(obs, intention).storyPlan;
    expect(coffeeVisualReportVoice(narrative)).toBeNull();
    expect(coffeeInternalJargon(narrative)).toBeNull();
    expect(coffeeForbiddenSpecificsTriggered(narrative, plan)).toEqual([]);
    expect(coffeeLabelLedOpening(narrative, plan)).toBe(false);
    expect(coffeeMetaNarration([narrative.visualObservation.text, narrative.overall.text, narrative.takeaway.text])).toBeNull();
    expect(coffeeQualityFailure(narrative, 'tr', { intention }, obs.evidence, plan)).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// PART 25 — proactive adjacent fixes found by the self audit
// ---------------------------------------------------------------------------
describe('C2.11A — proactive adjacent fixes', () => {
  it('"yola çıkmış" (life idiom) is not a cup report; "<sign> çıkmış" still is', () => {
    const obs = pair('may resemble a small bird');
    const plan = packetFor(obs).storyPlan;
    const idiom = narrativeOf({ visualObservation: 'Güzel bir haber sana doğru yola çıkmış gibi duruyor.', overall: 'x', takeaway: 'x' });
    const report = narrativeOf({ visualObservation: 'Fincanında yıldız çıkmış.', overall: 'x', takeaway: 'x' });
    expect(coffeeQualityFailure(idiom, 'tr', undefined, obs.evidence, plan)).not.toBe('evidence_leak');
    expect(coffeeQualityFailure(report, 'tr', undefined, obs.evidence, plan)).toBe('evidence_leak');
  });

  it('a hedged "… olacak gibi" is not certainty; bare "olacak" still is', () => {
    const plan = packetFor(pair('may resemble a fish')).storyPlan;
    expect(coffeeClaimSafetyFailure(one('Sana yakışan bir adım olacak gibi.'), plan)).toBeNull();
    expect(coffeeClaimSafetyFailure(one('Bu iş olacak.'), plan)).toBe('unsupported_certainty');
  });

  it('the noun "açılım" no longer counts as a told development', () => {
    expect(coffeeLabelLedOpening(narrativeOf({ overall: 'Mesleki alanında erişilebilir bir açılım bulunuyor.' }), career())).toBe(true);
  });
});
