/// Universe map, bands, and journey sections — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nUniverse = <String, L10nTriple>{
  'nav.reflect': L10nTriple('OR', 'OR', 'OR'),
  'nav.hint.reflect': L10nTriple(
    'Yansıma ve sohbet',
    'Reflection and conversation',
    'Размышление и разговор',
  ),
  'band.explore': L10nTriple('KEŞFET', 'EXPLORE', 'ОТКРЫВАТЬ'),
  'band.reflect': L10nTriple('YANSIT', 'REFLECT', 'ОТРАЖАТЬ'),
  'band.understand': L10nTriple('ANLA', 'UNDERSTAND', 'ПОНИМАТЬ'),
  'band.explore_hint': L10nTriple('Ritüel ve açılım', 'Ritual and spread', 'Ритуал и расклад'),
  'band.reflect_hint': L10nTriple('OR rehberin', 'OR, your guide', 'OR, твой проводник'),
  'band.understand_hint': L10nTriple(
    'Rüya, yıldızname, astroloji',
    'Dream, star reading, astrology',
    'Сон, звёздная книга, астрология',
  ),
  'section.remember': L10nTriple('Hatırla', 'Remember', 'Помнить'),
  'section.grow': L10nTriple('Büyü', 'Grow', 'Расти'),
  'section.account': L10nTriple('Hesap', 'Account', 'Аккаунт'),
  'section.remember_hint':
      L10nTriple('Arşivin ve hatırladıkların', 'Your archive and what is remembered', 'Твой архив и то, что помнится'),
  'section.grow_hint':
      L10nTriple('Yolculuğundaki izler', 'Traces on your path', 'Следы на твоём пути'),
  'section.account_hint':
      L10nTriple('Premium ve ayarlar', 'Premium and settings', 'Премиум и настройки'),
  'map.title': L10nTriple('Evren Haritası', 'Universe map', 'Карта вселенной'),
  'map.intro': L10nTriple(
    'ORACLY tek bir evren — her köşe farklı bir deneyim. Nereye gitmek istediğini hisset; burada kaybolmana gerek yok.',
    'ORACLY is one universe — each corner a different experience. Sense where you want to go; you need not get lost here.',
    'ORACLY — одна вселенная. Каждый угол — иной опыт. Почувствуй, куда идти; здесь не нужно теряться.',
  ),
  'realm.portal': L10nTriple('Evren', 'Universe', 'Вселенная'),
  'realm.explore': L10nTriple('Keşfet', 'Explore', 'Открывать'),
  'realm.reflect': L10nTriple('Yansıt', 'Reflect', 'Отражать'),
  'realm.understand': L10nTriple('Anla', 'Understand', 'Понимать'),
  'realm.remember': L10nTriple('Hatırla', 'Remember', 'Помнить'),
  'realm.grow': L10nTriple('Büyü', 'Grow', 'Расти'),
  'realm.portal_hint': L10nTriple(
    'Günlük ritüel ve keşif kapısı',
    'Daily ritual and the door of discovery',
    'Ежедневный ритуал и дверь открытий',
  ),
  'realm.explore_hint': L10nTriple('Tarot ve aktif ritüeller', 'Tarot and active rituals', 'Таро и живые ритуалы'),
  'realm.reflect_hint': L10nTriple(
    'OR ile sohbet ve kişisel yansımalar',
    'Conversation with OR and personal reflections',
    'Разговор с OR и личные отражения',
  ),
  'realm.understand_hint': L10nTriple(
    'Rüya, yıldızname, astroloji',
    'Dream, star reading, astrology',
    'Сон, звёздная книга, астрология',
  ),
  'realm.remember_hint':
      L10nTriple('Geçmiş, günlük, hafıza', 'Past, journal, memory', 'Прошлое, дневник, память'),
  'realm.grow_hint': L10nTriple(
    'Başarımlar ve büyüme anları',
    'Achievements and moments of growth',
    'Достижения и мгновения роста',
  ),
};
