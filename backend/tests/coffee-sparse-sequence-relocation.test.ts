/**
 * Story-first closure — the three remaining product classes, on the exact
 * real targeted11 outputs (gpt-5.6-sol, low):
 *   B/C sparse-cup length pressure and the sparse takeaway-echo false positive
 *   D   context -> sequence inside a section that also cites a real sign
 *   E   plain connection -> relocation
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeContextSequence,
  coffeeInsightCollapse,
  coffeeSemanticCollapse,
  coffeeSparseTakeawayEcho,
  coffeeTakeawayEcho,
  coffeeTakeawayEchoPairs,
  ideaClusterRepeats,
} from '../src/ai/human-quality.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import {
  coffeeEvidenceConcentration,
  coffeeNarrativelySparse,
  coffeePlainLineRelocation,
  coffeeSingleSemanticAnchorRoots,
} from '../src/ai/reading/coffee-diversity.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { coffeeWriterSystem, palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Stage = { kind: string; quality: string | null; narrative: CoffeeNarrative };
type Case = { label: string; evidence: ReadingEvidenceItem[]; stages: Stage[] };
const t11 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_targeted11.json', 'utf8'),
) as { cases: Record<string, Case> };
const BIRD = t11.cases.case2;
const ROAD = t11.cases.case4;
const HANDLE = t11.cases.case5;
const BRIDGE = t11.cases.case8;
const DOTS = t11.cases.case9;
const LOW = t11.cases.case10;
const NO_SIGN = t11.cases.case12;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const empty = { text: '', evidenceIds: [] as string[] };
const last = (c: Case) => c.stages[c.stages.length - 1].narrative;

describe('A/1. the saved DOTS repair — exact redundancy sub-gate', () => {
  const repaired = DOTS.stages[1].narrative;

  it('only coffeeTakeawayEcho fires; every other redundancy check is false', () => {
    const o = repaired.overall.text;
    const nf = repaired.nearFuture.text;
    const t = repaired.takeaway.text;
    expect(ideaClusterRepeats(meaning(repaired))).toBe(false);
    expect(coffeeInsightCollapse(o, nf, t, coffeeSingleSemanticAnchorRoots(DOTS.evidence))).toBe(false);
    expect(coffeeSemanticCollapse(o, nf, t)).toBe(false);
    expect(coffeeEvidenceConcentration({ overall: repaired.overall, nearFuture: repaired.nearFuture, takeaway: repaired.takeaway }, DOTS.evidence)).toBe(false);
    expect(coffeeTakeawayEchoPairs(o, t)).toEqual(['agiz kenar', 'temiz bant', 'yakin zaman']);
    expect(coffeeTakeawayEcho(o, t)).toBe(true);
  });

  it('it is a real paraphrase ("yakın zaman … ferah pay"), so it still fails on the sparse echo', () => {
    expect(coffeeNarrativelySparse(DOTS.evidence)).toBe(true);
    expect(coffeeSparseTakeawayEcho(repaired.overall.text, repaired.takeaway.text)).toBe(true);
    expect(coffeeQualityFailure(repaired, 'tr', undefined, DOTS.evidence)).toBe('section_redundancy');
  });

  it('C. the false-positive mode is fixed: sharing only the evidence\'s own name is not an echo', () => {
    const overall = 'Ağız kenarındaki temiz bant, önünde açık bir kısmet bırakıyor; gelecek olana yer var.';
    const takeaway = 'Ağız kenarındaki temiz bant fincanın ağzına yakın durduğu için, bu açıklığı uzak bir zamanda değil günlük hayatında göreceksin.';
    expect(coffeeTakeawayEchoPairs(overall, takeaway)).toEqual(expect.arrayContaining(['agiz kenar', 'temiz bant']));
    expect(coffeeTakeawayEcho(overall, takeaway)).toBe(true); // old behaviour: false positive
    expect(coffeeSparseTakeawayEcho(overall, takeaway)).toBe(false);
  });
});

describe('B. narratively sparse cups — evidence-derived, narrow', () => {
  it('only dots / faint marks / density / clean band / handle-side cups are sparse', () => {
    expect(coffeeNarrativelySparse(HANDLE.evidence)).toBe(true);
    expect(coffeeNarrativelySparse(DOTS.evidence)).toBe(true);
    for (const c of [BIRD, ROAD, BRIDGE, LOW, NO_SIGN]) expect(coffeeNarrativelySparse(c.evidence)).toBe(false);
  });

  it('2. the concise grounded HANDLE first pass (lead 49 words) is no longer too_short', () => {
    const first = structuredClone(HANDLE.stages[0].narrative);
    expect(HANDLE.stages[0].quality).toBe('too_short');
    // Its opener "Falın ev ve sana en yakın insanlar çevresinde duruyor" is
    // reading self-reference (a separate defect); told directly, at the same
    // length, the concise reading passes the sparse floor.
    first.overall.text = first.overall.text.replace(
      'Falın ev ve sana en yakın insanlar çevresinde duruyor.',
      'Ev ve sana en yakın insanlar hayatının merkezinde duruyor.',
    );
    expect(coffeeQualityFailure(first, 'tr', undefined, HANDLE.evidence)).toBeNull();
    expect(bindCoffeeNarrative(first, observation(HANDLE.evidence), 'tr')).toBeNull();
  });

  it('3. a concise grounded DOTS reading (meaning of the open rim + timing from where it sits) passes', () => {
    const n: CoffeeNarrative = {
      visualObservation: { text: 'Ağız kenarının hemen altında ince, temiz bir bant var; yukarıya küçük noktalar serpilmiş, dipte telve toplanmış.', evidenceIds: ['e1', 'e2', 'e3'] },
      overall: { text: 'Ağız kenarındaki temiz şerit, önünde açık bir kısmet bırakıyor; seni sıkıştıran bir şey yok, gelecek olana yer var. Yukarıya serpilmiş küçük noktalar bu açıklığın çevresinde, ufak tefek ayrıntılar olarak duruyor.', evidenceIds: ['e1', 'e2'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Şerit fincanın ağzına yakın durduğu için, bu açıklığı uzak bir zamanda değil günlük hayatında göreceksin.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).toBeNull();
    expect(bindCoffeeNarrative(n, observation(DOTS.evidence), 'tr')).toBeNull();
  });

  it('4. trivial generic sparse prose still fails', () => {
    const n: CoffeeNarrative = {
      visualObservation: { text: 'Fincanın ağzı temiz, yukarıda birkaç nokta var.', evidenceIds: ['e1', 'e2'] },
      overall: { text: 'Önün açık. Güzel şeyler olacak, her şey yoluna girecek.', evidenceIds: ['e1'] },
      love: empty,
      career: empty,
      money: empty,
      nearFuture: empty,
      takeaway: { text: 'Kısmetin açık, sabırlı ol.', evidenceIds: ['e1'] },
    };
    expect(coffeeQualityFailure(n, 'tr', undefined, DOTS.evidence)).not.toBeNull();
    expect(bindCoffeeNarrative(n, observation(DOTS.evidence), 'tr')).not.toBeNull();
  });

  it('the lead floor is lowered ONLY for sparse cups (a sign cup of the same length still fails)', () => {
    // Normal lead is now 48 (calibrated), so use a lead below it: 38 words.
    const short = structuredClone(HANDLE.stages[0].narrative);
    short.overall.text = 'Ev ve sana en yakın kişiler şu günlerde hayatında daha fazla yer tutuyor. Gelişmeler de uzak çevreden çok bu tanıdık halkanın içinde şekilleniyor.';
    expect(coffeeQualityFailure(short, 'tr', undefined, BIRD.evidence)).toBe('too_short');
  });

  it('repair is told that a concise reading is correct on a sparse cup — and only there', () => {
    const g = coffeeRepairGuidance('section_redundancy', DOTS.stages[1].narrative, DOTS.evidence, 'tr')!;
    expect(g).toContain('THIS CUP IS NARRATIVELY SPARSE');
    // B: a sparse repair never sees the full-fortune length target at all.
    expect(g).not.toContain('70–120');
    expect(g).toContain('never pad toward a length');
    const road = coffeeRepairGuidance('section_redundancy', last(ROAD), ROAD.evidence, 'tr') ?? '';
    expect(road).not.toContain('NARRATIVELY SPARSE');
  });
});

describe('D. context does not create sequence, even beside a sign', () => {
  it('5. BIRD "serpişen telve … haberin ardından … peş peşe" fails context_sequence', () => {
    const first = BIRD.stages[0].narrative;
    expect(first.overall.evidenceIds).toEqual(['e1', 'e2']);
    expect(coffeeContextSequence(meaning(first))).toContain('serpisen telve de haberin ardindan');
    expect(coffeeQualityFailure(first, 'tr', undefined, BIRD.evidence)).toBe('context_sequence');
  });

  it('6. a sign-led bird story with neutral context passes', () => {
    const n = structuredClone(BIRD.stages[0].narrative);
    n.overall.text = 'Sana yakın zamanda kısa ama dikkat çekici bir haber geliyor. Kuşun küçük oluşu, uzun uzun anlatılan bir şeyden çok doğrudan söylenen bir sözü gösteriyor. Bu haber geldiği anda bir gelişmenin hangi yönde ilerleyeceğini anlayacaksın. Fincanın ortasına serpişen telve haberin çevresinde birkaç küçük ayrıntı bırakıyor; asıl söz kuşta.';
    expect(coffeeContextSequence(meaning(n))).toBeNull();
    expect(coffeeQualityFailure(n, 'tr', undefined, BIRD.evidence)).toBeNull();
  });

  it('a road may still carry a sequence', () => {
    expect(coffeeContextSequence(['Yol önce dipten çıkıyor, sonra kıvrılarak ağza varıyor.'])).toBeNull();
  });
});

describe('E. a plain connection is not relocation', () => {
  it('7. LOW-SYMBOL "bulunduğu yerden başka bir noktaya doğru ilerleyeceğini" fails', () => {
    const first = LOW.stages[0].narrative;
    expect(coffeePlainLineRelocation(meaning(first), LOW.evidence)).toContain('baska bir noktaya dogru ilerleyecegini');
    expect(coffeeQualityFailure(first, 'tr', undefined, LOW.evidence)).toBe('plain_line_relocation');
  });

  it('8. ROAD — a reported road may carry movement and a course', () => {
    // targeted11 ROAD also presumed the person's prior thought ("gidişatın
    // başta düşündüğünden farklı"), now presumed_user_state; told directly:
    expect(coffeeQualityFailure(last(ROAD), 'tr', undefined, ROAD.evidence)).toBe('presumed_user_state');
    const direct = structuredClone(last(ROAD));
    direct.overall.text = direct.overall.text.replace('gidişatın başta düşündüğünden farklı şekillenebileceğini', 'gidişatın farklı biçimde şekillenebileceğini');
    expect(coffeeQualityFailure(direct, 'tr', undefined, ROAD.evidence)).toBeNull();
    expect(coffeePlainLineRelocation(['Yol seni bulunduğun yerden başka bir noktaya taşıyacak.'], ROAD.evidence)).toBeNull();
  });

  it('position words and negated lists are not relocation', () => {
    expect(coffeePlainLineRelocation(['Bulunduğun noktada bir kıpırtı başlamış.'], LOW.evidence)).toBeNull();
    expect(coffeePlainLineRelocation(['Burada güçlü bir haber, yolculuk ya da buluşma yok.'], LOW.evidence)).toBeNull();
    expect(coffeePlainLineRelocation(['Ev çevresinden başlayan bir gelişme bulunduğu yerden dışarıya doğru uzanıyor.'], NO_SIGN.evidence)).toBeNull();
  });
});

describe('9. current good topology outputs still pass', () => {
  it('BRIDGE (link landing toward home) and NO-SIGN (stops short) bind', () => {
    for (const c of [BRIDGE, NO_SIGN]) {
      expect(coffeeQualityFailure(last(c), 'tr', undefined, c.evidence)).toBeNull();
      expect(bindCoffeeNarrative(last(c), observation(c.evidence), 'tr')).toBeNull();
    }
  });
});

describe('writer rules and 10. Palm untouched', () => {
  it('Coffee writer states both rules', () => {
    expect(coffeeWriterSystem('tr')).toContain('CONTEXT CARRIES NO CHRONOLOGY');
    expect(coffeeWriterSystem('tr')).toContain('A PLAIN LINE IS NOT A ROAD');
  });

  it('no new rule reaches Palm', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('CONTEXT CARRIES NO CHRONOLOGY');
      expect(text).not.toContain('A PLAIN LINE IS NOT A ROAD');
      expect(text).not.toContain('NARRATIVELY SPARSE');
    }
  });
});
