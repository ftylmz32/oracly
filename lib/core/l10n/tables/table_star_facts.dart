/// Yıldızname natal fact layer chrome — TR / EN / RU.
///
/// Body, sign, aspect and element names are REUSED from the existing product
/// tables (`planet.*`, `zodiac.*`, `aspect.*`, `birth.element.*`,
/// `birth.conj_and`); only the fact-layer chrome and the few missing terms
/// live here.
library;

import '../l10n_triple.dart';

const kL10nStarFacts = <String, L10nTriple>{
  // Plate chrome.
  'star.fact.title': L10nTriple(
    'Doğum göğün',
    'Your birth sky',
    'Твоё небо рождения',
  ),
  'star.fact.more': L10nTriple(
    'Gökyüzünün ayrıntıları',
    'More of the sky',
    'Подробнее о небе',
  ),
  'star.fact.outer': L10nTriple(
    'Dış gezegenler',
    'Outer planets',
    'Внешние планеты',
  ),
  'star.fact.aspects': L10nTriple(
    'Öne çıkan açılar',
    'Closest aspects',
    'Самые точные аспекты',
  ),

  // Terms missing from the shared tables.
  'star.fact.midheaven': L10nTriple(
    'Gökyüzü Ortası',
    'Midheaven',
    'Середина неба',
  ),
  'star.fact.retrograde': L10nTriple(
    'geri hareket',
    'retrograde',
    'ретроградность',
  ),
  'star.fact.house': L10nTriple('{n}. ev', 'House {n}', '{n}-й дом'),

  // Balance.
  'star.fact.balance.element': L10nTriple(
    'Baskın element',
    'Dominant element',
    'Ведущая стихия',
  ),
  'star.fact.balance.quality': L10nTriple(
    'Baskın nitelik',
    'Dominant quality',
    'Ведущее качество',
  ),
  'star.fact.quality.cardinal': L10nTriple(
    'Kardinal',
    'Cardinal',
    'Кардинальное',
  ),
  'star.fact.quality.fixed': L10nTriple('Sabit', 'Fixed', 'Фиксированное'),
  'star.fact.quality.mutable': L10nTriple('Değişken', 'Mutable', 'Мутабельное'),
};
