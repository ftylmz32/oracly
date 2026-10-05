/**
 * PHASE C1.1 — grounded concreteness, no forced invention.
 *
 * C1 fixed the report/therapist voice but made "concrete life content" a
 * quota (lifeKinds < 2 failed; coaching could be escaped by adding events).
 * That pushes the writer to invent visitors, money and job offers on a
 * sparse cup. These tests pin the corrected contract: the gate judges
 * STYLE only, a sparse grounded reading passes, and stacking unrelated
 * events on generic residue is what fails.
 */

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeVoiceFailure,
  coffeeVoiceProfile,
  evaluateCoffeeQuality,
  evaluatePalmQuality,
} from '../src/ai/human-quality.js';
import {
  bindCoffeeNarrative,
  bindPalmNarrative,
  coffeeQualityFailure,
  toPublicCoffee,
} from '../src/ai/reading/evidence-bind.js';
import { COFFEE_WRITER_SCHEMA } from '../src/ai/reading/schemas.js';
import {
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  PalmNarrative,
  PalmObservation,
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

const E = { text: '', evidenceIds: [] as string[] };

function interpretation(n: CoffeeNarrative): string[] {
  return [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
}

const sha = (s: string) => createHash('sha256').update(s).digest('hex');

const sparse = load('coffee_good_sparse');
const bird = load('coffee_good');

describe('C1.1 — no concreteness quota', () => {
  it('a sparse cup (no resemblance at all) passes with a short, quiet, grounded reading', () => {
    expect(sparse.observation.evidence.every((e) => !e.resemblance)).toBe(true);
    const p = coffeeVoiceProfile(interpretation(sparse.narrative));
    expect(p.lifeKinds).toBeLessThan(2); // the old C1 hard rule would have failed this
    expect(p.eventDomains).toBe(0);
    expect(sparse.narrative.nearFuture.text).toBe('');
    expect(bindCoffeeNarrative(sparse.narrative, sparse.observation, 'tr')).toBeNull();
  });

  it('ONE grounded concrete development is enough to pass', () => {
    const one: CoffeeNarrative = {
      visualObservation: bird.narrative.visualObservation,
      overall: {
        text: 'Ağzın yanında kanat açmış küçük bir kuş var. Kuş haber diye okunur derler; ağza bu kadar yakın durduğuna göre sana gelecek bir haber pek uzakta değil gibi. Fincanın dibi de açık kalmış, yani o haber canını sıkacak türden değil; aksine bir süredir kafanı kurcalayan şeyi rahatlatacak gibi.',
        evidenceIds: ['e2', 'e3'],
      },
      love: E,
      career: E,
      money: E,
      nearFuture: E,
      takeaway: {
        text: 'Telvenin kulba doğru toplanması da bu haberin evine, yakınlarına dokunduğunu söylüyor. Bu fincanın bütün sözü o kuşta; geri kalanı sakin, seni yoracak bir şey görünmüyor. Fazlası yok bu fincanda, ama olanı güzel.',
        evidenceIds: ['e1'],
      },
    };
    expect(coffeeVoiceProfile(interpretation(one)).eventDomains).toBe(1);
    expect(bindCoffeeNarrative(one, bird.observation, 'tr')).toBeNull();
  });

  it('removing the life-event words from a grounded reading does not make it fail', () => {
    // Same sparse reading; the gate has nothing to "count up to".
    expect(coffeeVoiceFailure(interpretation(sparse.narrative), 0)).toBeNull();
    expect(coffeeVoiceFailure([sparse.narrative.overall.text], 0)).toBeNull();
  });
});

describe('C1.1 — bad styles still fail', () => {
  const therapy = [
    'Bir süredir zihninde ağırlık yapan bir mesele var gibi. Kendi sınırını koruyarak ilerlemen, ritmini kaybetmemen bu dönemde önemli.',
    'Önceliklerini netleştirdikçe içindeki gerilim azalacak; geride bırakman gerekenleri fark etmek sana iyi gelecek.',
  ];

  it('pure therapy/coaching prose FAILS', () => {
    expect(coffeeVoiceFailure(therapy)).toBe('coaching_voice');
  });

  it('coaching prose cannot escape by adding predicted events', () => {
    const padded = [
      ...therapy,
      'Yakında bir misafir gelecek, bir haber alacaksın, eline para geçecek ve sevgilinle aran düzelecek gibi.',
    ];
    expect(coffeeVoiceProfile(padded).lifeKinds).toBeGreaterThan(coffeeVoiceProfile(therapy).lifeKinds);
    expect(coffeeVoiceFailure(padded)).toBe('coaching_voice');
  });

  it('floating abstraction with neither the cup nor the person\'s life FAILS', () => {
    expect(
      coffeeVoiceFailure([
        'Şu sıralar içinde bir şeylerin yerine oturmaya başladığını hissediyorsun gibi. Olanı olduğu gibi kabul etmenin zamanı olabilir.',
        'Her şey zamanla yerini bulur gibi; acele etmeye gerek yok.',
      ]),
    ).toBe('abstract_reading');
  });

  it('vision-report prose FAILS', () => {
    const f = load('coffee_bad_observation_heavy');
    expect(coffeeQualityFailure(f.narrative, 'tr', undefined, f.observation.evidence)).toBe('observation_heavy');
    expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr')).toBe('human_quality');
  });

  it('pre-C1 approved fixtures and live outputs still FAIL', () => {
    for (const name of [
      'coffee_bad_former_good',
      'coffee_bad_former_good_3a3',
      'coffee_bad_former_good_3a5',
      'coffee_bad_former_diverse_3a4',
      'coffee_live_3a4',
      'coffee_bad_generic_cliche',
      'coffee_bad_repetitive',
    ]) {
      const f = load(name);
      expect(bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization), name).not.toBeNull();
    }
  });
});

describe('C1.1 — stacking unrelated events on generic residue is rejected', () => {
  const pile: CoffeeNarrative = {
    visualObservation: sparse.narrative.visualObservation,
    overall: {
      text: 'Fincanın dibi dolu; yakında kapını bir misafir çalacak gibi. Aynı günlerde eline beklemediğin bir para geçebilir, üstüne bir de iş teklifi gelecek gibi görünüyor. Bu fincan çok hareketli, her yandan bir şey geliyor; sen daha birini toparlamadan öbürü kapıda olacak, o kadar kalabalık bir ay seni bekliyor.',
      evidenceIds: ['e1'],
    },
    love: E,
    career: E,
    money: E,
    nearFuture: E,
    takeaway: {
      text: 'Gönül tarafında da bir kıpırtı var; sevgilinle aranız ısınacak gibi. Fincanın ağzı temiz, yani bunların hepsi peş peşe ve kolayca gelecek gibi duruyor.',
      evidenceIds: ['e2', 'e3'],
    },
  };

  it('visitor + money + job + romance from resemblance-free residue is event_pile', () => {
    expect(coffeeVoiceProfile(interpretation(pile)).eventDomains).toBeGreaterThanOrEqual(4);
    expect(coffeeQualityFailure(pile, 'tr', undefined, sparse.observation.evidence)).toBe('event_pile');
    expect(bindCoffeeNarrative(pile, sparse.observation, 'tr')).toBe('human_quality');
  });

  it('the cap grows only with resemblance-bearing signs, and is never a minimum', () => {
    const domains = coffeeVoiceProfile(interpretation(pile)).eventDomains;
    expect(coffeeVoiceFailure(interpretation(pile), domains - 2)).toBeNull();
    expect(coffeeVoiceFailure(interpretation(pile), 0)).toBe('event_pile');
  });

  it('repair for event_pile asks to drop events, not add them', () => {
    const focus = coffeeVoiceRepairFocus('event_pile') ?? '';
    expect(focus).toContain('drop the rest');
    expect(focus).toContain('leave optional sections empty');
    for (const code of ['coaching_voice', 'abstract_reading', 'event_pile']) {
      expect(coffeeVoiceRepairFocus(code)).not.toMatch(/a person, news, a visit, a plan, money/);
    }
    expect(repairWriterSystem('coffee')).toContain('Never repair by adding invented events');
  });
});

describe('C1.1 — writer prompt prefers one grounded story', () => {
  const p = coffeeWriterSystem('tr');

  it('no longer requires a concrete development in every section', () => {
    expect(p).not.toContain('Every filled section must land on at least one');
    expect(p).toContain('GROUNDED, NOT INVENTED');
    expect(p).toContain('one development is enough');
    expect(p).toContain('SPARSE CUP');
  });

  it('keeps the falcı voice and the report/coaching bans', () => {
    expect(p).toContain('Turkish coffee fortune teller');
    expect(p).toContain('TRANSFORM, DO NOT REPORT');
    expect(p).toContain('NOT A THERAPIST, COACH OR MINDFULNESS APP');
  });
});

describe('C1.1 — Palm parity and public contract', () => {
  it('Palm prompts match the Wave 4.3 release candidate byte-for-byte', () => {
    expect(sha(palmWriterSystem('tr'))).toBe('936ce247f105af55fe5719bfef944fc03af0d96303150cb13985a653288c1a6a');
    expect(sha(repairWriterSystem('palm'))).toBe('0f3f764b3f78ae2988b09c76a67bb045689d9aa740a66d79fc426a0f66740387');
  });

  it('Palm fixtures keep their verdicts', () => {
    const good = JSON.parse(readFileSync('./tests/fixtures/batch3a/palm_good.json', 'utf8')) as {
      observation: PalmObservation;
      narrative: PalmNarrative;
    };
    expect(bindPalmNarrative(good.narrative, good.observation, 'tr')).toBe('section_redundancy');
    const bad = JSON.parse(readFileSync('./tests/fixtures/batch3a/palm_bad_generic_cliche.json', 'utf8')) as {
      narrative: PalmNarrative;
    };
    expect(
      evaluatePalmQuality({
        visualObservation: bad.narrative.visualObservation.text,
        overall: bad.narrative.overall.text,
        lifeLine: bad.narrative.lifeLine.text,
        headLine: bad.narrative.headLine.text,
        heartLine: bad.narrative.heartLine.text,
        fateLine: bad.narrative.fateLine.text,
        takeaway: bad.narrative.takeaway.text,
        language: 'tr',
      }),
    ).not.toBeNull();
  });

  it('Coffee schema, public keys and bind failure codes are unchanged', () => {
    const schema = COFFEE_WRITER_SCHEMA as { required?: string[] };
    expect([...(schema.required ?? [])].sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'takeaway', 'visualObservation'].sort(),
    );
    expect(Object.keys(toPublicCoffee(sparse.narrative)).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
    // New internal codes never reach the transport as new values.
    expect(evaluateCoffeeQuality({
      visualObservation: sparse.narrative.visualObservation.text,
      overall: sparse.narrative.overall.text,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: sparse.narrative.takeaway.text,
      language: 'tr',
    })).toBeNull();
  });
});
