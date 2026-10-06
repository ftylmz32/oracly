/**
 * PHASE C1 — Coffee product truth.
 *
 * The pre-C1 quality system approved Coffee prose that read like either a
 * computer-vision report or a therapist / life coach ("iç ağırlık", "eşik",
 * "başkalarının temposu", "ölçülü açıklık"...). These tests pin the new
 * standard: a human Turkish coffee fortune teller, grounded in evidence.
 * Palm prompts and the public Coffee contract are proven unchanged.
 */

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeVoiceFailure,
  coffeeVoiceProfile,
  evaluateCoffeeQuality,
} from '../src/ai/human-quality.js';
import {
  bindCoffeeNarrative,
  coffeeQualityFailure,
  toPublicCoffee,
} from '../src/ai/reading/evidence-bind.js';
import { COFFEE_WRITER_SCHEMA } from '../src/ai/reading/schemas.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  palmWriterUser,
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
};

function load(name: string): Fixture {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8')) as Fixture;
}

function interpretation(n: CoffeeNarrative): string[] {
  return [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
}

function quality(n: CoffeeNarrative) {
  return evaluateCoffeeQuality({
    visualObservation: n.visualObservation.text,
    overall: n.overall.text,
    love: n.love.text,
    career: n.career.text,
    money: n.money.text,
    nearFuture: n.nearFuture.text,
    takeaway: n.takeaway.text,
    language: 'tr',
  });
}

const sha = (s: string) => createHash('sha256').update(s).digest('hex');

const NEW_GOOD = ['coffee_good', 'coffee_good_3a3', 'coffee_good_3a5', 'coffee_diverse_3a4'];
const FORMER_GOOD = [
  'coffee_bad_former_good',
  'coffee_bad_former_good_3a3',
  'coffee_bad_former_good_3a5',
  'coffee_bad_former_diverse_3a4',
];

describe('PHASE C1 — new GOOD Coffee fixtures are fortune-teller prose', () => {
  for (const name of NEW_GOOD) {
    it(`${name} passes quality and binds`, () => {
      const f = load(name);
      expect(quality(f.narrative)).toBeNull();
      expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization)).toBe('evidence_leak');
      const p = coffeeVoiceProfile(interpretation(f.narrative));
      expect(p.coachKinds).toBe(0);
      expect(p.labLedSections).toBe(0);
      // C1.1: no minimum number of life events; only a cap on stacking them.
      const signs = f.observation.evidence.filter((e) => e.resemblance).length;
      expect(p.eventDomains).toBeLessThanOrEqual(2 + signs);
    });
  }
});

describe('PHASE C1 — the old wrongly-approved standard is now rejected', () => {
  it('former coffee_good_3a5 prose FAILS, on both report and coaching grounds', () => {
    const f = load('coffee_bad_former_good_3a5');
    expect(quality(f.narrative)).not.toBeNull();
    expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization)).toBe('human_quality');
    const p = coffeeVoiceProfile(interpretation(f.narrative));
    // Every interpretation section opens by describing residue...
    expect(p.labLedSections).toBeGreaterThanOrEqual(2);
    // ...and, independently, the register is therapist/coach.
    expect(p.coachKinds).toBeGreaterThanOrEqual(6);
    expect(f.narrative.overall.text).toContain('iç ağırlığa');
    expect(f.narrative.takeaway.text).toContain('başkalarının temposundan');
  });

  it('coffee_live_3a4 prose FAILS, and its voice alone is coaching_voice', () => {
    const f = load('coffee_live_3a4');
    expect(quality(f.narrative)).not.toBeNull();
    expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization)).not.toBeNull();
    expect(coffeeVoiceFailure(interpretation(f.narrative))).toBe('coaching_voice');
    expect(f.narrative.takeaway.text).toContain('Ölçülü bir açıklık');
  });

  for (const name of FORMER_GOOD) {
    it(`${name} (formerly GOOD) FAILS`, () => {
      const f = load(name);
      expect(quality(f.narrative)).not.toBeNull();
      expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization)).not.toBeNull();
    });
  }

  it('existing BAD fixtures still FAIL (observation-heavy, generic cliché, repetition)', () => {
    expect(quality(load('coffee_bad_observation_heavy').narrative)).toBe('observation_heavy');
    expect(quality(load('coffee_bad_generic_cliche').narrative)).not.toBeNull();
    expect(quality(load('coffee_bad_repetitive').narrative)).toBe('duplicate_sections');
  });

  it('unknown evidence binding still FAILS on a good reading', () => {
    const f = load('coffee_good');
    const invented: CoffeeNarrative = {
      ...f.narrative,
      nearFuture: { text: f.narrative.nearFuture.text, evidenceIds: ['e3', 'invented'] },
    };
    expect(bindCoffeeNarrative(invented, f.observation, 'tr')).toBe('unknown_evidence_id');
  });
});

describe('PHASE C1 — structural voice checks (categories, not sentences)', () => {
  const good = load('coffee_good').narrative;

  it('rejects abstract prose with no concrete human-life development', () => {
    const abstract = [
      'Şu sıralar içinde bir şeylerin yerine oturmaya başladığını hissediyorsun gibi. Bu dönem, kendine dönmenin ve olanı olduğu gibi kabul etmenin zamanı olabilir.',
      'Önümüzdeki günlerde hafif bir değişim seziliyor; bu değişim yavaş ama kalıcı görünüyor.',
      'Her şey zamanla yerini bulur gibi; acele etmeye gerek yok.',
    ];
    expect(coffeeVoiceFailure(abstract)).toBe('abstract_reading');
  });

  it('rejects one abstract theme spread across sections (semantic soup)', () => {
    const soup = [
      'Bir karar seni bekliyor gibi; kardeşinle bu konuyu konuşacaksın.',
      'Yakında verilecek bir karar, bir haberle hızlanabilir.',
      'Bu kararın sonunda evde bir rahatlama olacak gibi.',
    ];
    expect(coffeeVoiceFailure(soup)).toBe('abstract_soup');
  });

  it('a single report clause or one coaching word does not fail a real reading', () => {
    expect(
      coffeeVoiceFailure([
        good.overall.text + ' Ortadaki küme biraz daha koyu duruyor.',
        good.nearFuture.text,
        good.takeaway.text + ' Biraz nefes alacaksın gibi.',
      ]),
    ).toBeNull();
  });

  it('EN/RU readings are not judged by the Turkish voice lexicon', () => {
    expect(['coaching_voice', 'abstract_reading', 'abstract_soup']).not.toContain(
      evaluateCoffeeQuality({
        visualObservation: 'The grounds gathered near the handle and the bottom of the cup stayed clear and open.',
        overall:
          'There is something you have kept to yourself for a while, and the cup suggests it is about to ease. The grounds leaning toward the handle point to someone close to home who will bring it up before you have to, and that conversation will go better than you expect.',
        love: '',
        career: '',
        money: '',
        nearFuture: 'A small bird shape near the rim suggests news on its way, perhaps a call you have been waiting for.',
        takeaway: 'The clear bottom of the cup is the good sign here: nothing is closed off, and the news will help settle the matter quickly.',
        language: 'en',
      }),
    );
  });
});

describe('PHASE C1 — writer and repair prompts', () => {
  it('Coffee writer asks for a fortune teller and bans report/coaching registers', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(p).toContain('Tell the life consequence, never a visual reason');
    expect(p).toContain('No symbol dictionary, analysis language, advice, coaching');
    expect(p).toContain('Do not invent a person, event, date, relationship, job, payment, history, motive, or certainty');
    expect(p).toContain('never as a guaranteed fact');
    // The coaching-biased shared priority line is no longer in the Coffee prompt.
    expect(p).not.toContain('small practical next step');
    expect(p).not.toContain('Prefer reflective close');
  });

  it('Coffee repair always targets fortune-teller voice and never coaching', () => {
    const r = repairWriterSystem('coffee');
    expect(r).toContain('PRIVATE GROUNDED MEANING FACETS');
    expect(r).toContain('Remove coaching, disclaimer, generic-wrapper');
    expect(r).toContain('Never expose or reconstruct figures, symbols, signs, cup regions, grounds, residue, geometry');
    for (const code of ['coaching_voice', 'abstract_reading', 'abstract_soup', 'observation_heavy']) {
      expect(coffeeVoiceRepairFocus(code)).toBeTruthy();
    }
    expect(coffeeVoiceRepairFocus('ai_disclosure')).toBeUndefined();
  });

  it('repair receives the specific voice failure behind human_quality', () => {
    const f = load('coffee_live_3a4');
    const rejected: CoffeeNarrative = { ...f.narrative, nearFuture: { text: '', evidenceIds: [] } };
    const detail = coffeeQualityFailure(rejected, 'tr', f.personalization);
    expect(detail).toBe('coaching_voice');
    expect(coffeeVoiceRepairFocus(detail)).toContain('therapist or life coach');
  });
});

describe('PHASE C1 — Palm parity and contract stability', () => {
  it('Palm writer/repair prompts match the Wave 4.3 release candidate', () => {
    // Writer sha256 captured after the Wave 4.3 Palm-only semantic correction.
    expect(sha(palmWriterSystem('tr'))).toBe('936ce247f105af55fe5719bfef944fc03af0d96303150cb13985a653288c1a6a');
    expect(sha(palmWriterSystem('en'))).toBe('fb5568973aebac7a26e264a2d41f1900599ca663451defc0ef1f778a2fc14722');
    expect(sha(palmWriterSystem('ru'))).toBe('3abbd45a48f2c7b1ccb63ab3534f7b0202e611ec4bc220ab18fcc70ef1f6d465');
    expect(sha(palmWriterUser('{}'))).toBe('101c7c16178b6ed63387f1016834f92a409ce3556df8bad8a56ac71488e42d3c');
    expect(sha(repairWriterSystem('palm'))).toBe('0f3f764b3f78ae2988b09c76a67bb045689d9aa740a66d79fc426a0f66740387');
  });

  it('Coffee writer schema and public result keys are unchanged', () => {
    const schema = COFFEE_WRITER_SCHEMA as { required?: string[] };
    expect([...(schema.required ?? [])].sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'takeaway', 'visualObservation'].sort(),
    );
    expect(Object.keys(toPublicCoffee(load('coffee_good').narrative)).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
  });
});
