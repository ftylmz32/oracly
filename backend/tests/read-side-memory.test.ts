import { describe, expect, it } from 'vitest';
import { dreamMessages } from '../src/ai/prompts.js';
import { soulmateInterpretationMessages } from '../src/ai/soulmate-interpretation.js';
import { validateAiBody } from '../src/ai/validate-request.js';

describe('Dream and Soulmate read-side memory prompts', () => {
  it('places current Dream evidence before bounded optional history', () => {
    const validated = validateAiBody({
      operation: 'dream_analysis',
      payload: {
        narrative: 'Iki yol arasinda kaldim ve konusmaya calistim.',
        symbols: ['iki yol'],
        emotions: ['kararsizlik'],
        memorySummary: `[tarot|2026-09-01|t1] ${'karar '.repeat(80)}`,
      },
    });
    if (validated.operation !== 'dream_analysis') throw new Error('wrong operation');
    const user = String(dreamMessages(validated.payload, validated.language)[1]?.content);
    expect(user.indexOf('Iki yol')).toBeLessThan(user.indexOf('[tarot|'));
    expect(user).toContain('destekliyorsa');
    expect(String(validated.payload.memorySummary).length).toBeLessThanOrEqual(220);
  });

  it('carries the cautious-memory instruction as clean, correctly-encoded Turkish', () => {
    // Regression for a real production defect: the memory-caution clause was
    // multiply mis-encoded (mojibake) in a way that survived undetected,
    // because the prior assertion above only checked for 'destekliyorsa' --
    // a pure-ASCII word that happens to sit right next to the corrupted
    // Turkish text and is unaffected by the corruption either way. This test
    // asserts the actual accented characters, not an ASCII neighbor of them.
    const validated = validateAiBody({
      operation: 'dream_analysis',
      payload: {
        narrative: 'Iki yol arasinda kaldim ve konusmaya calistim.',
        memorySummary: '[tarot|2026-09-01|t1] Karar temasi tekrar etti.',
      },
    });
    if (validated.operation !== 'dream_analysis') throw new Error('wrong operation');
    const user = String(dreamMessages(validated.payload, validated.language)[1]?.content);
    // The intended clause, byte-exact: any re-introduced mojibake breaks this.
    expect(user).toContain(
      'İlgili geçmiş bağlam (yalnızca bu rüyanın mevcut ayrıntıları ' +
        'destekliyorsa temkinli kullan; desteklemiyorsa yok say):',
    );
    // Mojibake's own signature glyphs must never appear anywhere in the
    // assembled prompt -- neither the double-encoding lead characters nor
    // the stray degree-sign artifact a corrupted 'İ' decodes to.
    expect(user).not.toMatch(/[ÂÃ][-ÿ]/);
    expect(user).not.toMatch(/Ä°/);
  });

  it('stays a valid, well-formed prompt when no memory is available', () => {
    const validated = validateAiBody({
      operation: 'dream_analysis',
      payload: { narrative: 'Iki yol arasinda kaldim ve konusmaya calistim.' },
    });
    if (validated.operation !== 'dream_analysis') throw new Error('wrong operation');
    const messages = dreamMessages(validated.payload, validated.language);
    const user = String(messages[1]?.content);
    expect(validated.payload.memorySummary).toBeUndefined();
    expect(user).not.toContain('İlgili geçmiş bağlam');
    expect(user).toContain('Iki yol arasinda kaldim');
    expect(messages).toHaveLength(2);
  });

  it('places Soulmate history after current identity and intention', () => {
    const messages = soulmateInterpretationMessages({
      name: 'Ada',
      birthDate: '1990-01-01',
      intention: 'Acik iletisim kurulan bir iliski istiyorum.',
      language: 'tr',
      memorySummary: '[coffee|2026-09-01|c1] Iletisim temasi.',
    });
    const user = String(messages[1]?.content);
    expect(user.indexOf('statedPreference=')).toBeLessThan(user.indexOf('[coffee|'));
    expect(messages[0]?.content).toContain('Historical context is optional');
  });
});
