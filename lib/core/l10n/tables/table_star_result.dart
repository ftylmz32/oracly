/// Yıldızname result chrome — chapter titles + truthful scope disclosure.
///
/// TR / EN / RU. Chrome only: stored prose is never localized or rewritten.
library;

import '../l10n_triple.dart';

const kL10nStarResult = <String, L10nTriple>{
  // Semantic roles.
  'star.result.role.summary': L10nTriple('Özet', 'Summary', 'Кратко'),
  'star.result.role.reflection': L10nTriple(
    'Üzerine düşün',
    'To reflect on',
    'Для размышления',
  ),
  'star.result.role.closing': L10nTriple('Kapanış', 'Closing', 'Завершение'),
  // Neutral chapter chrome — used when a section kind is not recognized.
  'star.result.chapter.neutral': L10nTriple('Fasıl', 'Chapter', 'Глава'),

  // Narrative section kinds.
  'star.result.chapter.identity': L10nTriple(
    'Kimlik',
    'Identity',
    'Идентичность',
  ),
  'star.result.chapter.emotional': L10nTriple(
    'Duygusal dünya',
    'Emotional world',
    'Эмоциональный мир',
  ),
  'star.result.chapter.mind': L10nTriple(
    'Zihin ve ifade',
    'Mind and expression',
    'Ум и выражение',
  ),
  'star.result.chapter.relationships': L10nTriple(
    'İlişkiler ve değerler',
    'Relationships and values',
    'Отношения и ценности',
  ),
  'star.result.chapter.drive': L10nTriple(
    'İtici güç ve büyüme',
    'Drive and growth',
    'Движение и рост',
  ),
  'star.result.chapter.angles': L10nTriple(
    'Açılar ve evler',
    'Angles and houses',
    'Углы и дома',
  ),
  'star.result.chapter.patterns': L10nTriple(
    'Örüntüler ve gerilimler',
    'Patterns and tensions',
    'Паттерны и напряжения',
  ),
  'star.result.chapter.strengths': L10nTriple(
    'Güçler ve kaynaklar',
    'Strengths and resources',
    'Сильные стороны и ресурсы',
  ),
  'star.result.chapter.echo': L10nTriple(
    'Arşiv yankısı',
    'Archive echo',
    'Эхо архива',
  ),
  'star.result.chapter.practice': L10nTriple(
    'Pratik yansıma',
    'Practical reflection',
    'Практическое отражение',
  ),

  // Scope disclosure — what the reading is based on. Never lists layers
  // positively; FULL never promises every possible layer.
  'star.result.scope.kicker': L10nTriple(
    'Bu yorumun dayanağı',
    'What this reading rests on',
    'На чём основано это толкование',
  ),
  'star.result.continuity.heading': L10nTriple(
    'Arşiv yankısı',
    'Archive echo',
    'Эхо архива',
  ),
  'star.result.continuity.body': L10nTriple(
    'Bu temalar önceki Yıldızname okumalarında da tekrar etmişti.',
    'These themes have also returned in earlier Yıldızname readings.',
    'Эти темы уже возвращались в прежних чтениях Йылдызнаме.',
  ),
  'star.result.scope.legacy': L10nTriple(
    'Bu okuma için mevcut sembolik Yıldızname bağlamına dayanan bir yorum. Kesin bir doğum haritası hesabı değildir.',
    'A symbolic Yıldızname interpretation based only on the context available to this reading. It is not a precise natal-chart calculation.',
    'Символическое толкование Йылдызнаме, основанное только на контексте, доступном этому чтению. Это не точный расчёт натальной карты.',
  ),
  'star.result.scope.reduced': L10nTriple(
    'Elde bulunan doğum bilgilerine göre kişiselleştirilmiş bir yorum. Doğum saati kesin olmadığı için Yükselen ve evler gibi saate bağlı katmanlar dahil edilmedi.',
    'A personalized interpretation based on the birth details available. Because the birth time is not certain, time-dependent layers such as the Ascendant and houses are not included.',
    'Персональное толкование на основе имеющихся данных о рождении. Поскольку время рождения неточно, слои, зависящие от времени, — такие как Асцендент и дома, — не включены.',
  ),
  'star.result.scope.full': L10nTriple(
    'Hesaplanan doğum bilgilerine dayanan bir doğum haritası yorumu.',
    'A natal interpretation based on the birth details that were calculated.',
    'Натальное толкование на основе рассчитанных данных о рождении.',
  ),
  'star.result.scope.full_partial': L10nTriple(
    'Hesaplanan doğum bilgilerine dayanan bir doğum haritası yorumu. Yalnızca gerçekten hesaplanabilen katmanlar kullanıldı.',
    'A natal interpretation based on the birth details that were calculated. Only the layers that could actually be calculated were used.',
    'Натальное толкование на основе рассчитанных данных о рождении. Использованы только те слои, которые действительно удалось рассчитать.',
  ),
};
