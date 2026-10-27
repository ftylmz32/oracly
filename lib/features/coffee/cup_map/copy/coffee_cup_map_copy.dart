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

  static const intro =
      'Falın bu üç fotoğrafla okundu. '
      'Buradaki işaretler yalnızca senin; ORACLY fotoğrafa sembol yerleştirmez.';
  static const gestureHint =
      'İki parmakla yakınlaştır ve kaydır. İşaret koymak için fotoğrafa dokun.';

  static String photoLabel(CoffeeV3PhotoSlot slot) => switch (slot) {
        CoffeeV3PhotoSlot.cupViewA => 'Fincan 1',
        CoffeeV3PhotoSlot.cupViewB => 'Fincan 2',
        CoffeeV3PhotoSlot.saucer => 'Tabak',
      };

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

  static const photoMissing =
      'Bu fotoğraf artık cihazında değil. İşaretlerin listede duruyor.';
  static const mapUnavailable =
      'Bu fal için fotoğraf haritası yok. '
      'Harita yalnızca üç fotoğrafla okunan yeni kahve fallarında açılır.';
  static const back = 'Geri dön';
}
