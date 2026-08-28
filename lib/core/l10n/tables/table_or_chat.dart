/// OR conversation extras — suggestions and empty states.
library;

import '../l10n_triple.dart';

const kL10nOrChat = <String, L10nTriple>{
  'or.empty_title': L10nTriple('Bu okuma hâlâ seninle.', 'This reading is still with you.', 'Это чтение всё ещё с тобой.'),
  'or.empty_body': L10nTriple(
    'Az önce aldığın yorumun ışığında sorunu sorabilirsin.',
    'You can ask in the light of the reading you just received.',
    'Можешь спросить в свете только что полученного толкования.',
  ),
  'or.sug.tarot.0': L10nTriple('Bu açılımın en önemli mesajı ne?', "What is this spread's most important message?", 'Какое самое важное послание этого расклада?'),
  'or.sug.tarot.1': L10nTriple('Aşk açısından ne söylüyor?', 'What does it say about love?', 'Что это говорит о любви?'),
  'or.sug.tarot.2': L10nTriple('En çok hangi karta dikkat etmeliyim?', 'Which card should I notice most?', 'На какую карту обратить внимание больше всего?'),
  'or.sug.coffee.0': L10nTriple('Falımda en dikkat çeken sembol ne?', 'Which symbol stands out in my cup?', 'Какой символ выделяется в чашке?'),
  'or.sug.coffee.1': L10nTriple('Aşk konusunda ne görünüyor?', 'What appears around love?', 'Что видно вокруг любви?'),
  'or.sug.coffee.2': L10nTriple('Yakın dönem için mesaj ne?', 'What is the near-term message?', 'Какое послание на ближайшее время?'),
  'or.sug.dream.0': L10nTriple('Bu rüyadaki en önemli sembol ne?', "What is this dream's most important symbol?", 'Какой самый важный символ этого сна?'),
  'or.sug.dream.1': L10nTriple('Bu rüyanın duygusal teması ne?', "What is this dream's emotional theme?", 'Какая эмоциональная тема этого сна?'),
  'or.sug.dream.2': L10nTriple('Bu rüyadan ne çıkarabilirim?', 'What can I take from this dream?', 'Что я могу вынести из этого сна?'),
  'or.sug.astro.0': L10nTriple('Bugün benim için en önemli tema ne?', 'What is the most important theme for me today?', 'Какая сегодня самая важная тема для меня?'),
  'or.sug.astro.1': L10nTriple('Aşk hayatım açısından ne söylüyor?', 'What does it say about my love life?', 'Что это говорит о моей любви?'),
  'or.sug.astro.2': L10nTriple('Bugün nelere dikkat etmeliyim?', 'What should I notice today?', 'На что сегодня обратить внимание?'),
  'or.sug.chart.0': L10nTriple('Haritamdaki en güçlü tema ne?', "What is the strongest theme in my chart?", 'Какая самая сильная тема в моей карте?'),
  'or.sug.chart.1': L10nTriple('İlişkiler açısından ne öne çıkıyor?', 'What stands out around relationships?', 'Что выделяется в отношениях?'),
  'or.sug.chart.2': L10nTriple('Kariyer açısından ne söylüyor?', 'What does it say about career?', 'Что это говорит о карьере?'),
  'or.coffee_empty_title': L10nTriple('Bu fincan hâlâ seninle.', 'This cup is still with you.', 'Эта чашка всё ещё с тобой.'),
  'or.coffee_empty_body': L10nTriple(
    'Az önce aldığın kahve yorumunun ışığında sorunu sorabilirsin.',
    'You can ask in the light of the coffee reading you just received.',
    'Можешь спросить в свете только что полученного кофейного толкования.',
  ),
  'or.dream_empty_title': L10nTriple('Bu rüya hâlâ seninle.', 'This dream is still with you.', 'Этот сон всё ещё с тобой.'),
  'or.dream_empty_body': L10nTriple(
    'Rüyanın sembolleri ve duygusu üzerinden sorabilirsin.',
    'You can ask through the dream’s symbols and feeling.',
    'Можешь спросить через символы и чувство сна.',
  ),
  'or.astro_empty_title': L10nTriple('Bu yorum hâlâ seninle.', 'This reading is still with you.', 'Это толкование всё ещё с тобой.'),
  'or.astro_empty_body': L10nTriple(
    'Bugünkü burç yorumunun ışığında sorunu sorabilirsin.',
    'You can ask in the light of today’s sign reading.',
    'Можешь спросить в свете сегодняшнего чтения знака.',
  ),
  'or.chart_empty_title': L10nTriple('Bu harita hâlâ seninle.', 'This chart is still with you.', 'Эта карта всё ещё с тобой.'),
  'or.chart_empty_body': L10nTriple(
    'Haritandaki temalar üzerinden sorabilirsin.',
    'You can ask through the themes in your chart.',
    'Можешь спросить через темы своей карты.',
  ),
};
