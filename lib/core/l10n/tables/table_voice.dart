/// Transparency, session ending, reading sections, universe nav — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nVoice = <String, L10nTriple>{
  'read.meaning': L10nTriple('Genel Yorum', 'General reading', 'Общее толкование'),
  'read.summary': L10nTriple('Açılımın Teması', 'Theme of the spread', 'Тема расклада'),
  'read.cards': L10nTriple('Kartların Mesajı', 'Message of the cards', 'Послание карт'),
  'read.love': L10nTriple('Aşk', 'Love', 'Любовь'),
  'read.career': L10nTriple('Kariyer', 'Career', 'Карьера'),
  'read.money': L10nTriple('Genel', 'General', 'Общее'),
  'read.spiritual': L10nTriple('Günlük', 'Daily', 'День'),
  'read.hidden': L10nTriple('Derin Mesaj', 'Deeper message', 'Глубинное послание'),
  'read.suggestion': L10nTriple('Bugün İçin Mesaj', 'A message for today', 'Послание на сегодня'),
  'read.lucky': L10nTriple('Şanslı Enerji', 'Fortunate energy', 'Благоприятная энергия'),
  'read.energy': L10nTriple('Genel Enerji', 'General energy', 'Общая энергия'),
  'read.possible': L10nTriple('Olası Gelişme', 'Possible development', 'Возможное развитие'),
  'read.obstacle': L10nTriple('Engel ve Sonuç', 'Obstacle and outcome', 'Препятствие и исход'),
  'read.love_other': L10nTriple('Karşı Taraf', 'The other person', 'Другая сторона'),
  'read.career_now': L10nTriple('Mevcut Durum', 'Present situation', 'Нынешнее положение'),
  'read.closing': L10nTriple('Sonuç', 'Closing', 'Итог'),
  'read.question': L10nTriple('Kendine Sor', 'Ask yourself', 'Спроси себя'),
  'end.title': L10nTriple('Son Yansıma', 'Lasting reflection', 'Последнее отражение'),
  'end.footer': L10nTriple(
    'Bu an seninle kalabilir. Acele etme — huzurla ayrılabilirsin.',
    'This moment can stay with you. There is no hurry — you may leave in peace.',
    'Этот миг может остаться с тобой. Спешки нет — можно уйти в покое.',
  ),
  'end.delete_title': L10nTriple('Bu yansımayı sil?', 'Delete this reflection?', 'Удалить это отражение?'),
  'end.delete_body': L10nTriple(
    'Okuma ve kişisel notun kalıcı olarak silinir. Geri alınamaz.',
    'The reading and your personal note will be deleted. This cannot be undone.',
    'Чтение и личная заметка будут удалены. Это необратимо.',
  ),
  'end.delete': L10nTriple('Sil', 'Delete', 'Удалить'),
  'end.dismiss': L10nTriple('Vazgeç', 'Dismiss', 'Отмена'),
  'trans.footnote': L10nTriple(
    'OR yorumları yansıma içindir — kehanet değil, düşünmek için bir davet. Kendi deneyimin en güvenilir rehberindir.',
    'OR readings are for reflection — not prediction, an invitation to think. Your own experience is the most trusted guide.',
    'Толкования OR — для размышления, не предсказание; приглашение думать. Твой опыт — самый надёжный проводник.',
  ),
  'nav.hint.home': L10nTriple('Evrenin kapısı', 'Door of the universe', 'Дверь вселенной'),
  'nav.hint.coffee': L10nTriple('Fincan ve yorum', 'Cup and reading', 'Чашка и толкование'),
  'nav.hint.astrology': L10nTriple(
    'Güneş burcu okuması',
    'Sun-sign reading',
    'Чтение солнечного знака',
  ),
  'nav.hint.star': L10nTriple(
    'Yerel · kişisel hikâye arşivi',
    'Local · personal story archive',
    'Локально · архив личной истории',
  ),
  'nav.hint.profile': L10nTriple('Hesap ve yolculuk', 'Account and journey', 'Аккаунт и путь'),
  'achievements.title': L10nTriple('Başarımlar', 'Achievements', 'Достижения'),
  'insights.retry': L10nTriple('TEKRAR DENE', 'TRY AGAIN', 'ЕЩЁ РАЗ'),
  'theme.insufficient': L10nTriple(
    'Henüz yeterli keşif birikmedi.',
    'Not enough discoveries have gathered yet.',
    'Пока недостаточно открытий.',
  ),
  'theme.accumulating': L10nTriple(
    'Keşiflerin biriktikçe sana özel bağlantılar daha görünür olacak.',
    'As discoveries gather, personal connections become clearer.',
    'По мере накопления открытий личные связи станут яснее.',
  ),
};
