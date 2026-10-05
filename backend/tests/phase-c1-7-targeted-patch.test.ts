/**
 * PHASE C1.7 — targeted patch before closure QA.
 *
 * coffee_qa_c16_case* are the eight exact real C1.6 outputs (six control
 * cases + two holdouts) with the human product judgement recorded in
 * `humanProductJudgement`. Stored prose is never edited to make a test pass.
 */

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeRegisterFailure,
  coffeeRegisterProfile,
  coffeeTakeawayEcho,
  coffeeTakeawayEchoPairs,
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
  coffeeVoiceRepairFocus,
  coffeeWriterSystem,
  palmWriterSystem,
  repairWriterSystem,
} from '../src/ai/reading/writer-prompts.js';
import type {
  CoffeeNarrative,
  CoffeeObservation,
  ReadingEvidenceItem,
  ReadingPersonalization,
} from '../src/ai/reading/types.js';

type Fixture = {
  observation: CoffeeObservation;
  narrative: CoffeeNarrative;
  personalization?: ReadingPersonalization;
  humanProductJudgement?: 'PASS' | 'WEAK';
  productJudgement?: 'PASS' | 'WEAK';
  requestId?: string;
};

function load(name: string): Fixture {
  return JSON.parse(readFileSync(`./tests/fixtures/batch3a/${name}.json`, 'utf8')) as Fixture;
}

const bind = (f: Fixture) => bindCoffeeNarrative(f.narrative, f.observation, 'tr', f.personalization);
const quality = (f: Fixture) => coffeeQualityFailure(f.narrative, 'tr', f.personalization, f.observation.evidence);
const interpretation = (n: CoffeeNarrative) =>
  [n.overall, n.love, n.career, n.money, n.nearFuture, n.takeaway].map((s) => s.text);
const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const ev = (id: string, region: string, description: string, resemblance: string | null = null) =>
  ({ id, region, description, confidence: 'medium', visibility: 'clear', resemblance }) as ReadingEvidenceItem;

const LABELS = ['SPARSE', 'BIRD', 'RING', 'ROAD', 'HANDLE', 'TWO-SIGN', 'KEY', 'GEOMETRIC'];
const C16 = LABELS.map((label, i) => ({ label, f: load(`coffee_qa_c16_case${i + 1}`) }));

/**
 * Story-first closure (2026-10-02): interpretation menus are now a product
 * failure. These C1.6 PASS readings each list alternatives ("mesaj ya da
 * cevap", "yolculuk, taşınma ya da …", "kazancı ya da … fırsatı", "erişim,
 * imkân ya da çözüm"), so they must now be rejected as possibility_menu.
 */
const SUPERSEDED_BY_MENU = new Set(['BIRD', 'ROAD', 'TWO-SIGN', 'KEY']);
const C14_SUPERSEDED = new Set([2, 3, 4, 6]);

describe('C1.7 — gate agrees with the real C1.6 human judgement (8/8)', () => {
  it('fixtures carry the recorded human labels and request ids', () => {
    expect(C16.map(({ f }) => f.humanProductJudgement)).toEqual(['WEAK', 'PASS', 'WEAK', 'PASS', 'WEAK', 'PASS', 'PASS', 'WEAK']);
    for (const { f } of C16) expect(f.requestId).toMatch(/^req_/);
  });

  for (const { label, f } of C16) {
    it(`${label}: human ${f.humanProductJudgement} ⇔ gate ${f.humanProductJudgement === 'PASS' ? 'binds' : 'rejects'}`, () => {
      if (SUPERSEDED_BY_MENU.has(label)) expect(quality(f)).toBe('possibility_menu');
      else if (f.humanProductJudgement === 'PASS') expect(bind(f)).toBeNull();
      else expect(bind(f)).not.toBeNull();
    });
  }

  it('each WEAK is rejected for its own reason', () => {
    expect(quality(C16[0].f)).toBe('caution_voice'); // SPARSE
    expect(quality(C16[2].f)).toBe('generic_wrapper'); // RING: dots -> short messages
    expect(quality(C16[4].f)).toBe('caution_voice'); // HANDLE
    expect(quality(C16[7].f)).toBe('section_redundancy'); // GEOMETRIC: takeaway echo
  });

  it('the earlier C1.4 agreement still holds (6/6)', () => {
    for (let i = 1; i <= 6; i++) {
      const f = load(`coffee_qa_c14_case${i}`);
      if (C14_SUPERSEDED.has(i)) expect(quality(f), `c14 case${i}`).toBe('possibility_menu');
      else if (f.productJudgement === 'PASS') expect(bind(f), `c14 case${i}`).toBeNull();
      else expect(bind(f), `c14 case${i}`).not.toBeNull();
    }
  });
});

describe('C1.7 D1 — dots: prompt and runtime say the same thing', () => {
  it('the writer no longer lists dots as a communication sign', () => {
    const p = coffeeWriterSystem('tr');
    const conversationRule = p.slice(p.indexOf('CONVERSATION ONLY WHEN AFFORDED'), p.indexOf('ENDINGS FOLLOW THE EVIDENCE'));
    expect(conversationRule).toContain('(a bird, figures or faces, letter-like shapes)');
    expect(conversationRule).not.toMatch(/scattered dots\)/);
    expect(conversationRule).toContain('never news, messages or "short messages in a row" by themselves');
  });

  it('RING + dots only: no communication affordance', () => {
    expect(coffeeCommunicationAffordance(load('coffee_qa_c16_case3').observation.evidence)).toBe(false);
  });
});

describe('C1.7 D1B — "mouth of the cup" is a cup part, not a mouth', () => {
  it('a rim description using "mouth of the cup" does not afford communication', () => {
    expect(coffeeCommunicationAffordance([ev('e1', 'rim', 'A thin clean band just below the mouth of the cup.')])).toBe(false);
    expect(coffeeCommunicationAffordance([ev('e1', 'handle_side', 'Grounds gathered near the ear of the cup.')])).toBe(false);
  });

  it('an observed human lips / mouth resemblance still affords communication', () => {
    expect(coffeeCommunicationAffordance([ev('e1', 'middle_wall', 'A curved double shape.', 'may resemble human lips / mouth')])).toBe(true);
  });
});

describe('C1.7 D2 — "başlangıç" the noun is not "yeni başlangıç" filler', () => {
  it('the real C1.6 ROAD reading is not rejected for "başlangıç"', () => {
    const road = C16[3].f;
    expect(road.narrative.overall.text).toContain('Başlangıcının');
    // Not repeated_stock. (Story-first closure: its route list is now an
    // interpretation menu — the only remaining rejection.)
    expect(quality(road)).toBe('possibility_menu');
  });

  it('real "yeni başlangıç" stock prose is still rejected', () => {
    const road = C16[3].f.narrative;
    const spam = (where: 'overall' | 'nearFuture', extra: string) =>
      evaluateCoffeeQuality({
        visualObservation: road.visualObservation.text,
        overall: where === 'overall' ? `${road.overall.text} ${extra}` : road.overall.text,
        love: '',
        career: '',
        money: '',
        nearFuture: where === 'nearFuture' ? `${road.nearFuture.text} ${extra}` : road.nearFuture.text,
        takeaway: road.takeaway.text,
        language: 'tr',
      });
    const filler = 'Yeni başlangıçlar seni bekliyor, yeni başlangıç kapında; yeni başlangıç yapacaksın.';
    expect(spam('nearFuture', filler)).toBe('repeated_stock');
    expect(spam('overall', filler)).not.toBeNull(); // caught even earlier (generic_closing)
    expect(bind(load('coffee_bad_generic_cliche'))).not.toBeNull();
  });
});

describe('C1.7 D3 — caution is not the story', () => {
  it('prompt tells the writer to say what IS in the cup, without forcing optimism', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('DO NOT USE CAUTION AS THE STORY');
    expect(p).toContain('Tell what IS in the cup');
    expect(p).toContain('if the cup is sparse, say less');
    expect(p).toContain('do not swap that for forced optimism');
  });

  it('caution-built SPARSE and HANDLE fail structurally (sentences + sections + close)', () => {
    for (const i of [0, 4]) {
      const r = coffeeRegisterProfile(interpretation(C16[i].f.narrative));
      expect(r.cautionSentences / r.sentences, LABELS[i]).toBeGreaterThanOrEqual(0.6);
      expect(r.cautionSections * 3, LABELS[i]).toBeGreaterThanOrEqual(r.sections * 2);
      expect(r.notYetClose, LABELS[i]).toBe(true);
    }
  });

  it('one natural caution, or a not-yet close alone, does not fail', () => {
    // BIRD, KEY: not-yet closes, but caution does not carry the reading.
    for (const i of [1, 6]) {
      const r = coffeeRegisterProfile(interpretation(C16[i].f.narrative));
      expect(r.notYetClose, LABELS[i]).toBe(true);
      expect(coffeeRegisterFailure(interpretation(C16[i].f.narrative)), LABELS[i]).toBeNull();
    }
    expect(
      coffeeRegisterFailure([
        'Fincanın ağzında kanat açmış bir kuş var; haber yolda. Kim getirecek, o da belli: telve kulba doğru toplanmış, yani evden.',
        'Haberin içinde bir isim var gibi; duyunca tanıyacaksın. Henüz kapıda değil.',
      ]),
    ).toBeNull();
  });

  it('caution_voice repair keeps meaning, does not lengthen or force optimism', () => {
    const focus = coffeeVoiceRepairFocus('caution_voice') ?? '';
    expect(focus).toContain('say what IS in the cup');
    expect(focus).toContain('do not force optimism');
  });
});

describe('C1.7 D4 — takeaway must add a distinct nuance', () => {
  it('the real C1.6 GEOMETRIC takeaway echoes overall and is rejected', () => {
    const g = C16[7].f.narrative;
    expect(coffeeTakeawayEchoPairs(g.overall.text, g.takeaway.text).length).toBeGreaterThanOrEqual(2);
    expect(bind(C16[7].f)).toBe('section_redundancy');
  });

  it('a sparse takeaway on the same evidence with a real new nuance passes', () => {
    const sparse = load('coffee_good_sparse');
    expect(sparse.narrative.takeaway.evidenceIds).toEqual(['e2']);
    expect(coffeeTakeawayEcho(sparse.narrative.overall.text, sparse.narrative.takeaway.text)).toBe(false);
    expect(bind(sparse)).toBeNull();
    // Same evidence id as overall is fine when the nuance is new.
    const sameEvidence: CoffeeNarrative = {
      ...sparse.narrative,
      takeaway: {
        text: 'Dipteki o ağır telve bir gün dağılacak ama kendi isteğinle; seni zorlayan biri görünmüyor fincanda.',
        evidenceIds: ['e1'],
      },
    };
    expect(coffeeTakeawayEcho(sameEvidence.overall.text, sameEvidence.takeaway.text)).toBe(false);
  });

  it('sharing one region phrase is not an echo (TWO-SIGN, ROAD)', () => {
    for (const i of [3, 5]) {
      const n = C16[i].f.narrative;
      expect(coffeeTakeawayEchoPairs(n.overall.text, n.takeaway.text).length, LABELS[i]).toBeLessThanOrEqual(1);
    }
  });
});

describe('C1.7 — no overcorrection', () => {
  it('all GOOD fixtures, concise and sparse readings still pass', () => {
    for (const name of ['coffee_good', 'coffee_good_3a3', 'coffee_good_3a5', 'coffee_diverse_3a4', 'coffee_good_sparse', 'coffee_good_two_sign']) {
      expect(bind(load(name)), name).toBeNull();
    }
  });

  it('report, coaching, wrapper, pre-C1 and live fixtures still fail', () => {
    for (const name of [
      'coffee_bad_observation_heavy',
      'coffee_bad_former_good',
      'coffee_bad_former_good_3a5',
      'coffee_bad_repetitive',
      'coffee_live_3a4',
      'coffee_qa_c12_case2',
      'coffee_qa_c12_case4',
    ]) {
      expect(bind(load(name)), name).not.toBeNull();
    }
  });

  it('Palm prompts byte-identical to Build 9; public Coffee contract unchanged', () => {
    expect(sha(palmWriterSystem('tr'))).toBe('6baea20276276349ed9434ea6691a3edec1ec3b904fc2e85d1119a8b49d8e951');
    expect(sha(repairWriterSystem('palm'))).toBe('0f3f764b3f78ae2988b09c76a67bb045689d9aa740a66d79fc426a0f66740387');
    const schema = COFFEE_WRITER_SCHEMA as { required?: string[] };
    expect([...(schema.required ?? [])].sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'takeaway', 'visualObservation'].sort(),
    );
    expect(Object.keys(toPublicCoffee(C16[1].f.narrative)).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
  });
});
