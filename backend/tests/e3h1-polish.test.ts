import { beforeEach, describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import {
  evaluateCoffeeQuality,
  evaluatePalmQuality,
} from '../src/ai/human-quality.js';
import {
  bindCoffeeNarrative,
  bindPalmNarrative,
} from '../src/ai/reading/evidence-bind.js';
import {
  buildCoffeeWriterPacket,
  coffeeRegionLabel,
  normalizeTrustedHand,
  sanitizeHandednessInItem,
} from '../src/ai/reading/locale-vocab.js';
import { coffeeWriterSystem, palmWriterSystem } from '../src/ai/reading/writer-prompts.js';
import { palmObserverUser } from '../src/ai/reading/observer-prompts.js';
import { readingStageStore } from '../src/ai/reading/stage-cache.js';
import {
  authHeader,
  coffeeBody,
  coffeeObserverJson,
  coffeeWriterJson,
  openaiReadingSequence,
  palmObserverJson,
  palmWriterJson,
  testApp,
  testConfig,
} from './helpers.js';

const coffeeLive = JSON.parse(
  readFileSync('./tests/fixtures/e3h1/e3h_coffee_quality_input.json', 'utf8'),
);
const palmLive = JSON.parse(
  readFileSync('./tests/fixtures/e3h1/e3h_palm_quality_input.json', 'utf8'),
);
const coffeeSections = JSON.parse(
  readFileSync('./tests/fixtures/e3h1/e3h_coffee_live_negative.json', 'utf8'),
);
const palmSections = JSON.parse(
  readFileSync('./tests/fixtures/e3h1/e3h_palm_live_negative.json', 'utf8'),
);

describe('E3H.1 language immersion polish', () => {
  beforeEach(() => readingStageStore.clear());

  it('rejects E3H live coffee for rim leak and generic closing', () => {
    const q = evaluateCoffeeQuality(coffeeLive);
    expect(['locale_leak', 'generic_closing', 'embedded_disclaimer']).toContain(q);
    expect(coffeeLive.takeaway.toLowerCase()).toContain('enerjini');
    expect(coffeeLive.nearFuture.toLowerCase()).toContain('rim');
  });

  it('rejects E3H live palm for disclaimer and inferred handedness', () => {
    const q = evaluatePalmQuality({ ...palmLive, trustedHandSide: false });
    expect(['embedded_disclaimer', 'inferred_handedness', 'generic_closing']).toContain(q);
  });

  it('rejects exact rim leak in Turkish narrative', () => {
    expect(
      evaluateCoffeeQuality({
        visualObservation: coffeeLive.visualObservation,
        overall: coffeeLive.overall,
        love: '',
        career: '',
        money: '',
        nearFuture: 'Ust duvarin acik ve rim bolgesi engelsiz.',
        takeaway: 'Dipteki koyu birikim ile acik alan yan yana: temposunu fark etmek yeterli.',
        language: 'tr',
      }),
    ).toBe('locale_leak');
  });

  it('accepts properly translated cup-region Turkish text', () => {
    const grounded = {
      visualObservation:
        'Fincanin agiz kenarinda ince bir telve izi, orta ic yuzeyde yogun bir kume ve dibinde acik bir alan duruyor. Kulp tarafina dogru hafif egimli.',
      overall:
        'Orta ic yuzeydeki yogun kume ile dibindeki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince izler henuz netlesmemis bir temasin kiyisina benziyor; kesin bir haber gibi degil. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Bu fincanda temponun degistigini fark etmek, falin sundugu en sakin yansima olabilir. Kulp tarafindaki egim ile dipteki aciklik ayni anda duruyor; ikisini birlikte tutmak yeterli. Yogun birikim, seyrek benek ve acik dip ucu yan yana; bunlar falin somut iskeletini kuruyor ve acele etmeden okunmayi hak ediyor.',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway:
        'Yogun kume ile acik dip yan yana: once neyin doldugunu, sonra nereye yer actigini fark etmek yeterli. Orta yuzeydeki birikim ile dibin acikligi birlikte duruyor; tempo farkini sakince okumak bu falin somut hediyesidir.',
      language: 'tr' as const,
    };
    expect(evaluateCoffeeQuality(grounded)).toBeNull();
  });

  it('maps coffee regions to Turkish vocabulary for writer handoff', () => {
    expect(coffeeRegionLabel('rim', 'tr')).toContain('a');
    expect(coffeeRegionLabel('upper wall', 'tr')).toContain('st');
    expect(coffeeRegionLabel('base', 'tr')).toContain('dib');
    expect(coffeeRegionLabel('handle side', 'tr')).toContain('kulp');
    const packet = buildCoffeeWriterPacket(JSON.parse(coffeeObserverJson), 'tr');
    expect(packet.evidence.every((e) => typeof e.regionLabel === 'string')).toBe(true);
  });

  it('rejects inferred handedness without trusted metadata', () => {
    expect(
      evaluatePalmQuality({
        visualObservation: 'Tek bir sag el avuc ici kameraya bakiyor. Kalp ve zihin cizgileri secilebiliyor.',
        overall:
          'Ana cizgilerin baslangicta yakin olup sonra ayrilmasi, temkin ile bagimsizlik arasinda bir iliskiyi dusunduruyor.',
        lifeLine: 'Basparmak kokunden yay cizerek bilege dogru devam ediyor.',
        headLine: 'Ortada uzun ve hafif egimli, surekli gorunuyor.',
        heartLine: 'Ustte nazikce kivrimli ve kismen gorunur.',
        fateLine: '',
        takeaway: 'Kivrim ve yay yan yana: tempo farklarini fark etmek yeterli.',
        language: 'tr',
        trustedHandSide: false,
      }),
    ).toBe('inferred_handedness');
  });

  it('accepts explicit trusted handedness', () => {
    expect(normalizeTrustedHand('right')).toBe('right');
    expect(normalizeTrustedHand('left')).toBe('left');
    expect(normalizeTrustedHand('unknown')).toBeNull();
    const ok = evaluatePalmQuality({
      visualObservation:
        'Guvenilir kayda gore sag el; avuc ici acik, kalp cizgisi ustte hafif kivrimli, zihin cizgisi ortada daha duz ve surekli, yasam cizgisi basparmak kokunden yay ciliyor.',
      overall:
        'Kivrimli kalp cizgisi ile duz zihin cizgisinin araligi, duygusal tepki ile dusunme ritminin ayni anda gorunur oldugunu dusunduruyor. Yasam cizgisinin kesiksiz yayi, temposu bozulmayan bir sureklilik izlenimi birakiyor.',
      heartLine: 'Ustte hafif kivrimli, koyu kontrastli; parmak diplerine dogru kisalarak bitiyor.',
      headLine: 'Ortada duz ve surekli; kalp cizgisinden net aralikla ayriliyor.',
      lifeLine: 'Basparmak kokunden yay cizerek bilege dogru kesiksiz devam ediyor.',
      fateLine: '',
      takeaway: 'Kivrim, duzluk ve yay yan yana: tempo farklarini fark etmek yeterli.',
      language: 'tr',
      trustedHandSide: true,
    });
    expect(ok).toBeNull();
  });

  it('mirrored image cannot decide hand side without metadata', () => {
    const prompt = palmObserverUser('', false);
    expect(prompt.toLowerCase()).toContain('do not say left or right');
    const scrubbed = sanitizeHandednessInItem(
      {
        id: 'x',
        region: 'full hand',
        description: 'A single right hand is shown palm-facing.',
        confidence: 'high',
        visibility: 'clear',
        resemblance: null,
      },
      null,
    );
    expect(scrubbed.description.toLowerCase()).not.toContain('right hand');
    expect(scrubbed.description.toLowerCase()).toContain('palm-facing hand');
  });

  it('rejects embedded disclaimer from narrative', () => {
    expect(
      evaluatePalmQuality({
        visualObservation:
          'Tek bir avuc ici acik; kalp ve zihin cizgileri secilebiliyor, yasam cizgisi yay ciliyor.',
        overall: 'Bu yalnizca eglence ve kisisel dusunme amacli sembolik bir okumadir.',
        lifeLine: 'Yay cizerek devam ediyor; derinligi orta, surekli.',
        headLine: 'Ortada uzun, hafif egimli ve surekli.',
        heartLine: 'Ustte kivrimli ve kismen gorunur.',
        fateLine: '',
        takeaway: 'Kivrim ve yay yan yana: tempo farklarini fark etmek yeterli.',
        language: 'tr',
        trustedHandSide: false,
      }),
    ).toBe('embedded_disclaimer');
  });

  it('rejects generic takeaway phrases and accepts grounded takeaway', () => {
    expect(
      evaluateCoffeeQuality({
        visualObservation:
          'Fincanin agiz kenarinda ince iz, orta ic yuzeyde yogun kume, dibinde acik alan duruyor.',
        overall:
          'Orta ic yuzeydeki yogun kume ile dibindeki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince izler henuz netlesmemis bir temasin kiyisina benziyor. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Tempo farkini fark etmek yeterli.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Enerjini gercekten etkileyebildigin noktaya yoneltmen iyi gelebilir.',
        language: 'tr',
      }),
    ).toBe('generic_closing');

    expect(
      evaluateCoffeeQuality({
        visualObservation:
          'Fincanin agiz kenarinda ince iz, orta ic yuzeyde yogun kume, dibinde acik alan ve kulp tarafinda kivrimli bant duruyor.',
        overall:
          'Orta ic yuzeydeki yogun kume ile dibindeki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince izler henuz netlesmemis bir temasin kiyisina benziyor. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Tempo farkini fark etmek yeterli. Yogun birikim, seyrek benek ve acik dip ucu yan yana; bunlar falin somut iskeletini kuruyor ve acele etmeden okunmayi hak ediyor.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Yogun kume ile acik dip yan yana: once neyin doldugunu fark etmek yeterli. Orta yuzeydeki birikim ile dibin acikligi birlikte duruyor; tempo farkini sakince okumak bu falin somut hediyesidir.',
        language: 'tr',
      }),
    ).toBeNull();
  });

  it('writer prompts ban disclaimer and require locale vocabulary', () => {
    const c = coffeeWriterSystem('tr');
    expect(c.includes('NEVER write policy')).toBe(true);
    expect(c.includes('agiz kenari') || c.includes('ağız kenarı')).toBe(true);
    const palm = palmWriterSystem('tr');
    expect(palm.includes('handPolicy')).toBe(true);
  });

  it('bind rejects E3H live coffee/palm sections', () => {
    const coffeeObs = JSON.parse(coffeeObserverJson);
    coffeeObs.evidence = [
      { id: 'e1', region: 'lower_wall', description: 'dense mass', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e2', region: 'handle_side', description: 'curved band', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e3', region: 'lower_wall', description: 'droplets', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e4', region: 'mid_wall', description: 'speckles', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e5', region: 'rim', description: 'open rim', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'e6', region: 'base', description: 'base line', confidence: 'medium', visibility: 'clear', resemblance: null },
    ];
    const coffeeNarrative = {
      visualObservation: coffeeSections.visualObservation,
      overall: coffeeSections.overall,
      love: coffeeSections.love,
      career: coffeeSections.career,
      money: coffeeSections.money,
      nearFuture: coffeeSections.nearFuture,
      takeaway: coffeeSections.takeaway,
    };
    expect(bindCoffeeNarrative(coffeeNarrative, coffeeObs, 'tr')).not.toBeNull();

    const palmObs = JSON.parse(palmObserverJson);
    palmObs.evidence = [
      { id: 'hand_orientation', region: 'full hand', description: 'one palm-facing hand', confidence: 'high', visibility: 'clear', resemblance: null },
      { id: 'heart_line', region: 'heart_line', description: 'heart line curves', confidence: 'medium', visibility: 'partial', resemblance: 'heart line' },
      { id: 'head_line', region: 'head_line', description: 'head line diagonal', confidence: 'high', visibility: 'clear', resemblance: 'head line' },
      { id: 'life_line', region: 'life_line', description: 'life line arcs', confidence: 'high', visibility: 'clear', resemblance: 'life line' },
      { id: 'major_line_spacing', region: 'spacing', description: 'lines begin close', confidence: 'medium', visibility: 'clear', resemblance: null },
      { id: 'secondary_creases', region: 'thenar', description: 'finer creases', confidence: 'high', visibility: 'clear', resemblance: null },
    ];
    const palmNarrative = {
      visualObservation: palmSections.visualObservation,
      overall: palmSections.overall,
      lifeLine: palmSections.lifeLine,
      headLine: palmSections.headLine,
      heartLine: palmSections.heartLine,
      fateLine: palmSections.fateLine,
      takeaway: palmSections.takeaway,
    };
    expect(bindPalmNarrative(palmNarrative, palmObs, 'tr', false)).not.toBeNull();
  });

  it('grounded helpers still bind; repair is text-only and at most once', async () => {
    expect(bindCoffeeNarrative(JSON.parse(coffeeWriterJson), JSON.parse(coffeeObserverJson), 'tr')).toBeNull();
    expect(bindPalmNarrative(JSON.parse(palmWriterJson), JSON.parse(palmObserverJson), 'tr', false)).toBeNull();

    const leakWriter = JSON.parse(coffeeWriterJson);
    leakWriter.nearFuture = {
      text: 'The rim looks clear on the upper wall.',
      evidenceIds: ['e3'],
    };
    const app = await testApp(
      testConfig(),
      openaiReadingSequence(coffeeObserverJson, JSON.stringify(leakWriter), coffeeWriterJson),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { ...authHeader(), 'idempotency-key': 'e3h1-repair-1' },
      payload: coffeeBody(),
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    const text = JSON.stringify(body.data ?? {});
    expect(text.toLowerCase()).not.toMatch(/\brim\b/);
  });

  it('TR/EN/RU writer systems keep structural parity', () => {
    for (const lang of ['tr', 'en', 'ru'] as const) {
      expect(coffeeWriterSystem(lang)).toContain(`locale=${lang}`);
      expect(palmWriterSystem(lang)).toContain(`locale=${lang}`);
      expect(coffeeWriterSystem(lang)).toContain('evidenceIds');
      expect(palmWriterSystem(lang)).toContain('handPolicy');
    }
  });
});
