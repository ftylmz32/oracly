import { describe, expect, it } from 'vitest';
import { chatMessages, oracleMessages } from '../src/ai/prompts.js';
import { chatSystem, oracleReadingGrounding } from '../src/ai/chat-style.js';
import type { ChatTurn } from '../src/ai/parse-turns.js';

const tarot = {
  spreadLabel: 'Üç kart',
  cardsSummary: '1. Ay — ters\n2. Kupa İkilisi — düz\n3. Kılıç Onlusu — düz',
  interpretationSummary:
    'Sabit test okuması. Ay ters: belirsizlik. Kupa İkilisi: karşılıklı yakınlık.',
  userQuestion: 'İlişkimde ne oluyor?',
};

function text(messages: { content: unknown }[]): string {
  return messages
    .map((message) =>
      typeof message.content === 'string' ? message.content : '',
    )
    .join('\n');
}

describe('luna editorial contract', () => {
  it('does not script a question onto a named feeling', () => {
    const system = chatSystem('tr');
    expect(system).not.toContain('Neye takıldın?');
    expect(system).toContain('Bir duygu anlattığında o cümleye karşılık ver');
    expect(system).toContain('Okuma veya duygu cümlesine kendini tanıtarak başlama');
    expect(system).toContain("Kimliğini sorduklarında");
  });

  it('keeps a denied cause inside the same chat', () => {
    const first = 'Bugün biraz kötü hissediyorum.';
    const second = 'Aslında sebebi iş değil.';
    const turns: ChatTurn[] = [
      { role: 'user', text: first },
      { role: 'assistant', text: 'Önceki yanıt.' },
    ];
    const messages = chatMessages(second, [], undefined, turns, 'mystical');
    const body = text(messages);
    expect(messages.map((message) => message.role)).toEqual([
      'system',
      'user',
      'assistant',
      'user',
    ]);
    expect(body).toContain(first);
    expect(body).toContain(second);
    expect(body).toContain('Önceki yanıt.');
    expect(body).not.toContain('Neye takıldın?');
  });

  it('carries tarot and the prior reply into the expand turn', () => {
    const turns: ChatTurn[] = [
      { role: 'user', text: 'Bu kartlar ilişkim için ne anlatıyor?' },
      { role: 'assistant', text: 'Birlikte bir eşik kuruyorlar.' },
      { role: 'user', text: 'Peki neden böyle hissettiğimi düşünüyorsun?' },
      { role: 'assistant', text: 'Eşik, bitiş değil.' },
    ];
    const messages = oracleMessages(
      'tarot',
      tarot,
      'Son söylediğini biraz açar mısın?',
      [],
      'tr',
      turns,
      'mystical',
    );
    const body = text(messages);
    expect(body).toContain('Kupa İkilisi');
    expect(body).toContain('Eşik, bitiş değil.');
    expect(body).toContain('o düşünceyi derinleştir');
    expect(body).toContain('ayrı sözlük maddeleri');
    expect(body).toContain('Kart adı geçebilir');
    expect(messages.at(-1)?.content).toBe('Son söylediğini biraz açar mısın?');
  });

  it('follows a move from relationship to work', () => {
    const turns: ChatTurn[] = [
      { role: 'user', text: 'İlişkimde bazı şeyler yolunda gitmiyor.' },
      { role: 'assistant', text: 'Orada duran şeyi duydum.' },
    ];
    const messages = chatMessages(
      'Aslında şimdi iş hayatımı konuşmak istiyorum.',
      [],
      undefined,
      turns,
      'mystical',
    );
    const body = text(messages);
    expect(body).toContain('İlişkimde bazı şeyler yolunda gitmiyor.');
    expect(body).toContain('iş hayatımı konuşmak istiyorum');
    expect(body).toContain('konu kaymasını takip et');
    expect(oracleReadingGrounding('tr')).toContain('okumadan uzaklaşırsa bırak');
  });
});
