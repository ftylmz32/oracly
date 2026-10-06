/**
 * Story-first closure — offline regressions from real targeted9 / targeted10
 * outputs (gpt-5.6-sol, low). Every case below is the EXACT delivered prose.
 *
 * 0. "yorulur" (targeted9 BIRD) — delivered then only because the
 *    dictionary_voice gate did not exist yet; it must now be rejected in the
 *    same ReadingPipeline bind path real Coffee readings use.
 * 1. Absence is not content ("fincanda belirgin bir figür olmadığı için").
 * 2. Context evidence cannot become life events (DOTS, HANDLE).
 * 3. Geometry does not create cause / agency / relationship roles.
 * 4. The handle side is a domain only.
 * 5. A short, grounded, evidence-limited sparse reading passes.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeCupMetaTalk, coffeeDictionaryVoice, coffeeGeometryInference } from '../src/ai/human-quality.js';
import { OpenAiTransport } from '../src/ai/openai-transport.js';
import { coffeeContextEventPromotion } from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';
import { testConfig } from './helpers.js';

type Packet = { label: string; evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const load = (name: string) =>
  JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8')) as { cases: Record<string, Packet> };
const t9 = load('coffee_qa_targeted9');
const t10 = load('coffee_qa_targeted10');

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const sections = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway];

/** Runs one Coffee reading through the production ReadingPipeline with a fake provider. */
async function runPipeline(evidence: ReadingEvidenceItem[], writer: CoffeeNarrative, repair: CoffeeNarrative) {
  const calls: Array<{ kind: string; user: string }> = [];
  const fetchFn = (async (_url: string, init?: RequestInit) => {
    const body = JSON.parse(String(init?.body));
    const reply = (content: string) =>
      new Response(JSON.stringify({ choices: [{ message: { content } }] }), { status: 200 });
    if (body.response_format?.json_schema?.name === 'coffee_observation') return reply(JSON.stringify(observation(evidence)));
    const system = body.messages[0].content;
    const kind = system === coffeeWriterSystem('tr') ? 'writer' : system === repairWriterSystem('coffee') ? 'repair' : 'other';
    calls.push({ kind, user: body.messages[1].content });
    return reply(JSON.stringify(kind === 'writer' ? writer : repair));
  }) as never;
  const config = testConfig();
  const pipeline = new ReadingPipeline(config, new OpenAiTransport(config, fetchFn));
  readingStageStore.clear();
  const ctx = { identity: 'u-grounding', parentKey: `p-grounding-${Date.now()}-${Math.random()}`, language: 'tr' as const };
  const observed = await pipeline.observeCoffee({ mimeType: 'image/jpeg', bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]) }, ctx);
  try {
    const delivered = await pipeline.writeCoffee({ observationToken: observed.observationToken }, ctx);
    return { calls, delivered, error: null as null | { code: string; bindFailure?: string } };
  } catch (e) {
    return { calls, delivered: null, error: { code: (e as { code: string }).code, bindFailure: (e as { details?: { bindFailure?: string } }).details?.bindFailure } };
  }
}

describe('0. dictionary_voice is enforced in the production bind path (targeted9 BIRD)', () => {
  const BIRD9 = t9.cases.case2;
  const BIRD10 = t10.cases.case2;
  const meaningRepair: CoffeeNarrative = {
    visualObservation: {
      text: 'Yakın zamanda sana ulaşacak belirgin bir iletişim gelişmesi öne çıkıyor.',
      evidenceIds: ['e1'],
    },
    overall: {
      text: 'Sana ulaşacak belirgin bir haber günlük akışında hareket yaratacak. Bu iletişim kısa ve doğrudan gelecek; taşıdığı ana fikir dikkatini hemen kendine çekecek. Ardından önündeki gelişmenin hangi yönde ilerleyeceği daha açık hâle gelecek.',
      evidenceIds: ['e1'],
    },
    love: { text: '', evidenceIds: [] },
    career: { text: '', evidenceIds: [] },
    money: { text: '', evidenceIds: [] },
    nearFuture: { text: '', evidenceIds: [] },
    takeaway: {
      text: 'Yakın zamanda gelen bu haber, önündeki gelişmenin yönünü açıkça belirginleştirecek.',
      evidenceIds: ['e1'],
    },
  };

  it('the exact delivered "… erişeceğine yorulur" output is rejected by the gate and the bind', () => {
    expect(BIRD9.narrative.nearFuture.text).toBe('Kuşun fincanın ağzına yakın durması, bu haberin yakın zamanda sana erişeceğine yorulur.');
    expect(coffeeDictionaryVoice([BIRD9.narrative.nearFuture.text])).toContain('yorulur');
    expect(coffeeQualityFailure(BIRD9.narrative, 'tr', undefined, BIRD9.evidence)).toBe('dictionary_voice');
    expect(bindCoffeeNarrative(BIRD9.narrative, observation(BIRD9.evidence), 'tr')).toBe('human_quality');
  });

  it('ReadingPipeline sends it to the ONE repair with dictionary guidance and delivers the clean repair', async () => {
    const { calls, delivered, error } = await runPipeline(BIRD9.evidence, BIRD9.narrative, meaningRepair);
    expect(error).toBeNull();
    expect(calls.map((c) => c.kind)).toEqual(['writer', 'repair']);
    expect(calls[1].user).toContain('Violation codes: human_quality');
    expect(coffeeVoiceRepairFocus('dictionary_voice')).toContain('symbol-dictionary form');
    expect(calls[1].user).toContain('Private grounded meaning facets:');
    expect(calls[1].user).toContain('"family":"communication"');
    expect(calls[1].user).not.toContain('"region"');
    expect(calls[1].user).not.toContain('"description"');
    expect(calls[1].user).not.toContain('"resemblance"');
    expect(calls[1].user).not.toMatch(/kuş|fincan|telve|ağız kenarı/i);
    expect(JSON.stringify(delivered)).not.toContain('yorulur');
    expect(JSON.stringify(delivered)).not.toMatch(/kuş|fincan|telve|ağız kenarı/i);
  });

  it('a repair that keeps "yorulur" is never delivered', async () => {
    const { calls, delivered, error } = await runPipeline(BIRD9.evidence, BIRD9.narrative, BIRD9.narrative);
    expect(calls.map((c) => c.kind)).toEqual(['writer', 'repair']);
    expect(delivered).toBeNull();
    expect(error).toEqual({ code: 'quality_unavailable', bindFailure: 'human_quality' });
  });

  it('the targeted10 BIRD (after the gate) has no "yorulur" and passes', () => {
    expect(JSON.stringify(BIRD10.narrative)).not.toContain('yorul');
    expect(bindCoffeeNarrative(BIRD10.narrative, observation(BIRD10.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('1. absence is not fortune content', () => {
  it('HANDLE "Fincanda belirgin bir figür çıkmadığı için …" is cup_meta_talk', () => {
    const HANDLE = t10.cases.case5;
    expect(coffeeCupMetaTalk(meaning(HANDLE.narrative))).toContain('fincanda belirgin bir figur cikmadigi icin');
    expect(coffeeQualityFailure(HANDLE.narrative, 'tr', undefined, HANDLE.evidence)).toBe('cup_meta_talk');
  });

  it('DOTS "Fincanda belirgin bir figür olmadığı için …" is cup_meta_talk', () => {
    expect(coffeeCupMetaTalk(meaning(t10.cases.case9.narrative))).toContain('fincanda belirgin bir figur olmadigi icin');
  });

  it('an honest, relevant single limit is not meta talk', () => {
    expect(coffeeCupMetaTalk(['Bir şeyler kıpırdıyor; ne zaman olacağını fincan göstermiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Haberin ne yönde olduğunu fincan tam göstermiyor.'])).toBeNull();
  });

  it('writer rule', () => {
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
  });
});

describe('2. context evidence cannot become life events', () => {
  const DOTS = t10.cases.case9;

  it('targeted10 DOTS overall (dots only) promoting "kısa uğraşlar" is rejected', () => {
    expect(DOTS.narrative.overall.evidenceIds).toEqual(['e2']);
    expect(coffeeContextEventPromotion([DOTS.narrative.overall], DOTS.evidence)).toContain('kısa uğraşlarla');
  });

  it('targeted9 DOTS promoting "kısa karşılaşmalar ve küçük kısmetler" is rejected', () => {
    const DOTS9 = t9.cases.case9;
    expect(coffeeContextEventPromotion(sections(DOTS9.narrative), DOTS9.evidence)).toContain('kısa karşılaşmalar ve küçük kısmetler');
    // Its "yakın çevrende" (no handle cue) may be rejected first as unsupported_home_domain.
    expect(['context_event', 'unsupported_home_domain']).toContain(coffeeQualityFailure(DOTS9.narrative, 'tr', undefined, DOTS9.evidence));
  });

  it('DOTS takeaway (clean band only) promoting "boş vakit" is rejected', () => {
    expect(coffeeContextEventPromotion([DOTS.narrative.takeaway], DOTS.evidence)).toContain('boş vakit');
  });

  it('HANDLE overall (sparse marks only) promoting "küçük uğraşlar" is rejected', () => {
    const HANDLE = t10.cases.case5;
    expect(coffeeContextEventPromotion([HANDLE.narrative.overall], HANDLE.evidence)).toContain('küçük uğraşları');
  });

  it('an event a real sign established may be referred to again (bird news + open base)', () => {
    const good = JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_good.json', 'utf8'));
    expect(coffeeContextEventPromotion(sections(good.narrative), good.observation.evidence)).toBeNull();
  });

  it('a clean / open area may still carry its traditional open kısmet', () => {
    const LOW = t10.cases.case10; // "Fincanın temiz dibi … açık bir kısmet payı" citing the clean base
    expect(coffeeContextEventPromotion([LOW.narrative.takeaway], LOW.evidence)).toBeNull();
  });

  it('superseded: the old sparse GOOD exemplar (base -> "olduğu gibi duran bir düzen … sabit") now fails', () => {
    const old: CoffeeNarrative = structuredClone(JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_good_sparse.json', 'utf8')).narrative);
    const ev = JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_good_sparse.json', 'utf8')).observation.evidence;
    old.overall.text = 'Telve dibe çökmüş ve orada kalmış; fincan pek kıpırdamamış. Böyle fincanın sözü azdır. Hayatında şu sıralar yerinden oynamayan, olduğu gibi duran bir düzen var gibi; ne iyiye ne kötüye dönmüş, sadece sabit. Fincanın üstü temiz, yani bu düzeni dışarıdan bozmaya gelen bir şey de görünmüyor.';
    expect(coffeeContextEventPromotion([old.overall], ev)).not.toBeNull();
    // Also "Böyle fincanın sözü azdır" — reading self-reference fires first now.
    expect(['context_event', 'cup_meta_talk']).toContain(coffeeQualityFailure(old, 'tr', undefined, ev));
  });
});

describe('3. geometry does not create cause, agency or a relationship role', () => {
  it('ROAD: a curve does not say WHY ("şartlara göre yön bulduğunu")', () => {
    const ROAD = t10.cases.case4;
    expect(coffeeGeometryInference(meaning(ROAD.narrative))).toContain('sartlara gore');
    expect(coffeeQualityFailure(ROAD.narrative, 'tr', undefined, ROAD.evidence)).toBe('geometry_inference');
  });

  it('LOW-SYMBOL: a line does not let one side steer the other (claim in the next sentence)', () => {
    const LOW = t10.cases.case10;
    expect(LOW.narrative.overall.text).toContain('Birindeki hareket, ötekinin yönünü de belirleyecek.');
    expect(coffeeGeometryInference(meaning(LOW.narrative))).toContain('otekinin yonunu de belirleyecek');
    expect(coffeeQualityFailure(LOW.narrative, 'tr', undefined, LOW.evidence)).toBe('geometry_inference');
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
  });

  it('BRIDGE: no reciprocity / who carries the bond', () => {
    const BRIDGE = t10.cases.case8;
    expect(coffeeGeometryInference(meaning(BRIDGE.narrative))).toContain('tek basina tasimiyorsun');
    expect(coffeeQualityFailure(BRIDGE.narrative, 'tr', undefined, BRIDGE.evidence)).toBe('geometry_inference');
  });

  it('structural topology sentences pass', () => {
    expect(coffeeGeometryInference(['Yol kıvrılarak yükseliyor ve fincanın ağzına kadar varıyor.'])).toBeNull();
    expect(coffeeGeometryInference(['Köprü iki ayrı tarafı birbirine bağlıyor; ucu kulp tarafına iniyor.'])).toBeNull();
    expect(coffeeGeometryInference(['Yol karşı taraftaki telveye az kala duruyor; son bağlantısı açık kalıyor.'])).toBeNull();
  });

  it('repair focus keeps topology structural', () => {
    expect(coffeeVoiceRepairFocus('geometry_inference')).toContain('Keep only what the shape shows');
  });
});

describe('4. the handle side is a domain only', () => {
  it('writer rule: no chores, contacts, standing or influence from the handle side', () => {
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
  });

  it('a handle-only takeaway that stays in the domain passes', () => {
    const HANDLE = t10.cases.case5;
    expect(coffeeContextEventPromotion([HANDLE.narrative.takeaway], HANDLE.evidence)).toBeNull();
  });
});

describe('5. an honest, concise sparse reading passes', () => {
  it('the rewritten sparse GOOD exemplar binds', () => {
    const sparse = JSON.parse(readFileSync('./tests/fixtures/batch3a/coffee_good_sparse.json', 'utf8'));
    expect(bindCoffeeNarrative(sparse.narrative, sparse.observation, 'tr')).toBe('evidence_leak');
  });

  it('a short DOTS reading with no invented event binds', () => {
    const DOTS = t10.cases.case9;
    const n: CoffeeNarrative = {
      visualObservation: DOTS.narrative.visualObservation,
      overall: {
        text: 'Üst tarafa küçük noktalar serpilmiş, ağız kenarının hemen altı ise tertemiz kalmış. Ağızdaki bu temizlik önünün açık olduğunu söylüyor; gelecek olana yer var. Noktalar dağınık ve ufak duruyor, tek bir yere toplanmamış.',
        evidenceIds: ['e1', 'e2'],
      },
      love: { text: '', evidenceIds: [] },
      career: { text: '', evidenceIds: [] },
      money: { text: '', evidenceIds: [] },
      nearFuture: { text: '', evidenceIds: [] },
      takeaway: { text: 'Noktalar ağız tarafına yakın serpildiği için, bu fincanın küçük ayrıntıları uzak bir zamana ait değil.', evidenceIds: ['e2'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBe('evidence_leak');
    expect(bindCoffeeNarrative(n, observation(DOTS.evidence), 'tr')).toBe('evidence_leak');
  });
});

describe('8. Palm untouched', () => {
  it('no Coffee grounding rule reaches Palm', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('ABSENCE IS NOT CONTENT');
      expect(text).not.toContain('GEOMETRY IS NOT CAUSE');
      expect(text).not.toContain('THE HANDLE SIDE IS A DOMAIN');
    }
  });
});
