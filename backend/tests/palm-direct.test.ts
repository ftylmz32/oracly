/**
 * PALM DIRECT — the palm reader writes freely from the photo; only palm's own
 * accuracy limits are enforced (no unseen line, no unconfirmed hand side, no
 * lifespan / health / death / pregnancy). Fake transport / fetch only: zero
 * real provider calls. All texts are SYNTHETIC.
 */
import { afterEach, describe, expect, it } from 'vitest';
import {
  FROZEN_PALM_DIRECT_PROMPT_SHA256,
  PALM_DIRECT_PROMPT,
  PALM_DIRECT_READING_STAGE,
  PALM_DIRECT_REJECTIONS_STAGE,
  checkPalmDirectDelivery,
  palmDirectPromptSha256,
  runPalmDirectReading,
} from '../src/ai/reading/palm-direct-pipeline.js';
import type { OpenAiCompleteOptions } from '../src/ai/openai-transport.js';
import { createReadingStageStore, readingStageStore } from '../src/ai/reading/stage-cache.js';
import { ProxyError } from '../src/errors.js';
import { authHeader, fakeJpeg, jsonResponse, palmBody, testApp, testConfig } from './helpers.js';

/** A free, bold palm reading (synthetic): line descriptions + concrete predictions. */
const FREE = {
  visualObservation: 'Avucun geniş, çizgilerin net ve derin; özellikle kalp çizgin göze çarpıyor.',
  overall: 'Önümüzdeki aylarda hayatında hızlanan bir dönem başlıyor: uzun zamandır beklediğin bir iş teklifi gelecek ve bu kez kararını hızlı vereceksin. Kalbinin sesini dinlediğinde doğru yolu bulacaksın.',
  lifeLine: 'Hayat çizgin başparmağının çevresini geniş bir kavisle dolaşıyor; enerjin yüksek, yeni bir şehre ya da yeni bir işe uyum sağlaman kolay olacak.',
  headLine: 'Akıl çizgin uzun ve hafif aşağı eğimli: hayal gücün güçlü, bu yıl yaratıcı bir projeyle adını duyurabilirsin.',
  heartLine: 'Kalp çizgin işaret parmağına kadar uzanıyor; bu yıl gönlünü çalan biriyle ciddi bir ilişki başlıyor, belki bir evlilik konuşması bile açılacak.',
  fateLine: '',
  takeaway: 'Bu el, cesaretle atılan adımların karşılığını gören birinin eli; önündeki yıl senin yılın.',
};
const json = (o: Record<string, unknown>) => JSON.stringify(o);

describe('PALM DIRECT delivery check — palm accuracy limits only', () => {
  it('accepts a free, bold reading with line descriptions, concrete predictions and an unseen (empty) fate line', () => {
    const r = checkPalmDirectDelivery(json(FREE), null);
    expect(r.ok, r.ok ? '' : JSON.stringify(r)).toBe(true);
    if (r.ok) {
      expect(r.sections.overall).toBe(FREE.overall);
      expect(r.sections.fateLine).toBe('');
    }
  });

  it('a confirmed hand side may be named; an unconfirmed one may not', () => {
    const named = json({ ...FREE, visualObservation: 'Sağ elinde çizgiler net ve derin; avucun geniş.' });
    expect(checkPalmDirectDelivery(named, 'right').ok).toBe(true);
    const r = checkPalmDirectDelivery(named, null);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toEqual(['handedness']);
  });

  it.each([
    ['lifespan', 'Hayat çizgin uzun, bu da uzun bir ömür demek; enerjin hiç azalmayacak.'],
    ['illness', 'Hayat çizgindeki kırılma geçireceğin bir hastalığı anlatıyor gibi.'],
    ['pregnancy', 'Hayat çizgin yakında bir hamilelik müjdesi verildiğini söylüyor.'],
    ['death', 'Bu kesinti bir ölüm haberini anlatıyor olabilir.'],
  ])('refuses a %s claim read from the palm', (_label, lifeLine) => {
    const r = checkPalmDirectDelivery(json({ ...FREE, lifeLine }), null);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.failures).toContain('health_claim');
  });

  it('refuses only broken output otherwise: not JSON, no overall, no line at all, markdown', () => {
    expect(checkPalmDirectDelivery('bir fal', null)).toMatchObject({ ok: false, failures: ['malformed'] });
    expect(checkPalmDirectDelivery(json({ ...FREE, overall: 'Kısa.' }), null)).toMatchObject({ ok: false, failures: ['overall_missing'] });
    expect(checkPalmDirectDelivery(json({ ...FREE, lifeLine: '', headLine: '', heartLine: '', fateLine: '' }), null)).toMatchObject({ ok: false, failures: ['no_line'] });
    expect(checkPalmDirectDelivery(json({ ...FREE, overall: `**Genel**\n${FREE.overall}` }), null)).toMatchObject({ ok: false, failures: ['formatting'] });
  });

  it('an unreadable photo is reported as such (not a writing failure)', () => {
    expect(checkPalmDirectDelivery('{"unreadable": true}', null)).toMatchObject({ ok: false, unreadable: true });
  });
});

describe('PALM DIRECT prompt — palm limits, free otherwise', () => {
  it('is pinned', () => {
    expect(palmDirectPromptSha256()).toBe(FROZEN_PALM_DIRECT_PROMPT_SHA256);
  });

  it('states palm accuracy limits and the freedom; no evidence ids, section jobs or tendency-only rule', () => {
    expect(PALM_DIRECT_PROMPT).toContain('Göremediğin ya da seçemediğin bir çizgiyi varmış gibi yazma');
    expect(PALM_DIRECT_PROMPT).toContain('Kişi hangi eli gösterdiğini söylemediyse sağ el ya da sol el deme');
    expect(PALM_DIRECT_PROMPT).toContain('Ömür uzunluğu, sağlık, hastalık, ölüm ya da hamilelik');
    expect(PALM_DIRECT_PROMPT).toContain('Aşk, ilişkiler, evlilik, kariyer, para, kısmet, fırsatlar, kararlar ve gelecek');
    for (const old of ['evidenceIds', 'tendencies', 'NO INVENTED LIFE STORY', 'cite']) expect(PALM_DIRECT_PROMPT).not.toContain(old);
  });
});

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
const run = (outputs: string[], over: Partial<Parameters<typeof runPalmDirectReading>[0]> = {}) => {
  const f = fake(outputs);
  const store = over.stageStore ?? createReadingStageStore();
  const p = runPalmDirectReading({
    config: testConfig(), transport: f.transport, stageStore: store, image: { mimeType: 'image/jpeg', bytes: fakeJpeg() },
    trustedHandSide: 'right', language: 'tr', identity: 'owner-a', parentKey: 'palm:p1', ...over,
  });
  return { f, store, p };
};
const code = (e: unknown) => (e instanceof ProxyError ? e.code : String(e));

describe('PALM DIRECT pipeline (fake transport)', () => {
  it('one vision request (prompt, language, hand, first name, one high-detail image); the public palm shape verbatim', async () => {
    const { f, p } = run([json(FREE)], { personalization: { firstName: 'Deniz' } });
    const result = await p;
    expect(result).toEqual({ ...FREE, symbols: [], themes: [] });
    expect(f.calls).toHaveLength(1);
    const call = f.calls[0];
    expect(call.jsonMode).toBe(true);
    expect(call.messages[0]).toEqual({ role: 'system', content: PALM_DIRECT_PROMPT });
    const parts = call.messages[1].content as Array<{ type: string; text?: string; image_url?: { detail: string } }>;
    expect(parts.filter((x) => x.type === 'image_url').map((x) => x.image_url!.detail)).toEqual(['high']);
    expect(parts[0].text).toContain('Türkçe');
    expect(parts[0].text).toContain('sağ el');
    expect(parts[0].text).toContain('Deniz');
  });

  it('a refused sample is re-sampled once; codes and terms are recorded, never the text', async () => {
    const leak = json({ ...FREE, lifeLine: 'Hayat çizgin uzun, uzun bir ömür seni bekliyor gibi duruyor bu avuçta.' });
    const { f, store, p } = run([leak, json(FREE)]);
    expect((await p).overall).toBe(FREE.overall);
    expect(f.calls).toHaveLength(2);
    expect(JSON.stringify(f.calls[0])).toBe(JSON.stringify(f.calls[1]));
    const rej = store.get<Array<{ failures: string[] }>>('owner-a', 'palm:p1', PALM_DIRECT_REJECTIONS_STAGE);
    expect(rej?.[0].failures).toEqual(['health_claim']);
    expect(JSON.stringify(rej)).not.toContain('seni bekliyor');
  });

  it('two refused samples → invalid response (the existing failure path); an unreadable palm → invalid image', async () => {
    const bad = json({ ...FREE, overall: 'Kısa.' });
    const two = run([bad, bad]);
    expect(code(await two.p.catch((e) => e))).toBe('invalid_response');
    expect(two.f.calls).toHaveLength(2);
    const unreadable = run(['{"unreadable": true}']);
    expect(code(await unreadable.p.catch((e) => e))).toBe('invalid_image');
    expect(unreadable.f.calls).toHaveLength(1);
  });

  it('a retry after delivery never sends again; an unpinned prompt sends nothing', async () => {
    const store = createReadingStageStore();
    await run([json(FREE)], { stageStore: store }).p;
    const again = run([], { stageStore: store });
    expect((await again.p).overall).toBe(FREE.overall);
    expect(again.f.calls).toHaveLength(0);
    expect(store.get<{ overall: string }>('owner-a', 'palm:p1', PALM_DIRECT_READING_STAGE)?.overall).toBe(FREE.overall);
    const pinned = run([json(FREE)], { expectedPromptSha256: '0'.repeat(64) });
    expect(await pinned.p.catch((e) => e)).toBeInstanceOf(ProxyError);
    expect(pinned.f.calls).toHaveLength(0);
  });
});

describe('PALM routing: direct by default, structured kept and selectable', () => {
  afterEach(() => readingStageStore.clear?.());

  it('config: only ORACLY_PALM_ENGINE=structured selects the old chain', () => {
    expect(testConfig().palmEngine).toBe('direct');
    expect(testConfig({ ORACLY_PALM_ENGINE: 'structured' }).palmEngine).toBe('structured');
    expect(testConfig({ ORACLY_PALM_ENGINE: 'other' }).palmEngine).toBe('direct');
  });

  it('the real palm_analysis route returns the direct reading in one provider call', async () => {
    let calls = 0;
    const app = await testApp(testConfig(), async () => {
      calls += 1;
      return jsonResponse({ choices: [{ message: { content: json(FREE) } }] });
    });
    const res = await app.inject({ method: 'POST', url: '/v1/ai/complete', headers: authHeader(), payload: palmBody() });
    expect(res.json().success).toBe(true);
    expect(res.json().data).toMatchObject({ overall: FREE.overall, heartLine: FREE.heartLine, fateLine: '' });
    expect(calls).toBe(1);
    await app.close();
  });
});
