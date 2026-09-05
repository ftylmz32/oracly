import { describe, expect, it } from 'vitest';
import { parseTarotData } from '../src/ai/parse-provider.js';
import { fingerprintRequest, isExpensiveOperation } from '../src/ai/request-fingerprint.js';
import { tarotMessages } from '../src/ai/tarot-style.js';
import { validateAiBody } from '../src/ai/validate-request.js';

function validBody() {
  return {
    operation: 'tarot_analysis',
    payload: {
      sessionId: 'session_42',
      spreadLabel: 'Üç Kart',
      userQuestion: 'İşimle ilgili neyi görmüyorum?',
      readingTheme: 'career',
      language: 'tr',
      cards: [
        {
          cardId: 2,
          cardName: 'Two of Swords',
          positionLabel: 'Şimdi',
          positionKey: 'present',
          isReversed: false,
          meaning: 'Bir kararın iki tarafı arasında durmak.',
          keywords: ['karar', 'denge'],
        },
      ],
      continuity: {
        recurringThemes: ['karar'],
        recentCardNames: ['Eight of Wands'],
        priorReadingCount: 3,
      },
    },
  };
}

describe('tarot_analysis contract', () => {
  it('validates cards and keeps continuity in a separate object', () => {
    const validated = validateAiBody(validBody());
    expect(validated.operation).toBe('tarot_analysis');
    if (validated.operation !== 'tarot_analysis') throw new Error('tarot expected');
    const cards = validated.payload.cards as Array<Record<string, unknown>>;
    expect(cards).toHaveLength(1);
    expect(cards[0]?.cardName).toBe('Two of Swords');
    expect((validated.payload.continuity as Record<string, unknown>).recurringThemes).toEqual(['karar']);
  });

  it('rejects tarot requests without real card evidence', () => {
    expect(() =>
      validateAiBody({
        operation: 'tarot_analysis',
        payload: { sessionId: 'x', spreadLabel: 'Tek Kart', cards: [] },
      }),
    ).toThrow();
  });

  it('prompt explicitly separates current evidence from continuity observations', () => {
    const validated = validateAiBody(validBody());
    if (validated.operation !== 'tarot_analysis') throw new Error('tarot expected');
    const messages = tarotMessages(validated.payload, validated.language);
    const system = String(messages[0]?.content ?? '');
    const input = String(messages[1]?.content ?? '');
    expect(system).toContain('READING_EVIDENCE');
    expect(system).toContain('CONTINUITY_OBSERVATIONS');
    expect(system).toContain('Never invent a card');
    expect(input).toContain('Two of Swords');
    expect(input).toContain('"recurringThemes":["karar"]');
  });

  it('normalizes strict provider JSON', () => {
    const parsed = parseTarotData(JSON.stringify({
      summary: 'Bu açılım kararı ertelemekten çok seçenekleri ayırmayı gösteriyor.',
      love: '',
      career: 'İş tarafında iki seçeneğin bedelini ayrı ayrı görmek önemli.',
      money: '',
      health: 'Şimdi konumundaki Two of Swords karar baskısını sembolik olarak taşıyor.',
      spiritualGuidance: '',
      advice: 'İki seçeneğin geri döndürülebilir taraflarını bugün yaz.',
      warnings: 'Kararı sadece rahatlama isteğiyle mi hızlandırıyorsun?',
      luckyEnergy: 'Açılımın bütünü aceleden önce ayrım yapmayı öne çıkarıyor.',
      dailyFocus: 'Tek bir somut kriter belirle.',
      closingMessage: 'İstersen iki seçeneği birlikte yan yana koyabiliriz.',
    }));
    expect(parsed.summary).toContain('kararı');
    expect(parsed.closingMessage).toContain('İstersen');
    expect(parsed.rawText).toContain('Two of Swords');
  });

  it('treats tarot as an expensive idempotent operation', () => {
    const validated = validateAiBody(validBody());
    expect(isExpensiveOperation('tarot_analysis')).toBe(true);
    expect(fingerprintRequest(validated)).toContain('tarot:session_42');
  });
});
