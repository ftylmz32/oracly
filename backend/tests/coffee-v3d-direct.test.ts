/**
 * V3D — direct fortune-teller engine. The ONE content rule: the reader never
 * gets a description of the cup / saucer / grounds / a seen symbol. Every
 * other choice (topics, boldness, length, flow) belongs to the writer.
 * Fake transport only: zero real provider calls. All texts are SYNTHETIC.
 */
import { existsSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  COFFEE_V3D_DIRECT_PROMPT,
  COFFEE_V3D_READING_STAGE,
  COFFEE_V3D_REJECTIONS_STAGE,
  FROZEN_COFFEE_V3D_PROMPT_SHA256,
  checkCoffeeV3DirectDelivery,
  coffeeV3DPromptSha256,
  runCoffeeV3DirectReading,
} from '../src/ai/reading/coffee-v3d-direct-pipeline.js';
import { CoffeeV3TerminalFailure } from '../src/ai/reading/coffee-v3-live-pipeline.js';
import { createReadingStageStore } from '../src/ai/reading/stage-cache.js';
import { loadConfig } from '../src/config.js';
import type { OpenAiCompleteOptions } from '../src/ai/openai-transport.js';
import { fakeJpeg, testConfig } from './helpers.js';

/** A bold, free, life-only fortune (synthetic). Uses yol / kalp / kuş / açıklık / kapı as LIFE words. */
const FREE = [
  'Önümüzdeki haftalarda uzun zamandır beklediğin bir haber kapını çalacak; bir telefonla başlayan konuşma seni hiç ummadığın bir yola çıkaracak gibi.',
  'Kalbin tarafında hareket var: araları bozuk olduğun biriyle barışma ihtimali çok güçlü, belki de yeniden yan yana gelip bir evlilik konuşması bile açılabilir. Kuş gibi hafifleyeceğin, içinin açıklığa kavuşacağı günler yakın.',
  'İş ve para tarafında kısmetin açık; yeni bir teklif geliyor ve bu kez kararını hızlı vereceksin. Bir ayrılık da görünüyor ama sana iyi gelecek bir veda bu.',
].join('\n\n');

describe('V3D delivery check — only a visual description is refused', () => {
  it('accepts a free, bold reading: love, reconciliation, marriage, news, money, separation, the definite future', () => {
    const r = checkCoffeeV3DirectDelivery(FREE);
    expect(r.ok, r.ok ? '' : JSON.stringify(r)).toBe(true);
    if (r.ok) expect(r.reading.split('\n\n')).toHaveLength(3);
  });

  it.each([
    ['yol', 'Önünde yeni bir yol açılıyor, uzun zamandır beklediğin değişim geliyor gibi; bu yol seni sevdiğin insanlara götürecek ve hayatına renk katacak bir dönemin başlangıcı olacak. Kapılar bir bir açılıyor.'],
    ['kalp', 'Kalbin hafifliyor; kalbinden geçen kişiyle yakında konuşacak, belki de çoktandır içinde taşıdığın duyguyu ona açacaksın. Bu açıklık ilişkine yeni bir sıcaklık getirecek ve aranızdaki mesafe azalacak gibi duruyor.'],
    ['kuş / gibi duruyor', 'Kuş gibi özgür hissedeceğin günler geliyor; uzaktan bir haber alacak, sevindirici bir gelişmeyle yüzün gülecek. Bu dönem sana yeni kapılar açacak gibi duruyor ve uzun zamandır beklediğin rahatlamayı getirecek bir sürece giriyorsun.'],
  ])('ordinary life words stay free (%s)', (_label, text) => {
    const r = checkCoffeeV3DirectDelivery(text);
    expect(r.ok, r.ok ? '' : JSON.stringify(r)).toBe(true);
  });

  it.each([
    ['the cup', 'Fincanında uzun zamandır beklediğin bir haber var; önümüzdeki günlerde bir telefonla başlayan konuşma seni sevindirecek ve hayatına yeni bir hareket getirecek gibi görünüyor, kısmetin açık.', 'fincanında'],
    ['the grounds', 'Telvenin koyulaştığı yerde bir yük görüyorum ama önümüzdeki günlerde bu yük hafifleyecek, iş tarafında rahatlatıcı bir gelişme seni sevindirecek ve yeni bir başlangıç yapacaksın gibi duruyor.', 'telvenin'],
    ['the saucer', 'Tabakta kısmetin toplanmış; önümüzdeki haftalarda para tarafında rahatlatıcı bir gelişme seni bekliyor, uzun süredir beklediğin bir ödeme ya da teklif gelecek ve içini ferahlatacak gibi görünüyor.', 'tabakta'],
    ['a symbol shape', 'Kalp şeklinde bir işaret aşk tarafında güzel bir gelişmeye işaret ediyor; önümüzdeki günlerde biriyle yakınlaşacak, belki de uzun zamandır beklediğin o konuşmayı yapacaksın ve içinin rahatladığını hissedeceksin.', 'kalp şeklinde'],
    ['a symbol that "looks like"', 'Kuş gibi duran işaret uzaktan gelecek bir haberi anlatıyor; önümüzdeki günlerde bir telefon ya da mesajla sevindirici bir gelişme yaşayacak, uzun zamandır beklediğin cevabı sonunda alacaksın gibi görünüyor.', 'kuş gibi'],
    ['a seen creature', 'Bir yılan görüyorum ama korkma, bu çevrendeki bir kıskançlığı anlatıyor; önümüzdeki günlerde bu kişiden uzaklaşacak, kendi yoluna daha güçlü devam edecek ve içinin rahatladığını fark edeceksin gibi.', 'yılan görüyorum'],
    ['a figure', 'Dipte bir insan figürü beliriyor; önümüzdeki dönemde hayatına yeni biri girecek, bu karşılaşma seni hem şaşırtacak hem sevindirecek ve uzun süredir beklediğin değişimin ilk adımı olacak gibi görünüyor.', 'figürü'],
  ])('refuses %s', (_label, text, term) => {
    const r = checkCoffeeV3DirectDelivery(text);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.failures).toContain('visual_description');
      expect(r.terms.join(' ')).toContain(term);
    }
  });

  it('refuses only technical breakage otherwise: empty, cut-off, markdown', () => {
    expect(checkCoffeeV3DirectDelivery('   ')).toMatchObject({ ok: false, failures: ['empty'] });
    expect(checkCoffeeV3DirectDelivery('Yakında bir haber geliyor.')).toMatchObject({ ok: false, failures: ['too_short'] });
    const md = checkCoffeeV3DirectDelivery(`**Aşk**\n\n${FREE}`);
    expect(md.ok).toBe(false);
    if (!md.ok) expect(md.failures).toEqual(['formatting']);
  });
});

describe('V3D delivery check — "figür / silüet" judged in context (first real V3D sample)', () => {
  const pad = ' Önümüzdeki haftalarda beklediğin bir haber gelecek ve iş tarafında yeni bir teklif kapını çalacak.';

  it.each([
    'Uzun zamandır yanında olan bir kadın figüründen samimi bir destek ve sevindirici bir haber alacaksın.',
    'Hayatındaki önemli bir erkek figürü bu dönemde sana yol gösterecek ve yanında duracak.',
    'Aile içinde güçlü bir figür olarak sözün dinlenecek, verdiğin kararlar saygı görecek.',
  ])('a person / life figure stays free: %s', (sentence) => {
    const r = checkCoffeeV3DirectDelivery(sentence + pad);
    expect(r.ok, r.ok ? '' : JSON.stringify(r)).toBe(true);
  });

  it.each([
    ['a seen creature figure', 'Bir kuş figürü uzaktan gelecek bir haberi anlatıyor.', 'kuş figürü'],
    ['a person figure being seen', 'Bir kadın figürü beliriyor, hayatına yeni biri girecek.', 'kadın figürü'],
    ['a figure being seen', 'Bir figür görüyorum, yakında biriyle karşılaşacaksın.', 'figür'],
    ['a person shape', 'Kadın şeklinde bir işaret aşkta bir gelişmeyi anlatıyor.', 'kadın şeklinde'],
    ['a silhouette of a symbol', 'Ağaç silüeti köklü bir değişimi anlatıyor gibi.', 'ağaç silüeti'],
  ])('a real visual description is still refused: %s', (_label, sentence, term) => {
    const r = checkCoffeeV3DirectDelivery(sentence + pad);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.failures).toContain('visual_description');
      expect(r.terms.join(' | ')).toContain(term);
    }
  });

  /**
   * The two REAL gpt-5.6-sol samples of the first V3D run, read from the
   * local evidence file (outside the repository — real readings are never
   * copied into it). Skipped where that file is absent.
   */
  const EVIDENCE = 'D:/oracly_coffee_live_output/coffee_v3d_1791828332993.json';
  it.skipIf(!existsSync(EVIDENCE))('REAL regression: sample 1 is no longer refused as visual; sample 2 is still delivered', () => {
    const e = JSON.parse(readFileSync(EVIDENCE, 'utf8')) as { requests: Array<{ raw: string }>; result: { overall: string } };
    const first = checkCoffeeV3DirectDelivery(e.requests[0].raw);
    expect(first.ok, first.ok ? '' : JSON.stringify(first.failures)).toBe(true);
    const second = checkCoffeeV3DirectDelivery(e.requests[1].raw);
    expect(second.ok).toBe(true);
    if (second.ok) expect(second.reading).toBe(e.result.overall);
  });
});

describe('V3D prompt — one rule, free otherwise', () => {
  it('is pinned', () => {
    expect(coffeeV3DPromptSha256()).toBe(FROZEN_COFFEE_V3D_PROMPT_SHA256);
  });

  it('states the single visual rule and the freedom; no V3N tables, plan or word budgets', () => {
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Gördüğünü kendine sakla, kişiye yalnızca falını anlat.');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('tek, bütünlüklü bir hikâye kur');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('sırf falda bulunsun diye sırayla dolaşma');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('kuru bir açıklama yazma');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('hikâyenin akışına ve uzunluğa sen karar ver');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Kişinin niyeti falın omurgasıdır.');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Herkese söylenebilecek genel bir fal yazma.');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Geleceği kesin olmuş bir bilgi gibi ilan etme.');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Yapılacaklar listesi');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('hazır bir kapanış cümlesi kurma');
    expect(COFFEE_V3D_DIRECT_PROMPT).toContain('Kanıtsız suçlama, iftira ya da zarar verici talimat yok.');
    expect(COFFEE_V3D_DIRECT_PROMPT).not.toMatch(/\b(12|700)\s*kelime\b/u);
    for (const v3n of ['lifeScenes', 'claims', 'outline', 'budget', 'weight', '-abilir', 'ihtimal dili']) expect(COFFEE_V3D_DIRECT_PROMPT).not.toContain(v3n);
  });
});

const STAGED = ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'] as const;
const images = () => STAGED.map((slot, i) => ({ slot, mimeType: 'image/jpeg', bytes: fakeJpeg(20_000 + i * 100) }));
function fake(outputs: string[]) {
  const calls: OpenAiCompleteOptions[] = [];
  const queue = [...outputs];
  return {
    calls,
    transport: {
      async complete(o: OpenAiCompleteOptions) {
        calls.push(o);
        const next = queue.shift();
        if (next === undefined) throw new Error('unexpected_extra_call');
        return next;
      },
    },
  };
}
const run = (outputs: string[], over: Partial<Parameters<typeof runCoffeeV3DirectReading>[0]> = {}) => {
  const f = fake(outputs);
  const store = over.stageStore ?? createReadingStageStore();
  const p = runCoffeeV3DirectReading({
    config: testConfig(), transport: f.transport, stageStore: store, images: images(),
    intention: 'Önümüzdeki dönem genel olarak', language: 'tr', identity: 'owner-a', parentKey: 'reading-operation:d1', ...over,
  });
  return { f, store, p };
};
const failure = (e: unknown) => (e instanceof CoffeeV3TerminalFailure ? `${e.failureCode}:${e.reason}` : String(e));

describe('V3D pipeline (fake transport)', () => {
  it('one vision request: the prompt, the intention and exactly three high-detail images; the reading is delivered verbatim', async () => {
    const { f, p } = run([FREE]);
    const result = await p;
    expect(result.coffeeResultContract).toBe('v3_narrative_v1');
    expect(result.overall).toBe(FREE);
    expect(result.symbols).toEqual([]);
    expect(f.calls).toHaveLength(1);
    const call = f.calls[0];
    expect(call.model).toBe('gpt-5.6-sol');
    expect(call.jsonSchema).toBeUndefined();
    expect(call.messages[0]).toEqual({ role: 'system', content: COFFEE_V3D_DIRECT_PROMPT });
    const parts = call.messages[1].content as Array<{ type: string; text?: string; image_url?: { detail: string } }>;
    expect(parts.filter((x) => x.type === 'image_url').map((x) => x.image_url!.detail)).toEqual(['high', 'high', 'high']);
    expect(parts[0].text).toContain('Önümüzdeki dönem genel olarak');
  });

  it('a visual leak is re-sampled once; the clean second reading is delivered', async () => {
    const { f, store, p } = run(['Fincanında bir kuş var, haber geliyor ve önümüzdeki günlerde sevineceksin; bir telefonla başlayan konuşma uzun zamandır beklediğin değişimi getirecek gibi görünüyor, kısmetin açık.', FREE]);
    expect((await p).overall).toBe(FREE);
    expect(f.calls).toHaveLength(2);
    expect(JSON.stringify(f.calls[0])).toBe(JSON.stringify(f.calls[1])); // byte-identical, no feedback
    const rejections = store.get<Array<{ failures: string[]; terms: string[]; outputSha256: string }>>('owner-a', 'reading-operation:d1', COFFEE_V3D_REJECTIONS_STAGE);
    expect(rejections?.[0].failures).toEqual(['visual_description']);
    expect(JSON.stringify(rejections)).not.toContain('haber geliyor'); // codes and terms only, never the text
  });

  it('two leaking samples are a terminal unavailable — at most two requests, no result', async () => {
    const leak = 'Tabakta kısmetin toplanmış; önümüzdeki haftalarda para tarafında rahatlatıcı bir gelişme seni bekliyor, uzun süredir beklediğin bir ödeme ya da teklif gelecek ve içini ferahlatacak gibi görünüyor.';
    const { f, p } = run([leak, leak]);
    const err = await p.catch((e) => e);
    expect(failure(err)).toBe('unavailable:v3d_delivery_failed:a1=visual_description;a2=visual_description');
    expect(f.calls).toHaveLength(2);
  });

  it('a task retry after delivery never sends again (the reading is cached per operation)', async () => {
    const store = createReadingStageStore();
    await run([FREE], { stageStore: store }).p;
    const again = run([], { stageStore: store });
    expect((await again.p).overall).toBe(FREE);
    expect(again.f.calls).toHaveLength(0);
    expect(store.get<{ reading: string }>('owner-a', 'reading-operation:d1', COFFEE_V3D_READING_STAGE)?.reading).toBe(FREE);
  });

  it('fails closed before any request: non-Turkish, malformed views, an unpinned prompt', async () => {
    for (const [over, reason] of [
      [{ language: 'en' as const }, 'unavailable:language_not_supported'],
      [{ images: images().slice(0, 2) }, 'unavailable:staged_views_malformed'],
      [{ expectedPromptSha256: '0'.repeat(64) }, 'unavailable:v3d_prompt_hash_mismatch'],
    ] as const) {
      const { f, p } = run([FREE], over);
      expect(failure(await p.catch((e) => e))).toBe(reason);
      expect(f.calls).toHaveLength(0);
    }
  });
});

describe('V3D routing: direct by default, V3N kept and selectable', () => {
  it('config: only ORACLY_COFFEE_V3_ENGINE=narrative selects V3N', () => {
    expect(testConfig().coffeeV3Engine).toBe('direct');
    expect(testConfig({ ORACLY_COFFEE_V3_ENGINE: 'narrative' }).coffeeV3Engine).toBe('narrative');
    expect(testConfig({ ORACLY_COFFEE_V3_ENGINE: 'something-else' }).coffeeV3Engine).toBe('direct');
    expect(typeof loadConfig).toBe('function');
  });
});
