/// OR-1060 — Turkish AI interpretation content per revealed card.
library;

import 'package:flutter/material.dart';

import '../card_reveal/card_reveal_spread.dart';
import '../../../domain/models/reading_session.dart';

/// Full AI reading sections for one tarot card.
class AiReadingContent {
  const AiReadingContent({
    required this.cardName,
    required this.tagline,
    required this.generalMeaning,
    required this.love,
    required this.career,
    required this.money,
    required this.spiritualGuidance,
    required this.luckyEnergy,
    required this.dailyAdvice,
    required this.imageAsset,
    required this.rarityColor,
    this.fullInterpretation,
    this.drawnCards = const [],
    this.spreadLabel,
    this.closingMessage = '',
  });

  final String cardName;
  final String tagline;
  final String generalMeaning;
  final String love;
  final String career;
  final String money;
  final String spiritualGuidance;
  final String luckyEnergy;
  final String dailyAdvice;
  final String imageAsset;
  final Color rarityColor;
  final String? fullInterpretation;
  final List<TarotDrawnCard> drawnCards;
  final String? spreadLabel;
  final String closingMessage;
}

abstract final class AiReadingCatalogue {
  AiReadingCatalogue._();

  static AiReadingContent forIndex(int index) {
    final reveal = CardRevealSpread.forIndex(index);
    return _readings[index.clamp(0, _readings.length - 1)](reveal);
  }

  static final List<AiReadingContent Function(RevealCardData)> _readings = [
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Yıldız kartı umut, şifa ve ilahi rehberliğin habercisidir. '
              'Evren senin yolunu aydınlatıyor; içindeki sessiz güven yeniden filizleniyor. '
              'Zorlu dönemlerin ardından gelen bu enerji, kalbine huzur taşıyor.',
          love:
              'Kalbin açık ve alıcı bir dönemde. Samimi duygular derinleşebilir; '
              'yalnızlık hissi yerini yumuşak bir bağa bırakıyor. Sevgiye güven.',
          career:
              'Yaratıcı projeler ve uzun vadeli hedefler için uygun bir zaman. '
              'Emeklerinin karşılığını görmeye başlayacaksın; sabırlı kal.',
          money:
              'Finansal akışta dengeli bir iyileşme mümkün. Küçük ama sürdürülebilir '
              'adımlar bolluğu çağırır; cömertlik enerjini koru.',
          spiritualGuidance:
              'Meditasyon, su elementi ve gece sessizliği senin rehberin. '
              'Evrenin sinyallerine kulak ver; sezgilerin doğru yolu gösteriyor.',
          luckyEnergy: 'Mor ve gümüş tonlar · Perşembe · Akışkanlık',
          dailyAdvice:
              'Bugün kendine nazik ol. Bir dileğini kağıda yaz ve gökyüzüne bak — '
              'niyetin duyuldu.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Ay kartı sezgi, rüyalar ve bilinçaltının derin sularını temsil eder. '
              'Her şey göründüğü gibi olmayabilir; iç sesin en güvenilir pusulan.',
          love:
              'Duygular dalgalı olabilir; acele etme. Partnerinle derin konuşmalar '
              'gizli mesajları açığa çıkarır. Kalbini dinle, korkulara teslim olma.',
          career:
              'Belirsizlik geçici. Sezgilerinle hareket et; veriler kadar hislerin de '
              'değerli. Yaratıcı ve sezgisel işler öne çıkıyor.',
          money:
              'Harcamalarda dikkatli ol; duygusal alışverişten kaçın. '
              'Gizli fırsatlar yavaşça beliriyor — sabırlı gözlem yap.',
          spiritualGuidance:
              'Ay döngüleriyle uyumlan. Rüya günlüğü tut; semboller sana rehberlik edecek.',
          luckyEnergy: 'İndigo · Pazartesi · Ay taşı',
          dailyAdvice:
              'Bugün net kararlar almak zorunda değilsin. Dinlen, günlük tut, '
              'gece yürüyüşü yap.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Güneş kartı aydınlanma, neşe ve başarının simgesidir. '
              'Enerjin yükseliyor; hayatına sıcaklık ve netlik geliyor.',
          love:
              'İlişkilerde sıcaklık ve dürüstlük ön planda. Tek başınaysan '
              'özgüvenin çekiciliğini artırıyor. Kutla ve paylaş.',
          career:
              'Tanınma ve başarı kapıda. Cesur adımlar destekleniyor; '
              'liderlik enerjisi güçlü.',
          money:
              'Bolluk ve bereket enerjisi aktif. Yatırımlar ve uzun vadeli planlar '
              'olumlu sonuç verebilir.',
          spiritualGuidance:
              'Işığını dünyayla paylaş. Minnettarlık pratiği ruhsal hizalanmanı güçlendirir.',
          luckyEnergy: 'Altın · Pazar · Güneş taşı',
          dailyAdvice:
              'Gülümse, dışarı çık ve bir başarıyı kutla. Işığın başkalarına ilham verir.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Aşıklar kartı uyum, seçim ve kalpten gelen bağlantıyı temsil eder. '
              'Önemli bir karar veya derin bir birleşme enerjisi hakim.',
          love:
              'Kalbin sesi netleşiyor. Mevcut ilişkide uyum derinleşir; yeni bir tanışma '
              'kadersel olabilir. Dürüstlük en büyük erdemin.',
          career:
              'Ortaklıklar ve iş birlikleri öne çıkıyor. Değerlerinle uyumlu '
              'seçimler uzun vadede kazandırır.',
          money:
              'Paylaşılan kaynaklar ve adil anlaşmalar bereket getirir. '
              'Duygusal harcamalardan kaçın.',
          spiritualGuidance:
              'Kalp çakrasını dengele. Seçimlerinde hem aklını hem sezgini dinle.',
          luckyEnergy: 'Pembe · Cuma · Rose kuvars',
          dailyAdvice:
              'Bugün kalbinle uyumlu bir seçim yap. Küçük bir jestle sevgini göster.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Ermiş kartı içsel bilgelik, yalnız arayış ve sessiz rehberlik getirir. '
              'Cevaplar dışarıda değil, içinde.',
          love:
              'Kendini tanımak ilişkilerini de dönüştürür. Yalnız kalmaya ihtiyaç duyabilirsin — '
              'bu bir kopuş değil, derinleşmedir.',
          career:
              'Mentorluk ve uzmanlık alanında ilerleme. Yalnız çalışma verimli; '
              'araştırma ve derinlemesine odaklan.',
          money:
              'Tutumlu ve bilinçli harcama dönemi. Acele yatırımdan kaçın; '
              'uzun vadeli birikim düşün.',
          spiritualGuidance:
              'Sessizlik en büyük öğretmenin. Meditasyon ve doğada yalnız zaman ayır.',
          luckyEnergy: 'Kehribar · Cumartesi · Lal taşı',
          dailyAdvice:
              'Bugün kalabalıktan uzaklaş. Bir soruyu içinde taşı ve cevabın gelmesine izin ver.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Ölüm kartı dönüşüm, son ve yeni başlangıçların habercisidir. '
              'Eski bir döngü kapanıyor; yenilenmeye hazır ol.',
          love:
              'İlişkide derin dönüşüm veya eski kalıplardan kurtuluş mümkün. '
              'Bırakman gerekenleri bırak; yer açılsın.',
          career:
              'Kariyerde köklü değişim veya yeni yön. Korku yerine cesareti seç; '
              'dönüşüm seni büyütür.',
          money:
              'Eski harcama alışkanlıklarını gözden geçir. Temiz bir mali başlangıç '
              'mümkün.',
          spiritualGuidance:
              'Bırakma ritüeli yap. Dönüşüm kutsal bir süreç — direnme, akışa güven.',
          luckyEnergy: 'Siyah-mor · Salı · Obsidyen',
          dailyAdvice:
              'Bugün bir şeyi bilinçli olarak bırak. Yeni bir niyet belirle.',
        ),
    (r) => AiReadingContent(
          cardName: r.displayName,
          tagline: r.subtitle,
          imageAsset: r.imageAsset,
          rarityColor: r.rarityColor,
          generalMeaning:
              'Büyücü kartı yaratıcı güç, niyet ve potansiyelin somutlaşmasını simgeler. '
              'Elindeki araçlar hazır — evren seni dinliyor.',
          love:
              'Çekiciliğin ve ifade gücün yükseliyor. İlişkide net niyetler güçlü bağ kurar. '
              'Kalbini açıkça ifade et.',
          career:
              'Yeteneklerin ön plana çıkıyor. Yeni proje başlatmak, sunum yapmak '
              've liderlik için ideal zaman.',
          money:
              'Becerilerini gelir kaynağına dönüştürme fırsatı. Proaktif adımlar '
              'bolluğu çeker.',
          spiritualGuidance:
              'Niyetini netleştir ve ritüel yap. Dört element seninle — denge kur.',
          luckyEnergy: 'Kırmızı-altın · Çarşamba · Karneol',
          dailyAdvice:
              'Bugün bir niyet belirle ve ilk somut adımı at. Gücün sende.',
        ),
  ];
}
