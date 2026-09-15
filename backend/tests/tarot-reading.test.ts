import { describe, expect, it } from 'vitest';
import { authHeader, openaiText, testApp, testConfig } from './helpers.js';

const tarotBody = {
  operation: 'tarot_reading',
  payload: {
    spreadLabel: 'Üç Kart',
    userQuestion: 'İş hayatımda ne bekliyor?',
    cards: [
      {
        name: 'The Fool',
        positionLabel: 'Geçmiş',
        reversed: false,
        meaning: 'Yeni bir yolculuğun eşiği, saf potansiyel.',
        keywords: ['başlangıç', 'risk'],
      },
      {
        name: 'The Tower',
        positionLabel: 'Şimdi',
        reversed: true,
        meaning: 'Ani değişim, sarsıntı; ters halinde direnç.',
        keywords: ['yıkım', 'direnç'],
      },
      {
        name: 'The Star',
        positionLabel: 'Gelecek',
        reversed: false,
        meaning: 'Umut, iyileşme, netleşen bir yön.',
        keywords: ['umut'],
      },
    ],
  },
};

const READING_TEXT =
  '## Açılımın Teması\nGeçiş ve yeniden toparlanma.\n\n' +
  '## Kartların Mesajı\nGeçmişte The Fool cesur bir başlangıcı işaret ediyor. ' +
  'Şimdi konumundaki ters The Tower, beklenen sarsıntıya karşı bir direnç olduğunu gösteriyor. ' +
  'Gelecekte The Star ise netleşen bir umudu taşıyor.\n\n' +
  '## Genel Bakış\nÜç kart birlikte okunduğunda, sarsıntının ardından gelen bir berraklık hikayesi ortaya çıkıyor.\n\n' +
  '## Tavsiye\nDirenç gösterdiğin yeri fark et; değişime tamamen kapını kapatma.\n\n' +
  '## Sonuç\nBu berraklık sana ne zaman ulaşacak gibi hissettiriyor?';

describe('tarot_reading operation', () => {
  it('rejects a request with no cards', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: { operation: 'tarot_reading', payload: { spreadLabel: 'Tek kart', cards: [] } },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('rejects a request missing spreadLabel', async () => {
    const app = await testApp(testConfig({ AI_DEV_AUTH_BYPASS: 'true' }));
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: {
        operation: 'tarot_reading',
        payload: { cards: tarotBody.payload.cards },
      },
    });
    expect(res.json().error.code).toBe('invalid_request');
    await app.close();
  });

  it('returns the real generated reading text, grounded in the sent cards', async () => {
    let seenBody = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seenBody = String(init?.body ?? '');
      return new Response(
        JSON.stringify({ choices: [{ message: { content: READING_TEXT } }] }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: tarotBody,
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().success).toBe(true);
    expect(res.json().data.text).toContain('Açılımın Teması');
    expect(res.json().data.text).toContain('The Star');

    // The evidence actually sent to the model must name every card, its
    // position, and orientation — never invented, never omitted.
    expect(seenBody).toContain('The Fool');
    expect(seenBody).toContain('The Tower');
    expect(seenBody).toContain('The Star');
    expect(seenBody).toContain('Geçmiş');
    expect(seenBody).toContain('Ters');
    expect(seenBody).toContain('Üç Kart');
    expect(seenBody).toContain('İş hayatımda ne bekliyor');
    await app.close();
  });

  it('never fabricates cards not present in the request', async () => {
    let seenBody = '';
    const app = await testApp(testConfig(), async (_url, init) => {
      seenBody = String(init?.body ?? '');
      return new Response(
        JSON.stringify({ choices: [{ message: { content: READING_TEXT } }] }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      );
    });
    await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: tarotBody,
    });
    // Cards never submitted must never appear in what we send the model.
    expect(seenBody).not.toContain('The Lovers');
    expect(seenBody).not.toContain('Death');
    await app.close();
  });

  it('extracts and returns plain text even without JSON mode', async () => {
    const app = await testApp(
      testConfig(),
      openaiText('## Açılımın Teması\nKısa bir yansıma.'),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: authHeader(),
      payload: tarotBody,
    });
    expect(res.json().success).toBe(true);
    expect(res.json().data.text).toContain('Kısa bir yansıma');
    await app.close();
  });

  it('requires auth like every other paid operation', async () => {
    const app = await testApp(testConfig());
    const res = await app.inject({
      method: 'POST',
      url: '/v1/ai/complete',
      headers: { 'content-type': 'application/json' },
      payload: tarotBody,
    });
    expect(res.statusCode).toBe(401);
    await app.close();
  });
});
