import { describe, expect, it } from 'vitest';
import { coffeePresumedUserState } from '../src/ai/human-quality.js';
import { coffeeQualityFailure } from '../src/ai/reading/evidence-bind.js';
import { palmWriterSystem, repairWriterSystem } from '../src/ai/reading/writer-prompts.js';
import type { CoffeeNarrative } from '../src/ai/reading/types.js';

const empty = { text: '', evidenceIds: [] as string[] };
const narrative = (text: string): CoffeeNarrative => ({
  visualObservation: { text: 'Fincanın ortasında tek gövdeden yükselen, yukarı doğru birkaç kısa dala ayrılan ağaç biçimi açıkça görülüyor.', evidenceIds: ['e1'] },
  overall: { text: `${text} tek gövdeden çıkan dallar zamanla birkaç yöne uzanacak ve aynı kökten büyüyecek. Ortadaki sağlam gövde, gelişmenin dağılmadan güç kazanacağını ve çevresini giderek genişleteceğini anlatıyor.`, evidenceIds: ['e1'] },
  love: empty, career: empty, money: empty, nearFuture: empty,
  takeaway: { text: 'Dalların yukarı yönelmesi, bu gelişmenin bulunduğu yerde kalmayıp görünür biçimde büyüyeceğini anlatıyor.', evidenceIds: ['e1'] },
});
const evidence = [{ id: 'e1', region: 'middle_wall', description: 'A branching shape rising from a single stem.', confidence: 'medium' as const, visibility: 'clear' as const, resemblance: 'may resemble a tree with branches' }];

describe('Coffee current user-state presumptions', () => {
  it('rejects current waiting forms but permits future waiting', () => {
    for (const text of ['tek bir sonuç beklerken', 'bir sonucu bekliyorken', 'bir sonucu bekliyorsun']) expect(coffeePresumedUserState([text])).not.toBeNull();
    expect(coffeePresumedUserState(['Bir süre beklemen gerekebilir.'])).toBeNull();
  });
  it('rejects current negative feelings that are already changing', () => {
    for (const text of ['sıkışıklık hissi azalırken', 'endişe hissi hafifliyor', 'huzursuzluk hissin geçiyor', 'yorgunluk hissin azalıyor']) expect(coffeePresumedUserState([text])).not.toBeNull();
  });
  it('allows clean growth, future ferahlık, and non-user emotion wording', () => {
    for (const text of ['Tek gövdeden çıkan dallar birkaç yöne uzanacak.', 'Yakın günlerde daha ferah bir hava var.', 'Sevindirici bir gelişme hissediliyor.']) expect(coffeePresumedUserState([text])).toBeNull();
  });
  it('preserves personalization exceptions', () => {
    for (const text of ['Tek bir sonuç beklerken', 'Sıkışıklık hissi azalırken']) {
      expect(coffeeQualityFailure(narrative(text), 'tr', undefined, evidence)).toBe('presumed_user_state');
      expect(coffeeQualityFailure(narrative(text), 'tr', { intention: text }, evidence)).not.toBe('presumed_user_state');
    }
  });
  it('leaves Palm prompts untouched', () => {
    expect(palmWriterSystem('tr')).not.toContain('CURRENT WAITING STATE');
    expect(repairWriterSystem('palm')).not.toContain('CURRENT WAITING STATE');
  });
});
