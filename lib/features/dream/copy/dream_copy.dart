/// SPRINT-001 — Dream Analysis user-facing copy.
library;

abstract final class DreamCopy {
  DreamCopy._();

  // Entry
  static const screenTitle = 'Rüya Analizi';
  static const entryHeadline = 'Rüyanı kaydet';
  static const entryDescription =
      'Anlat; önce dinleyelim, sonra birlikte düşünelim.';
  static const narrativeHint = 'Rüyanı olduğu gibi anlat…';
  static const narrativeTooShort = 'Rüyanı biraz daha detaylı anlat.';
  static const emotionsLabel = 'Hissettiklerin';
  static const tagsLabel = 'Etiketler (isteğe bağlı)';
  static const tagHint = 'Etiket ekle';
  static const voiceLabel = 'Sesle kaydet';
  static const voiceComingSoon = 'Yakında — ses kaydı bu alana eklenecek.';
  static const beginAnalysis = 'Anlamlandır';
  static const saveAndClose = 'Kaydet ve kapat';

  // Phases
  static const phaseUnderstanding = 'Rüyanın haritası';
  static const phaseUnderstandingSubtitle =
      'Önce neyin öne çıktığını düzenliyoruz — henüz yorum yok.';
  static const phaseReflection = 'Düşünmek için alan';
  static const phaseReflectionSubtitle =
      'Olasılıklar; kesin cevaplar değil.';
  static const phaseConnection = 'Önceki rüyalarla bağ';
  static const phaseConnectionSubtitle =
      'Yalnızca gerçek tekrarlar varsa gösterilir.';
  static const phaseClosing = 'Kapanış';

  // Understanding sections
  static const symbolsTitle = 'Semboller';
  static const emotionsTitle = 'Duygular';
  static const locationsTitle = 'Mekânlar';
  static const relationshipsTitle = 'İlişkiler';
  static const recurringTitle = 'Tekrarlayan imgeler';
  static const noSymbols = 'Belirgin sembol tespit edilmedi.';
  static const noLocations = 'Belirgin mekân tespit edilmedi.';
  static const noRelationships = 'Belirgin ilişki tespit edilmedi.';
  static const noRecurring = 'Bu rüyada belirgin tekrar yok.';

  // Loading
  static const organizing = 'Rüyan düzenleniyor…';
  static const reflecting = 'Düşünce alanı hazırlanıyor…';

  // Closing labels
  static const reflectiveQuestion = 'Sana bir soru';
  static const calmingTakeaway = 'Sakin bir not';

  // History
  static const previousDreams = 'Önceki rüyalar';
  static const noPreviousDreams = 'Henüz kayıtlı rüya yok.';
}
