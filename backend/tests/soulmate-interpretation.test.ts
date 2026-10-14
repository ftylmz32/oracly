import { describe, expect, it } from 'vitest';
import {
  assessSoulmateInterpretation,
  type SoulmateSections,
} from '../src/ai/soulmate-interpretation-gate.js';
import { authHeader, openaiText, testApp, testConfig } from './helpers.js';
import { soulmateInterpretationMessages } from '../src/ai/soulmate-interpretation.js';

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

function syntheticNaturalDraft(seed: number): SoulmateSections {
  const draft = good();
  draft.personality = seed === 1
    ? 'Deniz once dinler, sonra dusunur, ardindan acikca konusur. Karsisindakini acele ettirmez, sessizligi mesafe saymaz, yer acan dogal bir ritim yaratir.'
    : 'Deniz yeni bir ortamda once gozlemler, ayrintilari fark eder, sorular sorar. Sonra kendi fikrini sakince paylasir, karsisindakini dinler, yakinligi zorlamadan kurar.';
  draft.dynamic = seed === 1
    ? 'Iliski once temkinli ilerler, sonra merakla derinlesir, farkliliklari gorur. Belirsizligi uzatmaz, kararlari konusur, ortak bir yol arar.'
    : 'Iki kisi bazen geri cekilir, yeniden yaklasir, birbirini dinler. Zor konulari ertelemez, farkliliklari saklamaz, temasi zamanla buyutur.';
  return draft;
}

const syntheticRepeatedToneDrafts = Array.from({ length: 3 }, () => ({
  ...good(),
  dynamic: 'Sakin bir tempo, guven ve denge icinde ilerleyebilir.',
  attraction: 'Dingin tavri huzur ve guven duygusunu destekleyebilir.',
  challenge: 'Denge bozuldugunda sakin kalmak ve guveni korumak zor olabilir.',
}));

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

  it('does not mistake natural comma use across sentences for adjective lists', () => {
    const natural = good();
    natural.personality =
      'Deniz, sakin ve güven veren bir yaklaşım gösterir. Yakınlık kurarken düşünceli davranır, acele etmez. Bir konu zorlaştığında önce dinler, sonra kendi görüşünü açıkça söyler. Sessizliği, karşısındakine yer açan doğal bir ritim yaratabilir.';
    natural.dynamic =
      'İlişki önce temkinli ilerler, sonra karşılıklı merakla derinleşir. Biri geri çekildiğinde diğeri alan tanır, fakat belirsizliği uzatmaz. Kararlar konuşularak alınır, farklılıklar saklanmaz. Böylece yakınlık, yalnız huzura değil gerçek temasa dayanabilir.';
    expect(assessSoulmateInterpretation(natural, { name: 'Deniz' })).toBeNull();
  });

  it('still rejects actual comma-heavy adjective dumps in multiple sections', () => {
    const listed = good();
    listed.personality = 'Sakin, dengeli, nazik, güvenilir, düşünceli ve ölçülü bir karakter.';
    listed.dynamic = 'Uyumlu, huzurlu, güvenli, dengeli, sıcak ve sakin bir ilişki.';
    expect(assessSoulmateInterpretation(listed, { name: 'Deniz' })).toBe('adjective_list');
  });

  it('accepts synthetic regression drafts after removing the paragraph-wide comma false positive', () => {
    const fixtures = [syntheticNaturalDraft(1), syntheticNaturalDraft(2)];
    const legacyFalsePositive = (value: string) =>
      (value.match(/,/g) ?? []).length >= 3 &&
      !/\b(olabilir|hissed|durabilir|might|feel)\b/.test(value.toLowerCase());
    for (const draft of fixtures) {
      expect(Object.values(draft).filter(legacyFalsePositive).length).toBeGreaterThanOrEqual(2);
      expect(assessSoulmateInterpretation(draft, {
        name: 'Deniz', presence: 'masculine-presenting adult', mood: 'calm and attentive',
      })).toBeNull();
    }
  });

  it('turns adjective_list into an actionable one-shot repair instruction', () => {
    const messages = soulmateInterpretationMessages({
      name: 'Deniz', birthDate: '1994-03-12', language: 'tr',
      intention: 'Sakin, karşılıklı güvene dayanan bir bağ',
    }, 'adjective_list');
    const system = String(messages[0]?.content);
    expect(system).toContain('comma-heavy trait lists');
    expect(system).toContain('distinct relational insight');
    expect(system).toContain('do not recycle the same calm/trust/balance');
  });

  it('moves beyond a monotone profile into six distinct romantic beats', () => {
    const messages = soulmateInterpretationMessages({
      name: 'Deniz', birthDate: '1994-03-12', language: 'tr',
      intention: 'Sakin, karşılıklı güvene dayanan bir bağ',
      identity: {
        version: 1, nonce: 'qa-safe-001', presence: 'masculine-presenting adult',
        mood: 'calm and attentive', expression: 'gentle', wardrobe: 'simple neutral clothing',
        ageBand: 'adult', faceShape: 'oval', hairFamily: 'dark short hair',
        eyePresentation: 'steady gaze', relationshipArchetype: 'steady companion',
        expressionEnergy: 'calm', stylingEnergy: 'understated',
      },
    });
    const system = String(messages[0]?.content);
    const user = String(messages[1]?.content);
    expect(system).toContain('opening note for personality');
    expect(system).toContain('not the subject of the remaining sections');
    expect(system).toContain('move like a romantic story through interaction');
    expect(system).toContain('an evocative symbolic encounter');
    expect(system).toContain('instead of redescribing the character');
    expect(system).toContain('without inventing a place or date');
    expect(system).toContain('Never claim certainty, an exact date, or a guaranteed meeting');
    expect(user).toContain('relationalTone=steady companion');
    expect(user).not.toContain('expressionEnergy=');
    expect(user).not.toContain('stylingEnergy=');
  });

  it('keeps three synthetic regression drafts as evidence of the repeated-tone defect', () => {
    expect(syntheticRepeatedToneDrafts).toHaveLength(3);
    for (const draft of syntheticRepeatedToneDrafts) {
      const nonPersonality = [draft.dynamic, draft.attraction, draft.challenge, draft.meeting, draft.feeling]
        .join(' ').toLocaleLowerCase('tr-TR');
      const repeatedToneHits = ['sakin', 'huzur', 'güven', 'dingin', 'denge']
        .filter((word) => nonPersonality.includes(word));
      expect(repeatedToneHits.length).toBeGreaterThanOrEqual(3);
    }
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
