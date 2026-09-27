import { describe, expect, it } from 'vitest';
import type { AppLanguage } from '../src/ai/app-language.js';
import { sameStrict, sameWord, trInflects } from '../src/ai/dream-lexical.js';
import { evaluateDreamQuality } from '../src/ai/dream-quality.js';
import type { DreamData } from '../src/ai/parse-provider.js';
import { enGood, enNarrative, ruGood, ruNarrative, trGood, trNarrative } from './dream-phase2-fixtures.js';

/** Synthetic only — Dream Phase 2.2 lexical evidence red team. */
const input = (narrative: string, language: AppLanguage, symbols: string[] = []) => ({
  narrative,
  symbols,
  emotions: [],
  language,
});

const withSymbols = (data: DreamData, symbols: string[]): DreamData => ({ ...data, symbols });

describe('Dream 2.2 — strict symbol evidence (invented_symbol)', () => {
  const en = (narrative: string, symbol: string) =>
    evaluateDreamQuality(withSymbols(enGood, [symbol]), input(`${enNarrative} ${narrative}`, 'en'));
  const trBase = 'Ruyamda uzun bir yilan sessizce gecti ve gitti.';
  const tr = (narrative: string, symbol: string) =>
    evaluateDreamQuality(withSymbols(trGood, [symbol]), input(`${trBase} ${narrative}`, 'tr'));

  it('rejects English accidental prefixes', () => {
    const base = 'I tried to reduce the noise during a busy season with a catalogue and a rainbow.';
    const plain = (symbol: string) =>
      evaluateDreamQuality(withSymbols(enGood, [symbol]), input(base, 'en'));
    expect(plain('red')).toBe('invented_symbol');
    expect(plain('sea')).toBe('invented_symbol');
    expect(plain('cat')).toBe('invented_symbol');
    expect(plain('rain')).toBe('invented_symbol');
  });

  it('rejects Turkish accidental prefixes, including two-letter symbols', () => {
    expect(tr('Dun cok yemek yedim.', 'yedi')).toBe('invented_symbol');
    expect(tr('Bir sunum yaptım.', 'Su')).toBe('invented_symbol');
    expect(tr('Evren çok büyüktü.', 'Ev')).toBe('invented_symbol');
    expect(tr('Ateş yükseldi.', 'At')).toBe('invented_symbol');
    expect(tr('İşaret yanıp sönüyordu.', 'İş')).toBe('invented_symbol');
    expect(tr('Ayrıca dışarı çıktım.', 'Ay')).toBe('invented_symbol');
  });

  it('rejects lexicon-audit collisions', () => {
    expect(tr('İçimde bir kuşku vardı.', 'Kuş')).toBe('invented_symbol');
    expect(tr('Duvar soğuktu.', 'Dua')).toBe('invented_symbol');
    expect(tr('Huzursuz hissettim.', 'Huzur')).toBe('invented_symbol');
    expect(tr('Anneanneme gittim.', 'Anne')).toBe('invented_symbol');
    expect(tr('Denizli otobüsüne bindim.', 'Deniz')).toBe('invented_symbol');
    expect(tr('Şu an hatırlıyorum.', 'Su')).toBe('invented_symbol');
    expect(tr('Kedi yemek yedi.', 'Yedi')).toBe('invented_symbol');
  });

  it('keeps genuine inflected and ASCII-typed evidence', () => {
    expect(tr('Evdeydim.', 'Ev')).toBeNull();
    expect(tr('Kapıyı açtım.', 'Kapı')).toBeNull();
    expect(tr('Kapiyi actim.', 'Kapı')).toBeNull();
    expect(tr('Suya baktım.', 'Su')).toBeNull();
    expect(tr('Ayı gördüm.', 'Ay')).toBeNull();
    expect(tr('Yediyi gördüm.', 'Yedi')).toBeNull();
    expect(tr('Yedi kapı gördüm.', 'Yedi')).toBeNull();
    expect(tr('Köpeği sevdim.', 'Köpek')).toBeNull();
    expect(tr('Şehre döndüm.', 'Şehir')).toBeNull();
    expect(en('Two cats slept.', 'cat')).toBeNull();
    expect(en('The seas were grey.', 'sea')).toBeNull();
    expect(evaluateDreamQuality(ruGood, input(ruNarrative, 'ru'))).toBeNull();
    expect(evaluateDreamQuality(trGood, input(trNarrative, 'tr'))).toBeNull();
  });
});

describe('Dream 2.2 — general grounding never passes on an accidental prefix', () => {
  it('English red/reduce and sea/season prose is ungrounded', () => {
    const data: DreamData = {
      summary: 'A red glow over the sea carries a slow, patient mood tonight.',
      symbols: [],
      emotionalTheme: 'Quiet patience with a trace of longing.',
      interpretation:
        'The red light resting on the sea suggests a pause, a moment where colour and water meet without hurry or demand.',
      dailyLifeReflection: 'Today you might pause near something red and notice how it feels.',
      conclusion: 'What does the red sea bring to mind for you?',
    };
    const narrative = 'I tried to reduce clutter during a busy season at work.';
    expect(evaluateDreamQuality(data, input(narrative, 'en'))).toBe('ungrounded');
  });

  it('Turkish yedi/yedim prose is ungrounded', () => {
    const data: DreamData = {
      summary: 'Yedi parlak yildiz sessiz bir gokyuzunde siralaniyor.',
      symbols: [],
      emotionalTheme: 'Merak ile sakinlik birlikte duruyor.',
      interpretation:
        'Yedi yildizin ayni hizada durmasi, daginik parcalarin bir araya geldigi sakin bir duzen hissini akla getiriyor.',
      dailyLifeReflection: 'Bugun yedi kucuk seyi fark etmek iyi gelebilir.',
      conclusion: 'Yedi yildizdan hangisi sana daha yakin geliyor?',
    };
    const narrative = 'Dun cok yemek yedim ve erkenden uyudum.';
    expect(evaluateDreamQuality(data, input(narrative, 'tr'))).toBe('ungrounded');
  });

  it('keeps real inflection and paraphrase', () => {
    expect(sameWord('yilanin', 'yilan', 'tr')).toBe(true);
    expect(sameWord('evlerde', 'ev', 'tr')).toBe(true);
    expect(sameWord('raining', 'rain', 'en')).toBe(true);
    expect(sameWord('walked', 'walking', 'en')).toBe(true);
    expect(sameWord('лесу', 'лес', 'ru')).toBe(true);
    expect(sameWord('seasonal', 'season', 'en')).toBe(true);
    expect(sameWord('reduce', 'red', 'en')).toBe(false);
    expect(sameWord('season', 'sea', 'en')).toBe(false);
    expect(sameWord('yedim', 'yedi', 'tr')).toBe(false);
    expect(sameWord('carpenter', 'carpet', 'en')).toBe(false);
  });
});

describe('Dream 2.2 — Turkish grammar and strict pairs', () => {
  it('accepts inflections, rejects look-alikes', () => {
    for (const w of ['evde', 'eve', 'evden', 'evin', 'evi', 'evler', 'evlerde', 'evdeydim']) {
      expect(trInflects(w, 'ev'), w).toBe(true);
    }
    for (const w of ['evren', 'evre', 'evet', 'evli']) expect(trInflects(w, 'ev'), w).toBe(false);
    for (const w of ['suda', 'suya', 'suyu', 'suyun', 'sudan', 'suyla']) expect(trInflects(w, 'su'), w).toBe(true);
    expect(trInflects('sunum', 'su')).toBe(false);
    for (const w of ['yedide', 'yediye', 'yediyi']) expect(trInflects(w, 'yedi'), w).toBe(true);
    for (const w of ['yedim', 'yedin', 'yedik', 'yediler']) expect(trInflects(w, 'yedi'), w).toBe(false);
    expect(trInflects('ateş', 'at')).toBe(false);
    expect(trInflects('işaret', 'iş')).toBe(false);
    expect(trInflects('ayrıca', 'ay')).toBe(false);
  });

  it('strict matching keeps ş distinct but meets ASCII-typed words', () => {
    expect(sameStrict('su', 'şu', 'tr')).toBe(false);
    expect(sameStrict('şehir', 'sehirde', 'tr')).toBe(true);
    expect(sameStrict('red', 'reduce', 'en')).toBe(false);
    expect(sameStrict('cat', 'cats', 'en')).toBe(true);
  });
});
