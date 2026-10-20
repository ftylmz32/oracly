/// Turkish phrasing for sky-based daily readings.
///
/// Every phrase is written to sit in one fixed grammatical slot, so the
/// composer never has to inflect a planet or sign name itself.
library;

import '../../birth_chart/models/zodiac_sign_id.dart';
import 'astrology_natal_sky.dart';
import 'astrology_transit_engine.dart';

abstract final class AstrologySkyCopyTr {
  AstrologySkyCopyTr._();

  /// Subject of a sentence: "Mars bugün …".
  static const name = <SkyPoint, String>{
    SkyPoint.sun: 'Güneş',
    SkyPoint.moon: 'Ay',
    SkyPoint.mercury: 'Merkür',
    SkyPoint.venus: 'Venüs',
    SkyPoint.mars: 'Mars',
    SkyPoint.jupiter: 'Jüpiter',
    SkyPoint.saturn: 'Satürn',
    SkyPoint.ascendant: 'yükselen noktası',
    SkyPoint.midheaven: 'MC (kariyer) noktası',
  };

  /// Possessor: "Mars'ın …".
  static const genitive = <SkyPoint, String>{
    SkyPoint.sun: "Güneş'in",
    SkyPoint.moon: "Ay'ın",
    SkyPoint.mercury: "Merkür'ün",
    SkyPoint.venus: "Venüs'ün",
    SkyPoint.mars: "Mars'ın",
    SkyPoint.jupiter: "Jüpiter'in",
    SkyPoint.saturn: "Satürn'ün",
  };

  static const signLocative = <ZodiacSignId, String>{
    ZodiacSignId.aries: "Koç'ta",
    ZodiacSignId.taurus: "Boğa'da",
    ZodiacSignId.gemini: "İkizler'de",
    ZodiacSignId.cancer: "Yengeç'te",
    ZodiacSignId.leo: "Aslan'da",
    ZodiacSignId.virgo: "Başak'ta",
    ZodiacSignId.libra: "Terazi'de",
    ZodiacSignId.scorpio: "Akrep'te",
    ZodiacSignId.sagittarius: "Yay'da",
    ZodiacSignId.capricorn: "Oğlak'ta",
    ZodiacSignId.aquarius: "Kova'da",
    ZodiacSignId.pisces: "Balık'ta",
  };

  /// After "… ile": the aspect as a verb.
  static const aspectVerb = <TransitAspect, String>{
    TransitAspect.conjunction: 'kavuşuyor',
    TransitAspect.sextile: 'destekleyici bir açı kuruyor',
    TransitAspect.trine: 'uyumlu bir üçgen açı kuruyor',
    TransitAspect.square: 'gergin bir kare açı yapıyor',
    TransitAspect.opposition: 'karşıt konuma geliyor',
  };

  /// After "… ile yaptığı": the aspect as a noun.
  static const aspectNoun = <TransitAspect, String>{
    TransitAspect.conjunction: 'kavuşum',
    TransitAspect.sextile: 'destekleyici açı',
    TransitAspect.trine: 'üçgen açı',
    TransitAspect.square: 'kare açı',
    TransitAspect.opposition: 'karşıtlık',
  };

  /// What the moving body brings, as the subject of "… katıyor".
  static const influence = <SkyPoint, String>{
    SkyPoint.moon: "Ay'ın duygusal temposu",
    SkyPoint.sun: "Güneş'in ışığı",
    SkyPoint.mercury: "Merkür'ün zihinsel hızı",
    SkyPoint.venus: "Venüs'ün etkisi",
    SkyPoint.mars: "Mars'ın enerjisi",
    SkyPoint.jupiter: "Jüpiter'in genişletici etkisi",
    SkyPoint.saturn: "Satürn'ün ağırlığı",
  };

  /// Object of "… katıyor", by moving body and tone.
  static const adds = <SkyPoint, Map<TransitTone, String>>{
    SkyPoint.moon: {
      TransitTone.fusion: 'duyguları yüzeye taşıyan bir yoğunluk',
      TransitTone.flow: 'rahatlatıcı bir duygusal akış',
      TransitTone.friction: 'kısa süreli bir duygusal dalgalanma',
    },
    SkyPoint.sun: {
      TransitTone.fusion: 'odak ve canlılık',
      TransitTone.flow: 'canlılık ve görünürlük',
      TransitTone.friction: 'görünür olmakla geri çekilmek arasında bir gerilim',
    },
    SkyPoint.mercury: {
      TransitTone.fusion: 'yoğun bir düşünce trafiği',
      TransitTone.flow: 'netlik ve rahat bir ifade gücü',
      TransitTone.friction: 'dağınık düşünceler ve yanlış anlaşılma payı',
    },
    SkyPoint.venus: {
      TransitTone.fusion: 'çekim ve sıcaklık',
      TransitTone.flow: 'yumuşaklık ve uyum',
      TransitTone.friction: 'keyifle ihtiyaç arasında bir çekişme',
    },
    SkyPoint.mars: {
      TransitTone.fusion: 'yoğun ve dolaysız bir istek',
      TransitTone.flow: 'cesaret ve hareket',
      TransitTone.friction: 'sabırsızlık ve sürtünme',
    },
    SkyPoint.jupiter: {
      TransitTone.fusion: 'büyüme isteği ve iyimserlik',
      TransitTone.flow: 'güven ve genişlik',
      TransitTone.friction: 'abartıya kaçmaya hazır bir iştah',
    },
    SkyPoint.saturn: {
      TransitTone.fusion: 'ciddiyet ve sorumluluk duygusu',
      TransitTone.flow: 'düzen ve kalıcılık',
      TransitTone.friction: 'sınır, gecikme ve yorgunluk hissi',
    },
  };

  /// What a natal point stands for, in the dative: "… biçimine".
  static const meaningDative = <SkyPoint, String>{
    SkyPoint.sun: 'kendini ortaya koyma biçimine',
    SkyPoint.moon: 'duygusal ihtiyaçlarına',
    SkyPoint.mercury: 'düşünme ve konuşma biçimine',
    SkyPoint.venus: 'sevgiyi ve keyfi yaşama biçimine',
    SkyPoint.mars: 'harekete geçme isteğine',
    SkyPoint.jupiter: 'güven ve umut duygusuna',
    SkyPoint.saturn: 'sorumluluk ve sınır duygusuna',
    SkyPoint.ascendant: 'dışarıya verdiğin ilk izlenime',
    SkyPoint.midheaven: 'iş hayatındaki yönüne',
  };

  static const duration = <SkyPoint, String>{
    SkyPoint.moon: 'Bu etki gün içinde gelip geçiyor.',
    SkyPoint.sun: 'Bu açı birkaç gün boyunca hissediliyor.',
    SkyPoint.mercury: 'Etkisi birkaç gün sürüyor.',
    SkyPoint.venus: 'Etkisi birkaç gün sürüyor.',
    SkyPoint.mars: 'Etkisi yaklaşık bir hafta sürüyor.',
    SkyPoint.jupiter: 'Bu, birkaç haftaya yayılan bir dönemin parçası.',
    SkyPoint.saturn: 'Bu, haftalar süren daha uzun bir dönemin parçası.',
  };

  static const general = <TransitTone, List<String>>{
    TransitTone.fusion: [
      'Bugün dikkat tek bir noktada toplanıyor; o konuda geri adım atmak zor geliyor.',
      'Günün enerjisi yoğun ve odaklı; bir başlangıç ya da yüzleşme için zemin hazır.',
      'Kendine dair bir şeyi her zamankinden net gördüğün bir gün.',
    ],
    TransitTone.flow: [
      'Gün genelinde işler sana doğru akıyor; çaba ile sonuç arasındaki mesafe kısa.',
      'Bugün kendinle uyumlu hissetmek daha kolay; kararlar içinden geliyor.',
      'Rahat bir tempo var; acele etmeden de ilerlediğin bir gün.',
    ],
    TransitTone.friction: [
      'Günün ana teması, alışkanlıklarınla yeni bir talep arasındaki sürtünme.',
      'Bugün seni zorlayan şey, aslında neye önem verdiğini de gösteriyor.',
      'Gerilim gün içinde birkaç kez yüzeye çıkıyor; çoğu, açıkça konuşulmamış beklentilerden.',
    ],
  };

  static const love = <TransitTone, List<String>>{
    TransitTone.fusion: [
      'Duygular bugün yüzeye yakın; çekim de kırılganlık da daha belirgin.',
      'İlişkide bir konu merkeze oturuyor ve geçiştirmek zor geliyor.',
      'Hissettiğin şey bugün daha yoğun; bu yoğunluk hem yakınlaştırıyor hem yoruyor.',
    ],
    TransitTone.flow: [
      'Duygularını ifade etmek bugün daha az çaba istiyor; karşındaki de bunu daha kolay karşılıyor.',
      'Yakın ilişkilerde akış kendiliğinden kuruluyor; zorlamadan gelen bir sıcaklık var.',
      'Tanışmalar ve barışmalar için doğal bir yumuşaklık taşıyan bir gün.',
    ],
    TransitTone.friction: [
      'İlişkide istekler daha hızlı dile geliyor; küçük bir cümle olduğundan sert duyulabiliyor.',
      'Yakınlık isteğiyle kendi alanını koruma ihtiyacı gün içinde yer değiştiriyor.',
      'Bir yanlış anlamanın büyümesi bugün her zamankinden kolay; ton, içerik kadar belirleyici.',
    ],
  };

  static const career = <TransitTone, List<String>>{
    TransitTone.fusion: [
      'İş tarafında tek bir konu bütün dikkatini çekiyor; dağınık değil, odaklı bir gün.',
      'Hedeflerin bugün daha keskin görünüyor; neyi neden istediğin netleşiyor.',
      'Bir sorumluluğun ağırlığı belirgin, ama onu sahiplenme duygun da güçlü.',
    ],
    TransitTone.flow: [
      'Emeğin bugün daha kolay görünür oluyor; bir görüşme ya da yazışma için zemin elverişli.',
      'İş akışı seni yormadan ilerliyor; ertelediğin bir başlığı açmak olağandan kolay.',
      'Birlikte çalıştığın insanlarla iletişim pürüzsüz; ortak bir karara varmak zor değil.',
    ],
    TransitTone.friction: [
      'Planlarınla işin gerçek temposu arasında bir sürtünme var; bir işin uzaması şaşırtıcı değil.',
      'Yetki ve sorumluluk konuları gündemde; kimin neye karar verdiği netleşmek istiyor.',
      'Hız istediğin yerde dirençle karşılaşıyorsun; bu direnç çoğu zaman eksik bir bilgiye işaret ediyor.',
    ],
  };

  static const money = <TransitTone, List<String>>{
    TransitTone.fusion: [
      'Para ve değer konusu bugün gündemin ortasında; bir karar seni bekliyor.',
      'Neye para ve emek harcadığın sorusu bugün daha çok düşündürüyor.',
      'Maddi bir konuya yoğunlaşıyorsun; dağılmadan bir sonuca bağlamak kolaylaşıyor.',
    ],
    TransitTone.flow: [
      'Maddi konularda sakin bir zemin var; bir ödeme ya da pazarlık beklediğinden kolay ilerliyor.',
      'Kaynaklarını değerlendirme biçimin bugün isabetli; neye değer verdiğini net görüyorsun.',
      'Para tarafında küçük ama somut bir rahatlama hissi öne çıkıyor.',
    ],
    TransitTone.friction: [
      'Harcama isteğiyle güvende hissetme ihtiyacı çatışıyor; anlık bir alım sonradan sorgulanabilir.',
      'Bir hesap beklediğin gibi çıkmayabilir; rakamlar bugün ikinci bir bakışı hak ediyor.',
      'Değer verdiğin şeyle ödediğin bedel arasındaki dengeyi sorguladığın bir gün.',
    ],
  };

  /// Closes "Bu, … doğrudan dokunuyor; …" in the feelings lane.
  static const mood = <TransitTone, List<String>>{
    TransitTone.fusion: [
      'duygular olduğundan daha yakın ve daha çıplak hissediliyor.',
      'bir his gün boyunca seni bırakmıyor.',
      'içindekini saklamak bugün zor.',
    ],
    TransitTone.flow: [
      'rahatlatıcı bir duygusal akış hissediliyor.',
      'iç sesin bugün daha sakin ve anlaşılır.',
      'iyi hissettiren küçük şeyler daha kolay bulunuyor.',
    ],
    TransitTone.friction: [
      'kısa süreli bir duygusal dalgalanma hissediliyor.',
      'küçük bir şey beklenenden fazla dokunabiliyor.',
      'ruh hali gün içinde birkaç kez yön değiştiriyor.',
    ],
  };

  static const opportunity = <SkyPoint, String>{
    SkyPoint.sun: 'kendini göstermek ve bir fikri sahiplenmek',
    SkyPoint.moon: 'bir ilişkiyi onarmak ya da içini dökmek',
    SkyPoint.mercury: 'zor bir konuşma, bir yazışma ya da yeni bir şey öğrenmek',
    SkyPoint.venus: 'bir buluşma, bir uzlaşma ya da güzel bir şeye zaman ayırmak',
    SkyPoint.mars: 'ertelenmiş bir işe başlamak ya da bedeni harekete geçirmek',
    SkyPoint.jupiter: 'ufku açan bir teklif ya da bir öğrenme fırsatı',
    SkyPoint.saturn: 'uzun vadeli bir planı sağlamlaştırmak',
    SkyPoint.ascendant: 'yeni insanlarla tanışmak ve iyi bir ilk izlenim bırakmak',
    SkyPoint.midheaven: 'işte görünür olmak ve bir sorumluluğu üstlenmek',
  };

  static const caution = <SkyPoint, String>{
    SkyPoint.sun: 'gurur ve inat kolay tetikleniyor',
    SkyPoint.moon: 'duygular hızlı yükselip hızlı iniyor',
    SkyPoint.mercury: 'yanlış anlaşılmalar ve aceleyle verilen cevaplar öne çıkıyor',
    SkyPoint.venus: 'keyif için fazla harcamak ya da küsmek kolaylaşıyor',
    SkyPoint.mars: 'aceleyle yapılan hareketler ve tartışmaya dönen konuşmalar artıyor',
    SkyPoint.jupiter: 'abartılı sözler ve fazla iyimser planlar çoğalıyor',
    SkyPoint.saturn: 'yorgunluk ve kendine fazla yük bindirme eğilimi artıyor',
    SkyPoint.ascendant: 'başkalarının seni olduğundan sert algılaması kolaylaşıyor',
    SkyPoint.midheaven: 'iş yerinde yetki çatışmaları belirginleşiyor',
  };

  /// Reflection lane: one quiet observation, never an order.
  static const reflection = <TransitTone, String>{
    TransitTone.fusion:
        'Bugünün sorusu: Bu kadar dikkat çeken şey sana neyi göstermek istiyor?',
    TransitTone.flow:
        'Bugünün sorusu: Kolay gelen bu akışla hangi yarım işi tamamlamak istersin?',
    TransitTone.friction:
        'Bugünün sorusu: Seni zorlayan şeyin altında hangi ihtiyaç duruyor?',
  };

  static const elementWord = <SkyElement, String>{
    SkyElement.fire: 'ateş',
    SkyElement.earth: 'toprak',
    SkyElement.air: 'hava',
    SkyElement.water: 'su',
  };

  static const elementNature = <SkyElement, String>{
    SkyElement.fire: 'hız ve coşku',
    SkyElement.earth: 'sağlamlık ve somutluk',
    SkyElement.air: 'fikir ve iletişim',
    SkyElement.water: 'sezgi ve duygusal derinlik',
  };

  static const emotionRelation = <SkyRelation, String>{
    SkyRelation.same:
        'Bu, iç ritminle aynı dili konuşan bir hava; kendini anlatmak kolay.',
    SkyRelation.supportive:
        'Günün havası iç dünyanı besliyor; içinden geleni duymak kolaylaşıyor.',
    SkyRelation.different:
        'Günün temposu senin iç ritminden farklı; tepkilerinin alışılmadık gelmesi bundan.',
  };

  static const energyRelation = <SkyRelation, String>{
    SkyRelation.same:
        'Enerjin tanıdık bir yoldan akıyor; harekete geçmek için bahane gerekmiyor.',
    SkyRelation.supportive:
        'Bedenin ve isteklerin aynı yöne bakıyor; toparlanmak kolay.',
    SkyRelation.different:
        'Enerjin alışık olduğun yoldan akmıyor; tempo düşükse bu bir eksiklik değil, bir ayar.',
  };

  static const loveRelation = <SkyRelation, String>{
    SkyRelation.same:
        'Bu, sevgiyi yaşama biçiminle aynı tonda bir gökyüzü; yakınlık zahmetsiz kuruluyor.',
    SkyRelation.supportive:
        'Günün ilişki havası senin sevgi dilini destekliyor; küçük jestler karşılık buluyor.',
    SkyRelation.different:
        'Günün ilişki havası senin sevgi dilinden farklı; karşındakinin ihtiyacını okumak biraz daha dikkat istiyor.',
  };

  static const careerRelation = <SkyRelation, String>{
    SkyRelation.same:
        'Zihinsel temponla günün temposu örtüşüyor; işini anlatmak ve savunmak kolay.',
    SkyRelation.supportive:
        'Günün zihinsel havası senin düşünme biçimini besliyor; karmaşık bir işi sadeleştirmek kolaylaşıyor.',
    SkyRelation.different:
        'Günün zihinsel havası senin düşünme biçiminden farklı; bir konuyu başkasının diliyle anlatman gerekebiliyor.',
  };

  static const moneyRelation = <SkyRelation, String>{
    SkyRelation.same:
        'Para ve değer konusunda içgüdülerin günün havasıyla örtüşüyor.',
    SkyRelation.supportive:
        'Maddi konularda günün havası seni destekliyor; acele etmeden verilen kararlar isabetli.',
    SkyRelation.different:
        'Maddi konularda günün havası senin alışkanlıklarından farklı; bir harcamanın gerçekten gerekli olup olmadığı daha görünür.',
  };

  /// Whole-sign house as an area of life, for "… ilgili N. evinden".
  static const houseArea = <int, String>{
    1: 'kendinle ve görünüşünle',
    2: 'para ve kaynaklarla',
    3: 'yakın çevre ve yazışmalarla',
    4: 'ev ve aileyle',
    5: 'keyif, yaratıcılık ve aşkla',
    6: 'günlük iş düzeni ve sağlık rutinleriyle',
    7: 'ortaklıklar ve yakın ilişkilerle',
    8: 'ortak para, borç ve derin bağlarla',
    9: 'öğrenme, seyahat ve inançlarla',
    10: 'kariyer ve toplumdaki yerinle',
    11: 'arkadaşlar, gruplar ve gelecek planlarıyla',
    12: 'dinlenme, geri çekilme ve iç dünyayla',
  };

  static const quietLove =
      'Bugün ilişki tarafında haritana doğrudan dokunan güçlü bir açı yok.';
  static const quietCareer =
      'Bugün iş tarafında haritana doğrudan dokunan güçlü bir açı yok.';
  static const quietMoney =
      'Bugün para tarafında haritana doğrudan dokunan güçlü bir açı yok.';
  static const quietOpportunity =
      'Bugün haritana belirgin bir destek açısı gelmiyor; fırsatlar daha çok kendi başlattığın işlerden çıkıyor.';
  static const quietCaution =
      'Bugün haritana sert bir açı gelmiyor; gerilim varsa daha çok dış koşullardan kaynaklanıyor.';
  static const quietReflection =
      'Bugünün sorusu: Sakin bir günde kendine hangi alanı açmak istersin?';

  static const solarReturn =
      'Güneş, doğduğun günkü derecesine dönüyor; yeni yaşının ilk günlerindesin.';

  static const themeEcho =
      'Son okumalarında öne çıkan {theme} teması da bugün aynı yere dokunuyor.';

  static const basisFull =
      'Bugünkü gökyüzünün, doğum saatin ve şehrinle hesaplanan haritana yaptığı açılardan yazıldı.';
  static const basisDayOnly =
      'Bugünkü gökyüzünün, doğum günündeki gezegen konumlarına yaptığı açılardan yazıldı. Doğum saatin bilinmediği için Ay ve yükselen hesaba katılmadı.';
}

enum SkyRelation { same, supportive, different }

SkyRelation relationOf(ZodiacSignId a, ZodiacSignId b) {
  final x = elementOf(a);
  final y = elementOf(b);
  if (x == y) return SkyRelation.same;
  final pair = {x, y};
  if (pair.containsAll({SkyElement.fire, SkyElement.air}) ||
      pair.containsAll({SkyElement.earth, SkyElement.water})) {
    return SkyRelation.supportive;
  }
  return SkyRelation.different;
}
