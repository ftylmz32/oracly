import { describe, expect, it } from 'vitest';
import type { DreamData } from '../src/ai/parse-provider.js';
import { golden, goldenPayload, serveDream } from './dream-phase4b-support.js';

const rejected = { success: false, error: { code: 'invalid_response' } };

type RedTeam = [label: string, id: string, patch: (d: DreamData) => Partial<DreamData>];

const cases: RedTeam[] = [
  ['en B contradiction', 'en-rich-negated-fear', () => ({ emotionalTheme: 'A deep fear fills the climb toward the dark lamp.' })],
  ['en C generic reflection', 'en-rich-negated-fear', () => ({ dailyLifeReflection: 'Today, trust yourself and listen to your intuition as you move forward.' })],
  ['en D invented work', 'en-rich-negated-fear', () => ({ dailyLifeReflection: 'Today your job may need the same steady climb you showed on that spiral staircase.' })],
  ['en E extra question', 'en-rich-negated-fear', (d) => ({ interpretation: `${d.interpretation} Could the lamp be waiting for you?` })],
  ['en F shallow rich', 'en-rich-negated-fear', () => ({ interpretation: 'The lamp suggests guidance that has paused for a while, a signal waiting quietly for its moment to return.' })],
  ['tr contradiction', 'tr-rich-negated-fear', () => ({ emotionalTheme: 'Köprünün üstünde derin bir korku hakim.' })],
  ['tr generic reflection', 'tr-rich-negated-fear', () => ({ dailyLifeReflection: 'Bugün kendine güven ve sezgilerini dinle, her şey yoluna girecek.' })],
  ['tr invented family', 'tr-rich-negated-fear', () => ({ dailyLifeReflection: 'Bugün ailenle ilgili bekleyen bir konuya da köprüdeki bu merakla bakabilirsin.' })],
  ['tr extra question', 'tr-rich-negated-fear', () => ({ summary: 'Bulanık nehrin üstündeki köprü seni nereye götürüyor olabilir?' })],
  ['tr shallow rich', 'tr-rich-negated-fear', () => ({ interpretation: 'Fener, yol gösteren bir ışık olarak umudu ve yönü simgeliyor olabilir; bu ışık seni kendi yoluna çağırıyor.' })],
  ['ru contradiction', 'ru-rich-negated-fear', () => ({ emotionalTheme: 'Глубокий страх над ночным озером и лодкой.' })],
  ['ru generic reflection', 'ru-rich-negated-fear', () => ({ dailyLifeReflection: 'Сегодня доверься себе и прислушайся к своей интуиции.' })],
  ['ru invented work', 'ru-rich-negated-fear', () => ({ dailyLifeReflection: 'Сегодня на твоей работе может пригодиться то же спокойствие, что в лодке на озере.' })],
  ['ru extra question', 'ru-rich-negated-fear', () => ({ emotionalTheme: 'Спокойствие на озере — или это только тишина перед костром?' })],
  ['ru shallow rich', 'ru-rich-negated-fear', () => ({ interpretation: 'Луна — символ интуиции и скрытых чувств, её мягкое сияние может говорить о том, что внутреннее знание уже рядом.' })],
];

describe('Dream Phase 4B — route red team', () => {
  it('A: a premium EN reply is served with one provider call', async () => {
    const g = golden('en-rich-negated-fear');
    const { json, calls } = await serveDream(g.data, goldenPayload(g), '4b-route-a-0001');
    expect(calls).toBe(1);
    expect(json.success).toBe(true);
    expect(json.data.interpretation).toBe(g.data.interpretation);
  });

  cases.forEach(([label, id, patch], i) => {
    it(`${label} → invalid_response, one call, no retry, no reason`, async () => {
      const g = golden(id);
      const reply = { ...g.data, ...patch(g.data) };
      const { json, calls } = await serveDream(reply, goldenPayload(g), `4b-route-red-${String(i).padStart(4, '0')}`);
      expect(calls).toBe(1);
      expect(json).toEqual(rejected);
    });
  });
});
