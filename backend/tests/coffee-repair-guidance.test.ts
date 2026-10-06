/**
 * Story-first closure — the ONE Coffee repair call receives guidance for
 * every deterministic Coffee defect actually present in the rejected
 * narrative (primary violation unchanged; secondaries are guidance only).
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { OpenAiTransport } from '../src/ai/openai-transport.js';
import { coffeeAdditionalRepairDefects, coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { ReadingPipeline } from '../src/ai/reading/pipeline.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import { coffeeWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';
import { testConfig } from './helpers.js';

type Packet = { evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const qa = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_story_first_qa.json', 'utf8'),
) as { cases: Record<string, Packet>; starRun3FirstPass: Packet };

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });

/** The old STAR failure: takeaway restates overall, overall keeps its menu. */
function injectedStar(): CoffeeNarrative {
  const n = structuredClone(qa.starRun3FirstPass.narrative);
  n.takeaway = {
    text: 'Yıldızın açıkça belirmesi, seni öne çıkaracak küçük ama sevindirici bir gelişmeye yorulur; dikkat çekecek tek bir kısmet var.',
    evidenceIds: ['e1'],
  };
  return n;
}
const STAR_EVIDENCE = qa.starRun3FirstPass.evidence;
const PLANNABLE_STAR_EVIDENCE = STAR_EVIDENCE.map((evidence, index) => index === 0
  ? { ...evidence, description: 'A clear bird-like form near the upper wall.', resemblance: 'bird' }
  : evidence);

/**
 * run6 STAR (case11) closed overall on reading self-reference ("Fincanda
 * başka belirgin şekillerin öne çıkmaması …; falın sözü … toplanmış"), now
 * its own defect. Same reading with that sentence told directly.
 */
function cleanStar(): CoffeeNarrative {
  const n = structuredClone(qa.cases.case11.narrative);
  n.overall.text = n.overall.text.replace(
    'Fincanda başka belirgin şekillerin öne çıkmaması da bu haberi daha özel kılıyor; falın sözü tek bir sevindirici noktada toplanmış.',
    'Tek başına parlayan bu yıldız, sevinci dağıtmadan doğrudan sana getiriyor; bu takdir yalnız şanstan değil, ortaya koyduğun emeğin görünür hâle gelmesinden doğacak.',
  );
  return n;
}

/** Fixture-specific C2.1-safe repair: same STAR scenario and ids, no public visual evidence. */
function meaningStarRepair(): CoffeeNarrative {
  return {
    visualObservation: {
      text: 'Yakın dönemde emeğinin karşılığını görünür kılacak sevindirici bir fırsat öne çıkıyor.',
      evidenceIds: ['e1'],
    },
    overall: {
      text: 'Emeğin fark edilecek ve bunun karşılığını açık bir takdir olarak alacaksın. Önüne gelen tek ve seçkin fırsat, kalabalık gelişmeler arasında kaybolmadan doğrudan senin payına düşüyor. Bu ilerleme günlük düzeninde belirgin bir canlılık yaratacak ve verdiğin emeğin değerini başkalarının da açıkça görmesini sağlayacak. Sonuç gösterişli bir değişimden çok, sana tam denk gelen temiz ve kalıcı bir sevinç taşıyor.',
      evidenceIds: ['e1'],
    },
    love: { text: '', evidenceIds: [] },
    career: { text: '', evidenceIds: [] },
    money: { text: '', evidenceIds: [] },
    nearFuture: {
      text: 'Bu güzel gelişme yakın zamanda kendini belli edecek ve kısa süre içinde netleşecek.',
      evidenceIds: ['e1'],
    },
    takeaway: {
      text: 'Bu kısmetin asıl güzelliği büyüklüğünde değil, tam sana göre biçilmiş olmasında; geldiğinde onu hemen tanıyacaksın.',
      evidenceIds: ['e1'],
    },
  };
}

describe('one Coffee repair request carries every detected defect (real pipeline, fake transport)', () => {
  it('section_redundancy + possibility_menu → one repair whose guidance names both', async () => {
    const injected = injectedStar();
    expect(bindCoffeeNarrative(injected, observation(PLANNABLE_STAR_EVIDENCE), 'tr')).toBe('section_redundancy');

    const repaired = meaningStarRepair();
    const calls: Array<{ kind: string; user: string }> = [];
    const fetchFn = (async (_url: string, init?: RequestInit) => {
      const body = JSON.parse(String(init?.body));
      const reply = (content: string) =>
        new Response(JSON.stringify({ choices: [{ message: { content } }] }), { status: 200 });
      if (body.response_format?.json_schema?.name === 'coffee_observation') {
        return reply(JSON.stringify(observation(PLANNABLE_STAR_EVIDENCE)));
      }
      const system = body.messages[0].content;
      const kind = system === coffeeWriterSystem('tr') ? 'writer' : system === repairWriterSystem('coffee') ? 'repair' : 'other';
      calls.push({ kind, user: body.messages[1].content });
      return reply(JSON.stringify(kind === 'writer' ? injected : repaired));
    }) as never;

    const config = testConfig();
    const pipeline = new ReadingPipeline(config, new OpenAiTransport(config, fetchFn));
    readingStageStore.clear();
    const ctx = { identity: 'u-guidance', parentKey: `p-guidance-${Date.now()}`, language: 'tr' as const };
    const observed = await pipeline.observeCoffee({ mimeType: 'image/jpeg', bytes: Buffer.from([0xff, 0xd8, 0xff, 0xd9]) }, ctx);
    const delivered = await pipeline.writeCoffee({ observationToken: observed.observationToken }, ctx);

    expect(calls.map((c) => c.kind)).toEqual(['writer', 'repair']);
    const repairUser = calls[1].user;
    expect(repairUser).toContain('Violation codes: section_redundancy');
    const guidance = coffeeRepairGuidance('section_redundancy', injected, STAR_EVIDENCE, 'tr')!;
    expect(guidance).toContain('Overall already covers the collapsed pattern.');
    // The injected takeaway also repeats overall's first sentence.
    expect(guidance).toContain('Additional detected Coffee defects: possibility_menu, repeated_sentence, dictionary_voice.');
    expect(guidance).toContain('yaptigin ya da sundugun');
    expect(guidance).not.toContain('invented_plan');
    expect(repairUser).toContain('Private structured Coffee story plan:');
    expect(repairUser).not.toContain('Rejected narrative JSON:');
    expect(repairUser).not.toContain('"region"');
    expect(repairUser).not.toContain('"description"');
    expect(repairUser).not.toContain('"resemblance"');
    expect(JSON.stringify(delivered)).toContain(repaired.overall.text.slice(0, 40));
    expect(JSON.stringify(delivered)).not.toMatch(/yıldız|fincan|telve|üst iç yüzey/i);
  });
});

describe('coffeeRepairGuidance — combinations', () => {
  it('insight_collapse + possibility_menu', () => {
    const g = coffeeRepairGuidance('insight_collapse', injectedStar(), STAR_EVIDENCE, 'tr')!;
    expect(g).toContain('Overall already covers the collapsed pattern.');
    expect(g).toContain('Additional detected Coffee defects: possibility_menu, repeated_sentence, dictionary_voice.');
  });

  it('section_redundancy + invented_plan', () => {
    const n = injectedStar();
    n.overall.text = n.overall.text.replace('yaptığın ya da sunduğun bir şeyin', 'elindeki planın devamında yaptığın bir şeyin');
    const g = coffeeRepairGuidance('section_redundancy', n, STAR_EVIDENCE, 'tr')!;
    expect(g).toContain('Additional detected Coffee defects: invented_plan, repeated_sentence, dictionary_voice.');
    expect(g).not.toContain('possibility_menu');
  });

  it('possibility_menu (primary) + invented_plan (secondary) — real ROAD output', () => {
    const road = qa.cases.case4;
    expect(bindCoffeeNarrative(road.narrative, observation(road.evidence), 'tr')).toBe('human_quality');
    expect(coffeeQualityFailure(road.narrative, 'tr', undefined, road.evidence)).toBe('possibility_menu');
    const g = coffeeRepairGuidance('human_quality', road.narrative, road.evidence, 'tr')!;
    expect(g).toContain('lists alternative interpretations of one sign'); // primary focus
    expect(g).toContain('Additional detected Coffee defects: invented_plan.');
    // The primary defect is not repeated as a secondary.
    expect(coffeeAdditionalRepairDefects(road.narrative, 'possibility_menu').map((d) => d.defect)).toEqual(['invented_plan']);
  });

  it('both secondaries present (menu + invented plan) are both listed', () => {
    const road = qa.cases.case4; // run6 ROAD: "… iş veya yer değişikliği" + "planın biçim değiştirerek"
    const g = coffeeRepairGuidance('section_redundancy', road.narrative, road.evidence, 'tr')!;
    expect(g).toContain('Additional detected Coffee defects: possibility_menu, invented_plan.');
  });

  it('NO-SIGN: the handle pair "evinden ya da yakın çevrenden" is not a menu; its plan is', () => {
    const nosign = qa.cases.case12;
    expect(coffeeAdditionalRepairDefects(nosign.narrative, null).map((d) => d.defect)).toEqual(['invented_plan']);
  });
});

describe('coffeeRepairGuidance — no false guidance', () => {
  it('benign "ya da / veya" adds nothing', () => {
    const sparse = structuredClone(qa.cases.case1.narrative); // "kişi, haber ya da yol çıkmamış"
    // run6 SPARSE also said "fincan büyük vaatler sıralamıyor" (reading self-reference, now its own defect).
    sparse.overall.text = sparse.overall.text.replace('; bu yüzden fincan büyük vaatler sıralamıyor.', '.');
    sparse.takeaway.text = 'Er ya da geç, ağız kenarındaki açıklık önünde bir ya da iki küçük kısmet bulunduğunu söylüyor.';
    sparse.takeaway.evidenceIds = ['e3']; // the clean rim it talks about (open kısmet)
    expect(coffeeAdditionalRepairDefects(sparse, null)).toEqual([]);
    const g = coffeeRepairGuidance('section_redundancy', sparse, qa.cases.case1.evidence, 'tr');
    expect(g ?? '').not.toContain('Additional detected Coffee defects');
  });

  it('a clean real reading gets exactly the primary guidance', () => {
    const star = qa.cases.case11;
    const g = coffeeRepairGuidance('section_redundancy', cleanStar(), star.evidence, 'tr');
    expect(g).toContain('Overall already covers the collapsed pattern.');
    expect(g).not.toContain('Additional detected Coffee defects');
  });
});
