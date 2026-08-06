/// EPIC-014 — Trust through transparency: shared communication copy.
library;

/// Quiet, honest language — earns trust without policy walls.
abstract final class TransparencyCopy {
  TransparencyCopy._();

  /// Shown beneath AI interpretations.
  static const interpretationFootnote =
      'OR yorumları yapay zekâ ile oluşturulur — kehanet değil, '
      'düşünmek için bir davet. Kendi deneyimin en güvenilir rehberindir.';

  /// Shorter variant for tight spaces.
  static const interpretationBrief =
      'Yansıtma amaçlıdır — kesin bir gerçek iddiası değildir.';

  /// Oracle follow-up and general chat.
  static const conversationCaption =
      'OR yanıtları rehberlik içindir; kararların senin.';

  /// Personal journal notes.
  static const journalPrivacy =
      'Kişisel notların yalnızca senin cihazında kalır — sana aittir.';

  /// Empty journal prompt.
  static const journalEmptyPrompt =
      'Bu okumaya kısa bir not ekleyebilirsin — sadece sana ait, '
      'istediğin zaman düzenleyebilir veya silebilirsin.';

  /// History archive header extension.
  static const journeyOwnership =
      'Sessiz bir arşiv — yalnızca senin cihazında, senin ritminle.';

  /// Insight journal footnote (recurring themes).
  static const insightFootnote =
      'Bunlar kehanet değil — sadece kendi ritminin yansımaları.';

  /// Privacy screen intro.
  static const privacyIntro =
      'ORACLY kişisel yansımalarını cihazında saklar. '
      'Yapay zekâ yorumları rehberlik içindir; profesyonel tıbbi, '
      'hukuki veya mali danışmanlık yerine geçmez. '
      'Verilerin üzerinde tam kontrol sende.';

  /// About screen boundary.
  static const aboutBoundary =
      'OR, yansıtma ve içgörü için tasarlandı — geleceği bildirmek için değil.';

  /// Delete reading confirmation.
  static const deleteReadingTitle = 'Bu yansımayı sil?';
  static const deleteReadingBody =
      'Okuma ve kişisel notun kalıcı olarak silinir. Geri alınamaz.';
  static const deleteReadingConfirm = 'Sil';
  static const deleteReadingCancel = 'Vazgeç';

  /// Memory item delete confirmation.
  static const memoryDeleteTitle = 'Bu hafızayı sil?';
  static const memoryDeleteBody =
      'OR bu bilgiyi unutur. Geri alınamaz.';
  static const memoryDeleteConfirm = 'Sil';
  static const memoryDeleteCancel = 'Vazgeç';

  /// Privacy action confirmations (snackbar).
  static const journalCleared = 'Tarot günlüğü temizlendi.';
  static const memoryCleared = 'Hafıza temizlendi.';
  static const chatHistoryCleared = 'Sohbet geçmişi temizlendi.';
  static const allDataReset = 'Tüm veriler sıfırlandı.';
}
