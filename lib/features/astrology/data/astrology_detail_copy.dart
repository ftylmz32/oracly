/// Extra sign-aware Turkish copy — energy, emotion, opportunity, caution.
library;

class AstrologyDetailFields {
  const AstrologyDetailFields({
    required this.energy,
    required this.emotion,
    required this.opportunity,
    required this.caution,
  });

  final String energy;
  final String emotion;
  final String opportunity;
  final String caution;
}

abstract final class AstrologyDetailCopy {
  AstrologyDetailCopy._();

  static AstrologyDetailFields forId(String id) =>
      _byId[id] ?? _byId['aries']!;

  static const _byId = <String, AstrologyDetailFields>{
    'aries': AstrologyDetailFields(
      energy:
          'Beden hareket istiyor. Kısa bir yürüyüş veya net bir spor, iç ateşi dengeler.',
      emotion:
          'İçeride duran, öfkeyi karşıya savurmak değil. Bugünkü tempo seni biraz erken konuşturuyor olabilir; bir nefes, sonra cümle.',
      opportunity:
          'Cesur bir teklif veya ilk adım kapısı açık. Küçük, görünür bir hamle yeter.',
      caution:
          'Acele karar ve keskin dil bugün iz bırakır. Bir nefes, sonra konuş.',
    ),
    'taurus': AstrologyDetailFields(
      energy:
          'Ritim yavaş ama sağlam. Uyku ve düzenli öğün, dayanıklılığını korur.',
      emotion:
          'Güven arayışı belirgin durur. İnatlaşma yerine tutarlı bir yakınlık seç.',
      opportunity:
          'Kalıcı bir iş veya birikim adımı kazandırır. Acele değişimi ertele.',
      caution:
          'Konfor adına erteleme tuzağı var. Bir küçük adımı bugün tamamla.',
    ),
    'gemini': AstrologyDetailFields(
      energy:
          'Zihin hızlı, sinir sistemi yorulabilir. Ekranı kes, nefes al.',
      emotion:
          'Merak ve dağınıklık birlikte gelir. Bir duyguyu sonuna kadar taşı.',
      opportunity:
          'Net bir konuşma veya yazı kapısı açık. Dağınık sohbeti eleme.',
      caution:
          'Her mesaja cevap yetiştirmeye çalışma. Sözü yarım bırakma.',
    ),
    'cancer': AstrologyDetailFields(
      energy:
          'Hassasiyet yüksek. Sıcak bir iç alan ve erken uyku seni toparlar.',
      emotion:
          'Koruma içgüdüsü güçlü. İçine kapanmadan ihtiyacını sakin söyle.',
      opportunity:
          'Yakın bir bağ veya ev düzeni iyileşebilir. Küçük bir bakım jesti yeter.',
      caution:
          'Her duyguyu fırtınaya çevirme. Sınır koymak soğukluk değildir.',
    ),
    'leo': AstrologyDetailFields(
      energy:
          'Işık açık; kalp ritmini zorlama. Paylaş, ama sahneyi sürekli isteme.',
      emotion:
          'Gurur ve cömertlik birlikte. Onay beklemeden sıcak dur.',
      opportunity:
          'Görünür bir iş veya yaratıcı paylaşım desteklenir. Bir başarıyı sun.',
      caution:
          'Ego sürtünmesi kolay alevlenir. Alkış için risk alma.',
    ),
    'virgo': AstrologyDetailFields(
      energy:
          'Zihin detayda takılı. Bedeni hareketle boşalt; listeyi kısalt.',
      emotion:
          'Eleştiri iç sesi yüksek. Kusursuzluk değil, işleyen düzen ara.',
      opportunity:
          'Tek net teslim veya sadeleştirme kazandırır. Yeni liste açma.',
      caution:
          'Kendine ve başkasına fazla yüklenme. Küçük hatayı büyüteçleme.',
    ),
    'libra': AstrologyDetailFields(
      energy:
          'Denge aranıyor. Ortamı sadeleştirmek sinir sistemini rahatlatır.',
      emotion:
          'Kararsızlık yorabilir. Adil bir seçim, herkesi memnun etmekten iyi.',
      opportunity:
          'Uyum ve iş birliği kapısı açık. Bir tercihi bugün kapat.',
      caution:
          'Erteleme zarafet değildir. İki seçeneği birden taşıma.',
    ),
    'scorpio': AstrologyDetailFields(
      energy:
          'Yoğunluk yüksek. Su, sessizlik veya kısa yalnızlık denge getirir.',
      emotion:
          'Derinlik ve şüphe birlikte. Test etmek yerine dürüst bir cümle kur.',
      opportunity:
          'Eski bir kalıbı bırakmak güçlendirir. Tek katmanı açman yeter.',
      caution:
          'Kontrol ve kıskançlık iz bırakır. Perde arkasını kurcalama.',
    ),
    'sagittarius': AstrologyDetailFields(
      energy:
          'Hareket iyi gelir. Açık hava veya kısa bir yol, zihni genişletir.',
      emotion:
          'Özgürlük ihtiyacı yüksek. Kaçmadan yer bırak; sözünü tut.',
      opportunity:
          'Öğrenme veya yeni bir yön kapısı açık. Bir fikri uygula.',
      caution:
          'Her yere aynı anda koşma. Dağınık iyimserlik bütçeyi de zorlar.',
    ),
    'capricorn': AstrologyDetailFields(
      energy:
          'Tempo düşebilir. Dinlenmek planı korur; yavaşlığı küçümseme.',
      emotion:
          'Sorumluluk ağır gelebilir. Duyguyu erteleme; kısa bir yakınlık yeter.',
      opportunity:
          'Uzun vadeli bir milestone bitirmek kazandırır. Yeni dağ açma.',
      caution:
          'Her yükü tek başına alma. Gösterişli risk bugün uygun değil.',
    ),
    'aquarius': AstrologyDetailFields(
      energy:
          'Zihin taze, beden kopuk kalabilir. Kısa hareketle yere in.',
      emotion:
          'Mesafe ve bağımsızlık belirgin durur. Kopmadan alan tut.',
      opportunity:
          'Yenilik ve topluluk fikri desteklenir. Bir prototipi paylaş.',
      caution:
          'İnsanı sistem gibi görme. Ortak kararı tek başına alma.',
    ),
    'pisces': AstrologyDetailFields(
      energy:
          'Sezgi açık, sınır zayıf. Su ve erken uyku seni toplar.',
      emotion:
          'Şefkat ve sis birlikte. Hayali ilişkiyi gerçek cümleyle yere indir.',
      opportunity:
          'Sanat, bakım veya sezgisel bir teslim işe yarar. Somutla bağla.',
      caution:
          'Kaçış ve teselli harcaması kolay açılır. Yumuşak ol, silik olma.',
    ),
  };
}
