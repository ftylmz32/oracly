import { describe, expect, it } from 'vitest';
import { dreamMessages } from '../src/ai/dream-prompts.js';
import type { AppLanguage } from '../src/ai/app-language.js';

/**
 * Dream Phase 2.1 — the client sends ORACLY-owned evidence (emotion chips,
 * catalogue symbols, entry context) already in the operation language; the
 * prompt must carry it under same-language headings. Synthetic payloads,
 * built exactly as the Flutter Phase 2.1 tests assert; no provider call.
 */
const cases: Array<{
  language: AppLanguage;
  payload: Record<string, unknown>;
  present: string[];
  absent: string[];
}> = [
  {
    language: 'en',
    payload: {
      narrative:
        'I walked toward a door by the sea and felt uneasy.\n\n[Context]\n- I had a nightmare\n- Who was in your dream?: Mira  and   Leo, by the lantern',
      symbols: ['door', 'sea'],
      emotions: ['fearful'],
    },
    present: [
      'Respond entirely in English',
      'Observed symbols: door, sea',
      'Stated feelings: fearful',
      '[Context]\n- I had a nightmare\n- Who was in your dream?: Mira  and   Leo, by the lantern',
    ],
    absent: ['Korkulu', 'Kapı', 'Deniz', 'Gözlenen', 'Belirtilen', '[Bağlam]', 'Kabus', 'Названные'],
  },
  {
    language: 'ru',
    payload: {
      narrative:
        'Мне снилось, что я шла по тихому лесу.\n\n[Контекст]\n- Был кошмар\n- Помнишь, где это было?: У старого дома',
      symbols: [],
      emotions: ['испуганный'],
    },
    present: [
      'Отвечай полностью на русском языке',
      'Названные чувства: испуганный',
      '[Контекст]\n- Был кошмар\n- Помнишь, где это было?: У старого дома',
    ],
    absent: ['Korkulu', 'fearful', 'Kapı', 'Deniz', 'Stated feelings', 'Observed symbols', 'Замеченные символы', '[Context]', 'I had a nightmare'],
  },
  {
    language: 'tr',
    payload: {
      narrative:
        'Rüyamda sessiz bir ev ve açık bir pencere vardı, kapı aralıktı.\n\n[Bağlam]\n- Kabus gördüm\n- Rüyanda kimler vardı?: Annem  ve Leo',
      symbols: ['Ev', 'Kapı'],
      emotions: ['Korkulu'],
    },
    present: [
      'Yanıtı tamamen Türkçe yaz',
      'Gözlenen semboller: Ev, Kapı',
      'Belirtilen duygular: Korkulu',
      '[Bağlam]\n- Kabus gördüm\n- Rüyanda kimler vardı?: Annem  ve Leo',
    ],
    absent: ['Observed symbols', 'Stated feelings', '[Context]', 'I had a nightmare', 'fearful'],
  },
];

describe('Dream Phase 2.1 — prompt evidence language integrity', () => {
  it.each(cases)('$language: ORACLY-owned headings and evidence share one language', ({ language, payload, present, absent }) => {
    const messages = dreamMessages(payload, language);
    expect(messages).toHaveLength(2);
    const wire = messages.map((m) => m.content).join('\n');
    for (const text of present) expect(wire).toContain(text);
    for (const text of absent) expect(wire).not.toContain(text);
  });
});
