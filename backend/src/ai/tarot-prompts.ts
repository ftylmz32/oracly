/** Real Tarot reading generation — grounded strictly in the drawn cards. */

import type { OpenAiMessage } from '../types.js';
import { responseLanguageDirective, type AppLanguage } from './app-language.js';
import type { TarotCardInput, TarotJourneyHints } from './validate-request.js';

const HEADINGS: Record<AppLanguage, Record<string, string>> = {
  tr: {
    theme: 'Açılımın Teması',
    cards: 'Kartların Mesajı',
    love: 'Aşk',
    career: 'Kariyer',
    overview: 'Genel Bakış',
    spiritual: 'Ruhsal',
    advice: 'Tavsiye',
    askYourself: 'Kendine Sor',
    energy: 'Genel Enerji',
    today: 'Bugün İçin Mesaj',
    closing: 'Sonuç',
  },
  en: {
    theme: 'Theme of the Spread',
    cards: 'Message of the Cards',
    love: 'Love',
    career: 'Career',
    overview: 'Wider View',
    spiritual: 'Spiritual',
    advice: 'Advice',
    askYourself: 'Ask Yourself',
    energy: 'Overall Energy',
    today: 'Message for Today',
    closing: 'Closing',
  },
  ru: {
    theme: 'Тема расклада',
    cards: 'Послание карт',
    love: 'Любовь',
    career: 'Карьера',
    overview: 'Общий взгляд',
    spiritual: 'Духовное',
    advice: 'Совет',
    askYourself: 'Спроси себя',
    energy: 'Общее толкование',
    today: 'Послание на сегодня',
    closing: 'Итог',
  },
};

function tarotSystem(language: AppLanguage): string {
  const h = HEADINGS[language] ?? HEADINGS.tr;
  return [
    "Sen OR — Oracly'nin sakin tarot okuyucususun.",
    'Sana verilen kartlar, pozisyonlar ve düz/ters durum DIŞINDA hiçbir kart veya sembol icat etme.',
    'Her kartı kendi pozisyonuyla birlikte, kartlar arasındaki etkileşimi de dikkate alarak yorumla — kartı tek başına, açılımdan kopuk yorumlama.',
    'Sözlük maddesi yazma (Kart = Anlam gibi bir format yok). Kehanet, kesin tarih, kesin sonuç, hastalık veya ölüm iddiası yok.',
    'Aynı cümleyi veya aynı fikri farklı başlıklar altında tekrarlama — her bölüm yeni bilgi taşımalı, bir öncekini başka kelimelerle tekrar etmemeli.',
    'Klişe kalıplardan kaçın: "yeni bir başlangıç", "kendine güven", "evren sana", "kapılar açılıyor", "enerji", "ayna" gibi ifadeler yasak.',
    'Yapay zeka olduğunu belirtme; politika/güvenlik/uyarı cümlesi yazma (bunlar sessizce uygulanır, okumada görünmez).',
    `Yanıtı şu başlıklarla, markdown "## Başlık" biçiminde ver (yalnızca gerçekten karşılığı olan başlıkları doldur, ilgisizleri boş bırakma — kısa tut): ` +
      `## ${h.theme}, ## ${h.cards}, ## ${h.love}, ## ${h.career}, ## ${h.overview}, ` +
      `## ${h.spiritual}, ## ${h.advice}, ## ${h.askYourself}, ## ${h.energy}, ## ${h.today}, ## ${h.closing}.`,
    responseLanguageDirective(language),
  ].join(' ');
}

function cardLines(cards: TarotCardInput[]): string {
  return cards
    .map((c, i) => {
      const orientation = c.reversed ? 'Ters' : 'Düz';
      const keywords = c.keywords.length ? ` (${c.keywords.join(', ')})` : '';
      return `${i + 1}. ${c.positionLabel} — ${c.name} · ${orientation}${keywords}\n   Anlam ipuçları: ${c.meaning || '—'}`;
    })
    .join('\n');
}

function journeyLines(hints?: TarotJourneyHints): string {
  if (!hints) return '';
  const lines: string[] = [];
  if (hints.recurringThemes.length) {
    lines.push(
      `Kayıtlı geçmişinde tekrar eden temalar: ${hints.recurringThemes.join(', ')}. ` +
        'Yalnızca gerçekten ilgiliyse doğal biçimde değin; zorlama, tarih verme.',
    );
  }
  if (hints.recentCardNames.length) {
    lines.push(`Yakın zamanda çekilen kartlar: ${hints.recentCardNames.join(', ')}.`);
  }
  if (hints.revisitExcerpt) {
    lines.push(`Önceki ilgili okumadan kısa not: "${hints.revisitExcerpt}"`);
  }
  if (hints.memorySummary) {
    lines.push(
      `Kaynaklı ilgili geçmiş: ${hints.memorySummary} ` +
        'Kartlar ve şimdiki soru bunu desteklemiyorsa hiç kullanma; kesin süreklilik kurma.',
    );
  }
  if (!lines.length) return '';
  return '\n\nGeçmiş bağlam (yalnızca gerçekten yardımcı oluyorsa kullan):\n' + lines.join('\n');
}

export function tarotMessages(
  request: {
    cards: TarotCardInput[];
    spreadLabel: string;
    userQuestion?: string;
    readingTheme?: string;
    journeyHints?: TarotJourneyHints;
  },
  language: AppLanguage = 'tr',
): OpenAiMessage[] {
  const lines = [
    `Açılım: ${request.spreadLabel}`,
    `Kartlar:\n${cardLines(request.cards)}`,
  ];
  if (request.userQuestion) lines.push(`Kullanıcının sorusu/niyeti: ${request.userQuestion}`);
  if (request.readingTheme) lines.push(`Okuma teması: ${request.readingTheme}`);
  const journey = journeyLines(request.journeyHints);
  const user = lines.join('\n\n') + journey;
  return [
    { role: 'system', content: tarotSystem(language) },
    { role: 'user', content: user },
  ];
}
