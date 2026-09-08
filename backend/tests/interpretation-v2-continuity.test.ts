import { describe, expect, it } from 'vitest';
import { oracleMessages } from '../src/ai/prompts.js';
import { validateAiBody } from '../src/ai/validate-request.js';

const tarotContext = {
  kind: 'tarot',
  spreadLabel: 'Üç Kart',
  cardsSummary: 'Two of Swords (Düz) · Eight of Wands (Düz)',
  interpretationSummary: 'Karar ve harekete geçiş arasında gerilim var.',
};

describe('Interpretation Engine V2 continuity contract', () => {
  it('keeps prior continuity separate from current reading evidence', () => {
    const continuity =
      'OBSERVATION: Karar teması Tarot ve Kahve okumalarında tekrar etti.';
    const messages = oracleMessages(
      'tarot',
      tarotContext,
      'Bu karar neden yine karşıma çıkıyor?',
      [],
      'tr',
      [],
      undefined,
      continuity,
    );

    const system = String(messages[0]?.content ?? '');
    const reading = String(messages[1]?.content ?? '');

    expect(system).toContain(continuity);
    expect(system).toContain('mevcut kartın, görselin, fincanın veya avucun kanıtı değildir');
    expect(system).toContain('geçmişi hatırlıyormuş gibi konuşma');
    expect(reading).toContain('Two of Swords');
    expect(reading).not.toContain('Tarot ve Kahve okumalarında tekrar etti');
  });

  it('accepts tagged continuity through request validation without identity fields', () => {
    const validated = validateAiBody({
      operation: 'oracle',
      payload: {
        userMessage: 'Bu karar neden yine karşıma çıkıyor?',
        language: 'tr',
        styleHint:
          'OBSERVATION: Karar teması Tarot ve Kahve okumalarında tekrar etti.',
        context: tarotContext,
      },
    });

    expect(validated.operation).toBe('oracle');
    if (validated.operation !== 'oracle') throw new Error('oracle expected');
    expect(validated.styleHint).toMatch(/^OBSERVATION:/);
    expect(JSON.stringify(validated)).not.toContain('firebaseUid');
    expect(JSON.stringify(validated)).not.toContain('"uid"');
  });

  it('bounds client-supplied continuity at the backend boundary', () => {
    const validated = validateAiBody({
      operation: 'oracle',
      payload: {
        userMessage: 'Bu karar ne anlatıyor?',
        language: 'tr',
        styleHint: `OBSERVATION: ${'x'.repeat(1000)}`,
        context: tarotContext,
      },
    });

    if (validated.operation !== 'oracle') throw new Error('oracle expected');
    expect(validated.styleHint?.length ?? 0).toBeLessThanOrEqual(360);
  });
});
