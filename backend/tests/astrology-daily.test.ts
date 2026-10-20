/**
 * Daily astrology writer contract / prompt / result.
 * REAL PROVIDER CALLS = 0 (scripted fake fetch).
 */
import { describe, expect, it } from 'vitest';
import { ProxyError } from '../src/errors.js';
import { authHeader, testApp, testConfig } from './helpers.js';
import {
  validateAstrologyDailyPayload,
  type AstrologyWireSky,
} from '../src/ai/astrology-daily-contract.js';
import {
  astrologyDailyMessages,
  astrologyDailySystemRules,
} from '../src/ai/astrology-daily-prompts.js';
import { parseAstrologyDailyResult } from '../src/ai/astrology-daily-result.js';
import { ASTROLOGY_DAILY_SCHEMA_NAME } from '../src/ai/astrology-daily-limits.js';
import { ritualKindOf, RITUAL_DAILY_LIMIT } from '../src/reading/ritual-daily-quota.js';

const NOW = new Date('2026-10-20T10:00:00Z');
const TRANSITS = ['moon', 'sun', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];

function natal(full: boolean) {
  const base = [
    { point: 'sun', sign: 'aries' },
    { point: 'moon', sign: 'taurus' },
    { point: 'mercury', sign: 'pisces' },
    { point: 'venus', sign: 'pisces' },
    { point: 'mars', sign: 'pisces' },
    { point: 'jupiter', sign: 'virgo' },
    { point: 'saturn', sign: 'aquarius' },
  ];
  if (!full) return base;
  return [
    ...base,
    { point: 'ascendant', sign: 'leo' },
    { point: 'midheaven', sign: 'taurus' },
  ].map((p, i) => ({ ...p, house: (i % 12) + 1 }));
}

function sky(overrides: Record<string, unknown> = {}, full = true) {
  return {
    day: '2026-10-20',
    depth: full ? 'full' : 'dayOnly',
    natal: natal(full),
    transits: TRANSITS.map((point, i) =>
      full
        ? { point, sign: 'libra', natalHouse: (i % 12) + 1 }
        : { point, sign: 'libra' },
    ),
    findings: [
      {
        lane: 'overall',
        transit: 'mars',
        natal: 'moon',
        aspect: 'square',
        tone: 'friction',
        strength: 'close',
        span: 'week',
      },
      {
        lane: 'money',
        transit: 'venus',
        natal: 'jupiter',
        aspect: 'sextile',
        tone: 'flow',
        strength: 'wide',
        span: 'days',
      },
    ],
    themes: [],
    ...overrides,
  };
}

function payload(s: Record<string, unknown> = sky()) {
  return { mode: 'sky_daily_v1', contractVersion: 1, language: 'tr', sky: s };
}

const validate = (p: Record<string, unknown>) =>
  validateAstrologyDailyPayload(p, NOW);

function result(overrides: Record<string, string> = {}) {
  return {
    contractVersion: 1,
    portrait: 'Dışarıya hızla çıkan, içeride ise sağlam bir zemin arayan birisin.',
    overall:
      'Ayşe, bugün sabrın biraz daha çabuk tükeniyor ve küçük şeyler içini her zamankinden fazla kıpırdatıyor. Bu huzursuzluk bir hafta kadar sürecek bir dönemin parçası.',
    love: 'Yakınlık tarafında sakin bir gün; sevgini gösterme biçimin bugün daha yumuşak ve içten.',
    career: 'İş tarafında belirgin bir dalga yok. Düşüncelerini toparlamak için uygun bir zemin var.',
    money: 'Para tarafında ılımlı bir destek var; bir harcamanın gerçekten sana iyi gelip gelmediği kolay görünüyor.',
    mood: 'Ruh halin gün içinde birkaç kez yön değiştiriyor.',
    drive: 'Enerjin dağınık ama tükenmiş değil.',
    opportunity: 'Bir şeyi sadeleştirmek bugün kolay.',
    caution: 'Tepkiler olduğundan sert çıkabiliyor.',
    reflection: 'Seni bugün en çok ne sabırsızlandırıyor?',
    ...overrides,
  };
}

describe('astrology_daily contract', () => {
  it('accepts full and birth-day-only skies', () => {
    expect(validate(payload()).sky.depth).toBe('full');
    expect(validate(payload(sky({}, false))).sky.depth).toBe('dayOnly');
    const named = validate(payload(sky({ addressName: 'Ayşe' })));
    expect(named.sky.addressName).toBe('Ayşe');
  });

  it('rejects anything outside the calculated contract', () => {
    const cases: Record<string, unknown>[] = [
      { ...payload(), language: 'en' },
      { ...payload(), extra: 1 },
      payload(sky({ birthDate: '1992-04-05' })),
      payload(sky({ day: '2026-10-25' })),
      payload(sky({ day: '2026-02-30' })),
      payload(sky({ addressName: 'user123' })),
      payload(sky({ themes: ['a', 'b', 'c', 'd'] })),
      // A rising sign without a birth time.
      payload({ ...sky({}, false), natal: [...natal(false), { point: 'ascendant', sign: 'leo' }] }),
      // Houses without a birth time.
      payload({ ...sky({}, false), natal: natal(false).map((n) => ({ ...n, house: 1 })) }),
      // Tone that does not match the aspect.
      payload(sky({ findings: [{ lane: 'love', transit: 'venus', natal: 'mars', aspect: 'square', tone: 'flow', strength: 'close', span: 'days' }] })),
      // Two findings for one lane.
      payload(sky({ findings: [
        { lane: 'love', transit: 'venus', natal: 'mars', aspect: 'square', tone: 'friction', strength: 'close', span: 'days' },
        { lane: 'love', transit: 'moon', natal: 'venus', aspect: 'trine', tone: 'flow', strength: 'close', span: 'hours' },
      ] })),
      // A finding on a natal point that is not supplied.
      payload({ ...sky({}, false), findings: [{ lane: 'career', transit: 'sun', natal: 'midheaven', aspect: 'trine', tone: 'flow', strength: 'close', span: 'days' }] }),
      // A degree slipped into a finding.
      payload(sky({ findings: [{ lane: 'love', transit: 'venus', natal: 'mars', aspect: 'square', tone: 'friction', strength: 'close', span: 'days', orb: 1.2 }] })),
    ];
    for (const c of cases) expect(() => validate(c)).toThrow(ProxyError);
  });
});

describe('astrology_daily prompt', () => {
  it('carries the editorial rules and the lane grounds', () => {
    const rules = astrologyDailySystemRules().join('\n');
    for (const rule of ['LANES MUST DIFFER', 'HIDDEN TECHNIQUE', 'NO INVENTED LIFE', 'NO FIXED FUTURE', 'NOT A COACH', 'ADDRESSING']) {
      expect(rules).toContain(rule);
    }
    const v = validate(payload(sky({ addressName: 'Ayşe' })));
    const user = astrologyDailyMessages(v.sky)[1].content as string;
    expect(user).toContain('- overall: moving mars');
    expect(user).toContain('- love: no finding today. Anchor: venus');
    expect(user).toContain('addressName: "Ayşe"');
    const dayOnly = validate(payload(sky({}, false)));
    const plain = astrologyDailyMessages(dayOnly.sky)[1].content as string;
    expect(plain).toContain('no rising sign, MC or houses exist');
    expect(plain).toContain('do not use or invent a name');
  });
});

describe('astrology_daily result', () => {
  const full = validate(payload(sky({ addressName: 'Ayşe' }))).sky as AstrologyWireSky;
  const dayOnly = validate(payload(sky({}, false))).sky as AstrologyWireSky;

  it('accepts a grounded, plain reading', () => {
    const r = parseAstrologyDailyResult(JSON.stringify(result()), full);
    expect(r.overall).toContain('Ayşe');
  });

  it('rejects technique, fixed futures, orders, repeats and invented layers', () => {
    const repeated = 'Bugün sabrın biraz daha çabuk tükeniyor ve küçük şeyler içini kıpırdatıyor.';
    const bads: [AstrologyWireSky, Record<string, string>][] = [
      [full, { love: 'Venüs Mars ile kare açı yapıyor, bu yüzden gergin.' }],
      [full, { money: 'Bugün kesinlikle para gelecek ve borçların kapanacak.' }],
      [full, { career: 'Bugün işte yeni bir şey dene ve kendine izin ver.' }],
      [full, { overall: repeated, love: repeated }],
      [full, { overall: 'Sevgili Ayşe, bugün sakin bir gün seni bekliyor gibi duruyor.' }],
      [full, { reflection: 'Bugün kendine biraz zaman ayır.' }],
      [full, { mood: 'Ayşe Ayşe Ayşe, bugün duygular yoğun.' }],
      [dayOnly, { portrait: 'Yükselen burcun Aslan olduğu için ilk izlenimin güçlü.' }],
      [full, { love: 'Venüs 5. evinde ilerliyor.' }],
      [full, { love: 'Son okumalarında öne çıkan ilişki teması bugün yine burada.' }],
    ];
    for (const [s, o] of bads) {
      expect(() => parseAstrologyDailyResult(JSON.stringify(result(o)), s)).toThrow(ProxyError);
    }
    expect(() => parseAstrologyDailyResult('not json', full)).toThrow(ProxyError);
    expect(() =>
      parseAstrologyDailyResult(JSON.stringify({ ...result(), extra: 'x' }), full),
    ).toThrow(ProxyError);
  });

  it('"ev" as home is allowed without a birth time', () => {
    const r = parseAstrologyDailyResult(
      JSON.stringify(result({ mood: 'Evinde sessiz bir köşe bugün iyi geliyor.' })),
      dayOnly,
    );
    expect(r.mood).toContain('Evinde');
  });
});

describe('astrology_daily quota', () => {
  it('is a separate daily ritual allowance', () => {
    expect(ritualKindOf('astrology_daily')).toBe('astrology');
    expect(RITUAL_DAILY_LIMIT.astrology).toBe(2);
  });
});

describe('astrology_daily end-to-end scripted provider', () => {
  it('sends the frozen schema and returns the checked result (0 real OpenAI)', async () => {
    let seenBody = '';
    let calls = 0;
    const app = await testApp(testConfig(), async (_url, init) => {
      calls += 1;
      seenBody = String(init?.body ?? '');
      return new Response(
        JSON.stringify({ choices: [{ message: { content: JSON.stringify(result()) } }] }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const today = new Date().toISOString().slice(0, 10);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': `astro.${today}.abcdef12` },
      payload: {
        operation: 'astrology_daily',
        payload: payload(sky({ day: today, addressName: 'Ayşe' })),
      },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.overall).toContain('Ayşe');
    expect(seenBody).toContain(ASTROLOGY_DAILY_SCHEMA_NAME);
    expect(calls).toBe(1);
    await app.close();
  });
});
