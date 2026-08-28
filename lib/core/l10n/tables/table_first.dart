/// Remaining first-session and reading-flow phrases.
library;

import '../l10n_triple.dart';

const kL10nFirst = <String, L10nTriple>{
  'first.intention_title': L10nTriple(
    'Bugün ne düşünüyorsun?',
    'What are you thinking about today?',
    'О чём ты думаешь сегодня?',
  ),
  'first.intention_sub': L10nTriple(
    'Bir konu seç — zorunlu değil, sadece odak için. İstediğin zaman atlayabilirsin.',
    'Choose a theme — optional, only for focus. You can skip anytime.',
    'Выбери тему — не обязательно, лишь для фокуса. Можно пропустить.',
  ),
  'first.intention_title_d': L10nTriple('Odak için bir konu', 'A theme for focus', 'Тема для фокуса'),
  'first.intention_sub_d': L10nTriple(
    'İstersen bir konu seç — zorunlu değil.',
    'You may choose a theme — it is optional.',
    'Можно выбрать тему — это необязательно.',
  ),
  'first.shuffle': L10nTriple(
    'Kartlar karışıyor. Bir an nefes al.',
    'The cards are mixing. Take a breath.',
    'Карты перемешиваются. Вдохни.',
  ),
  'first.shuffle_d': L10nTriple('Kartlar hazırlanıyor…', 'The cards are preparing…', 'Карты готовятся…'),
  'first.card_title': L10nTriple('İlk kartın.', 'Your first card.', 'Твоя первая карта.'),
  'first.card_sub': L10nTriple(
    'Sezgine güven — doğru ya da yanlış kart yok.',
    'Trust your sense — there is no right or wrong card.',
    'Доверься чутью — нет верной или неверной карты.',
  ),
  'first.card_title_d': L10nTriple('Seni çağıran kartı seç.', 'Choose the card that calls you.', 'Выбери карту, которая зовёт.'),
  'first.card_sub_d': L10nTriple('Sezgilerine güven.', 'Trust your intuition.', 'Доверься интуиции.'),
  'first.reveal': L10nTriple('Yorumuna geç', 'Continue to the reading', 'Перейти к толкованию'),
  'first.reveal_d': L10nTriple('Yorumu Gör', 'See the reading', 'Смотреть толкование'),
  'first.breath': L10nTriple('Bir an nefes al…', 'Take a breath…', 'Вдохни…'),
  'first.prep_first': L10nTriple(
    'Bu bir kehanet değil — düşünmek için bir davet.',
    'This is not a prediction — an invitation to think.',
    'Это не предсказание — приглашение думать.',
  ),
  'first.prep_d': L10nTriple(
    'Yorumun sakin bir tempoda açılıyor.',
    'Your reading opens at a calm pace.',
    'Толкование открывается спокойным темпом.',
  ),
  'home.hello_named': L10nTriple(
    'Hoş geldin, {name} ✨',
    'Welcome, {name} ✨',
    'Добро пожаловать, {name} ✨',
  ),
  'flow.session_missing': L10nTriple(
    'Açılım oturumu bulunamadı. Lütfen yeniden başla.',
    'The spread session was not found. Please start again.',
    'Сеанс расклада не найден. Пожалуйста, начни снова.',
  ),
  'flow.reading_missing': L10nTriple(
    'Yorum yüklenemedi. Açılım oturumu sona ermiş olabilir.',
    'The reading could not load. The spread session may have ended.',
    'Толкование не загрузилось. Сеанс расклада мог завершиться.',
  ),
};
