/// SPRINT-004 — Calm, letter-like copy for Personal Insights.
library;

abstract final class PersonalInsightsCopy {
  PersonalInsightsCopy._();

  static const screenTitle = 'Kişisel Yansımalar';

  static const salutation =
      'Merhaba — kaydettiğin anlardan, yalnızca gözlemlenebilir '
      'desenler çıkardık. Bunlar bir yargı değil; kendi yolculuğuna '
      'nazikçe bakman için bir davet.';

  static const closingNote =
      'Bu yansımalar senin — istediğin zaman gizleyebilir, '
      'yenileyebilir veya dışa aktarabilirsin.';

  static const emptyTitle = 'Henüz bir yansıma birikmedi';

  static const emptyBody =
      'Tarot açılımları, rüya kayıtları veya kişisel notlar '
      'ekledikçe burada nazik bir özet belirecek — acele yok.';

  static const footnote =
      'Bunlar kehanet değil — sadece kendi ritminin yansımaları.';

  static const privacyTitle = 'Bu yansıma senin';

  static const hideAction = 'Gizle';
  static const deleteAction = 'Sil';
  static const regenerateAction = 'Yeniden oluştur';
  static const exportAction = 'Dışa aktar';

  static const hiddenConfirmation = 'Yansıma gizlendi.';
  static const deletedConfirmation = 'Yansıma silindi.';
  static const regeneratedConfirmation = 'Yansımalar yenilendi.';
  static const exportedConfirmation = 'Metin panoya kopyalandı.';

  static const deletePrompt =
      'Bu yansımayı kalıcı olarak kaldırmak istiyor musun? '
      'Gelecekte yeniden oluşturulmayacak.';

  static const exportHeader = 'ORACLY — Kişisel Yansımalar';
}
