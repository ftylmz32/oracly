/// Data catalog — sign-aware Turkish daily astrology copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../content/astrology/models/astrology_content.dart';

part 'astrology_daily_copy_en.dart';
part 'astrology_daily_copy_ru.dart';

class AstrologySignDayCopy {
  const AstrologySignDayCopy({
    required this.overall,
    required this.love,
    required this.career,
    required this.money,
    required this.advice,
  });

  final List<String> overall;
  final String love;
  final String career;
  final String money;
  final String advice;
}

abstract final class AstrologyDailyCopy {
  AstrologyDailyCopy._();

  static String personality(ZodiacSignContent sign) {
    return OraclyL10n.t('fortune.astro.personality')
        .replaceAll('{sign}', OraclyL10n.t('zodiac.${sign.id}'));
  }

  static AstrologySignDayCopy forId(String id) {
    final pack = switch (OraclyL10n.code) {
      'en' => kAstrologyDailyEn,
      'ru' => kAstrologyDailyRu,
      _ => _byId,
    };
    return pack[id] ?? pack['aries']!;
  }

  static const _byId = <String, AstrologySignDayCopy>{
    'aries': AstrologySignDayCopy(
      overall: [
        'Koç, bugün tempo yüksek. Cesaretin açık; acele büyük karar yerine tek görünür adım daha doğru.',
        'Koç, bugün yön netleşiyor. Dikkatini bir hedefe kilitle; dağınık savaşma.',
        'Koç, bugün iç ateşi koru. Kısa bir durak, yarınki hamleni güçlendirir.',
      ],
      love:
          'Yakınlıkta tahmin oyunu seni yoruyor. Ne istediğini tek cümlede söylemek '
          'karşı tarafın aklını okumaktan daha temiz. Bunu kesin bir evet-hayır gibi '
          'okumuyorum; bağdaki ısının düşmesi, söylenmeyen yerde duruyor.',
      career:
          'Görünmek istiyorsun, üç işi birden açmak değil. Tek teslim, dağınık cesaretten '
          'daha ileri götürür. Asıl mesele önde durmak değil, durduğun işi bitirmek.',
      money:
          'Harcama isteği yüksek. Büyük riski ertele, eldeki kaynağı toparla.',
      advice: 'Bugün bir işi tamamla. Yarım kalanları çoğaltma.',
    ),
    'taurus': AstrologySignDayCopy(
      overall: [
        'Boğa, bugün istikrar kazandırır. Acele değişim değil; eldeki düzeni sağlamlaştır.',
        'Boğa, bugün emek görünür olur. Kaliteye yatırım yap; yüzeysel işe zaman verme.',
        'Boğa, bugün beden ve ritim önemli. Yavaşlamak köklerini toparlar; tempo düşük diye küçümseme.',
      ],
      love:
          'Güven ve dokunuş bağda asıl mesele. Sadakati sözle değil, tutarlı hallerle göster.',
      career:
          'İstikrarlı üretim kazandırır. Bir işi iyi bitirmek, beşini yarım bırakmaktan daha değerli.',
      money: 'Harcama isteği yüksek. Büyük riski ertele, eldeki kaynağı toparla.',
      advice: 'Bugün ritmini koru. Ani sapma yerine bildiğin sağlam adımı at.',
    ),
    'gemini': AstrologySignDayCopy(
      overall: [
        'İkizler, bugün yarım kalmış bir konuşmanın yeniden '
            'açılması veya ertelediğin bir kararı adlandırmak asıl duran yer.',
        'İkizler, bugün zihin hızlı. Sözün net olsun; her mesaja cevap '
            'vermek zorunda değilsin, bir konuyu derinleştir.',
        'İkizler, bugün dağınık sohbet dikkati böler. Tek net cümle, '
            'on kapıyı aralamaktan daha işe yarar.',
      ],
      love:
          'Sohbet bağ kurar. Merakını paylaş; ama sözü yarım bırakıp kaçma.',
      career:
          'Çok iş aynı anda cazip. Önce birini teslim et; hızın dağınık görünmesin.',
      money:
          'Ani fikirle harcama cazip. Kararı bir gece beklet, sonra netleştir.',
      advice: 'Bugün tek net cümle kur. Fazla kapı açma.',
    ),
    'cancer': AstrologySignDayCopy(
      overall: [
        'Yengeç, bugün sezgi güçlü. İç sesini yok sayma; ama her duyguyu fırtınaya çevirme.',
        'Yengeç, bugün yuva ve düzen seçilir durur. Yakın çevreni toparlamak seni dengeler.',
        'Yengeç, bugün hassasiyet yüksek. Kendine yer bırak; her şeyi taşımak zorunda değilsin.',
      ],
      love:
          'Derin bağ istiyorsun. İhtiyacını dolaylı imayla değil, sakin cümleyle söyle.',
      career:
          'Destekleyici rolün görünür. Sınırını da koy; her yükü almak yormasın.',
      money:
          'Güvenlik ihtiyacı belirgin durur. Acil olmayan harcamayı ertele, rezervi koru.',
      advice: 'Bugün bir yakınını dinle, kendini de boşlama.',
    ),
    'leo': AstrologySignDayCopy(
      overall: [
        'Aslan, bugün ışığın açık. Görünmek doğru; sahneyi sürekli istemek değil.',
        'Aslan, bugün yaratım kazandırır. Bir işe yüreğini koy, yarım alkış bekleme.',
        'Aslan, bugün kalbi dinlendir. Her bakışı onay sanma; kendi ritmini tut.',
      ],
      love:
          'Sıcaklık ve sadakat bağda asıl mesele. Sevgiyi göster; ama karşılık için sahne kurma.',
      career:
          'Liderlik isteği yüksek. Görünür dur, fakat her ayrıntıyı tek başına kontrol etme.',
      money:
          'Cömertlik açık. Keyif için harca, gösteriş için değil.',
      advice: 'Bugün bir başarıyı paylaş. Sessiz kalma, abartma da.',
    ),
    'virgo': AstrologySignDayCopy(
      overall: [
        'Başak, bugün düzen işe yarar. Kusursuzluk değil; işleyen bir sistem kur.',
        'Başak, bugün detay kazandırır. Bir işi temiz bitir; yeni liste açma.',
        'Başak, bugün zihni yumuşat. Her hatayı düzeltmek zorunda değilsin.',
      ],
      love:
          'Güven, küçük tutarlılıkta büyür. Eleştiriyi öğüt gibi sunma; yakınlık kırılır.',
      career:
          'Uzmanlığın görünür. Tek net teslim, dağınık mükemmeliyetten daha değerlidir.',
      money:
          'Hesap tut. Küçük sızıntıları kapat; büyük riski bugün açma.',
      advice: 'Bugün bir işi sadeleştir. Fazlalığı çıkar.',
    ),
    'libra': AstrologySignDayCopy(
      overall: [
        'Terazi, bugün denge aranıyor. Herkesi memnun etmek değil; adil bir seçim yap.',
        'Terazi, bugün ilişki ve uyum asıl mesele. Net dur; kararsızlık yorar.',
        'Terazi, bugün güzellik ve ritim iyi gelir. Ortamı sadeleştir, zihni boşalt.',
      ],
      love:
          'Eşitlik bağını güçlendirir. Ne istediğini söyle; karşı tarafı tahminle yönetme.',
      career:
          'Arabuluculuk kazandırır. Kararı ertelemek değil; iki seçenekten birini seç.',
      money:
          'Paylaşılan hesaplarda net ol. Belirsiz borç-alacak bugün gerilim yaratır.',
      advice: 'Bugün bir tercihi kapat. İkisini birden taşıma.',
    ),
    'scorpio': AstrologySignDayCopy(
      overall: [
        'Akrep, bugün derinlik kazandırır. Gizlemeyi bırak; tek gerçeği netleştir.',
        'Akrep, bugün eski bir kalıbı bırakmak daha gerçekçi duruyor. Bunu romantikleştirmezdim; zor tarafı da görünür.',
        'Akrep, bugün yoğunluk yüksek. Her şeyi çözmek zorunda değilsin; bir katmanı aç.',
      ],
      love:
          'Bağ yoğun. Kıskançlık veya test yerine dürüst bir cümle daha şifalıdır.',
      career:
          'Strateji kazandırır. Perde arkasını kurcalama; görünür ve net bir adım at.',
      money:
          'Kontrol isteği yüksek. Ortak hesaba şüpheyle değil, açıklıkla bak.',
      advice: 'Bugün bir sırrı taşımayı bırak. Sadeleştir.',
    ),
    'sagittarius': AstrologySignDayCopy(
      overall: [
        'Yay, bugün ufuk açık. Yeni kapı cazip; her yere aynı anda koşma.',
        'Yay, bugün öğrenme ve yön kazandırır. Bir fikri uygula, onunu hayal etme.',
        'Yay, bugün özgürlük ihtiyacı yüksek. Kaçmadan mesafe tut; sözünü tut.',
      ],
      love:
          'Özgürlük ve dürüstlük bağ kurar. Söz verip kaybolma; net bir plan söyle.',
      career:
          'Vizyon güçlü. Büyük resmi gör, ilk somut adımı da at.',
      money:
          'İyimser harcama cazip. Macera bütçesini sınırla, kalıcı olana dokunma.',
      advice: 'Bugün bir yere git veya bir şeyi öğren. Dağınık gezinme.',
    ),
    'capricorn': AstrologySignDayCopy(
      overall: [
        'Oğlak, bugün yapı kazandırır. Uzun vadeli adım, kısa zaferden daha doğru.',
        'Oğlak, bugün sorumluluk görünür. Yükü paylaş; her şeyi tek başına taşıma.',
        'Oğlak, bugün tempo düşebilir. Dinlenmek işi bırakmak değil; planı korur.',
      ],
      love:
          'Ciddiyet bağ kurar. Duyguyu erteleme; kısa ve gerçek bir yakınlık yeter.',
      career:
          'Yönetim ve plan burada asıl iş. Bir milestone bitir; yeni dağ açma.',
      money:
          'Disiplin kazandırır. Birikimi koru, gösterişli riske girme.',
      advice: 'Bugün bir görevi kapat. Listeyi uzatma.',
    ),
    'aquarius': AstrologySignDayCopy(
      overall: [
        'Kova, bugün fikir taze. Yenilik doğru; insanı sistem sanma.',
        'Kova, bugün topluluk ve zihin seçilir durur. Birini dinle, mesafeyi azalt.',
        'Kova, bugün bağımsızlık yüksek. Ayrılmadan alan tut; kopma.',
      ],
      love:
          'Zihinsel bağ önemli. Yakınlığı fikirle kur; ama duyguyu da inkar etme.',
      career:
          'Yenilik kazandırır. Alışılmış yolu kır, somut bir prototip çıkar.',
      money:
          'Bağımsız bütçe isteği açık. Ortak kararı tek başına alma.',
      advice: 'Bugün bir fikri paylaş. İçinde kilitleme.',
    ),
    'pisces': AstrologySignDayCopy(
      overall: [
        'Balık, bugün sezgi ve hayal açık. Sisin içinde kaybolma; bir gerçeği tut.',
        'Balık, bugün şefkat kazandırır. Başkasını taşı, kendini de boşlama.',
        'Balık, bugün sınır önemli. Kaçış değil; yumuşak ama net bir duruş.',
      ],
      love:
          'Romantik birleşme bağda asıl mesele. Hayali ilişkiyi gerçek cümleyle yere indir.',
      career:
          'Sezgi ve sanat işe yarar. Belirsiz projeyi somut bir teslime bağla.',
      money:
          'Duygusal harcama cazip. Teselli alışverişini bugün kes.',
      advice: 'Bugün bir sınırı söyle. Yumuşak ol, silik olma.',
    ),
  };
}
