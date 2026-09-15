import { describe, expect, it } from 'vitest';
import {
  assessSoulmateInterpretation,
  type SoulmateSections,
} from '../src/ai/soulmate-interpretation-gate.js';
import { authHeader, openaiText, testApp, testConfig } from './helpers.js';

const line =
  'Mart isiginda duran biri gibi, once ice donuk bir duruluk one cikabilir. Yaninda kolay konusulan ama hemen acilmayan bir sakinlik olabilir.';

function good(): SoulmateSections {
  return {
    personality: line,
    dynamic:
      'Bu dinamikte tempo yavas kurulabilir. Yakinlik, acele ettirilmeden, kucuk duruslardan buyuyebilir ve bir yerde durabilir.',
    attraction:
      'Seni ceken taraf gosteris degil, dikkatini dagilmadan verebilmesi olabilir. Niyetindeki sakin bag, bu portredeki olculu sicaklikla ortusebilir.',
    challenge:
      'Surtunme, cok konusmamaktan da gelebilir. Birinin ice cekildigi anda digerinin bunu ilgisizlik sanmasi olasi ve olgunluk ister.',
    meeting:
      'Karsilasma, kalabalik bir sahneden cok, sessiz bir aralikta kisa bir bakis gibi hissedilebilir. Sonra ayni yerde durabilmek yeterli olabilir.',
    feeling:
      'Genel his, acele etmeyen bir yakinlik. Kesin bir vaat degil; sana guven veren ama hemen cozulmeyen bir eslik olabilir.',
  };
}

describe('soulmate interpretation gate', () => {
  it('accepts a careful reading', () => {
    expect(assessSoulmateInterpretation(good(), { name: 'Ayse' })).toBeNull();
  });

  it('rejects generic cliche', () => {
    const bad = good();
    bad.attraction = `${bad.attraction} Ruh esin seni bekliyor.`;
    expect(assessSoulmateInterpretation(bad)).toBe('generic_cliche');
  });

  it('rejects deterministic prediction', () => {
    const bad = good();
    bad.meeting = 'Seni su tarihte 12/03 kesin olarak karsilasacaksin ve orada durabilirsin.';
    expect(assessSoulmateInterpretation(bad)).toBe('deterministic');
  });

  it('rejects fake memory', () => {
    const bad = good();
    bad.dynamic = 'Eski sevgilin gibi daha once seninle yasadigin bir yakinligi hatirliyorum ve bu dinamikte durabilir.';
    expect(assessSoulmateInterpretation(bad)).toBe('fake_memory');
  });

  it('rejects presentation contradiction', () => {
    const bad = good();
    bad.personality = `${bad.personality} Bu portre feminine-presenting bir durus tasiyabilir.`;
    expect(
      assessSoulmateInterpretation(bad, {
        presence: 'masculine-presenting adult',
      }),
    ).toBe('contradiction');
  });
});

describe('soulmate_interpretation route', () => {
  it('uses chat completions and never image generation', async () => {
    const seen: string[] = [];
    const payload = {
      personality: good().personality,
      dynamic: good().dynamic,
      attraction: good().attraction,
      challenge: good().challenge,
      meeting: good().meeting,
      feeling: good().feeling,
    };
    const fetchImpl: typeof fetch = async (url) => {
      seen.push(String(url));
      if (String(url).includes('/images/')) {
        throw new Error('image generation must not run');
      }
      return openaiText(JSON.stringify(payload))(url, undefined);
    };
    const app = await testApp(testConfig(), fetchImpl);
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: {
        operation: 'soulmate_interpretation',
        payload: { name: 'Ayse', birthDate: '1994-03-12', language: 'tr' },
      },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.operation).toBe('soulmate_interpretation');
    expect(res.json().data.personality).toContain('duruluk');
    expect(seen.every((url) => url.includes('/chat/completions'))).toBe(true);
    expect(seen.some((url) => url.includes('/images/'))).toBe(false);
    await app.close();
  });
});
