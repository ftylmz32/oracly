/// Fincan Haritası copy (Turkish — Coffee V3 is Turkish-only). Every line
/// describes what the USER does; nothing claims ORACLY found a symbol.
library;

import '../../coffee_v3/models/coffee_v3_photo_slot.dart';

abstract final class CoffeeCupMapCopy {
  CoffeeCupMapCopy._();

  static const title = 'Fincan Haritası';

  static const entryBody =
      'Bu falın okunduğu üç fotoğrafa geri dön. '
      'Gözüne takılan yerleri kendin işaretle, istersen not düş.';
  static const entryOpen = 'Haritayı aç';
  static String entryCount(int pins) =>
      pins == 0 ? 'Henüz işaretin yok' : '$pins işaretin var';

  /// One short line on the map; the full detail is in [helpBody].
  static const intro = 'İşaretleri sen koyarsın, yalnızca sende kalır.';

  static const helpOpen = 'Fincan Haritası hakkında';
  static const helpTitle = 'Fincan Haritası';
  static const helpBody =
      'Falın bu üç fotoğrafla okundu. Buradaki işaretleri ve notları yalnızca '
      'sen koyarsın; ORACLY fotoğrafa sembol yerleştirmez.\n\n'
      'Dokunarak işaret koy, iki parmakla yakınlaştır. İşaretlerin ve '
      'notların yalnızca bu cihazda kalır; bu falın haritasını istediğin an '
      'silebilirsin.';
  static const helpClose = 'Tamam';
  /// Shown on the photo while it has no pins yet.
  static const gestureHint = 'Dokunarak işaret koy, iki parmakla yakınlaştır';
  static const photoLoading = 'Fotoğraf hazırlanıyor';

  static String photoLabel(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupViewA => 'Fincan 1',
        CoffeeV3PhotoSlot.cupViewB => 'Fincan 2',
        CoffeeV3PhotoSlot.saucer => 'Tabak',
      };

  /// Strip tab, read in full by screen readers (the visual label is short).
  static String tabSemantics(String label, int pins, {bool missing = false}) =>
      missing ? '$label, fotoğraf cihazda yok, $pins işaret' : '$label, $pins işaret';

  static String photoSemantics(CoffeeV3PhotoSlot slot, int pins) =>
      '${photoLabel(slot)} fotoğrafı, $pins işaret. '
      'İşaret koymak için iki kez dokun.';

  static const pinAtCenter = 'Ortaya işaret koy';
  static const resetZoom = 'Yakınlaştırmayı sıfırla';

  static String pinName(int number) => 'İşaret $number';
  static const noNote = 'Not yok';
  static String pinSemantics(int number, String? note) =>
      note == null || note.isEmpty
          ? '${pinName(number)}, not yok. Düzenlemek için dokun.'
          : '${pinName(number)}, not: $note. Düzenlemek için dokun.';

  static const listTitle = 'İşaretlerin';
  static const listEmpty =
      'Bu fotoğrafta henüz işaretin yok. Dikkatini çeken bir yere dokun.';

  static const noteTitle = 'Bu işaret için notun';
  static const noteHint = 'Ne gördün? (isteğe bağlı)';
  static const noteSave = 'Kaydet';
  static const noteDelete = 'İşareti sil';
  static const noteClose = 'Kapat';

  static const samePlace = 'Burada zaten bir işaretin var.';
  static const limitReached = 'Bu fotoğrafa en fazla 12 işaret koyabilirsin.';
  static const saveFailed = 'Kaydedilemedi. Tekrar dener misin?';

  static const consentTitle = 'Fincan Haritası için fotoğraflarımı sakla';
  static const consentBody =
      'Açıkken, tamamlanan Kahve Falı\'nın üç fotoğrafı yalnızca bu cihazda '
      'tutulur; fala dönüp gözüne takılan yerleri işaretleyebilirsin. '
      'Kapalıyken fotoğraflar, falın hazır olunca cihazdan silinir.';
  static const consentFacts =
      'Bu seçim, fotoğrafların fal için gönderilmesini değiştirmez; fal iki '
      'durumda da aynı okunur. Fotoğraflar, işaretlerin ve notların '
      'uygulamanın bu cihazdaki kendi alanında kalır; buluta eşitlenmez, cihaz '
      'yedeklerine alınmaz. Telefon değiştirirsen ya da uygulamayı silersen '
      'geri gelmez. Her falın haritasını istediğin an silebilirsin.';
  static const consentFuture = 'Bu ayar bundan sonra tamamlanan fallar için geçerli.';

  static const deleteMap = 'Bu falın haritasını sil';
  static const deleteConfirmTitle = 'Fincan Haritası silinsin mi?';
  static const deleteConfirmBody =
      'Bu falın üç fotoğrafı, işaretlerin ve notların bu cihazdan silinir. '
      'Fal yorumun silinmez.';
  static const deleteConfirm = 'Sil';
  static const deleteCancel = 'Vazgeç';
  static const deleteFailed =
      'Fotoğraflar silinemedi; harita yerinde duruyor. Tekrar dener misin?';
  static const deleted = 'Fincan Haritası silindi.';

  static const photoMissing =
      'Bu fotoğraf artık cihazında değil. İşaretlerin listede duruyor.';
  static const mapUnavailable =
      'Bu fal için fotoğraf haritası yok. '
      'Harita yalnızca üç fotoğrafla okunan yeni kahve fallarında açılır.';
  static const back = 'Geri dön';
}
