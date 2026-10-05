/**
 * PHASE C1.3 — anti-template diversity + required takeaway consistency.
 *
 * Real provider QA (C1.2, 6 × gpt-5.6-sol) showed two product defects:
 * 3/6 readings left the REQUIRED takeaway empty, and 6/6 were narrated
 * through one wrapper ("an unnamed long-standing matter → a conversation →
 * relief"). The coffee_qa_c12_case* fixtures are those real outputs,
 * verbatim, with their provider request ids.
 */

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeGenericWrapper,
  coffeeVoiceFailure,
  coffeeWrapperProfile,
  evaluateCoffeeQuality,
} from '../src/ai/human-quality.js';
import {
  bindCoffeeNarrative,
  coffeeQualityFailure,
  toPublicCoffee,
} from '../src/ai/reading/evidence-bind.js';
import { coffeeCommunicationAffordance } from '../src/ai/reading/coffee-diversity.js';
import { COFFEE_WRITER_SCHEMA } from '../src/ai/reading/schemas.js';
import {
  coffeeEmptyRequiredFocus,
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  ReadingPersonalization,
} from '../src/ai/reading/types.js';

type Fixture = {
  observation: CoffeeObservation;
  narrative: CoffeeNarrative;
  personalization?: ReadingPersonalization;
  requestId?: string;
};

function load(name: string): Fixture {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8')) as Fixture;
}

function interpretation(n: CoffeeNarrative): string[] {
  return [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
}

function bind(f: Fixture) {
  return bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization);
}

function quality(f: Fixture) {
  return coffeeQualityFailure(f.narrative, 'tr', f.personalization, f.observation.evidence);
}

const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const E = { text: '', evidenceIds: [] as string[] };

const GOOD = [
  'coffee_good',
  'coffee_good_3a3',
  'coffee_good_3a5',
  'coffee_diverse_3a4',
  'coffee_good_sparse',
  'coffee_good_two_sign',
];

describe('C1.3 A — takeaway is required, optional sections stay optional', () => {
  it('the writer prompt states the runtime contract unambiguously', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('REQUIRED NON-EMPTY: visualObservation, overall, takeaway');
    expect(p).toContain('OPTIONAL (may be "" with empty evidenceIds): love, career, money, nearFuture');
    expect(p).toContain('TAKEAWAY: required, never empty');
    expect(p).toContain('NEAR FUTURE: optional');
    expect(p).toContain('Takeaway is still required');
  });

  it('a sparse reading cannot leave takeaway empty', () => {
    const sparse = load('coffee_good_sparse');
    expect(bind({ ...sparse, narrative: { ...sparse.narrative, takeaway: E } })).toBe('empty_required');
  });

  it('the real sparse / ring / two-sign outputs with empty takeaway are empty_required', () => {
    for (const name of ['coffee_qa_c12_case1', 'coffee_qa_c12_case3', 'coffee_qa_c12_case6']) {
      const f = load(name);
      expect(f.narrative.takeaway.text, name).toBe('');
      expect(bind(f), name).toBe('empty_required');
    }
  });

  it('empty_required gets a targeted repair: fill only the missing field from cited evidence', () => {
    const ring = load('coffee_qa_c12_case3');
    const focus = coffeeEmptyRequiredFocus(ring.narrative) ?? '';
    expect(focus).toContain('Missing required field(s): takeaway.');
    expect(focus).toContain('leave every other section unchanged');
    expect(focus).toMatch(/already cited in this reading \(e1, e2, e3\)/);
    expect(focus).toContain('do not open a new life domain');
    expect(coffeeEmptyRequiredFocus(load('coffee_good').narrative)).toBeUndefined();
    expect(repairWriterSystem('coffee')).toContain('If empty_required: fill ONLY the missing required field(s)');
  });

  it('optional nearFuture may remain empty', () => {
    const sparse = load('coffee_good_sparse');
    expect(sparse.narrative.nearFuture.text).toBe('');
    expect(bind(sparse)).toBeNull();
    const twoSign = load('coffee_good_two_sign');
    expect(twoSign.narrative.nearFuture.text).toBe('');
    expect(bind(twoSign)).toBeNull();
  });
});

describe('C1.3 B/D — the generic wrapper is rejected structurally', () => {
  it('the six real C1.2 outputs: five fail as generic_wrapper', () => {
    for (const name of [
      'coffee_qa_c12_case1',
      'coffee_qa_c12_case2',
      'coffee_qa_c12_case3',
      'coffee_qa_c12_case4',
      'coffee_qa_c12_case5',
    ]) {
      const f = load(name);
      expect(f.requestId, name).toMatch(/^req_/);
      expect(quality(f), name).toBe('generic_wrapper');
      expect(bind(f), name).not.toBeNull();
    }
  });

  it('real two-sign output also fails (empty takeaway + talk-and-relief home section)', () => {
    const f = load('coffee_qa_c12_case6');
    expect(quality(f)).toBe('generic_wrapper');
    expect(bind(f)).toBe('empty_required');
  });

  it('the differentiated two-sign reading on the same evidence PASSES', () => {
    const f = load('coffee_good_two_sign');
    expect(f.observation).toEqual(load('coffee_qa_c12_case6').observation);
    expect(bind(f)).toBeNull();
    const w = coffeeWrapperProfile(interpretation(f.narrative));
    expect(w.genericOpening).toBe(false);
    expect(w.conversationSections).toBe(0);
  });

  it('opening on an unnamed long-standing issue fails, even with real signs later', () => {
    const f = load('coffee_qa_c12_case2'); // bird cup: communication IS afforded
    expect(coffeeCommunicationAffordance(f.observation.evidence)).toBe(true);
    expect(coffeeWrapperProfile(interpretation(f.narrative)).genericOpening).toBe(true);
  });

  it('a single "konu" or "mesele" is normal Turkish and passes', () => {
    const good = load('coffee_good');
    const once = {
      ...good.narrative,
      takeaway: {
        text: 'Yalnız kuş biraz silik duruyor; haberin hangi konuda olduğunu fincan tam göstermiyor. Sevindirir mi, düşündürür mü, onu gelince göreceksin.',
        evidenceIds: ['e3'],
      },
    };
    expect(coffeeWrapperProfile(interpretation(once)).genericIssues).toBe(1);
    expect(bindCoffeeNarrative(once, good.observation, 'tr')).toBeNull();
  });

  it('generic issue nouns carrying the reading fail', () => {
    expect(
      coffeeGenericWrapper([
        'Telve kulba doğru toplanmış; bu konu evinle ilgili. Konunun içinde yakınların da var.',
        'Bu meseleyi kendi aranızda halledeceksiniz gibi; konu büyümeyecek.',
      ]),
    ).toBe(true);
  });

  it('a talk-and-relief arc fails only when no sign affords communication', () => {
    const arc = [
      'Telve kulba doğru toplanmış; evin içinde bir hareketlilik var gibi.',
      'Yakınlarınla kısa bir konuşma olacak ve sonunda içini ferahlatacak.',
    ];
    expect(coffeeGenericWrapper(arc, false)).toBe(true);
    expect(coffeeGenericWrapper(arc, true)).toBe(false);
    // Road cup: no communication affordance in the evidence.
    expect(coffeeCommunicationAffordance(load('coffee_qa_c12_case4').observation.evidence)).toBe(false);
  });

  it('prompt builds from the strongest sign and gates conversation on affordance', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('HOW TO BUILD THE READING (in this order)');
    expect(p).toContain('NO GENERIC WRAPPER');
    expect(p).toContain('CONVERSATION ONLY WHEN AFFORDED');
    expect(p).not.toContain('a pending conversation');
    expect(coffeeVoiceRepairFocus('generic_wrapper')).toContain('strongest cited sign');
    expect(repairWriterSystem('coffee')).toContain('Never repair by adding a generic "long-standing matter" wrapper');
  });
});

describe('C1.3 C — endings follow the evidence', () => {
  it('neutral and open closings PASS (no relief required)', () => {
    for (const name of ['coffee_good_sparse', 'coffee_diverse_3a4']) {
      const f = load(name);
      expect(coffeeWrapperProfile(interpretation(f.narrative)).resolution, name).toBe(false);
      expect(bind(f), name).toBeNull();
    }
  });

  it('a mixed closing PASSES', () => {
    const f = load('coffee_good');
    expect(f.narrative.takeaway.text).toContain('Sevindirir mi, düşündürür mü');
    expect(bind(f)).toBeNull();
  });

  it('no GOOD fixture relies on a habitual relief phrase', () => {
    const relieved = GOOD.filter(
      (name) => coffeeWrapperProfile(interpretation(load(name).narrative)).resolution,
    );
    expect(relieved).toEqual([]);
  });

  it('the prompt no longer assumes a happy ending', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('ENDINGS FOLLOW THE EVIDENCE');
    expect(p).toContain('positive, neutral, mixed or open');
    expect(p).not.toContain('something about to resolve');
    expect(p).not.toContain('something at home easing');
  });
});

describe('C1.3 F — no overcorrection', () => {
  it('a reading need not name the symbol literally; the lane carries identity', () => {
    const good = load('coffee_good');
    const unnamed: CoffeeNarrative = {
      ...good.narrative,
      overall: {
        text: 'Fincanın ağzına yakın bir yerde kanatlanmış bir şey var; böyle bir işaret haberin yolda olduğunu gösterir. Bu fincanda en canlı duran o: bir mesaj, bir duyum, belki de kimsenin sana henüz söylemediği bir bilgi. Telvenin kulba doğru toplanmasına bakılırsa bu haber uzaktan değil, evin içinden ya da yakın çevrenden çıkacak gibi.',
        evidenceIds: ['e1', 'e3'],
      },
    };
    expect(unnamed.overall.text).not.toMatch(/\bkuş/);
    expect(bindCoffeeNarrative(unnamed, good.observation, 'tr')).toBeNull();
  });

  it('every GOOD fixture passes and has a different opening', () => {
    const openings = GOOD.map((name) => {
      const f = load(name);
      expect(bind(f), name).toBeNull();
      return f.narrative.overall.text.split(/(?<=[.!?])\s+/)[0];
    });
    expect(new Set(openings).size).toBe(GOOD.length);
  });
});

describe('C1.3 — earlier protections preserved', () => {
  it('pre-C1 report prose, live coaching prose and generic clichés still FAIL', () => {
    for (const name of [
      'coffee_bad_former_good',
      'coffee_bad_former_good_3a3',
      'coffee_bad_former_good_3a5',
      'coffee_bad_former_diverse_3a4',
      'coffee_bad_observation_heavy',
      'coffee_bad_generic_cliche',
      'coffee_bad_repetitive',
      'coffee_live_3a4',
    ]) {
      expect(bind(load(name)), name).not.toBeNull();
    }
  });

  it('therapy prose still fails as coaching_voice', () => {
    expect(
      coffeeVoiceFailure([
        'Bir süredir zihninde ağırlık yapan bir mesele var gibi. Kendi sınırını koruyarak ilerlemen, ritmini kaybetmemen bu dönemde önemli.',
        'Önceliklerini netleştirdikçe içindeki gerilim azalacak.',
      ]),
    ).toBe('coaching_voice');
  });

  it('event pile still fails on resemblance-free evidence', () => {
    const sparse = load('coffee_good_sparse');
    const pile = [
      'Fincanın dibi dolu; yakında kapını bir misafir çalacak, eline beklemediğin bir para geçecek.',
      'Üstüne bir de iş teklifi var, sevgilinle aranız da ısınacak gibi.',
    ];
    expect(coffeeVoiceFailure(pile, 0, coffeeCommunicationAffordance(sparse.observation.evidence))).toBe('event_pile');
  });

  it('Palm prompts match Wave 4.3 and the public Coffee contract is unchanged', () => {
    expect(sha(palmWriterSystem('tr'))).toBe('936ce247f105af55fe5719bfef944fc03af0d96303150cb13985a653288c1a6a');
    expect(sha(repairWriterSystem('palm'))).toBe('0f3f764b3f78ae2988b09c76a67bb045689d9aa740a66d79fc426a0f66740387');
    const schema = COFFEE_WRITER_SCHEMA as { required?: string[] };
    expect([...(schema.required ?? [])].sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'takeaway', 'visualObservation'].sort(),
    );
    expect(Object.keys(toPublicCoffee(load('coffee_good').narrative)).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
    // EN readings are not judged by the Turkish wrapper lexicon.
    expect(
      evaluateCoffeeQuality({
        visualObservation: 'x'.repeat(50),
        overall: 'The matter has been on your mind for a while and the conversation will ease it. '.repeat(3),
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'The matter will be settled after a talk with someone close. '.repeat(3),
        language: 'en',
        communicationAffordance: false,
      }),
    ).not.toBe('generic_wrapper');
  });
});
