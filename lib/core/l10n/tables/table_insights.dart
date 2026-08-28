/// Personal insights chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nInsights = <String, L10nTriple>{
  'insights.title': L10nTriple('Kişisel Yansımalar', 'Personal reflections', 'Личные отражения'),
  'insights.salutation': L10nTriple(
    'Merhaba — kaydettiğin anlardan, yalnızca gözlemlenebilir desenler çıkardık. Bunlar bir yargı değil; kendi yolculuğuna nazikçe bakman için bir davet.',
    'Hello — from the moments you saved, we drew only observable patterns. This is not a verdict; it is a gentle invitation to look at your own path.',
    'Здравствуй — из сохранённых мгновений мы взяли только наблюдаемые узоры. Это не приговор, а мягкое приглашение взглянуть на свой путь.',
  ),
  'insights.closing': L10nTriple(
    'Bu yansımalar senin — istediğin zaman gizleyebilir, yenileyebilir veya dışa aktarabilirsin.',
    'These reflections are yours — you can hide, refresh, or export them anytime.',
    'Эти отражения твои — их можно скрыть, обновить или выгрузить в любой момент.',
  ),
  'insights.empty_title': L10nTriple(
    'İlk yansımaların burada yerini bulacak.',
    'Your first reflections will find their place here.',
    'Твои первые отражения найдут здесь своё место.',
  ),
  'insights.empty_body': L10nTriple(
    'Tarot açılımları, rüya kayıtları veya kişisel notlar ekledikçe burada nazik bir özet belirecek — acele yok.',
    'As tarot spreads, dream notes, or personal notes are added, a gentle summary will appear here — there is no hurry.',
    'По мере добавления раскладов Таро, записей снов или личных заметок здесь появится мягкое резюме — спешки нет.',
  ),
  'insights.privacy': L10nTriple('Bu yansıma senin', 'This reflection is yours', 'Это отражение твоё'),
  'insights.hide': L10nTriple('Gizle', 'Hide', 'Скрыть'),
  'insights.delete': L10nTriple('Sil', 'Delete', 'Удалить'),
  'insights.regen': L10nTriple('Yeniden oluştur', 'Regenerate', 'Создать заново'),
  'insights.export': L10nTriple('Dışa aktar', 'Export', 'Выгрузить'),
  'insights.hidden': L10nTriple('Yansıma gizlendi.', 'The reflection was hidden.', 'Отражение скрыто.'),
  'insights.deleted': L10nTriple('Yansıma silindi.', 'The reflection was deleted.', 'Отражение удалено.'),
  'insights.regen_ok': L10nTriple('Yansımalar yenilendi.', 'Reflections were refreshed.', 'Отражения обновлены.'),
  'insights.exported': L10nTriple('Metin panoya kopyalandı.', 'The text was copied to the clipboard.', 'Текст скопирован в буфер.'),
  'insights.delete_prompt': L10nTriple(
    'Bu yansımayı kalıcı olarak kaldırmak istiyor musun? Gelecekte yeniden oluşturulmayacak.',
    'Do you want to remove this reflection permanently? It will not be generated again later.',
    'Хочешь навсегда убрать это отражение? Позже оно не будет создано снова.',
  ),
  'insights.export_header': L10nTriple(
    'ORACLY — Kişisel Yansımalar',
    'ORACLY — Personal reflections',
    'ORACLY — Личные отражения',
  ),
  'insights.patterns': L10nTriple('Tekrar eden desenler', 'Recurring patterns', 'Повторяющиеся узоры'),
};
