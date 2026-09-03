/// OR-1150 — Builds all 78 tarot card content entries.
library;

import '../../shared/models/content_types.dart';
import '../models/tarot_card_content.dart';
import 'tarot_court_legacy.dart';

abstract final class TarotContentCatalogue {
  TarotContentCatalogue._();

  static const _majorRoot = 'lib/assets/images/tarot/major_arcana';
  static const _minorRoot = 'lib/assets/images/tarot/minor_arcana';

  static List<TarotCardContent> get all => [...majorArcana, ...minorArcana];

  static TarotCardContent byId(int id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static TarotCardContent forPersistedCard({
    required int cardId,
    String? imageAsset,
  }) =>
      TarotCourtLegacy.contentFor(cardId: cardId, imageAsset: imageAsset);

  static List<TarotCardContent> get majorArcana => _majorData
      .map((d) => _majorCard(d))
      .toList();

  static List<TarotCardContent> get minorArcana {
    final cards = <TarotCardContent>[];
    var id = 22;
    for (final suit in _suits) {
      for (var n = 1; n <= 14; n++) {
        cards.add(_minorCard(id: id++, suit: suit, number: n));
      }
    }
    return cards;
  }

  static TarotCardContent _majorCard(_MajorSeed d) {
    return TarotCardContent(
      id: d.id,
      name: d.name,
      nameTr: d.nameTr,
      arcana: TarotContentArcana.major,
      suit: TarotContentSuit.none,
      number: d.id,
      element: d.element,
      planet: d.planet,
      zodiac: d.zodiac,
      keywords: d.keywords,
      uprightMeaning: d.upright,
      reversedMeaning: d.reversed,
      loveMeaning: d.love,
      careerMeaning: d.career,
      moneyMeaning: d.money,
      healthMeaning: d.health,
      spiritualMeaning: d.spiritual,
      advice: d.advice,
      shadowMeaning: d.shadow,
      symbols: d.symbols,
      affirmation: d.affirmation,
      // Bundle/runtime uses `.webp` cards; keep catalogue seeds as-is.
      imageAsset: '$_majorRoot/${d.file}'.replaceAll('.png', '.webp'),
      rarity: ContentRarity.legendary,
    );
  }

  static TarotCardContent _minorCard({
    required int id,
    required _SuitDef suit,
    required int number,
  }) {
    final rank = _rankLabel(number);
    final nameTr = '$rank ${suit.nameTr}';
    final name = '${_rankLabelEn(number)} of ${suit.nameEn}';
    final file = '${_minorRankFile(number)}_${suit.folder}.png';
    final theme = suit.themes[(number - 1) % suit.themes.length];

    return TarotCardContent(
      id: id,
      name: name,
      nameTr: nameTr,
      arcana: TarotContentArcana.minor,
      suit: suit.suit,
      number: number,
      element: suit.element,
      planet: suit.planet,
      zodiac: suit.zodiac,
      keywords: [theme, suit.keyword, rank],
      uprightMeaning:
          'Düz $nameTr, ${suit.domain} alanında $theme tonunu daha seçilir kılar. '
          '${suit.uprightTemplate(number)}',
      reversedMeaning:
          'Ters $nameTr, ${suit.domain} konusunda dengesizlik veya gecikme '
          'sinyali verir. Sabır ve net bakış gerekir.',
      loveMeaning:
          'Aşkta $nameTr, ${suit.loveHint(number)} duygusal bağları güçlendirir.',
      careerMeaning:
          'Kariyerde $nameTr, ${suit.careerHint(number)} odaklı ilerlemeyi destekler.',
      moneyMeaning:
          'Maddi alanda $nameTr, ${suit.moneyHint(number)} konusunda bilinçli adımlar önerir.',
      healthMeaning:
          'Sağlıkta $nameTr, ${suit.element} elementinin dengesini hatırlatır; '
          'beden ve zihin uyumuna dikkat et.',
      spiritualMeaning:
          'Ruhsal olarak $nameTr, ${suit.spiritualHint(number)} tarafına işaret eder.',
      advice: '${suit.adviceTemplate(number)} — $theme tonunu acele etmeden taşı.',
      shadowMeaning:
          'Gölge yönü: aşırı ${suit.shadowWord} eğilimi; dengeyi kaybetmeden ilerle.',
      symbols: [suit.symbol, theme, rank],
      affirmation: 'Ben ${suit.affirmationRoot} ile uyum içindeyim.',
      // Bundle/runtime uses `.webp` cards; keep catalogue generation as-is.
      imageAsset: '$_minorRoot/${suit.folder}/$file'.replaceAll('.png', '.webp'),
      rarity: number >= 11 ? ContentRarity.rare : ContentRarity.common,
    );
  }

  static String _rankLabel(int n) => switch (n) {
        1 => 'As',
        11 => 'Papaz',
        12 => 'Kız',
        13 => 'Kraliçe',
        14 => 'Kral',
        _ => '$n',
      };

  static String _rankLabelEn(int n) => switch (n) {
        1 => 'Ace',
        11 => 'Page',
        12 => 'Knight',
        13 => 'Queen',
        14 => 'King',
        _ => '$n',
      };

  static const _minorRankFiles = <String>[
    '01_ace',
    '02_two',
    '03_three',
    '04_four',
    '05_five',
    '06_six',
    '07_seven',
    '08_eight',
    '09_nine',
    '10_ten',
    '11_page',
    '12_knight',
    '14_queen',
    '13_king',
  ];

  static String _minorRankFile(int n) =>
      _minorRankFiles[(n.clamp(1, 14)) - 1];

  static const _suits = [
    _SuitDef(
      suit: TarotContentSuit.cups,
      nameEn: 'Cups',
      nameTr: 'Kupa',
      prefix: 'Cups',
      folder: 'cups',
      element: 'Su',
      planet: 'Ay',
      zodiac: 'Yengeç',
      keyword: 'Duygu',
      domain: 'duygusal',
      symbol: 'Kadeh',
      shadowWord: 'duygusal bağımlılık',
      affirmationRoot: 'sevgi ve empati',
      themes: [
        'sezgi',
        'aşk',
        'şefkat',
        'iyileşme',
        'kayıp',
        'nostalji',
        'umut',
        'hayal',
        'tatmin',
        'bolluk',
        'aile',
        'ruhsal bağ',
        'arınma',
        'kutlama',
      ],
    ),
    _SuitDef(
      suit: TarotContentSuit.pentacles,
      nameEn: 'Pentacles',
      nameTr: 'Tılsım',
      prefix: 'Pentacles',
      folder: 'pentacles',
      element: 'Toprak',
      planet: 'Venüs',
      zodiac: 'Boğa',
      keyword: 'Maddi',
      domain: 'maddi',
      symbol: 'Pentagram',
      shadowWord: 'açgözlülük',
      affirmationRoot: 'bolluk ve istikrar',
      themes: [
        'fırsat',
        'emek',
        'plan',
        'sabır',
        'kaynak',
        'cömertlik',
        'verim',
        'beceri',
        'disiplin',
        'başarı',
        'miras',
        'güven',
        'yatırım',
        'refah',
      ],
    ),
    _SuitDef(
      suit: TarotContentSuit.swords,
      nameEn: 'Swords',
      nameTr: 'Kılıç',
      prefix: 'Swords',
      folder: 'swords',
      element: 'Hava',
      planet: 'Merkür',
      zodiac: 'İkizler',
      keyword: 'Zihin',
      domain: 'zihinsel',
      symbol: 'Kılıç',
      shadowWord: 'sertlik',
      affirmationRoot: 'netlik ve hakikat',
      themes: [
        'fikir',
        'karar',
        'ayrılık',
        'huzursuzluk',
        'yenilgi',
        'çatışma',
        'kaçış',
        'kısıtlama',
        'korku',
        'son',
        'adalet',
        'strateji',
        'uyku',
        'zafer',
      ],
    ),
    _SuitDef(
      suit: TarotContentSuit.wands,
      nameEn: 'Wands',
      nameTr: 'Asa',
      prefix: 'Wands',
      folder: 'wands',
      element: 'Ateş',
      planet: 'Mars',
      zodiac: 'Koç',
      keyword: 'Eylem',
      domain: 'yaratıcı',
      symbol: 'Asa',
      shadowWord: 'tükenmişlik',
      affirmationRoot: 'tutku ve cesaret',
      themes: [
        'ilham',
        'girişim',
        'genişleme',
        'mücadele',
        'rekabet',
        'zafer',
        'savunma',
        'hız',
        'dayanıklılık',
        'yük',
        'keşif',
        'liderlik',
        'vizyon',
        'başarı',
      ],
    ),
  ];

  static const _majorData = [
    _MajorSeed(0, 'The Fool', 'Deli', '00_deli.png', 'Hava', 'Uranüs', 'Kova',
        ['Yeni başlangıç', 'Özgürlük', 'Macera'], 'Cesur bir adım ve saf potansiyel.',
        'Acelecilik ve sorumsuzluk riski.', 'Spontane tanışma ve taze bir başlangıç.',
        'Yeni kariyer yolu ve girişim fırsatı.', 'Cesur yatırımlara açıklık.',
        'Yüksek ama dağınık tempo; dengeyi koru.', 'İçeride yeni bir sayfanın başlangıcı.',
        'Cesur ol ama bilinçli ol.', 'Naiflik ve kaçış eğilimi.',
        ['Beyaz köpek', 'Uçurum', 'Güneş'], 'Ben yeni başlangıçlara güvenle açılım.'),
    _MajorSeed(1, 'The Magician', 'Büyücü', '01_buyucu.png', 'Hava', 'Merkür', 'İkizler',
        ['Güç', 'Manifestasyon', 'Beceri'], 'Kaynakların birleşimi ve yaratma gücü.',
        'Manipülasyon veya potansiyelin boşa harcanması.', 'Çekim ve net iletişim.',
        'Yeteneklerini sahneye taşıma zamanı.', 'Kaynakları stratejik kullan.',
        'Zihinsel odak güçlü; dinlenmeyi ihmal etme.', 'Kaynaklarını bilinçle yönlendir.',
        'Niyetini netleştir ve harekete geç.', 'Ego ve kontrol takıntısı.',
        ['Asa', 'Kupa', 'Kılıç', 'Tılsım'], 'Ben düşüncelerimi gerçeğe dönüştürürüm.'),
    _MajorSeed(2, 'The High Priestess', 'Başrahibe', '02_basrahibe.png', 'Su', 'Ay', 'Yengeç',
        ['Sezgi', 'Gizem', 'Bilinçaltı'], 'İç sesin güçleniyor; sessizlik bilgelik getirir.',
        'Sırların bastırılması veya sezgiyi reddetmek.', 'Derin duygusal bağ ve sezgisel anlayış.',
        'Araştırma ve bilgi birikimi dönemi.', 'Gizli fırsatlar ortaya çıkabilir.',
        'Dinlenme ve hormonal denge önemli.', 'Ruhsal kapılar aralanıyor.',
        'İç sesini dinle ve acele etme.', 'Pasiflik ve kaçınma.',
        ['Ay taşı', 'Sütunlar', 'Perde'], 'Ben sezgime güvenirim.'),
    _MajorSeed(3, 'The Empress', 'İmparatoriçe', '03_imparatorice.png', 'Toprak', 'Venüs', 'Boğa',
        ['Bolluk', 'Annelik', 'Yaratıcılık'], 'Verimlilik, şefkat ve büyüme.',
        'Aşırı koruma veya tükenmişlik.', 'Sıcaklık ve besleyici ilişkiler.',
        'Yaratıcı projeler filizleniyor.', 'Maddi bolluk artıyor.',
        'Doğa ve bedenle bağ kur.', 'Yaratıcı, besleyici bir duruş.',
        'Besle ve büyüt; cömert ol.', 'Boğucu kontrol.',
        ['Buğday', 'Yastık', 'Venüs'], 'Ben bolluğu hayatıma davet ederim.'),
    _MajorSeed(4, 'The Emperor', 'İmparator', '04_imparator.png', 'Ateş', 'Mars', 'Koç',
        ['Otorite', 'Yapı', 'Liderlik'], 'Disiplin ve sağlam temeller.',
        'Katılık ve duygusal mesafe.', 'Güven veren partnerlik.',
        'Liderlik ve stratejik kararlar.', 'Finansal istikrar ve plan.',
        'Omurga ve tempo yönetimi.', 'Düzen ve sorumluluk tarafı.',
        'Sınırlarını koru ve sorumluluk al.', 'Otoriter baskı.',
        ['Taht', 'Koç', 'Zırh'], 'Ben hayatımda düzen ve güç kurarım.'),
    _MajorSeed(5, 'The Hierophant', 'Aziz', '05_aziz.png', 'Toprak', 'Venüs', 'Boğa',
        ['Gelenek', 'Öğreti', 'İnanç'], 'Kurumsal bilgelik ve rehberlik.',
        'Kör inanç veya isyan.', 'Ciddi ilişki ve evlilik potansiyeli.',
        'Mentorluk ve eğitim fırsatları.', 'Geleneksel yatırım yaklaşımları.',
        'Rutin ve manevi pratikler iyi gelir.', 'Ruhsal öğretmen ve topluluk.',
        'Köklerine saygı duy.', 'Dogmatizm.',
        ['Anahtar', 'Asa', 'Tapınak'], 'Ben bilgeliği saygıyla taşırım.'),
    _MajorSeed(6, 'The Lovers', 'Âşıklar', '06_asiklar.png', 'Hava', 'Merkür', 'İkizler',
        ['Seçim', 'Uyum', 'Birlik'], 'Kalp ve zihin uyumu.',
        'Uyumsuzluk veya yanlış seçim.', 'Derin bağ ve karşılıklı seçim.',
        'Ortaklık ve uyumlu işbirliği.', 'Değerlerle uyumlu harcama.',
        'Denge ve duygusal iyileşme.', 'Ruhsal eşleşme.',
        'Kalbinle seç ve sorumluluk al.', 'Bağımlılık.',
        ['Melek', 'Elma', 'Dağ'], 'Ben sevgiyle seçim yaparım.'),
    _MajorSeed(7, 'The Chariot', 'Savaş Arabası', '07_savas_arabasi.png', 'Su', 'Ay', 'Yengeç',
        ['İrade', 'Zafer', 'Kontrol'], 'Odaklanmış ilerleme ve zafer.',
        'Yön kaybı veya agresiflik.', 'İlişkide kararlılık.',
        'Hedefe doğru hızlı ilerleme.', 'Disiplinli birikim.',
        'Fiziksel tempo yüksek.', 'İrade ile ruhsal yol.',
        'Kontrolü elinde tut ve ilerle.', 'Zorlama.',
        ['Sphinx', 'Taç', 'Zırh'], 'Ben irademle yön bulurum.'),
    _MajorSeed(8, 'Strength', 'Güç', '08_guc.png', 'Ateş', 'Güneş', 'Aslan',
        ['Cesaret', 'Sabır', 'Merhamet'], 'Yumuşak güç ve içsel dayanıklılık.',
        'Özgüven eksikliği veya öfke.', 'Sabırlı ve şefkatli bağ.',
        'Sakin liderlik.', 'Uzun vadeli güven.',
        'Stres yönetimi kritik.', 'Kalp merkezli güç.',
        'Merhametle güçlen.', 'Baskı altında patlama.',
        ['Aslan', 'Sonsuzluk'], 'Ben merhametle güçlüyüm.'),
    _MajorSeed(9, 'The Hermit', 'Ermiş', '09_ermis.png', 'Toprak', 'Merkür', 'Başak',
        ['Yalnızlık', 'Bilgelik', 'Rehberlik'], 'İçe dönüş ve aydınlanma.',
        'İzolasyon veya kaçış.', 'Kendini tanıma dönemi.',
        'Uzmanlık ve derinlemesine çalışma.', 'Tasarruf ve planlama.',
        'Dinlenme ve detoks.', 'İç rehberlik.',
        'Sessizlikte cevap ara.', 'Sosyal geri çekilme.',
        ['Fener', 'Asa', 'Dağ'], 'Ben iç ışığımı takip ederim.'),
    _MajorSeed(10, 'Wheel of Fortune', 'Kader Çarkı', '10_kader_carki.png', 'Ateş', 'Jüpiter', 'Yay',
        ['Kader', 'Döngü', 'Şans'], 'Dönüm noktası ve evrensel akış.',
        'Direnç veya şanssızlık algısı.', 'Kadersel karşılaşma.',
        'Beklenmedik fırsatlar.', 'Finansal dalgalanma.',
        'Döngüsel sağlık değişimleri.', 'Karmik dersler.',
        'Akışa güven.', 'Kurban rolü.',
        ['Çark', 'Sfenks', 'Yılan'], 'Ben evrenin döngüsüne güvenirim.'),
    _MajorSeed(11, 'Justice', 'Adalet', '11_adalet.png', 'Hava', 'Venüs', 'Terazi',
        ['Denge', 'Hakikat', 'Sorumluluk'], 'Adil kararlar ve denge.',
        'Adaletsizlik veya kaçınma.', 'Dürüst iletişim.',
        'Hukuki veya resmi konular.', 'Borç ve denge hesabı.',
        'Denge ve orta yol.', 'Karma ve hakikat.',
        'Sorumluluğunu kabul et.', 'Yargılayıcılık.',
        ['Terazi', 'Kılıç'], 'Ben denge ve hakikatle hareket ederim.'),
    _MajorSeed(12, 'The Hanged Man', 'Asılan Adam', '12_asilan_adam.png', 'Su', 'Neptün', 'Balık',
        ['Teslim', 'Perspektif', 'Bekleme'], 'Farklı açıdan bakış.',
        'Gereksiz fedakarlık.', 'Ara verme ve yeniden değerlendirme.',
        'Stratejik bekleme.', 'Geçici maddi duraklama.',
        'Bedensel dinlenme.', 'Ruhsal teslimiyet.',
        'Bırak ve yeni bakış kazan.', 'Kurban psikolojisi.',
        ['Halat', 'Hale'], 'Ben teslimiyetle bilgelik bulurum.'),
    _MajorSeed(13, 'Death', 'Ölüm', '13_olum.png', 'Su', 'Plüton', 'Akrep',
        ['Dönüşüm', 'Son', 'Yenilenme'], 'Bitiş ve yeni başlangıç.',
        'Değişime direnç.', 'İlişkide dönüşüm veya ayrılık.',
        'Kariyer değişimi.', 'Finansal yapılandırma.',
        'Detoks ve yenilenme.', 'Ego ölümü.',
        'Bırak ve dönüş.', 'Korku.',
        ['Zırh', 'Güneş', 'Bayrak'], 'Ben dönüşümü kucaklarım.'),
    _MajorSeed(14, 'Temperance', 'Denge', '14_denge.png', 'Ateş', 'Jüpiter', 'Yay',
        ['Uyum', 'Sabır', 'İyileşme'], 'Orta yol ve alçakgönüllülük.',
        'Aşırılık ve dengesizlik.', 'Uyumlu birliktelik.',
        'Uzun vadeli işbirliği.', 'Dengeli bütçe.',
        'Moderasyon.', 'Ruhsal denge.',
        'Sabırla harmanla.', 'Sabırsızlık.',
        ['Melek', 'Kadehler'], 'Ben denge içinde akarım.'),
    _MajorSeed(15, 'The Devil', 'Şeytan', '15_seytan.png', 'Toprak', 'Satürn', 'Oğlak',
        ['Bağımlılık', 'Gölge', 'Tutku'], 'Bağımlılık ve illüzyon.',
        'Özgürleşme ve net bakış.', 'Toxic bağlar.', 'Kontrol eden iş ortamı.',
        'Maddi bağımlılık.', 'Bedensel aşırılıklar.', 'Gölge çalışması.',
        'Zincirlerini fark et.', 'Manipülasyon.',
        ['Zincir', 'Meşale'], 'Ben zincirlerimin farkındayım.'),
    _MajorSeed(16, 'The Tower', 'Kule', '16_kule.png', 'Ateş', 'Mars', 'Koç',
        ['Yıkım', 'Aydınlanma', 'Şok'], 'Ani değişim ve gerçek.',
        'Felaketten kaçınma veya gecikme.', 'İlişkide sarsıntı.', 'Kariyerde ani değişim.',
        'Beklenmedik kayıp veya kazanç.', 'Stres ve uyku.', 'Ego yıkımı.',
        'Temeli yeniden kur.', 'Kaos korkusu.',
        ['Yıldırım', 'Taş'], 'Ben gerçekle yüzleşirim.'),
    _MajorSeed(17, 'The Star', 'Yıldız', '17_yildiz.png', 'Hava', 'Uranüs', 'Kova',
        ['Umut', 'İlham', 'Şifa'], 'Umut ve ruhsal rehberlik.',
        'Umutsuzluk.', 'İyileşen ilişki.', 'Yaratıcı vizyon.',
        'Uzun vadeli refah.', 'Enerji toparlanması.', 'Kozmik bağ.',
        'Umut et ve paylaş.', 'Hayal kırıklığı.',
        ['Yıldız', 'Su'], 'Ben umut ışığıyım.'),
    _MajorSeed(18, 'The Moon', 'Ay', '18_ay.png', 'Su', 'Neptün', 'Balık',
        ['Sezgi', 'İllüzyon', 'Rüya'], 'Bilinçaltı ve belirsizlik.',
        'Korkuların açığa çıkması.', 'Belirsiz duygular.', 'Gizli ofis dinamikleri.',
        'Finansal belirsizlik.', 'Uyku ve rüyalar.', 'Ruhsal derinlik.',
        'Sezgine güven ama doğrula.', 'Paranoya.',
        ['Ay', 'Yol', 'Köpek'], 'Ben sezgisel karanlıkta yürürüm.'),
    _MajorSeed(19, 'The Sun', 'Güneş', '19_gunes.png', 'Ateş', 'Güneş', 'Aslan',
        ['Neşe', 'Başarı', 'Canlılık'], 'Aydınlık ve başarı.',
        'Geçici mutsuzluk.', 'Mutlu ilişki.', 'Tanınma ve başarı.',
        'Bolluk.', 'Canlılık.', 'Ruhsal aydınlanma.',
        'Parla ve kutla.', 'Aşırı ego.',
        ['Güneş', 'Çocuk', 'Bayrak'], 'Ben ışığımı paylaşırım.'),
    _MajorSeed(20, 'Judgement', 'Yargı', '20_yargi.png', 'Ateş', 'Plüton', 'Akrep',
        ['Uyanış', 'Çağrı', 'Yeniden doğuş'], 'Ruhsal çağrı ve değerlendirme.',
        'Öz eleştiri veya kaçınma.', 'Geçmişin çözülmesi.', 'Kariyer çağrısı.',
        'Miras ve hesap.', 'İyileşme dönemi.', 'Yüksek benlik.',
        'Geçmişi bırak ve yüksel.', 'Yargı.',
        ['Melek', 'Trampet'], 'Ben çağrıyı duyuyorum.'),
    _MajorSeed(21, 'The World', 'Dünya', '21_dunya.png', 'Toprak', 'Satürn', 'Oğlak',
        ['Tamamlanma', 'Bütünlük', 'Başarı'], 'Döngünün tamamlanması.',
        'Tamamlanmamış işler.', 'Olgun birliktelik.', 'Uluslararası fırsatlar.',
        'Kalıcı refah.', 'Bütünsel sağlık.', 'Evrensel birlik.',
        'Kutla ve entegre ol.', 'Durgunluk.',
        ['Hale', 'Figür'], 'Ben bütünüm.'),
  ];
}

class _MajorSeed {
  const _MajorSeed(
    this.id,
    this.name,
    this.nameTr,
    this.file,
    this.element,
    this.planet,
    this.zodiac,
    this.keywords,
    this.upright,
    this.reversed,
    this.love,
    this.career,
    this.money,
    this.health,
    this.spiritual,
    this.advice,
    this.shadow,
    this.symbols,
    this.affirmation,
  );

  final int id;
  final String name;
  final String nameTr;
  final String file;
  final String element;
  final String planet;
  final String zodiac;
  final List<String> keywords;
  final String upright;
  final String reversed;
  final String love;
  final String career;
  final String money;
  final String health;
  final String spiritual;
  final String advice;
  final String shadow;
  final List<String> symbols;
  final String affirmation;
}

class _SuitDef {
  const _SuitDef({
    required this.suit,
    required this.nameEn,
    required this.nameTr,
    required this.prefix,
    required this.folder,
    required this.element,
    required this.planet,
    required this.zodiac,
    required this.keyword,
    required this.domain,
    required this.symbol,
    required this.shadowWord,
    required this.affirmationRoot,
    required this.themes,
  });

  final TarotContentSuit suit;
  final String nameEn;
  final String nameTr;
  final String prefix;
  final String folder;
  final String element;
  final String planet;
  final String zodiac;
  final String keyword;
  final String domain;
  final String symbol;
  final String shadowWord;
  final String affirmationRoot;
  final List<String> themes;

  String uprightTemplate(int n) =>
      'Kart numarası $n, bu alanda ilerlemeyi ve netleşmeyi destekler.';

  String loveHint(int n) => 'duygusal derinlik ve karşılıklı anlayış';

  String careerHint(int n) => 'odaklı çalışma ve işbirliği';

  String moneyHint(int n) => 'kaynak yönetimi ve sabır';

  String spiritualHint(int n) => 'içeride büyüme ve daha net bakış';

  String adviceTemplate(int n) => 'Net niyet belirle ve adım adım ilerle';
}
