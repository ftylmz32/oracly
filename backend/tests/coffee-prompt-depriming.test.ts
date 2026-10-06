/**
 * Story-first closure — prompt de-priming. Real full12_run8: a quoted
 * topology example ("seni bulunduğun noktadan başka bir yere taşıyan somut
 * bir hareket") was copied into ROAD (twice), BRIDGE, LOW-SYMBOL and
 * NO-SIGN; BIRD closed on the dense base as a second story; DOTS padded a
 * sparse cup with meta talk. Rules now describe behaviour; quoted Turkish
 * remains only for wording that must NOT be used. Not a phrase blacklist on
 * output — ordinary Turkish words stay allowed.
 */

import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { coffeeCupMetaTalk, coffeeRepeatedSentence } from '../src/ai/human-quality.js';
import { coffeeContextOnlyTakeaway } from '../src/ai/reading/coffee-diversity.js';
import { coffeeRepairGuidance } from '../src/ai/reading/coffee-repair-guidance.js';
import { bindCoffeeNarrative, coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative, CoffeeObservation, ReadingEvidenceItem } from '../src/ai/reading/types.js';

type Packet = { label: string; evidence: ReadingEvidenceItem[]; narrative: CoffeeNarrative };
const run8 = JSON.parse(
  readFileSync('./tests/fixtures/batch3a/coffee_qa_run8_deprime.json', 'utf8'),
) as { cases: Record<string, Packet> };
const ROAD = run8.cases.case4;
const BIRD = run8.cases.case2;
const BRIDGE = run8.cases.case8;
const DOTS = run8.cases.case9;
const LOW = run8.cases.case10;
const NO_SIGN = run8.cases.case12;

const checks = { cupInteriorVisible: true, adequateFocusLight: true, residueVisible: true, milkFoamObstruction: false, usefulRegionsVisible: true };
const observation = (evidence: ReadingEvidenceItem[]): CoffeeObservation => ({ usable: true, reason: '', checks, evidence });
const meaning = (n: CoffeeNarrative) => [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);

/** Wording that leaked from the instructions into unrelated cups. */
const LEAKED = [
  'seni bulunduğun noktadan başka bir yere taşıyan somut bir hareket',
  'dikkat çekeceğin sevindirici bir gelişme',
  'bağın daha belirgin ve karşılıklı bir hâl alması',
  'maddi karşılığı olan bir kısmet',
  'emeğinin fark edilmesi',
  'birkaç küçük ayrıntı',
  'Burada senin öne çıktığın sevindirici bir gelişme var',
  'kendini belli edecek',
  'senin payına düşüyor',
];

function allCoffeeGuidance(): string {
  const focus = [
    'possibility_menu', 'invented_plan', 'formulaic_voice', 'too_short', 'repeated_sentence',
    'cup_meta_talk', 'caution_voice', 'analyst_voice', 'generic_wrapper',
  ].map((code) => coffeeVoiceRepairFocus(code) ?? '');
  const guidance = [ROAD, BIRD, BRIDGE, DOTS, LOW, NO_SIGN].map(
    (c) => coffeeRepairGuidance('section_redundancy', c.narrative, c.evidence, 'tr') ?? '',
  );
  return [coffeeWriterSystem('tr'), repairWriterSystem('coffee'), ...focus, ...guidance].join('\n');
}

describe('de-priming: no copyable Turkish fortune wording in Coffee instructions', () => {
  it('none of the leaked phrases is fed to the writer or the repair any more', () => {
    const text = allCoffeeGuidance();
    for (const phrase of LEAKED) expect(text).not.toContain(phrase);
  });

  it('writer and repair both say examples are not wording', () => {
    expect(coffeeWriterSystem('tr')).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(repairWriterSystem('coffee')).toContain('PRIVATE GROUNDED MEANING FACETS');
  });

  it('the leak was real: one instruction phrase appeared in four unrelated topology cups', () => {
    const stock = /bulundu[gğ]un (noktadan|yerden)|ba[sş]ka bir (yere|noktaya) ta[sş][iı]y/;
    for (const c of [ROAD, BRIDGE, LOW, NO_SIGN]) expect(c.narrative.overall.text).toMatch(stock);
  });
});

describe('1. ROAD — the stock topology sentence told twice is rejected', () => {
  it('repeated_sentence catches the delivered ROAD repair', () => {
    expect(coffeeRepeatedSentence(meaning(ROAD.narrative))).toContain('somut bir hareket');
    expect(coffeeQualityFailure(ROAD.narrative, 'tr', undefined, ROAD.evidence)).toBe('repeated_sentence');
    expect(bindCoffeeNarrative(ROAD.narrative, observation(ROAD.evidence), 'tr')).toBe('human_quality');
  });

  it('ordinary shared words across sentences are not a repeat', () => {
    expect(coffeeRepeatedSentence(meaning(run8.cases.case3.narrative))).toBeNull(); // RING
    expect(coffeeRepeatedSentence(meaning(run8.cases.case11.narrative))).toBeNull(); // STAR
  });
});

describe('2/3. topology must stay cup-specific (BRIDGE, LOW-SYMBOL do not inherit ROAD wording)', () => {
  it('the writer is told to use what is distinctive about THIS shape', () => {
    const writer = coffeeWriterSystem('tr');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(writer).toContain('Use only domains and timing explicitly carried by the supplied facets');
    expect(writer).toContain('Do not invent a person, event, date, relationship, job, payment, history, motive, or certainty');
    expect(writer).toContain('never a visual reason');
    expect(writer).not.toMatch(/travel category|who initiates|easier conditions|prior history/i);
  });

  it('menu repair asks for fresh, cup-specific wording instead of a replacement sentence', () => {
    const focus = coffeeVoiceRepairFocus('possibility_menu')!;
    expect(focus).toContain('fresh wording');
    expect(focus).toContain('what this particular shape does');
    expect(focus).toContain('do not reuse wording from these instructions');
  });
});

describe('4. NO-SIGN keeps its "stops short" distinction', () => {
  it('the stops-short takeaway is grounded on the line and is not context-only', () => {
    expect(NO_SIGN.narrative.takeaway.text).toContain('değmeden bitiyor');
    expect(coffeeContextOnlyTakeaway(NO_SIGN.narrative.takeaway, NO_SIGN.evidence)).toBe(false);
    expect(coffeeCupMetaTalk([NO_SIGN.narrative.takeaway.text])).toBeNull();
  });

  it('only its meta sentence ("fincan fazla ayrıntı vermiyor") is flagged', () => {
    expect(coffeeCupMetaTalk([NO_SIGN.narrative.overall.text])).toContain('fazla ayrinti vermiyor');
  });
});

describe('5. BIRD — the dense base cannot carry a second story in the takeaway', () => {
  it('a takeaway resting only on base context is rejected on a cup with a real sign', () => {
    expect(BIRD.narrative.takeaway.text).toContain('Dipte toplu duran telve');
    expect(coffeeContextOnlyTakeaway(BIRD.narrative.takeaway, BIRD.evidence)).toBe(true);
  });

  it('the same cup closing on the bird itself passes that check', () => {
    const n = structuredClone(BIRD.narrative);
    n.takeaway = { text: 'Kuşun kanatları açık; gelen haber yerinde durmayacak, seni de peşinden kıpırdatacak.', evidenceIds: ['e1'] };
    expect(coffeeContextOnlyTakeaway(n.takeaway, BIRD.evidence)).toBe(false);
  });

  it('low-symbol cups (no resemblance) may still close on what little they hold', () => {
    expect(coffeeContextOnlyTakeaway(run8.cases.case5.narrative.takeaway, run8.cases.case5.evidence)).toBe(false); // HANDLE
  });

  it('writer rule: the base never becomes the after-story', () => {
    const writer = coffeeWriterSystem('tr');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
  });
});

describe('6. DOTS — no meta / caution padding, no malformed personification', () => {
  it('"Fincanın sakin konuşuyor" is rejected as cup_meta_talk', () => {
    expect(coffeeCupMetaTalk(meaning(DOTS.narrative))).toContain('fincanin sakin konusuyor');
    expect(coffeeQualityFailure(DOTS.narrative, 'tr', undefined, DOTS.evidence)).toBe('cup_meta_talk');
  });

  it('the generic "not much detail" frame is caught across cups', () => {
    expect(coffeeCupMetaTalk(meaning(LOW.narrative))).toContain('fazla ayrinti vermemis');
    expect(coffeeCupMetaTalk(meaning(BIRD.narrative))).toContain('buyuk sozler vermiyor');
  });

  it('an honest single-dimension limit is not meta talk', () => {
    expect(coffeeCupMetaTalk(['Bir şeyler yerinden oynamak istiyor; ne zaman olacağını fincan göstermiyor.'])).toBeNull();
    expect(coffeeCupMetaTalk(['Haberin ne yönde olduğunu fincan tam göstermiyor.'])).toBeNull();
  });

  it('the sparse rule forbids caution padding and cup personification', () => {
    const writer = coffeeWriterSystem('tr');
    for (const w of ['"şimdilik"', '"henüz"', '"göstermemiş"', '"büyük sözler vermiyor"', 'do not personify the cup']) {
      expect(writer).toContain('PRIVATE GROUNDED MEANING FACETS');
    }
  });
});

describe('8. Palm untouched', () => {
  it('no Coffee de-priming rule reaches Palm', () => {
    for (const text of [palmWriterSystem('tr'), repairWriterSystem('palm')]) {
      expect(text).not.toContain('EXAMPLES ARE NOT WORDING');
      expect(text).not.toContain('EACH TOPOLOGY TYPE HAS ITS OWN AFFORDANCE');
      expect(text).not.toContain('NATURAL FALCI DELIVERY');
    }
  });
});
