import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  evaluateCoffeeQuality,
  evaluatePalmQuality,
} from '../src/ai/human-quality.js';
import { coffeeSystem, coffeeUserLead } from '../src/ai/coffee-style.js';
import { palmSystem, palmUserLead } from '../src/ai/palm-style.js';
import { parseCoffeeData } from '../src/ai/parse-provider.js';
import { parsePalmData } from '../src/ai/parse-palm.js';
import { ProxyError } from '../src/errors.js';

const coffeeNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_coffee_negative.json', 'utf8'),
);
const palmNeg = JSON.parse(
  readFileSync('./tests/fixtures/e3g/e3f_palm_negative.json', 'utf8'),
);

const goodCoffee = {
  visualObservation:
    'Agiz kenarinda ince bir telve izi, orta duvarda daha yogun bir kume ve dipte acik bir alan duruyor. Kume kenari kulpa dogru hafif egimli; dipteki aciklikla yan yana duruyorlar. Ust duvarda seyrek bir iz seridi de gorunuyor.',
  overall:
    'Orta duvardaki yogun kume ile dipteki acik alan yan yana okununca, bir toplanma izinin yaninda bir ferahlama alani gibi duruyor. Bu ikisini birlikte dusunmek, kalabalik bir gundemden sonra nefes alacak bir aralik birakma olasiligini cagristirabilir. Agizdaki ince iz henuz netlesmemis bir temasin kiyisina benziyor; kesin bir haber gibi degil. Ustteki seyrek serit ise ayni hikayenin daha hafif bir devamini ima edebilir. Istersen bu hafta bir gorusmeyi biraz daha sakin tutmak icinden gecebilir; bu bir kehanet degil, fincanin ritmine yaklasik bir okuma.',
  love: '',
  career: '',
  money: '',
  nearFuture: '',
  takeaway:
    'Yogun kume ile acik dip yan yana: once neyin doldugunu, sonra nereye yer actigini fark etmek yeterli. Tempo farkini hissetmek, falin sundugu en sakin hediyedir.',
  language: 'tr' as const,
};

const goodPalm = {
  visualObservation:
    'Acik bir avuc ici kameraya bakiyor. Kalp cizgisi avuc ustunde hafif kivrimli ve koyu kontrastli; parmak diplerine dogru kisalarak bitiyor. Zihin cizgisi ortada daha duz, surekli ve kalp cizgisinden belirgin aralikla ayriliyor. Yasam cizgisi basparmak kokunden yay cizerek bilege dogru devam ediyor; kopuk gorunmuyor.',
  overall:
    'Kivrimli kalp cizgisi ile duz zihin cizgisinin araligi, duygusal tepki ile dusunme ritminin ayni anda gorunur oldugunu dusunduruyor. Yasam cizgisinin kesiksiz yayi, temposu bozulmayan bir sureklilik izlenimi birakiyor; saglik tahmini veya kader iddiasi degil.',
  heartLine:
    'Ustte hafif kivrimli, koyu kontrastli; parmak diplerine dogru kisalarak bitiyor.',
  headLine:
    'Ortada duz ve surekli; kalp cizgisinden net aralikla ayriliyor.',
  lifeLine:
    'Basparmak kokunden yay cizerek bilege dogru kesiksiz devam ediyor.',
  fateLine: '',
  takeaway:
    'Kivrim, duzluk ve yay yan yana: tempo farklarini fark etmek yeterli.',
  language: 'tr',
};

describe('E3G human quality regression', () => {
  it('rejects exact E3F coffee negative fixture', () => {
    expect(evaluateCoffeeQuality(coffeeNeg)).not.toBeNull();
  });
  it('rejects exact E3F palm negative fixture', () => {
    expect(evaluatePalmQuality(palmNeg)).not.toBeNull();
  });
  it('accepts grounded natural coffee', () => {
    expect(evaluateCoffeeQuality(goodCoffee)).toBeNull();
  });
  it('accepts grounded natural palm', () => {
    expect(evaluatePalmQuality(goodPalm)).toBeNull();
  });
  it('rejects duplicated closing question', () => {
    const long = {
      ...goodCoffee,
      overall:
        goodCoffee.overall +
        ' Yakin zamanda bir bulusma planliyor musun?',
      takeaway: 'Yakin zamanda keyifli bir bulusma planliyor musun?',
    };
    expect(evaluateCoffeeQuality(long)).toBe('closing_question_habit');
  });
  it('rejects duplicated conclusion text', () => {
    const line =
      'Yogun kume ile acik dip yan yana duruyor ve bunu sakince okumak yeterli burada.';
    expect(
      evaluateCoffeeQuality({
        ...goodCoffee,
        overall: goodCoffee.overall + ' ' + line,
        takeaway: line,
      }),
    ).toBe('duplicate_sections');
  });
  it('rejects generic palm energy/balance text', () => {
    expect(
      evaluatePalmQuality({
        ...goodPalm,
        takeaway: 'Bu avuc dengeli bir yaklasim ve guclu bir enerji tasiyor.',
      }),
    ).toBe('repeated_stock');
  });
  it('rejects stock traditionally-means coffee phrasing', () => {
    expect(
      evaluateCoffeeQuality({
        ...goodCoffee,
        overall:
          goodCoffee.overall +
          ' Bu iz geleneksel olarak sicak bir sohbet anlamina gelebilir.',
      }),
    ).toBe('repeated_stock');
  });
  it('rejects medical/lifespan language', () => {
    expect(
      evaluatePalmQuality({
        ...goodPalm,
        lifeLine: goodPalm.lifeLine + ' Bu cizgi uzun bir omur gosterir ve kesin yasam suresi verir.',
      }),
    ).toBe('prohibited_claim');
  });
  it('accepts valid tentative symbolism', () => {
    expect(
      evaluateCoffeeQuality({
        ...goodCoffee,
        overall:
          goodCoffee.overall +
          ' Bu kume bir demligi andiran bir iz gibi duruyor; kesin demlik demiyorum.',
      }),
    ).toBeNull();
  });
  it('keeps Turkish UTF-8 characters valid in fixtures', () => {
    expect(/[\u00e7\u011f\u0131\u00f6\u015f\u00fc\u0130]/.test(coffeeNeg.visualObservation)).toBe(true);
    expect(/[\u00e7\u011f\u0131\u00f6\u015f\u00fc]/.test(palmNeg.overall)).toBe(true);
  });
  it('parser rejects E3F negatives as invalid_response', () => {
    expect(() =>
      parseCoffeeData(
        JSON.stringify({
          gorselTespit: coffeeNeg.visualObservation,
          genelYorum: coffeeNeg.overall,
          sonuc: coffeeNeg.takeaway,
          ask: '',
          kariyer: '',
          maddiDurum: '',
          yakinDonem: '',
          semboller: [],
        }),
      ),
    ).toThrow(ProxyError);
    expect(() =>
      parsePalmData(
        JSON.stringify({
          gorselTespit: palmNeg.visualObservation,
          genelYapi: palmNeg.overall,
          kalpCizgisi: palmNeg.heartLine,
          zihinCizgisi: palmNeg.headLine,
          yasamCizgisi: palmNeg.lifeLine,
          kaderYon: '',
          sonuc: palmNeg.takeaway,
        }),
      ),
    ).toThrow(ProxyError);
  });
  it('rejects E3G live coffee boilerplate closing question pattern', () => {
    expect(
      evaluateCoffeeQuality({
        visualObservation:
          'Fincanin orta kisminda yogun bir telve birikintisi var. Bu birikinti bir caydanlik veya demlik formunu andiriyor. Kulpa yakin bir yerde daha acik bir alan bulunuyor.',
        overall:
          'Fincanin ortasinda beliren demlik sekli, yeni bir baslangici veya bir araya gelmeyi sembolize edebilir. Bu, sosyal cevrenizde yeni bir bulusma ya da bir araya gelme anlamina gelebilir. Kulpa yakin acik alan ise, bu bulusmanin sizin icin rahatlatici ve olumlu etkiler tasiyabilecegini isaret ediyor.',
        love: 'Ask hayatinda yeni bir baslangic veya onemli bir bulusma yasanabilir.',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: 'Hayatinizdaki bu yeni baslangic, size beklenmedik kapilar acabilir mi?',
        language: 'tr',
      }),
    ).not.toBeNull();
  });
  it('EN/RU prompts keep usable:false and grounding contracts', () => {
    for (const lang of ['en', 'ru'] as const) {
      const c = coffeeSystem(lang) + coffeeUserLead(lang);
      const p = palmSystem(lang) + palmUserLead(lang);
      expect(c.includes('usable:false')).toBe(true);
      expect(p.includes('usable:false')).toBe(true);
      expect(c.includes('gorselTespit')).toBe(true);
      expect(p.includes('gorselTespit')).toBe(true);
    }
    expect(coffeeSystem('en').includes('concrete anchors')).toBe(true);
    expect(palmSystem('en').includes('concrete attributes')).toBe(true);
    expect(coffeeSystem('ru').includes('якоря')).toBe(true);
    expect(palmSystem('ru').includes('атрибута')).toBe(true);
  });
});

