/**
 * PHASE C1.5 — gate alignment, natural falcı form, dots affordance.
 *
 * coffee_qa_c14_case* are the six exact real C1.4 outputs (gpt-5.6-sol,
 * same evidence as C1.2) with the human product judgement recorded in
 * `productJudgement`. The deterministic gate must agree with it on 6/6.
 */

import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  coffeeRegisterFailure,
  coffeeRegisterProfile,
  coffeeVoiceFailure,
  evaluateCoffeeQuality,
} from '../src/ai/human-quality.js';
import {
  bindCoffeeNarrative,
  coffeeQualityFailure,
  toPublicCoffee,
} from '../src/ai/reading/evidence-bind.js';
import {
  coffeeCommunicationAffordance,
  coffeeEvidenceCluster,
  coffeeEvidenceConcentration,
} from '../src/ai/reading/coffee-diversity.js';
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
const words = (s: string) => s.split(/\s+/).filter(Boolean).length;
const sha = (s: string) => createHash('sha256').update(s).digest('hex');

const ev = (id: string, region: string, description: string, resemblance: string | null = null) =>
  ({ id, region, description, confidence: 'medium', visibility: 'clear', resemblance }) as ReadingEvidenceItem;

const C14 = ['case1', 'case2', 'case3', 'case4', 'case5', 'case6'].map((c) => ({
  name: `coffee_qa_c14_${c}`,
  f: load(`coffee_qa_c14_${c}`),
}));

/**
 * Story-first closure (2026-10-02): the product standard now forbids
 * interpretation menus ("mesajı ya da duyumu", "bir bağa ya da … bir
 * anlaşmaya", "ödeme, ek kazanç ya da … para"). These C1.4 PASS readings
 * each carry one, so that judgement is superseded: they must now be
 * rejected as possibility_menu (never for an unrelated reason).
 */
const SUPERSEDED_BY_MENU = new Set(['coffee_qa_c14_case2', 'coffee_qa_c14_case3', 'coffee_qa_c14_case4', 'coffee_qa_c14_case6']);

describe('C1.5 H — gate agrees with the real C1.4 product judgement (6/6)', () => {
  it('the six real outputs carry their judgement and request ids', () => {
    expect(C14.map(({ f }) => f.productJudgement)).toEqual(['WEAK', 'PASS', 'PASS', 'PASS', 'WEAK', 'PASS']);
    for (const { f } of C14) expect(f.requestId).toMatch(/^req_/);
  });

  for (const { name, f } of C14) {
    it(`${name}: product ${f.productJudgement} ⇔ gate ${f.productJudgement === 'PASS' ? 'binds' : 'rejects'}`, () => {
      if (SUPERSEDED_BY_MENU.has(name)) {
        expect(quality(f)).toBe('possibility_menu');
        expect(bind(f)).toBe('human_quality');
      } else if (f.productJudgement === 'PASS') {
        expect(bind(f)).toBeNull();
      } else {
        expect(quality(f)).toBe('analyst_voice');
        expect(bind(f)).toBe('human_quality');
      }
    });
  }
});

describe('C1.5 A — no aggregate word quota', () => {
  it('the real BIRD reading (62 interpretation words) now PASSES without padding', () => {
    const bird = load('coffee_qa_c14_case2');
    expect(words(interpretation(bird.narrative).join(' '))).toBe(62);
    // No length failure. (Story-first closure: its "mesajı ya da duyumu"
    // is now an interpretation menu — the only remaining rejection.)
    expect(quality(bird)).toBe('possibility_menu');
  });

  it('trivially thin sections still fail', () => {
    const bird = load('coffee_qa_c14_case2');
    const oneLineOverall: CoffeeNarrative = {
      ...bird.narrative,
      overall: { text: 'Bu fincanın başrolünde haber var; kuş ağız kenarına yakın, haber yakında.', evidenceIds: ['e1'] },
    };
    expect(quality({ ...bird, narrative: oneLineOverall })).toBe('too_short');
    const stubTakeaway: CoffeeNarrative = {
      ...bird.narrative,
      takeaway: { text: 'Haber gelecek.', evidenceIds: ['e2'] },
    };
    expect(quality({ ...bird, narrative: stubTakeaway })).toBe('too_short');
  });
});

describe('C1.5 B — evidence clustering uses region tokens, not substrings', () => {
  it('"cluster" in a description is not "ust" (upper)', () => {
    expect(coffeeEvidenceCluster(ev('e1', 'base', 'A small dense cluster at the base.'))).toBe('base');
    expect(coffeeEvidenceCluster(ev('e1', 'unknown', 'A small dense cluster of grounds.'))).toBe('unknown');
  });

  it('a base item mentioning the rim stays base', () => {
    expect(coffeeEvidenceCluster(ev('e1', 'base', 'Grounds at the base reaching toward the rim.'))).toBe('base');
  });

  it('a lower/body item mentioning the rim stays body', () => {
    expect(coffeeEvidenceCluster(ev('e1', 'lower_wall', 'Marks rising toward the rim.'))).toBe('body');
    expect(coffeeEvidenceCluster(ev('e1', 'middle_wall', 'A line winding from the lower wall up toward the rim.'))).toBe('body');
  });

  it('description is only a fallback, and its earliest region word wins', () => {
    expect(coffeeEvidenceCluster(ev('e1', 'area', 'A line from the lower wall up toward the rim.'))).toBe('body');
    expect(coffeeEvidenceCluster(ev('e1', 'handle_side', 'Grounds near the handle.'))).toBe('handle');
    expect(coffeeEvidenceCluster(ev('e1', 'upper_wall', 'Sparse marks.'))).toBe('upper');
  });

  it('the real ROAD evidence yields distinct clusters and the reading no longer collapses', () => {
    const road = load('coffee_qa_c14_case4');
    expect(road.observation.evidence.map(coffeeEvidenceCluster)).toEqual(['body', 'base', 'upper']);
    expect(coffeeEvidenceConcentration(road.narrative, road.observation.evidence)).toBe(false);
    // No collapse. (Story-first closure: its list of route alternatives is
    // now an interpretation menu — the only remaining rejection.)
    expect(quality(road)).toBe('possibility_menu');
  });

  it('genuine single-cluster concentration is still caught', () => {
    const thin = [ev('e1', 'base', 'Dense base.'), ev('e2', 'bottom', 'More grounds at the bottom.'), ev('e3', 'base', 'Ring of grounds at the base.')];
    const n = load('coffee_qa_c14_case4').narrative;
    const relabeled: CoffeeNarrative = {
      ...n,
      overall: { ...n.overall, evidenceIds: ['e1'] },
      nearFuture: { ...n.nearFuture, evidenceIds: ['e2'] },
      takeaway: { ...n.takeaway, evidenceIds: ['e3'] },
    };
    expect(coffeeEvidenceConcentration(relabeled, thin)).toBe(true);
  });
});

describe('C1.5 C — dots/specks are not communication by themselves', () => {
  it('dots only: no communication affordance', () => {
    expect(coffeeCommunicationAffordance([
      ev('e1', 'upper_wall', 'A few sparse dots on the upper inner surface.'),
      ev('e2', 'middle_wall', 'Scattered specks and speckles.'),
    ])).toBe(false);
  });

  it('bird + dots: affordance comes from the bird, not the dots', () => {
    const bird = load('coffee_qa_c14_case2').observation.evidence;
    expect(coffeeCommunicationAffordance(bird)).toBe(true);
    expect(coffeeCommunicationAffordance(bird.filter((e) => !/bird/.test(e.resemblance ?? '')))).toBe(false);
  });

  it('ring + dots: the ring cup does not gain communication from its dots', () => {
    expect(coffeeCommunicationAffordance(load('coffee_qa_c14_case3').observation.evidence)).toBe(false);
  });
});

describe('C1.5 D/E/F/G — natural delivery', () => {
  it('prompt: start reading, never announce the lane; contrasts sparingly; speak directly', () => {
    const p = coffeeWriterSystem('tr');
    expect(p).toContain('START READING from that sign at once');
    expect(p).toContain('DO NOT ANNOUNCE THE LANE');
    expect(p).toContain('main word');
    expect(p).toContain('CONTRAST SPARINGLY');
    expect(p).toContain('SPEAK DIRECTLY');
    expect(p).not.toContain("open overall from that sign\\'s identity");
  });

  it('a meta-opener alone does not fail a good reading', () => {
    const bird = load('coffee_qa_c14_case2');
    const r = coffeeRegisterProfile(interpretation(bird.narrative));
    expect(r.metaOpener).toBe(true);
    expect(coffeeRegisterFailure(interpretation(bird.narrative))).toBeNull();
  });

  it('one natural contrast and ordinary "düzen"/"durum" do not fail', () => {
    expect(
      coffeeRegisterFailure([
        'Telve kulba doğru toplanmış; evinin düzeni şu sıralar hareketli. Uzaktan çok yakından gelen bir şey var.',
        'Durum seni yormuyor, sadece meşgul ediyor.',
      ]),
    ).toBeNull();
  });

  it('"not X but Y" scaffolding fails as formulaic_voice', () => {
    expect(
      coffeeRegisterFailure([
        'Kuş haberden çok bir duyum getiriyor. Telve ağırlıktan ziyade bir bekleyiş anlatıyor.',
        'Yol uzaktan çok yakına gidiyor; acele yerine sabır var.',
        'Bu, bitişten çok bir başlangıç; bir kapanış değil, bir açılış.',
      ]),
    ).toBe('formulaic_voice');
  });

  it('hedge verbs carrying nearly every sentence fail as formulaic_voice', () => {
    expect(
      coffeeRegisterFailure([
        'Kuş bir haberi gösteriyor. Ağız kenarı yakınlığı düşündürüyor. Dipteki telve bir ağırlığa işaret ediyor.',
        'Noktalar ayrıntıları gösteriyor. Kulp evi düşündürüyor. Yol bir yolculuğa işaret ediyor.',
      ]),
    ).toBe('formulaic_voice');
  });

  it('analyst register is caught as an accumulation (C1.4 SPARSE & HANDLE)', () => {
    for (const c of ['case1', 'case5']) {
      const r = coffeeRegisterProfile(interpretation(load(`coffee_qa_c14_${c}`).narrative));
      expect(r.analystKinds, c).toBeGreaterThanOrEqual(6);
      expect(r.score, c).toBeGreaterThanOrEqual(6);
    }
  });

  it('repair focus for the new codes keeps meaning and does not lengthen', () => {
    for (const code of ['analyst_voice', 'formulaic_voice']) {
      const focus = coffeeVoiceRepairFocus(code) ?? '';
      expect(focus).toContain('Do not add events and do not lengthen it');
    }
  });
});

describe('C1.5 I — earlier protections preserved', () => {
  it('report, coaching, wrapper, pre-C1 and live fixtures still FAIL', () => {
    for (const name of [
      'coffee_bad_observation_heavy',
      'coffee_bad_former_good',
      'coffee_bad_former_good_3a5',
      'coffee_bad_generic_cliche',
      'coffee_bad_repetitive',
      'coffee_live_3a4',
      'coffee_qa_c12_case1',
      'coffee_qa_c12_case2',
      'coffee_qa_c12_case4',
      'coffee_qa_c12_case5',
    ]) {
      expect(bind(load(name)), name).not.toBeNull();
    }
    expect(
      coffeeVoiceFailure([
        'Bir süredir zihninde ağırlık yapan bir şey var gibi. Kendi sınırını koruyarak ilerlemen, ritmini kaybetmemen önemli.',
        'Önceliklerini netleştirdikçe gerilim azalacak.',
      ]),
    ).toBe('coaching_voice');
  });

  it('event pile, fake memory, certainty and schema jargon still FAIL', () => {
    const base = load('coffee_good_sparse');
    expect(
      coffeeVoiceFailure(
        ['Yakında kapını bir misafir çalacak, eline para geçecek.', 'Bir iş teklifi var, sevgilinle aranız ısınacak.'],
        0,
        false,
      ),
    ).toBe('event_pile');
    const input = (extra: string) => ({
      visualObservation: base.narrative.visualObservation.text,
      overall: `${base.narrative.overall.text} ${extra}`,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: base.narrative.takeaway.text,
      language: 'tr' as const,
    });
    expect(evaluateCoffeeQuality(input('Geçen seferinde de böyle bir fincan çıkmıştı.'))).toBe('fake_memory');
    expect(evaluateCoffeeQuality(input('Bu fincan ölüm tarihi gibi şeyler söylemez ama kesin olacak.'))).toBe('unsupported_certainty');
    expect(evaluateCoffeeQuality(input('Bu evidenceId ile bağlantılı.'))).toBe('schema_jargon_leak');
  });

  it('sparse grounded, concise, neutral/mixed/open GOOD fixtures still PASS', () => {
    for (const name of ['coffee_good', 'coffee_good_3a3', 'coffee_good_3a5', 'coffee_diverse_3a4', 'coffee_good_sparse', 'coffee_good_two_sign']) {
      expect(bind(load(name)), name).toBeNull();
    }
  });

  it('Palm prompts byte-identical to Build 9; public Coffee contract unchanged', () => {
    expect(sha(palmWriterSystem('tr'))).toBe('6baea20276276349ed9434ea6691a3edec1ec3b904fc2e85d1119a8b49d8e951');
    expect(sha(repairWriterSystem('palm'))).toBe('0f3f764b3f78ae2988b09c76a67bb045689d9aa740a66d79fc426a0f66740387');
    const schema = COFFEE_WRITER_SCHEMA as { required?: string[] };
    expect([...(schema.required ?? [])].sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'takeaway', 'visualObservation'].sort(),
    );
    expect(Object.keys(toPublicCoffee(load('coffee_qa_c14_case2').narrative)).sort()).toEqual(
      ['career', 'love', 'money', 'nearFuture', 'overall', 'symbols', 'takeaway', 'visualObservation'].sort(),
    );
  });
});
