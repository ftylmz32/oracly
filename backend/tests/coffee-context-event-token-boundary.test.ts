import { describe, expect, it } from 'vitest';
import { coffeeContextEventPromotion } from '../src/ai/reading/coffee-diversity.js';
import type { ReadingEvidenceItem } from '../src/ai/reading/types.js';

/**
 * CONTEXT_EVENT lexeme contract. Each event concept matches a complete
 * folded token: a noun lexeme plus Turkish plural / possessive / case /
 * copula suffixes, or a verb stem plus any verbal suffix. Derived adjectives
 * and unrelated compounds ("davetkâr", "haberdar", "düzenli") are not events.
 */
const context: ReadingEvidenceItem = {
  id: 'e1',
  region: 'middle_wall',
  description: 'A faint grey smear with no outline.',
  confidence: 'high',
  visibility: 'clear',
  resemblance: null,
};
const sign: ReadingEvidenceItem = {
  id: 'e2',
  region: 'upper_wall',
  description: 'Two thin strokes spread from a small body.',
  confidence: 'high',
  visibility: 'clear',
  resemblance: 'may resemble a bird',
};
const promoted = (text: string) =>
  coffeeContextEventPromotion([{ text, evidenceIds: ['e1'] }], [context]) !== null;

describe('context event — derived words are not events', () => {
  it.each([
    'Davetkâr bir dönem.',
    'Davetkar bir dönem.',
    'Her şeyden haberdar bir dönem.',
    'Bu dönem her şeyden haberdarsın.',
    // -li / -siz adjectives describe a quality, not a routine event.
    'Düzenli ve sakin bir akış var.',
    'Düzensiz ama yumuşak bir akış var.',
    // -ci "herald" metaphor, not a news event.
    'Sakin bir dönemin habercisi gibi.',
    'Telefonik bir tını var.',
    'Sakin bir dönem.',
  ])('%s → clean', (text) => {
    expect(promoted(text)).toBe(false);
  });
});

describe('context event — real event language still triggers', () => {
  it.each([
    'Yakında bir haber gelebilir.',
    'Beklenmedik bir haberi duyabilirsin.',
    'Haberler hızla gelebilir.',
    'Bir haberden söz edilebilir.',
    'Bir mesaj gelebilir.',
    'Mesajlar artabilir.',
    'Mesajlaşma sıklaşabilir.',
    'Haberleşme sıklaşabilir.',
    'Bir davet gündeme gelebilir.',
    'Bir daveti kabul edebilirsin.',
    'Davetler çoğalabilir.',
    'Bir buluşma görünüyor.',
    'Bir bulusma görünüyor.',
    'Biriyle buluşacaksın.',
    'Bir görüşme görünüyor.',
    'İş görüşmesinden söz edilebilir.',
    'Bir karşılaşma olabilir.',
    'Ziyaret görünüyor.',
    'Bir ziyaretçi gelebilir.',
    'Bir misafir gelebilir.',
    'Bir telefon gelebilir.',
    'Telefonun çalabilir.',
    'Bir toplantı görünüyor.',
    'Bir toplantıdan söz edilebilir.',
    'Uzun bir sohbet görünüyor.',
    'Sohbetler uzayabilir.',
    'Kendine vakit ayırabilirsin.',
    'Rutin değişebilir.',
    'Günlük düzen değişebilir.',
    'Düzeninde bir değişiklik olabilir.',
    'İşler yoğunlaşabilir.',
    'İşlerin hızlanabilir.',
    'Bir uğraş görünüyor.',
  ])('%s → event', (text) => {
    expect(promoted(text)).toBe(true);
  });
});

describe('context event — established events match across inflections', () => {
  it('an event a sign-grounded section introduced may be referred to again in another form', () => {
    const sections = [
      { text: 'Yakında bir haber gelebilir.', evidenceIds: ['e2'] },
      { text: 'Haberin ayrıntısı sakin bir zamanda netleşebilir.', evidenceIds: ['e1'] },
      { text: 'Haberleri sakin karşılayabilirsin.', evidenceIds: ['e1'] },
    ];
    expect(coffeeContextEventPromotion(sections, [context, sign])).toBeNull();
  });

  it('an event the sign-grounded section did not introduce is still promoted', () => {
    const sections = [
      { text: 'Yakında bir haber gelebilir.', evidenceIds: ['e2'] },
      { text: 'Bir davet de gündeme gelebilir.', evidenceIds: ['e1'] },
    ];
    expect(coffeeContextEventPromotion(sections, [context, sign])).toBe('Bir davet de gündeme gelebilir.');
  });
});
