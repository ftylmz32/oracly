/// RC-003 — User-facing resilience copy: errors, loading, empty states.
library;

abstract final class ResilienceCopy {
  ResilienceCopy._();

  static const errorTitle = 'Bir anlık aksaklık';

  static const retryAction = 'Tekrar Dene';

  // Loading
  static const chatLoading = 'Sohbet hazırlanıyor…';
  static const memoryLoading = 'Hafıza yükleniyor…';
  static const historyLoading = 'Geçmiş yükleniyor…';
  static const splashLoading = 'ORACLY açılıyor…';
  static const genericLoading = 'Yükleniyor…';
  static const settingsLoading = 'Ayarlar yükleniyor…';
  static const achievementsLoading = 'Başarımlar yükleniyor…';
  static const profileLoading = 'Profil yükleniyor…';
  static const genericLoadFailed =
      'Yüklenemedi. Bir an sonra tekrar dene.';

  // Network / AI
  static const offline =
      'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
  static const slowResponse =
      'Yanıt beklenenden uzun sürüyor. Bir an bekle veya tekrar dene.';
  static const aiUnavailable =
      'OR şu an yanıt veremiyor. Biraz sonra tekrar dene.';
  static const aiConfigMissing =
      'OR henüz hazır değil. Lütfen daha sonra tekrar dene.';
  static const aiEmptyResponse =
      'OR boş bir yanıt döndü. Tekrar denemek ister misin?';
  static const aiResponseUnavailable =
      'Yanıt alınamadı. Biraz sonra tekrar deneyebilirsin.';

  // Tarot flow
  static const cardDrawFailed =
      'Kart seçilemedi. Lütfen tekrar dene.';
  static const sessionInitFailed =
      'Açılım başlatılamadı. Geri dönüp tekrar dene.';
  static const interpretationFailed =
      'Yorum şu an hazırlanamadı. Biraz sonra tekrar dene.';
  static const interpretationTimeout =
      'Yorum beklenenden uzun sürdü. Tekrar deneyebilirsin.';

  // Oracle
  static const oracleSendFailed =
      'OR yanıt veremedi. Tekrar dene.';
  static const oracleRegenerateFailed =
      'Yeniden oluşturulamadı. Tekrar dene.';

  // Empty states
  static const memoryEmptyTitle = 'Henüz bir hafıza yok';
  static const memoryEmptyBody =
      'OR, sohbetlerinden öğrendikçe burada nazikçe birikecek. '
      'İstediğin zaman silebilirsin.';
  static const chatHistoryEmptyTitle = 'Henüz sohbet geçmişi yok';
  static const chatHistoryEmptyBody =
      'OR ile konuşmaya başladığında geçmişin burada görünecek.';

  // Splash
  static const bootstrapFailed =
      'Uygulama açılırken küçük bir aksaklık oldu. Tekrar dene.';
  static const profileLoadFailed =
      'Profil yüklenemedi. Bir an sonra tekrar dene.';
}
