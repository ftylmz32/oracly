/// OR-1080 — Major Arcana card detail encyclopedia catalogue.
library;

import 'package:flutter/material.dart';

import 'card_detail_models.dart';

abstract final class CardDetailCatalogue {
  CardDetailCatalogue._();

  static const _root = 'lib/assets/images/tarot/major_arcana';

  static CardDetailContent forId(int id) => _cards[id.clamp(0, 21)];

  static List<CardDetailContent> get all => _cards;

  static final List<CardDetailContent> _cards = [
    CardDetailContent(
      id: 0,
      name: 'The Fool',
      displayNameTr: 'Deli',
      imageAsset: '$_root/00_deli.png',
      arcanaType: 'Major Arcana',
      element: 'Hava',
      planet: 'Uranüs',
      zodiac: 'Kova',
      number: 0,
      keywords: ['Yeni başlangıç', 'Özgürlük', 'Macera', 'Saflık', 'Cesaret'],
      accentColor: Color(0xFFF5D76E),
      meanings: CardMeaningSections(
        general:
            'Deli, tarot destesinin sıfır numaralı kartıdır ve saf potansiyelin, '
            'henüz biçim kazanmamış yolculuğun sembolüdür. Bilinçli bir adım atmadan '
            'önceki anı temsil eder; hem sonsuz olanak hem de dikkatsizlik riski taşır.',
        upright:
            'Düz konumda Deli, cesur bir başlangıcı, içgüdüsel güveni ve hayata '
            'açık bir kalbi müjdeler. Bilinmeyene adım atma zamanı gelmiştir; '
            'evren seni destekliyor.',
        reversed:
            'Ters Deli, acelecilik, sorumsuzluk veya korkudan kaçınmayı işaret '
            'eder. Plan yapmadan atılan adımlar seni savrabilir; önce temeli '
            'sağlamlaştır.',
        love:
            'Aşkta Deli, spontane bir tanışmayı veya ilişkide taze bir enerjiyi '
            'anlatır. Kalbinin sesine güven; ancak gerçekçi beklentiler de '
            'kurmaktan kaçınma.',
        career:
            'Kariyer alanında yeni bir yol, girişim veya riskli ama ödüllendirici '
            'bir fırsat kapıda. Deneyim eksikliğini merak ve öğrenme isteğiyle '
            'dengele.',
        money:
            'Maddi konularda beklenmedik harcamalar veya cesur yatırımlar gündeme '
            'gelebilir. Bütçe disiplinini korurken yeni gelir kapılarına açık ol.',
        spiritual:
            'Ruhsal yolculuğun başlangıcında olduğunu hatırlatır. Öğretmen aramak '
            'yerine deneyimle öğren; her adım bir ders taşır.',
        health:
            'Enerji yüksek ama dağınık olabilir. Aşırıya kaçmadan hareket et; '
            'bedenin sinyallerini dinlemek bu dönemde kritik.',
        personality:
            'Deli enerjisi taşıyan biri meraklı, özgür ruhlu ve maceracıdır. '
            'Kurallara meydan okur ama kalbi genellikle saf niyetle hareket eder.',
        shadow:
            'Gölge yönü naiflik, kaçış ve sorumluluktan uzaklaşmadır. '
            'Özgürlük bahanesiyle bağlılıktan kaçmak gerçek büyümeyi engeller.',
        advice:
            'Cesur ol ama bilinçli ol. Adım at, fakat nereye gittiğini en azından '
            'sezgisel olarak bil; evren seni desteklerken sen de kendine güven.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Beyaz Köpek',
          icon: Icons.pets_rounded,
          description:
              'Sadakat ve içgüdüsel rehberliği simgeler; bilinçaltının '
              'tehlikelere karşı uyarısını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Uçurum Kenarı',
          icon: Icons.landscape_rounded,
          description:
              'Bilinmeyene atılan adımı anlatır; cesaret ile dikkatsizlik '
              'arasındaki ince çizgiyi hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Güneş',
          icon: Icons.wb_sunny_rounded,
          description:
              'Saf iyimserlik ve yeni bir günün başlangıcını temsil eder; '
              'henüz gölgeye düşmemiş potansiyeli simgeler.',
        ),
        CardSymbolEntry(
          name: 'Beyaz Gül',
          icon: Icons.local_florist_rounded,
          description:
              'Saflık ve masum niyeti işaret eder; kalbin temiz '
              'motivasyonlarla hareket etmesi gerektiğini hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Deri Çanta',
          icon: Icons.backpack_rounded,
          description:
              'Yolculuk için taşınan deneyimleri simgeler; geçmişten '
              'öğrenilenleri yeni maceraya taşımayı anlatır.',
        ),
      ],
      aiInsight:
          'Deli kartı, hayatın en saf anını temsil eder: henüz sonuçtan korkmadan '
          'adım atılan o eşsiz eşik. Bu kart seni hatırlatır ki bilgelik bazen '
          'plan yapmadan güvenmekle gelir. Yolculuğun başında olduğunu kabul et; '
          'her düşüş de bir öğretmendir.',
      relatedIds: [1, 21, 10],
      heroTag: 'card_detail_hero_0',
    ),
    CardDetailContent(
      id: 1,
      name: 'The Magician',
      displayNameTr: 'Büyücü',
      imageAsset: '$_root/01_buyucu.png',
      arcanaType: 'Major Arcana',
      element: 'Hava',
      planet: 'Merkür',
      zodiac: 'İkizler',
      number: 1,
      keywords: ['Yaratım', 'Niyet', 'Güç', 'Beceri', 'Manifestasyon'],
      accentColor: Color(0xFF7EC8E3),
      meanings: CardMeaningSections(
        general:
            'Büyücü, düşüncenin eyleme dönüştüğü noktayı temsil eder. Masadaki '
            'dört element, evrenin tüm kaynaklarının elinin altında olduğunu '
            'gösterir; niyet odaklandığında gerçeklik şekillenir.',
        upright:
            'Düz Büyücü, yaratıcı gücün zirvesini ve becerilerin somut sonuç '
            'doğurduğunu müjdeler. İradeni odakla; istediğin şeyi inşa etme '
            'zamanı gelmiştir.',
        reversed:
            'Ters konumda manipülasyon, dağınık enerji veya potansiyelin '
            'kullanılmaması söz konusudur. Araçların var ama niyetin net '
            'değil; önce içsel hizalanmayı sağla.',
        love:
            'Aşkta çekicilik, iletişim gücü ve ilişkiyi şekillendirme yeteneği '
            'öne çıkar. Samimi ve net ol; duygularını kelimelere dökmek bağları '
            'güçlendirir.',
        career:
            'Kariyerde liderlik, girişimcilik ve teknik becerilerin ön plana '
            'çıktığı bir dönem. Fikirlerini sun; yeteneklerin fark edilecek.',
        money:
            'Maddi konularda kendi kaynaklarını akıllıca kullanma fırsatı var. '
            'Yeni gelir akışları yaratmak için becerilerini pazara taşı.',
        spiritual:
            'Ruhsal alanda bilinçli yaratım gücünü hatırlatır. Meditasyon, '
            'niyet çalışmaları ve ritüeller bu dönemde derin etki yaratır.',
        health:
            'Zihin-beden bağlantısı güçlü; iradeyle alışkanlıkları '
            'dönüştürebilirsin. Ancak aşırı zihinsel aktiviteden dinlen.',
        personality:
            'Büyücü enerjisi taşıyan biri karizmatik, becerikli ve ikna '
            'gücü yüksektir. Fikirlerini hızla eyleme dönüştürme yeteneğine sahiptir.',
        shadow:
            'Gölge yönü aldatıcılık, ego odaklı manipülasyon ve boş '
            'gösteriştir. Gücü başkalarını kontrol etmek için kullanmak '
            'uzun vadede tüketir.',
        advice:
            'Elindeki tüm araçları kullan ama niyetini saf tut. Odaklan, '
          'eyleme geç ve yarattığın dünyanın sorumluluğunu üstlen.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Sonsuzluk İşareti',
          icon: Icons.all_inclusive_rounded,
          description:
              'Başın üzerindeki lemniskat, sınırsız potansiyeli ve '
              'enerjinin döngüsel doğasını simgeler.',
        ),
        CardSymbolEntry(
          name: 'Dört Element',
          icon: Icons.category_rounded,
          description:
              'Kupa, değnek, kılıç ve pentagram masadaki dört suiti '
              'temsil eder; tüm kaynakların elinin altında olduğunu anlatır.',
        ),
        CardSymbolEntry(
          name: 'Asa',
          icon: Icons.auto_fix_high_rounded,
          description:
              'Yaratıcı iradeyi ve niyetin maddi dünyaya indirilmesini '
              'simgeleyen güçlü bir semboldür.',
        ),
        CardSymbolEntry(
          name: 'Kırmızı Beyaz Robe',
          icon: Icons.checkroom_rounded,
          description:
              'Tutku ile saflığın birleşimini temsil eder; hem arzu '
              'hem bilgelikle hareket etmeyi hatırlatır.',
        ),
      ],
      aiInsight:
          'Büyücü, evrenin seninle iş birliği yapmaya hazır olduğunu fısıldar. '
          'Potansiyelin zaten içinde; eksik olan yalnızca net niyet ve eylemdir. '
          'Bu kart, hayallerini somut gerçekliğe dönüştürme gücünü hatırlatır. '
          'Odaklandığında sınırların çoğu yalnızca zihninde vardır.',
      relatedIds: [0, 2, 21],
      heroTag: 'card_detail_hero_1',
    ),
    CardDetailContent(
      id: 2,
      name: 'The High Priestess',
      displayNameTr: 'Başrahibe',
      imageAsset: '$_root/02_basrahibe.png',
      arcanaType: 'Major Arcana',
      element: 'Su',
      planet: 'Ay',
      zodiac: 'Balık',
      number: 2,
      keywords: ['Sezgi', 'Gizem', 'Bilinçaltı', 'Sessizlik', 'İçsel bilgelik'],
      accentColor: Color(0xFF6B8CAE),
      meanings: CardMeaningSections(
        general:
            'Başrahibe, görünmeyen bilgeliğin bekçisidir. İki sütun arasında '
            'oturarak bilinçli ile bilinçsiz arasındaki eşiği korur; cevaplar '
            'dışarıda değil, derin sessizlikte gizlidir.',
        upright:
            'Düz konumda sezgi güçlenir, gizli bilgiler yüzeye çıkmaya hazırdır. '
            'Acele etme; iç sesini dinle ve sembollerin dilini okumayı öğren.',
        reversed:
            'Ters Başrahibe, sezgiyi bastırmayı veya gizli gerçeklerden kaçmayı '
            'gösterir. İç sesini duymayı reddettiğinde dış dünya seni yanıltabilir.',
        love:
            'Aşkta derin ama henüz söylenmemiş duygular vardır. Sabırlı ol; '
            'ilişkinin gerçek doğası zamanla açığa çıkacaktır.',
        career:
            'Kariyerde araştırma, gizli bilgi ve sezgisel kararlar önem kazanır. '
            'Her şeyi açıkça paylaşmadan önce stratejik bekle.',
        money:
            'Maddi konularda henüz net olmayan fırsatlar veya gizli yükümlülükler '
            'olabilir. Acele karar verme; detayları araştır.',
        spiritual:
            'Ruhsal uyanışın eşiğindesin. Meditasyon, rüya çalışması ve ay '
            'ritüelleri bu dönemde derin içgörüler sunar.',
        health:
            'Duygusal ve hormonal döngülere dikkat et. Dinlenme, su tüketimi '
            've sessizlik bedenin iyileşmesini destekler.',
        personality:
            'Başrahibe enerjisi taşıyan biri gizemli, sezgisel ve sakin bir '
            'varlığa sahiptir. Söylenmeyenleri hisseder; sırları güvenle korur.',
        shadow:
            'Gölge yönü pasiflik, aşırı gizlilik ve duygusal mesafe '
            'yaratmaktır. Bilgeliği paylaşmamak izolasyona yol açabilir.',
        advice:
            'Sessizliğe çekil ve iç sesini dinle. Cevaplar dışarıda aranmaz; '
            'derin bir nefes al ve sezgine güven.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Ay Tahtı',
          icon: Icons.nightlight_round,
          description:
              'Ay döngülerini ve bilinçaltının dalgalı doğasını simgeler; '
              'sezgisel bilgeliğin kaynağıdır.',
        ),
        CardSymbolEntry(
          name: 'Torah Tomarı',
          icon: Icons.menu_book_rounded,
          description:
              'Gizli bilgi ve kutsal öğretileri temsil eder; henüz '
              'açılmamış sırların bekçisidir.',
        ),
        CardSymbolEntry(
          name: 'İki Sütun',
          icon: Icons.view_column_rounded,
          description:
              'Bilinen ile bilinmeyen, bilinçli ile bilinçsiz arasındaki '
              'sınırı işaret eder.',
        ),
        CardSymbolEntry(
          name: 'Nar Perde',
          icon: Icons.curtains_rounded,
          description:
              'Örtülü gerçekleri ve henüz açığa çıkmamış bilgiyi simgeler; '
              'sabırla beklemeyi hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Su',
          icon: Icons.water_drop_rounded,
          description:
              'Duygusal derinliği ve bilinçaltının akışkan doğasını '
              'temsil eden temel semboldür.',
        ),
      ],
      aiInsight:
          'Başrahibe, cevapların gürültünün ötesinde olduğunu hatırlatır. '
          'Bu kart seni acele etmekten alıkoyar ve içsel rehberliğe davet eder. '
          'Görünmeyen dünyanın dili sembollerle konuşur; dinlemeyi öğren. '
          'Sessizlik bir boşluk değil, en zengin bilgi kaynağıdır.',
      relatedIds: [1, 3, 18],
      heroTag: 'card_detail_hero_2',
    ),
    CardDetailContent(
      id: 3,
      name: 'The Empress',
      displayNameTr: 'İmparatoriçe',
      imageAsset: '$_root/03_imparatorice.png',
      arcanaType: 'Major Arcana',
      element: 'Toprak',
      planet: 'Venüs',
      zodiac: 'Boğa',
      number: 3,
      keywords: ['Bereket', 'Annelik', 'Doğa', 'Yaratıcılık', 'Bolluk'],
      accentColor: Color(0xFF4CAF7A),
      meanings: CardMeaningSections(
        general:
            'İmparatoriçe, doğanın ana enerjisini ve yaratıcı bolluğu temsil '
            'eder. Verimli topraklar, olgunlaşan projeler ve sevgi dolu bir '
            'ortam bu kartın özünü oluşturur.',
        upright:
            'Düz konumda bereket, yaratıcılık ve duyusal zevkler ön plana '
            'çıkar. Ektiğin tohumlar filizleniyor; kendine ve çevrene şefkatle '
            'bak.',
        reversed:
            'Ters İmparatoriçe, tükenmişlik, yaratıcı blokaj veya aşırı '
            'bağımlılığı işaret eder. Kendine bakım yapmadan vermeye devam '
            'etme; dengeyi yeniden kur.',
        love:
            'Aşkta derin bağlılık, tutku ve besleyici bir enerji hakim. '
            'İlişkide güven ve fiziksel yakınlık güçlenir; kalbin açılmasına izin ver.',
        career:
            'Kariyerde yaratıcı projeler olgunlaşır ve somut sonuçlar doğar. '
            'Sanatsal veya bakım odaklı alanlarda başarı elde edilebilir.',
        money:
            'Maddi bolluk ve konfor artabilir. Yatırımların meyve vermeye '
            'başlıyor; ancak keyfi harcamalara dikkat et.',
        spiritual:
            'Doğayla bağ kurmak ruhsal iyileşmeyi hızlandırır. Topraklama '
            'pratikleri ve yaratıcı ifade bu dönemde derin huzur verir.',
        health:
            'Bedensel ve üreme sağlığına dikkat çekilir. Besleyici gıdalar, '
            'dinlenme ve doğada vakit geçirmek iyileşmeyi destekler.',
        personality:
            'İmparatoriçe enerjisi taşıyan biri sıcak, cömert ve yaratıcıdır. '
            'Çevresindekileri besler; güzelliği ve konforu takdir eder.',
        shadow:
            'Gölge yönü aşırı koruyuculuk, tembellik veya maddi dünyaya '
            'bağımlılıktır. Verirken kendini tüketmek sürdürülebilir değildir.',
        advice:
            'Kendini ve projelerini besle. Doğayla bağ kur, yaratıcılığına '
            'alan aç ve bolluğun zaten seninle olduğunu hatırla.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Buğday Tarlaları',
          icon: Icons.grass_rounded,
          description:
              'Hasat ve bereketi simgeler; emeğin somut meyvelerini '
              'verdiğini hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Venüs Tahtı',
          icon: Icons.favorite_rounded,
          description:
              'Aşk, güzellik ve sanatsal yaratıcılığın gezegenini temsil '
              'eder; duyusal zenginliği simgeler.',
        ),
        CardSymbolEntry(
          name: 'Nar Kalkanı',
          icon: Icons.shield_rounded,
          description:
              'Bolluk ve doğurganlığı simgeleyen kadim bir semboldür; '
              'yaşamın sürekliliğini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Orman',
          icon: Icons.forest_rounded,
          description:
              'Doğanın ana enerjisini ve vahşi yaratıcılığı temsil eder; '
              'doğayla uyum içinde yaşamayı hatırlatır.',
        ),
      ],
      aiInsight:
          'İmparatoriçe, hayatın seni desteklediğini ve bolluğun doğal '
          'akışının içinde olduğunu hatırlatır. Bu kart kendine şefkat '
          'göstermeni ve yaratıcı enerjini serbest bırakmanı ister. '
          'Ektiğin her tohum, doğru koşullarda mutlaka filizlenecektir.',
      relatedIds: [2, 4, 14],
      heroTag: 'card_detail_hero_3',
    ),
    CardDetailContent(
      id: 4,
      name: 'The Emperor',
      displayNameTr: 'İmparator',
      imageAsset: '$_root/04_imparator.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Mars',
      zodiac: 'Koç',
      number: 4,
      keywords: ['Otorite', 'Yapı', 'Disiplin', 'Liderlik', 'Kararlılık'],
      accentColor: Color(0xFFC45C4A),
      meanings: CardMeaningSections(
        general:
            'İmparator, düzenin, otoritenin ve yapısal gücün temsilcisidir. '
            'Tahtı kayalıklar üzerindedir; istikrar ve disiplinle inşa edilen '
            'dünyayı simgeler.',
        upright:
            'Düz konumda liderlik, stratejik düşünce ve sınırların net '
            'belirlenmesi gündeme gelir. Kontrolü ele al; sağlam temeller '
            'atma zamanı.',
        reversed:
            'Ters İmparator, aşırı kontrol, katılık veya otorite boşluğunu '
            'gösterir. Esneklik kaybettiğinde yapı hapis haline gelebilir.',
        love:
            'Aşkta güven, bağlılık ve koruyucu enerji öne çıkar. İlişkide '
            'net sınırlar ve kararlılık istikrar sağlar; ancak duygusal '
            'mesafe yaratmamaya dikkat et.',
        career:
            'Kariyerde yöneticilik, strateji ve uzun vadeli planlama '
            'başarı getirir. Disiplinli çalışmanın meyvelerini topluyorsun.',
        money:
            'Maddi güvenlik ve istikrar öncelikli. Bütçe yönetimi ve '
            'uzun vadeli yatırımlar bu dönemde olgunlaşır.',
        spiritual:
            'Ruhsal disiplin ve yapılandırılmış pratikler derinlik kazandırır. '
            'Rastgele arayışlar yerine tutarlı bir yol seç.',
        health:
            'Fiziksel güç ve dayanıklılık artabilir. Ancak stres ve '
            'aşırı kontrol bedensel gerginliğe yol açabilir; gevşemeyi unutma.',
        personality:
            'İmparator enerjisi taşıyan biri kararlı, disiplinli ve '
            'koruyucudur. Sorumluluk almaktan çekinmez; güvenilir bir liderdir.',
        shadow:
            'Gölge yönü baskıcı otorite, duygusal soğukluk ve '
            'kontrol takıntısıdır. Güç paylaşılmadığında yalnızlaşır.',
        advice:
            'Sağlam temeller at ve sınırlarını net belirle. Liderlik et, '
            'fakat esnekliği kaybetme; gerçek güç dengeyle gelir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Taş Taht',
          icon: Icons.chair_rounded,
          description:
              'Kalıcı otoriteyi ve sağlam temelleri simgeler; geçici '
              'değil köklü gücü temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Koç Başlıkları',
          icon: Icons.crisis_alert_rounded,
          description:
              'Mars enerjisini ve cesur liderliği temsil eder; '
              'savaşçı ruhun koruyucu yönünü simgeler.',
        ),
        CardSymbolEntry(
          name: 'Kırmızı Cüppe',
          icon: Icons.checkroom_rounded,
          description:
              'Tutku, güç ve yaşam enerjisini simgeler; aktif '
              've kararlı eylemi temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Asa',
          icon: Icons.gavel_rounded,
          description:
              'Yönetim gücünü ve düzen kurma yeteneğini temsil eder; '
              'dünyayı şekillendiren iradeyi simgeler.',
        ),
        CardSymbolEntry(
          name: 'Dağlar',
          icon: Icons.terrain_rounded,
          description:
              'Zorlukların üstesinden gelinmiş otoriteyi simgeler; '
              'deneyimle kazanılmış bilgeliği temsil eder.',
        ),
      ],
      aiInsight:
          'İmparator, hayatında düzen kurma ve sorumluluk alma çağrısıdır. '
          'Bu kart seni istikrarlı adımlar atmaya ve sınırlarını korumaya davet '
          'eder. Gerçek güç baskıdan değil, güven vermekten doğar. '
          'Yapı, özgürlüğün düşmanı değil; onu taşıyan iskelettir.',
      relatedIds: [3, 5, 11],
      heroTag: 'card_detail_hero_4',
    ),
    CardDetailContent(
      id: 5,
      name: 'The Hierophant',
      displayNameTr: 'Aziz',
      imageAsset: '$_root/05_aziz.png',
      arcanaType: 'Major Arcana',
      element: 'Toprak',
      planet: 'Venüs',
      zodiac: 'Boğa',
      number: 5,
      keywords: ['Gelenek', 'Öğreti', 'İnanç', 'Rehberlik', 'Kurum'],
      accentColor: Color(0xFF8B6DB0),
      meanings: CardMeaningSections(
        general:
            'Aziz, geleneksel bilgeliği, ruhsal öğretileri ve toplumsal '
            'yapıları temsil eder. Kutsal bilginin aktarıldığı köprü '
            'görevini üstlenir; inanç sistemleri ve mentorluk bu kartın özüdür.',
        upright:
            'Düz konumda rehberlik arayışı, eğitim ve ruhsal öğretilere '
            'bağlılık öne çıkar. Deneyimli bir mentordan veya geleneksel '
            'bilgiden faydalanma zamanı.',
        reversed:
            'Ters Aziz, kör inanç, dogmatizm veya kurallara isyanı '
            'gösterir. Gelenekleri sorgulamak büyümenin parçası olabilir; '
            'ancak kaosla karıştırma.',
        love:
            'Aşkta geleneksel bağlılık, evlilik veya resmi adımlar gündeme '
            'gelebilir. Değerlerinizin uyumlu olduğundan emin ol; ortak '
            'inançlar ilişkiyi güçlendirir.',
        career:
            'Kariyerde eğitim, mentorluk ve kurumsal yapılar önem kazanır. '
            'Uzmanlık belgesi almak veya rehberlik etmek bu dönemde verimli.',
        money:
            'Maddi güvenlik geleneksel yollarla sağlanabilir. Bankacılık, '
            'sigorta veya kurumsal yapılar bu dönemde destek sunar.',
        spiritual:
            'Ruhsal yolculukta öğretmen veya topluluk arayışı derinleşir. '
            'Kutsal metinler, ritüeller ve geleneksel pratikler rehberlik eder.',
        health:
            'Alternatif tıbbın yanı sıra geleneksel tedavilere güven '
            'duyulabilir. Uzman görüşü almak iyileşmeyi hızlandırır.',
        personality:
            'Aziz enerjisi taşıyan biri bilge, öğretici ve inançlıdır. '
            'Toplumsal normlara saygı duyar; bilgisini cömertçe paylaşır.',
        shadow:
            'Gölge yönü dogmatizm, baskıcı inanç ve eleştiriye kapalılıktır. '
            'Kurallar kişisel büyümeyi engellediğinde hapishane haline gelir.',
        advice:
            'Bilgelik arayışında deneyimli rehberlerden faydalan. '
            'Geleneklere saygı duy ama körü körüne takip etme; '
            'kendi inancını bilinçli seç.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Üçlü Taç',
          icon: Icons.workspace_premium_rounded,
          description:
              'Ruhsal, zihinsel ve maddi otoriteyi simgeler; '
              'kutsal bilginin taşıyıcısını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'İki Anahtar',
          icon: Icons.vpn_key_rounded,
          description:
              'Gizli bilgiye erişimi simgeler; öğretinin kapılarını '
              'açan ruhsal anahtarları temsil eder.',
        ),
        CardSymbolEntry(
          name: 'İki Takipçi',
          icon: Icons.groups_rounded,
          description:
              'Öğretinin aktarımını ve topluluk bağını simgeler; '
              'bilgeliğin paylaşıldığı ilişkiyi temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Asa',
          icon: Icons.account_balance_rounded,
          description:
              'Ruhsal otoriteyi ve kutsal görevi simgeler; '
              'dünyevi ile ruhsal arasındaki köprüyü temsil eder.',
        ),
      ],
      aiInsight:
          'Aziz, bilgeliğin aktarımının kadim bir gelenek olduğunu hatırlatır. '
          'Bu kart seni bir rehber aramaya veya kendi bilgini paylaşmaya davet '
          'eder. İnanç sistemleri iskelet gibidir; seni taşır ama nefes almana '
          'izin verecek esneklik de gerekir.',
      relatedIds: [4, 6, 9],
      heroTag: 'card_detail_hero_5',
    ),
    CardDetailContent(
      id: 6,
      name: 'The Lovers',
      displayNameTr: 'Aşıklar',
      imageAsset: '$_root/06_asiklar.png',
      arcanaType: 'Major Arcana',
      element: 'Hava',
      planet: 'Merkür',
      zodiac: 'İkizler',
      number: 6,
      keywords: ['Aşk', 'Seçim', 'Uyum', 'Bağ', 'Değerler'],
      accentColor: Color(0xFFFF6B9D),
      meanings: CardMeaningSections(
        general:
            'Aşıklar kartı sadece romantik aşkı değil, bilinçli seçimleri '
            've değerlerin uyumunu temsil eder. İki ruhun birleşimi veya '
            'hayati bir kararın eşiğinde olmak bu kartın özünü oluşturur.',
        upright:
            'Düz konumda derin bağ, uyum ve kalpten gelen bir seçim '
            'gündeme gelir. İlişkiler güçlenir; değerlerinle uyumlu '
            'adımlar at.',
        reversed:
            'Ters Aşıklar, uyumsuzluk, kararsızlık veya değer çatışmasını '
            'gösterir. Kalbin ile aklın arasında sıkışmış olabilirsin; '
            'netleşmeden karar verme.',
        love:
            'Aşkta tutku, derin bağ ve ruhsal uyum ön plandadır. Yeni bir '
            'aşk başlayabilir veya mevcut ilişki daha derin bir boyuta '
            'geçebilir.',
        career:
            'Kariyerde ortaklık, iş birliği veya değerlerinle uyumlu bir '
            'yol seçimi gündeme gelir. Doğru partnerle büyük işler başarılabilir.',
        money:
            'Maddi kararlarda duygusal faktörler etkili olabilir. '
            'Ortak yatırımlar veya aile kaynakları bu dönemde öne çıkar.',
        spiritual:
            'Ruhsal birliktelik ve ikiz alev bağlantısı mümkündür. '
            'Seçimlerin ruhunun yolunu yansıtıp yansıtmadığını sorgula.',
        health:
            'Kalp sağlığı ve duygusal denge önem kazanır. Sevdiklerinle '
            'geçirilen zaman iyileşmeyi destekler.',
        personality:
            'Aşıklar enerjisi taşıyan biri çekici, uyumlu ve değer '
            'odaklıdır. İlişkilerde derinlik arar; seçimlerinde kalbi dinler.',
        shadow:
            'Gölge yönü bağımlılık, kararsızlık ve değerlerden '
            'vazgeçmektir. Başkalarını memnun etmek için kendini '
            'feda etmek uzun vadede acı verir.',
        advice:
            'Kalbinin sesini dinle ama değerlerini de gözet. Seçimlerin '
            'seni gerçek benliğine yaklaştırmalı; uyum iç huzurdan doğar.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Adem ve Havva',
          icon: Icons.people_rounded,
          description:
              'İnsan birliğini ve bilinçli seçimi simgeler; '
              'ruhsal eşleşmenin sembolik temsilidir.',
        ),
        CardSymbolEntry(
          name: 'Melek',
          icon: Icons.flutter_dash_rounded,
          description:
              'İlahi rehberliği ve kutsal korumayı simgeler; '
              'seçimlerin üstünde duran bilgeliği temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Elma Ağacı',
          icon: Icons.park_rounded,
          description:
              'Bilgi ağacını ve bilinçli seçimin bedelini simgeler; '
              'özgür iradenin sembolüdür.',
        ),
        CardSymbolEntry(
          name: 'Dağ',
          icon: Icons.landscape_rounded,
          description:
              'Arkada duran volkanik dağ, tutkulu enerjiyi simgeler; '
              'ilişkideki derin duygusal gücü temsil eder.',
        ),
      ],
      aiInsight:
          'Aşıklar, hayatının en önemli seçimlerinden birinin eşiğinde '
          'olduğunu fısıldar. Bu kart seni kalbinle hizalanmaya davet eder. '
          'Gerçek aşk özgür iradeyle seçilir; zorunluluktan değil, uyumdan '
          'doğar. Değerlerinle uyumlu olan yol seni eve götürür.',
      relatedIds: [5, 14, 19],
      heroTag: 'card_detail_hero_6',
    ),
    CardDetailContent(
      id: 7,
      name: 'The Chariot',
      displayNameTr: 'Savaş Arabası',
      imageAsset: '$_root/07_savas_arabasi.png',
      arcanaType: 'Major Arcana',
      element: 'Su',
      planet: 'Ay',
      zodiac: 'Yengeç',
      number: 7,
      keywords: ['Zafer', 'İrade', 'Kontrol', 'İlerleme', 'Kararlılık'],
      accentColor: Color(0xFF5B9BD5),
      meanings: CardMeaningSections(
        general:
            'Savaş Arabası, zıt güçleri bir araya getirerek ilerlemeyi '
            'simgeleyen güçlü bir karttır. İrade, disiplin ve hedefe '
            'odaklanma ile engeller aşılır; zafer içsel kontrolden doğar.',
        upright:
            'Düz konumda zafer, ilerleme ve kararlılık müjdelenir. '
            'Engeller aşılabilir; iradeni odakla ve yola devam et. '
            'Başarı yakın.',
        reversed:
            'Ters Savaş Arabası, kontrol kaybı, yön belirsizliği veya '
            'agresif ilerlemeyi gösterir. Hedefin net değilse güç dağılır; '
            'durup yönünü belirle.',
        love:
            'Aşkta ilişkiyi ilerletme isteği güçlüdür. Ancak kontrol '
            'takıntısı partneri uzaklaştırabilir; dengeyi koru.',
        career:
            'Kariyerde hızlı ilerleme, terfi veya rekabetçi bir '
            'ortamda zafer mümkün. Disiplinli çalışma meyve verecek.',
        money:
            'Maddi hedeflere ulaşmak için kararlı adımlar at. '
            'Disiplinli birikim veya cesur girişimler başarı getirebilir.',
        spiritual:
            'Ruhsal yolculukta içsel çatışmaları dengelemek gerekir. '
            'Zıt enerjileri birleştirdiğinde derin bir bütünlük hissedersin.',
        health:
            'Fiziksel enerji yüksek; spor ve hareket faydalı. Ancak '
            'aşırı hırs stres yaratabilir; dinlenmeyi ihmal etme.',
        personality:
            'Savaş Arabası enerjisi taşıyan biri kararlı, hırslı ve '
            'hedef odaklıdır. Engelleri aşma konusunda azimli ve cesurdur.',
        shadow:
            'Gölge yönü baskı, agresif rekabet ve duygusal '
            'baskılamadır. Zafer uğruna ilişkileri feda etmek boş bir '
            'kazançtır.',
        advice:
            'Hedefini net belirle ve kararlılıkla ilerle. Zıt güçleri '
            'dengeleyerek kontrolü elinde tut; zafer disiplinden gelir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Sphinx Atları',
          icon: Icons.directions_car_rounded,
          description:
              'Siyah ve beyaz atlar zıt güçleri simgeler; '
              'bunları bir arada yönlendirmek irade gerektirir.',
        ),
        CardSymbolEntry(
          name: 'Yıldızlı Gökyüzü',
          icon: Icons.star_rounded,
          description:
              'İlahi korumayı ve kaderin desteğini simgeler; '
              'doğru yolda olduğunu hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Zırh',
          icon: Icons.shield_rounded,
          description:
              'Koruma ve savaşçı ruhu simgeler; dış dünyadan '
              'gelene karşı direnci temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Taç',
          icon: Icons.emoji_events_rounded,
          description:
              'Zaferi ve başarıyı simgeler; hedefe ulaşmanın '
              'sembolik ödülünü temsil eder.',
        ),
      ],
      aiInsight:
          'Savaş Arabası, iradenin en güçlü silah olduğunu hatırlatır. '
          'Bu kart seni hedefe odaklanmaya ve içsel çatışmaları '
          'dengelemeye davet eder. Zafer dışarıda değil, önce kendi '
          'içinde kazanılır. Yol uzun olsa da her adım seni yaklaştırır.',
      relatedIds: [4, 8, 11],
      heroTag: 'card_detail_hero_7',
    ),
    CardDetailContent(
      id: 8,
      name: 'Strength',
      displayNameTr: 'Güç',
      imageAsset: '$_root/08_guc.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Güneş',
      zodiac: 'Aslan',
      number: 8,
      keywords: ['Cesaret', 'Sabır', 'Merhamet', 'İçsel güç', 'Denge'],
      accentColor: Color(0xFFE8A84C),
      meanings: CardMeaningSections(
        general:
            'Güç kartı fiziksel kuvvetten çok içsel cesareti temsil eder. '
            'Aslanı nazikçe kontrol eden figür, sabır ve merhametle '
            'kazanılan gerçek gücü simgeler.',
        upright:
            'Düz konumda içsel cesaret, sabır ve duygusal denge öne '
            'çıkar. Korkularınla yüzleşme gücün var; yumuşaklık en '
            'büyük silahın.',
        reversed:
            'Ters Güç, özgüven eksikliği, korku veya bastırılmış '
            'öfkeyi gösterir. İçsel aslanını tanımak ve kabul etmek '
            'iyileşmenin ilk adımıdır.',
        love:
            'Aşkta sabır, anlayış ve derin duygusal bağ önem kazanır. '
            'Tutku ile şefkatin dengesi ilişkiyi güçlendirir.',
        career:
            'Kariyerde zorlu durumları sabırla yönetme becerisi '
            'takdir edilir. Liderlik merhametle yapıldığında kalıcı olur.',
        money:
            'Maddi konularda sabırlı ve disiplinli yaklaşım başarı '
            'getirir. Ani kararlar yerine uzun vadeli plan yap.',
        spiritual:
            'Ruhsal güç, ego ile ruh arasındaki dengeyle gelir. '
            'Meditasyon ve nefes çalışmaları içsel aslanını uyandırır.',
        health:
            'Bedensel ve zihinsel dayanıklılık artar. Stres yönetimi '
            've düzenli egzersiz bu dönemde kritik önem taşır.',
        personality:
            'Güç enerjisi taşıyan biri cesur, sabırlı ve merhametlidir. '
            'Zorluklar karşısında sakin kalır; başkalarına ilham verir.',
        shadow:
            'Gölge yönü bastırılmış öfke, korkaklık veya aşırı '
            'kontrol ihtiyacıdır. Gücü baskı aracı olarak kullanmak '
            'gerçek gücün tersidir.',
        advice:
            'İçsel cesaretini besle ve sabırlı ol. Gerçek güç '
            'kaba kuvvetten değil, merhamet ve dengeyle gelir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Aslan',
          icon: Icons.pets_rounded,
          description:
              'Vahşi içgüdüleri ve tutkuyu simgeler; nazik '
              'dokunuşla kontrol edilmesi gereken gücü temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Sonsuzluk İşareti',
          icon: Icons.all_inclusive_rounded,
          description:
              'Başın üzerindeki lemniskat, sınırsız içsel '
              'gücü ve ruhsal dayanıklılığı simgeler.',
        ),
        CardSymbolEntry(
          name: 'Beyaz Elbise',
          icon: Icons.checkroom_rounded,
          description:
              'Saflık ve ruhsal gücü simgeler; fiziksel '
              'güçten üstün olan içsel cesareti temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Çiçek Taç',
          icon: Icons.local_florist_rounded,
          description:
              'Doğayla uyumu ve yumuşak gücü simgeler; '
              'merhametin zaferini temsil eder.',
        ),
      ],
      aiInsight:
          'Güç kartı, gerçek cesaretin korkusuzluk değil korkuyla '
          'yüzleşmek olduğunu hatırlatır. Bu kart seni sabırlı ve '
          'merhametli olmaya davet eder. İçindeki aslanı tanı; onu '
          'bastırmak yerine sevgiyle yönlendir.',
      relatedIds: [7, 9, 11],
      heroTag: 'card_detail_hero_8',
    ),
    CardDetailContent(
      id: 9,
      name: 'The Hermit',
      displayNameTr: 'Ermiş',
      imageAsset: '$_root/09_ermis.png',
      arcanaType: 'Major Arcana',
      element: 'Toprak',
      planet: 'Merkür',
      zodiac: 'Başak',
      number: 9,
      keywords: ['Yalnızlık', 'Bilgelik', 'İçe dönüş', 'Rehberlik', 'Arayış'],
      accentColor: Color(0xFFD4AF37),
      meanings: CardMeaningSections(
        general:
            'Ermiş, dağın zirvesinde feneriyle yol gösteren içsel '
            'bilgenin sembolüdür. Yalnızlık bir ceza değil; derin '
            'içgörüye ulaşmak için gerekli bir inzivadır.',
        upright:
            'Düz konumda içe dönüş, bilgelik arayışı ve sessiz '
            'rehberlik öne çıkar. Kalabalıktan uzaklaş; cevaplar '
            'içinde saklı.',
        reversed:
            'Ters Ermiş, aşırı izolasyon, yalnızlık korkusu veya '
            'rehberlik reddini gösterir. İçe dönmek ile kaçmak '
            'arasındaki farkı ayırt et.',
        love:
            'Aşkta yalnızlık ihtiyacı veya ilişkide mesafe gündeme '
            'gelebilir. Kendini tanımak, daha derin bir bağ için '
            'gereklidir.',
        career:
            'Kariyerde bağımsız çalışma, araştırma veya uzmanlık '
            'alanında derinleşme faydalı. Mentörlük rolü de mümkün.',
        money:
            'Maddi konularda tutumlu ve düşünceli ol. Acele '
            'kararlar yerine uzun vadeli planlama yap.',
        spiritual:
            'Ruhsal uyanışın en derin aşamasındasın. Meditasyon, '
            'oruç veya inziva bu dönemde dönüştürücü olabilir.',
        health:
            'Dinlenme ve yalnızlık bedeni iyileştirir. Zihinsel '
            'sağlık için meditasyon ve doğada yürüyüş faydalı.',
        personality:
            'Ermiş enerjisi taşıyan biri bilge, sakin ve içe '
            'dönüktür. Az konuşur ama söyledikleri derin anlam taşır.',
        shadow:
            'Gölge yönü aşırı izolasyon, sosyal kaçış ve '
            'bilgeliği paylaşmama korkusudur. Yalnızlık hapishane '
            'haline geldiğinde büyüme durur.',
        advice:
            'Sessizliğe çekil ve içsel fenerini yak. Bilgelik '
            'dışarıda aranmaz; kendi ışığın başkalarına da yol gösterir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Fener',
          icon: Icons.lightbulb_rounded,
          description:
              'İçsel bilgeliğin ışığını simgeler; karanlıkta '
              'yol gösteren sezgisel rehberliği temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Asa',
          icon: Icons.hiking_rounded,
          description:
              'Ruhsal otoriteyi ve yolculuğun desteğini simgeler; '
              'deneyimle kazanılmış bilgeliği temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Dağ Zirvesi',
          icon: Icons.terrain_rounded,
          description:
              'Ruhsal yükselişi ve yalnız arayışı simgeler; '
              'dünyevi gürültüden uzaklaşmayı temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Gri Cüppe',
          icon: Icons.checkroom_rounded,
          description:
              'Mütevazılığı ve dünyevi arzulardan arınmayı simgeler; '
              'içsel zenginliğin sembolüdür.',
        ),
      ],
      aiInsight:
          'Ermiş, cevapların dışarıda değil içinde olduğunu fısıldar. '
          'Bu kart seni kalabalıktan uzaklaşıp kendi ışığını '
          'yakmaya davet eder. Yalnızlık bir eksiklik değil; derin '
          'bilgeliğe açılan kutsal bir kapıdır.',
      relatedIds: [2, 8, 18],
      heroTag: 'card_detail_hero_9',
    ),
    CardDetailContent(
      id: 10,
      name: 'Wheel of Fortune',
      displayNameTr: 'Kader Çarkı',
      imageAsset: '$_root/10_kader_carki.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Jüpiter',
      zodiac: 'Yay',
      number: 10,
      keywords: ['Kader', 'Döngü', 'Değişim', 'Şans', 'Dönüm noktası'],
      accentColor: Color(0xFF2EC4B6),
      meanings: CardMeaningSections(
        general:
            'Kader Çarkı, hayatın döngüsel doğasını ve değişimin '
            'kaçınılmazlığını temsil eder. Yükseliş ve düşüşler geçicidir; '
            'evrenin ritmine güvenmek bu kartın özüdür.',
        upright:
            'Düz konumda şans, dönüm noktası ve olumlu değişim '
            'müjdelenir. Kader senin lehine dönüyor; fırsatları '
            'değerlendir.',
        reversed:
            'Ters Kader Çarkı, şanssızlık, direnç veya döngüye '
            'takılı kalmayı gösterir. Değişime direnmek acıyı uzatır; '
            'akışa teslim ol.',
        love:
            'Aşkta kaderin müdahalesi veya ilişkide dönüm noktası '
            'mümkün. Beklenmedik gelişmeler bağları güçlendirebilir.',
        career:
            'Kariyerde ani fırsatlar, terfi veya yön değişikliği '
            'gündeme gelebilir. Esnek ol; evren seni yönlendiriyor.',
        money:
            'Maddi konularda şans dönemi başlayabilir. Ancak '
            'kazançlar geçici olabilir; akıllıca değerlendir.',
        spiritual:
            'Ruhsal yolculukta karmik dersler ve döngüler '
            'tamamlanıyor. Evrenin planına güven; her şey bir nedeni vardır.',
        health:
            'Sağlıkta iyileşme döngüsü başlayabilir. Ancak '
            'düzensizlikler de gündeme gelebilir; rutin oluştur.',
        personality:
            'Kader Çarkı enerjisi taşıyan biri uyumlu, esnek ve '
            'kaderci bir bakışa sahiptir. Değişimi kucaklar; şansa inanır.',
        shadow:
            'Gölge yönü pasiflik, kurban rolü ve kontrol '
            'fantezisidir. Her şeyi kadere yüklemek sorumluluktan '
            'kaçmak olabilir.',
        advice:
            'Değişime açık ol ve evrenin ritmine güven. '
            'Döngüler geçicidir; inişler de çıkışlar da bir ders taşır.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Dönen Çark',
          icon: Icons.sync_rounded,
          description:
              'Hayatın döngüsel doğasını simgeler; yükseliş '
              've düşüşlerin geçiciliğini hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Sfenks',
          icon: Icons.psychology_rounded,
          description:
              'Bilgeliği ve bilinmeyeni simgeler; çarkın '
              'üstündeki gizemli figür kaderin sırlarını korur.',
        ),
        CardSymbolEntry(
          name: 'Yılan',
          icon: Icons.water_rounded,
          description:
              'Düşüşü temsil eden figür; her yükselişin '
              'bir düşüşe, her düşüşün bir yükselişe bağlı olduğunu anlatır.',
        ),
        CardSymbolEntry(
          name: 'Anubis',
          icon: Icons.pets_rounded,
          description:
              'Yükselişi temsil eden figür; ölüm ve yeniden '
              'doğuş döngüsünü simgeler.',
        ),
        CardSymbolEntry(
          name: 'Dört Harf',
          icon: Icons.abc_rounded,
          description:
              'Tetragrammaton — kutsal ismi simgeler; '
              'evrenin ilahi düzenini temsil eder.',
        ),
      ],
      aiInsight:
          'Kader Çarkı, hayatın sürekli hareket halinde olduğunu '
          'hatırlatır. Bu kart seni değişime teslim olmaya davet eder. '
          'Şu an nerede olursan ol, çark dönmeye devam edecek. '
          'Direnç yerine akışa güven; her dönüş yeni bir fırsattır.',
      relatedIds: [0, 13, 20],
      heroTag: 'card_detail_hero_10',
    ),
    CardDetailContent(
      id: 11,
      name: 'Justice',
      displayNameTr: 'Adalet',
      imageAsset: '$_root/11_adalet.png',
      arcanaType: 'Major Arcana',
      element: 'Hava',
      planet: 'Venüs',
      zodiac: 'Terazi',
      number: 11,
      keywords: ['Adalet', 'Denge', 'Gerçek', 'Sorumluluk', 'Karar'],
      accentColor: Color(0xFF9B59B6),
      meanings: CardMeaningSections(
        general:
            'Adalet kartı denge, hakkaniyet ve eylemlerin sonuçlarını '
            'temsil eder. Terazi ve kılıç, kalp ile aklın, merhamet ile '
            'gerçeğin dengelenmesi gerektiğini hatırlatır.',
        upright:
            'Düz konumda adalet, doğruluk ve sorumluluk öne çıkar. '
            'Kararlar verilecek; geçmiş eylemlerin sonuçları ortaya '
            'çıkacak.',
        reversed:
            'Ters Adalet, adaletsizlik, önyargı veya sorumluluktan '
            'kaçmayı gösterir. Gerçeği görmezden gelmek dengeyi '
            'bozar; dürüst ol.',
        love:
            'Aşkta dürüstlük ve denge kritik önem taşır. '
            'İlişkide ver-al dengesi kurulmalı; gizli gerçekler '
            'açığa çıkabilir.',
        career:
            'Kariyerde hukuki konular, sözleşmeler veya adil '
            'değerlendirme gündeme gelir. Etik davranış ödüllendirilir.',
        money:
            'Maddi konularda adil anlaşmalar ve denge önemli. '
            'Borç-alacak dengesi kurulmalı; şeffaflık güven getirir.',
        spiritual:
            'Ruhsal yolculukta karma yasası devreye girer. '
            'Ektiğin ne ise onu biçeceksin; niyetlerin önem kazanır.',
        health:
            'Bedensel denge ve uyum önem kazanır. Aşırılıklardan '
            'kaçın; orta yolu bulmak iyileşmeyi destekler.',
        personality:
            'Adalet enerjisi taşıyan biri dürüst, dengeli ve '
            'objektiftir. Doğruluktan ödün vermez; sorumluluk alır.',
        shadow:
            'Gölge yönü acımasız yargı, katılık ve '
            'merhametsizliktir. Adalet merhametten yoksun olduğunda '
            'baskıya dönüşür.',
        advice:
            'Dürüst ol ve sorumluluğunu üstlen. Gerçeği gör; '
            'denge hem kalbin hem aklın arasında kurulur.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Terazi',
          icon: Icons.balance_rounded,
          description:
              'Denge ve adaleti simgeler; kararların '
              'tartılarak verilmesi gerektiğini hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Kılıç',
          icon: Icons.gavel_rounded,
          description:
              'Gerçeği keskin bir şekilde ortaya koymayı simgeler; '
              'adaletin kesin ve net olması gerektiğini anlatır.',
        ),
        CardSymbolEntry(
          name: 'Kırmızı Cüppe',
          icon: Icons.checkroom_rounded,
          description:
              'Tutku ve eylemi simgeler; adaletin pasif '
              'değil aktif bir süreç olduğunu hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Taht',
          icon: Icons.chair_rounded,
          description:
              'Otoriteyi ve karar verme gücünü simgeler; '
              'adaletin yüksek bir sorumluluk olduğunu temsil eder.',
        ),
      ],
      aiInsight:
          'Adalet kartı, evrenin her eylemi kaydettiğini hatırlatır. '
          'Bu kart seni dürüstlüğe ve sorumluluğa davet eder. Gerçek '
          'her zaman ortaya çıkar; gizlemek yalnızca dengeyi bozar. '
          'Merhamet ve adalet bir arada yürür.',
      relatedIds: [4, 8, 20],
      heroTag: 'card_detail_hero_11',
    ),
    CardDetailContent(
      id: 12,
      name: 'The Hanged Man',
      displayNameTr: 'Asılan Adam',
      imageAsset: '$_root/12_asilan_adam.png',
      arcanaType: 'Major Arcana',
      element: 'Su',
      planet: 'Neptün',
      zodiac: 'Balık',
      number: 12,
      keywords: ['Teslimiyet', 'Bekleme', 'Perspektif', 'Fedakarlık', 'Duraklama'],
      accentColor: Color(0xFF7B9EAF),
      meanings: CardMeaningSections(
        general:
            'Asılan Adam, gönüllü duraklamayı ve bakış açısı '
            'değişimini temsil eder. Baş aşağı asılı figür, dünyayı '
            'farklı görmeyi ve teslimiyeti simgeler.',
        upright:
            'Düz konumda bekleme, teslim olma ve perspektif '
            'değişikliği gündeme gelir. Acele etme; duraklama '
            'bilgelik getirecek.',
        reversed:
            'Ters Asılan Adam, direnç, boşa harcanan fedakarlık '
            'veya kaçışı gösterir. Teslim olmak ile pes etmek '
            'arasındaki farkı ayırt et.',
        love:
            'Aşkta sabır ve beklemek gerekebilir. İlişkide '
            'fedakarlık gündeme gelir; ancak kendini feda '
            'etmekten kaçın.',
        career:
            'Kariyerde duraklama veya yön değişikliği olabilir. '
            'Bu bekleyiş dönemi yeni bir perspektif kazandıracak.',
        money:
            'Maddi konularda harcamaları gözden geçir. '
            'Beklemek bazen en akıllıca yatırım kararıdır.',
        spiritual:
            'Ruhsal uyanış için gönüllü teslimiyet gerekir. '
            'Ego kontrolü bıraktığında derin bir içgörü gelir.',
        health:
            'İyileşme süreci yavaş olabilir; sabır gerekir. '
            'Alternatif tedavi yöntemleri faydalı olabilir.',
        personality:
            'Asılan Adam enerjisi taşıyan biri sabırlı, '
            'derin düşünen ve fedakardır. Acele etmez; olgun '
            'kararlar alır.',
        shadow:
            'Gölge yönü kurban rolü, pasiflik ve kaçış '
            'fantezisidir. Teslimiyet bahanesiyle sorumluluktan '
            'kaçmak büyümeyi engeller.',
        advice:
            'Dur ve bakış açısını değiştir. Bazen en büyük '
            'ilerleme hareketsizlikte gizlidir; teslim ol ve öğren.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Ters Asılı Figür',
          icon: Icons.swap_vert_rounded,
          description:
              'Perspektif değişimini simgeler; dünyayı '
              'farklı açıdan görmek bilgelik getirir.',
        ),
        CardSymbolEntry(
          name: 'Hale',
          icon: Icons.all_inclusive_rounded,
          description:
              'Başın etrafındaki ışık halesi, ruhsal '
              'aydınlanmayı ve gönüllü fedakarlığı simgeler.',
        ),
        CardSymbolEntry(
          name: 'Ağaç',
          icon: Icons.park_rounded,
          description:
              'Yaşam ağacını simgeler; duraklama döneminin '
              'büyümenin parçası olduğunu hatırlatır.',
        ),
        CardSymbolEntry(
          name: 'Bağlı Ayak',
          icon: Icons.link_rounded,
          description:
              'Gönüllü bağlılığı simgeler; zorla değil '
              'seçerek teslim olmayı temsil eder.',
        ),
      ],
      aiInsight:
          'Asılan Adam, durmanın da bir eylem olduğunu hatırlatır. '
          'Bu kart seni acele etmekten alıkoyar ve yeni bir bakış '
          'açısına davet eder. Baş aşaşı gördüğünde dünya değişir; '
          'teslimiyet bazen en cesur adımdır.',
      relatedIds: [9, 13, 18],
      heroTag: 'card_detail_hero_12',
    ),
    CardDetailContent(
      id: 13,
      name: 'Death',
      displayNameTr: 'Ölüm',
      imageAsset: '$_root/13_olum.png',
      arcanaType: 'Major Arcana',
      element: 'Su',
      planet: 'Plüton',
      zodiac: 'Akrep',
      number: 13,
      keywords: ['Dönüşüm', 'Son', 'Yenilenme', 'Bırakma', 'Geçiş'],
      accentColor: Color(0xFF6B4BC4),
      meanings: CardMeaningSections(
        general:
            'Ölüm kartı fiziksel ölümü değil, köklü dönüşümü temsil '
            'eder. Eski bir döngünün sonu ve yeni bir başlangıcın '
            'eşiği; bırakmak ve yeniden doğuş bu kartın özüdür.',
        upright:
            'Düz konumda dönüşüm, son ve yenilenme müjdelenir. '
            'Artık hizmet etmeyen bir şey sona eriyor; direnme, '
            'akışa teslim ol.',
        reversed:
            'Ters Ölüm, değişime direnç, takılı kalma veya '
            'korkuyla yüzleşmemeyi gösterir. Eskiyi bırakmak acı '
            'verebilir ama büyüme için gereklidir.',
        love:
            'Aşkta bir ilişki döneminin sonu veya derin '
            'dönüşüm mümkün. Eski kalıpları bırakmak yeni bir '
            'bağ için alan açar.',
        career:
            'Kariyerde köklü değişiklik, iş değişikliği veya '
            'bir dönemin kapanması gündeme gelebilir. Endişelenme; '
            'bu geçiş yenilenme getirir.',
        money:
            'Maddi konularda eski harcama alışkanlıklarını '
            'bırakma zamanı. Finansal yeniden yapılandırma faydalı.',
        spiritual:
            'Ruhsal ölüm ve yeniden doğuş en derin dönüşümdür. '
            'Ego ölür, gerçek benlik doğar; korkma, teslim ol.',
        health:
            'Bedensel veya zihinsel bir dönüşüm süreci '
            'başlayabilir. Eski alışkanlıkları bırakmak iyileşmeyi '
            'hızlandırır.',
        personality:
            'Ölüm enerjisi taşıyan biri dönüşümün ustasıdır. '
            'Değişimi kucaklar; bırakmayı bilir. Derin ve yoğundur.',
        shadow:
            'Gölge yönü yıkım takıntısı, değişim korkusu ve '
            'geçmişe tutunmaktır. Her sonu kabul edememek '
            'büyümeyi engeller.',
        advice:
            'Bırak ve yenilen. Her son yeni bir başlangıçtır; '
            'direnmek acıyı uzatır, teslim olmak özgürleştirir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'İskelet Binici',
          icon: Icons.skateboarding_rounded,
          description:
              'Ölümün kaçınılmazlığını simgeler; tüm '
              'canlıların geçiş noktasını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Siyah Bayrak',
          icon: Icons.flag_rounded,
          description:
              'Dönüşümün bayrağını simgeler; eski '
              'dönemin resmen sona erdiğini anlatır.',
        ),
        CardSymbolEntry(
          name: 'Güneş',
          icon: Icons.wb_sunny_rounded,
          description:
              'Ufukta doğan güneş, yeniden doğuşu simgeler; '
              'her sonun ardında yeni bir gün vardır.',
        ),
        CardSymbolEntry(
          name: 'Papa',
          icon: Icons.church_rounded,
          description:
              'Ruhsal otoriteyi simgeler; ölümün ruhsal '
              'anlamını ve kutsal geçişi temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Çocuklar',
          icon: Icons.child_care_rounded,
          description:
              'Masumiyeti simgeler; dönüşümün ardından '
              'gelene saf yeniden doğuşu temsil eder.',
        ),
      ],
      aiInsight:
          'Ölüm kartı, en çok korkulan ama en dönüştürücü '
          'arkadaşındır. Bu kart seni eskiyi bırakmaya davet '
          'eder. Gerçek ölüm değil, ego ve kalıpların ölümü '
          'söz konusudur. Her son, daha büyük bir başlangıcın habercisidir.',
      relatedIds: [10, 12, 16],
      heroTag: 'card_detail_hero_13',
    ),
    CardDetailContent(
      id: 14,
      name: 'Temperance',
      displayNameTr: 'Denge',
      imageAsset: '$_root/14_denge.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Jüpiter',
      zodiac: 'Yay',
      number: 14,
      keywords: ['Denge', 'Uyum', 'Sabır', 'İyileşme', 'Orta yol'],
      accentColor: Color(0xFF64B5F6),
      meanings: CardMeaningSections(
        general:
            'Denge kartı uyum, sabır ve zıt güçlerin birleşimini '
            'temsil eder. Melek figürün iki kupadan akan su, denge '
            've ılımlılığın sanatını simgeler.',
        upright:
            'Düz konumda denge, uyum ve sabırlı ilerleme '
            'müjdelenir. Aşırılıklardan kaçın; orta yol en '
            'bilge seçimdir.',
        reversed:
            'Ters Denge, dengesizlik, aşırılık veya sabırsızlığı '
            'gösterir. Acele etmek uyumu bozar; yavaşla ve '
            'dengeyi yeniden kur.',
        love:
            'Aşkta uyum, sabır ve derin anlayış öne çıkar. '
            'İlişkide denge kuruluyor; taraflar birbirini '
            'tamamlıyor.',
        career:
            'Kariyerde iş birliği ve uyumlu ortaklıklar '
            'başarı getirir. Sabırlı ve dengeli yaklaşım '
            'mevki kazandırır.',
        money:
            'Maddi konularda dengeli harcama ve birikim '
            'önemli. Ne aşırı cimrilik ne savurganlık; '
            'orta yolu bul.',
        spiritual:
            'Ruhsal alkimya — zıt enerjilerin birleşimi '
            'derin bir bütünlük yaratır. Meditasyon ve nefes '
            'çalışmaları bu dönemde güçlüdür.',
        health:
            'İyileşme süreci yavaş ama kalıcıdır. Dengeli '
            'beslenme, uyku ve egzersiz bedeni destekler.',
        personality:
            'Denge enerjisi taşıyan biri sakin, uyumlu ve '
            'sabırlıdır. Çatışmalardan kaçınmaz ama barışçıl '
            'çözümler arar.',
        shadow:
            'Gölge yönü aşırı uyumluluk, kararsızlık ve '
            'duygusal bastırmadır. Her şeyi dengelemek '
            'gerçek duyguları gizleyebilir.',
        advice:
            'Sabırlı ol ve orta yolu bul. Aşırılıklardan '
            'kaçın; gerçek güç uyum ve dengeyle gelir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Melek',
          icon: Icons.flutter_dash_rounded,
          description:
              'İlahi rehberliği ve ruhsal dengeyi simgeler; '
              'dünyevi ile ruhsal arasındaki köprüyü temsil eder.',
        ),
        CardSymbolEntry(
          name: 'İki Kupa',
          icon: Icons.water_drop_rounded,
          description:
              'Zıt enerjilerin birleşimini simgeler; '
              'su aktarımı alkimyanın sembolüdür.',
        ),
        CardSymbolEntry(
          name: 'Ayak Su',
          icon: Icons.waves_rounded,
          description:
              'Bir ayağın sudaki, birinin karadaki olması '
              'dünyevi ile ruhsal arasındaki dengeyi simgeler.',
        ),
        CardSymbolEntry(
          name: 'Güneş Yolu',
          icon: Icons.wb_sunny_rounded,
          description:
              'Arkada yükselen dağa giden yol, ruhsal '
              'yükselişi ve aydınlanmayı simgeler.',
        ),
      ],
      aiInsight:
          'Denge kartı, hayatın bir alkimya olduğunu hatırlatır. '
          'Bu kart seni sabırlı olmaya ve zıt güçleri uyumla '
          'birleştirmeye davet eder. Acele etme; en güzel '
          'sonuçlar yavaş ve bilinçli ilerlemeyle gelir.',
      relatedIds: [3, 6, 17],
      heroTag: 'card_detail_hero_14',
    ),
    CardDetailContent(
      id: 15,
      name: 'The Devil',
      displayNameTr: 'Şeytan',
      imageAsset: '$_root/15_seytan.png',
      arcanaType: 'Major Arcana',
      element: 'Toprak',
      planet: 'Satürn',
      zodiac: 'Oğlak',
      number: 15,
      keywords: ['Bağımlılık', 'Gölge', 'Maddi bağ', 'Tutku', 'Kısıtlama'],
      accentColor: Color(0xFF8B2942),
      meanings: CardMeaningSections(
        general:
            'Şeytan kartı gerçek bir şeytani varlığı değil, içsel '
            'bağımlılıkları ve gölge yönleri temsil eder. Zincirler '
            'gevşektir; özgür iradeyle kurtulmak mümkündür.',
        upright:
            'Düz konumda bağımlılık, obsesyon veya maddi dünyaya '
            'aşırı bağlılık gündeme gelir. Zincirlerin farkına var; '
            'kurtulmak için önce farkındalık gerekir.',
        reversed:
            'Ters Şeytan, bağımlılıktan kurtuluş, gölgeyle yüzleşme '
            'veya özgürleşmeyi gösterir. Zincirler kırılıyor; '
            'karanlıkla yüzleşme cesareti taşırsın.',
        love:
            'Aşkta toksik bağ, obsesyon veya cinsel tutku gündeme '
            'gelebilir. Sağlıklı sınırlar koy; bağımlılık aşk değildir.',
        career:
            'Kariyerde maddi güvenlik uğruna ruhunu satma riski '
            'var. Altın kafeste yaşamak özgürlük değildir; değerlerini '
            'sorgula.',
        money:
            'Maddi konularda aşırı hırs veya borç tuzağı olabilir. '
            'Para peşinde koşarken ruhunu kaybetme.',
        spiritual:
            'Gölge çalışması bu dönemde kritik önem taşır. '
            'Bastırılmış korkular ve arzular yüzeye çıkmaya hazır.',
        health:
            'Bağımlılıklar — sigara, alkol, şeker — sağlığı '
            'tehdit edebilir. Bedensel bağımlılıklardan kurtulma '
            'zamanı.',
        personality:
            'Şeytan enerjisi taşıyan biri karizmatik, tutkulu ve '
            'manyetiktir. Ancak karanlık çekiciliği bağımlılık '
            'yaratabilir.',
        shadow:
            'Gölge yönü manipülasyon, kontrol ve maddi '
            'dünyaya köleliktir. Zincirleri fark etmeden yaşamak '
            'en derin hapishanedir.',
        advice:
            'Zincirlerinin farkına var; onlar gevşektir. '
            'Bağımlılıkların seni kontrol etmesine izin verme; '
            'özgür iraden hâlâ seninle.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Baphomet',
          icon: Icons.pentagon_rounded,
          description:
              'Maddi ve ruhsal dünyanın birleşimini simgeler; '
              'karanlık bilgeliğin sembolik figürüdür.',
        ),
        CardSymbolEntry(
          name: 'Zincirler',
          icon: Icons.link_rounded,
          description:
              'Bağımlılık ve kısıtlamayı simgeler; ancak '
              'gevşek oldukları için kurtulmak mümkündür.',
        ),
        CardSymbolEntry(
          name: 'Meşale',
          icon: Icons.local_fire_department_rounded,
          description:
              'Ters tutulmuş meşale, bastırılmış tutkuyu '
              'simgeler; arzuların gölgede kalmasını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Boynuzlar',
          icon: Icons.crisis_alert_rounded,
          description:
              'Hayvan içgüdülerini simgeler; vahşi '
              've kontrol edilmemiş arzuları temsil eder.',
        ),
      ],
      aiInsight:
          'Şeytan kartı, en karanlık zincirlerin bile gevşek '
          'olduğunu hatırlatır. Bu kart seni bağımlılıklarınla '
          'yüzleşmeye davet eder. Kurtulmak için önce fark '
          'etmek gerekir. Gölge senin bir parçan; onu reddetmek '
          'güç verir, kabul etmek özgürleştirir.',
      relatedIds: [6, 13, 16],
      heroTag: 'card_detail_hero_15',
    ),
    CardDetailContent(
      id: 16,
      name: 'The Tower',
      displayNameTr: 'Kule',
      imageAsset: '$_root/16_kule.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Mars',
      zodiac: 'Mars',
      number: 16,
      keywords: ['Yıkım', 'Sarsıntı', 'Aydınlanma', 'Gerçek', 'Kriz'],
      accentColor: Color(0xFFE74C3C),
      meanings: CardMeaningSections(
        general:
            'Kule kartı ani yıkımı, sahte yapıların çöküşünü ve '
            'gerçeğin sarsıcı ortaya çıkışını temsil eder. Yıldırım '
            'kuleyi yıkar; ancak temeli sağlam olan kalır.',
        upright:
            'Düz konumda ani değişim, kriz veya şok gündeme '
            'gelir. Sahte temeller çöküyor; acı verici ama '
            'gerekli bir temizlik.',
        reversed:
            'Ters Kule, yıkımdan kaçınma, bastırılmış kriz '
            'veya yavaş çözülmeyi gösterir. Değişimi ertelemek '
            'patlamayı büyütür; yüzleş.',
        love:
            'Aşkta ani ayrılık, ifşa veya ilişkide köklü '
            'sarsıntı mümkün. Sağlam temeller kalır; sahte '
            'olanlar düşer.',
        career:
            'Kariyerde ani kayıp, işten çıkarma veya '
            'organizasyonel çöküş olabilir. Kriz aynı zamanda '
            'yeni fırsatların kapısını açar.',
        money:
            'Maddi kayıp veya beklenmedik harcama gündeme '
            'gelebilir. Güvenli olmayan yatırımlar risk taşır.',
        spiritual:
            'Ruhsal uyanış bazen yıkıcı gelir. Ego kulesi '
            'yıkıldığında gerçek benlik ortaya çıkar.',
        health:
            'Ani sağlık krizi veya stres kaynaklı çöküş '
            'olabilir. Uyarı sinyallerini ciddiye al.',
        personality:
            'Kule enerjisi taşıyan biri yoğun, patlayıcı ve '
            'dönüştürücüdür. İstikrarsızlık yaratabilir ama '
            'gerçeği ortaya çıkarır.',
        shadow:
            'Gölge yönü yıkım takıntısı, kaos yaratma '
            've kontrolsüz öfke. Her şeyi yıkmak iyileşme '
            'değil, kaçış olabilir.',
        advice:
            'Yıkılan temeller sağlam değildi. Kriz acı '
            'verir ama gerçeği ortaya çıkarır; direnme, '
            'yeniden inşa et.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Yıldırım',
          icon: Icons.bolt_rounded,
          description:
              'Ani ilahi müdahaleyi simgeler; sahte '
              'yapıları yıkan sarsıcı gerçeği temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Yıkılan Kule',
          icon: Icons.domain_disabled_rounded,
          description:
              'Ego ve sahte otoritenin çöküşünü simgeler; '
              'temeli sağlam olmayanın sonu gelmiştir.',
        ),
        CardSymbolEntry(
          name: 'Taç',
          icon: Icons.emoji_events_rounded,
          description:
              'Düşen taç, yıkılan otoriteyi simgeler; '
              'gurur ve kibirin bedelini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Alevler',
          icon: Icons.local_fire_department_rounded,
          description:
              'Yıkımın ardından gelen arınmayı simgeler; '
              'ateş eskiyi yakarak yeniye yer açar.',
        ),
      ],
      aiInsight:
          'Kule kartı, en sarsıcı ama en dürüst arkadaşındır. '
          'Bu kart seni sahte temellerin çöküşüne hazırlar. Acı '
          'verici olsa da yıkım arınmadır; gerçek her zaman '
          'özgürlük getirir. Yeniden inşa etmek için önce '
          'eskiyi bırak.',
      relatedIds: [13, 15, 20],
      heroTag: 'card_detail_hero_16',
    ),
    CardDetailContent(
      id: 17,
      name: 'The Star',
      displayNameTr: 'Yıldız',
      imageAsset: '$_root/17_yildiz.png',
      arcanaType: 'Major Arcana',
      element: 'Hava',
      planet: 'Uranüs',
      zodiac: 'Kova',
      number: 17,
      keywords: ['Umut', 'Rehberlik', 'İlham', 'Yenilenme', 'Huzur'],
      accentColor: Color(0xFF9B6DFF),
      meanings: CardMeaningSections(
        general:
            'Yıldız kartı karanlıktan sonra gelen umut ve ilahi '
            'rehberliği temsil eder. Çıplak figürün sudan dökmesi, '
            'ruhsal arınma ve yenilenmeyi simgeler.',
        upright:
            'Düz konumda umut, ilham ve ruhsal rehberlik '
            'müjdelenir. Zorlu bir dönemin ardından huzur '
            'geliyor; evrene güven.',
        reversed:
            'Ters Yıldız, umutsuzluk, ilham kaybı veya '
            'bağlantı kopukluğunu gösterir. Işık hâlâ orada; '
            'gözlerini kapatmış olabilirsin.',
        love:
            'Aşkta umut, iyileşme ve derin ruhsal bağ '
            'mümkün. Yeni bir aşk veya mevcut ilişkide '
            'yenilenme kapıda.',
        career:
            'Kariyerde ilham, yaratıcılık ve rehberlik '
            'rolü öne çıkar. Hayallerin gerçekleşmeye '
            'başlıyor.',
        money:
            'Maddi konularda umut ve yeni fırsatlar '
            'doğuyor. Cömertlik ve paylaşım bolluğu çeker.',
        spiritual:
            'Ruhsal rehberlik güçlü; meditasyon ve '
            'yıldızlara bakmak derin içgörüler sunar. '
            'Evren seninle konuşuyor.',
        health:
            'İyileşme ve yenilenme süreci başlıyor. '
            'Su terapileri ve doğada vakit geçirmek '
            'bedeni destekler.',
        personality:
            'Yıldız enerjisi taşıyan biri umut verici, '
            'ilham kaynağı ve huzur yayıcıdır. Başkalarına '
            'ışık olur.',
        shadow:
            'Gölge yönü hayal kırıklığı, kaçış '
            'fantezisi ve gerçeklikten kopmadır. Umut '
            'pasiflik bahanesi olmamalı.',
        advice:
            'Umut et ve evrene güven. Karanlığın ardından '
            'her zaman yıldızlar parlar; sen de o ışıksın.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Sekiz Yıldız',
          icon: Icons.star_rounded,
          description:
              'İlahi rehberliği simgeler; büyük yıldız '
              'umut ve hedefi, küçükler yol göstericileri temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Su Dökme',
          icon: Icons.water_drop_rounded,
          description:
              'Ruhsal arınmayı simgeler; bilinçli '
              've bilinçsiz arasındaki akışı temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Çıplak Figür',
          icon: Icons.self_improvement_rounded,
          description:
              'Saflığı ve savunmasızlığı simgeler; '
              'gerçek benliğin maskesiz ortaya çıkışını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Kuş',
          icon: Icons.flutter_dash_rounded,
          description:
              'İlahi mesajcıyı simgeler; ruhsal '
              'rehberliğin sembolik temsilidir.',
        ),
      ],
      aiInsight:
          'Yıldız kartı, en karanlık gecenin ardından '
          'parlayan ilk ışıktır. Bu kart seni umut etmeye '
          've evrene güvenmeye davet eder. Yıkımın ardından '
          'gelir; yenilenme ve huzur müjdesi taşır. '
          'Sen de bir yıldızsın.',
      relatedIds: [0, 14, 19],
      heroTag: 'card_detail_hero_17',
    ),
    CardDetailContent(
      id: 18,
      name: 'The Moon',
      displayNameTr: 'Ay',
      imageAsset: '$_root/18_ay.png',
      arcanaType: 'Major Arcana',
      element: 'Su',
      planet: 'Ay',
      zodiac: 'Balık',
      number: 18,
      keywords: ['Sezgi', 'Gizem', 'Rüya', 'Korku', 'Bilinçaltı'],
      accentColor: Color(0xFFB794FF),
      meanings: CardMeaningSections(
        general:
            'Ay kartı bilinçaltının derin sularını, rüya '
            'alemini ve gizemi temsil eder. Her şey göründüğü '
            'gibi değil; sezgi rehberin olmalı.',
        upright:
            'Düz konumda sezgi güçlenir, rüyalar anlam '
            'kazanır. Korkular yüzeye çıkabilir; onlarla '
            'yüzleş, gerçeği gör.',
        reversed:
            'Ters Ay, kafa karışıklığı, yanılsama veya '
            'korkuların kontrolünü gösterir. Gerçek ile '
            'hayal arasındaki çizgiyi netleştir.',
        love:
            'Aşkta gizli duygular, belirsizlik veya '
            'derin sezgisel bağ gündeme gelir. Sabırlı ol; '
            'gerçek zamanla açığa çıkar.',
        career:
            'Kariyerde belirsizlik ve sezgisel kararlar '
            'önem kazanır. Her bilgiyi açıkça paylaşma; '
            'stratejik bekle.',
        money:
            'Maddi konularda gizli riskler veya '
            'belirsiz fırsatlar olabilir. Detayları '
            'araştır, acele etme.',
        spiritual:
            'Ruhsal yolculukta rüya çalışması, ay '
            'ritüelleri ve sezgi geliştirme bu dönemde '
            'derin içgörüler sunar.',
        health:
            'Uyku düzeni ve duygusal sağlık önem '
            'kazanır. Hormonal döngülere dikkat et.',
        personality:
            'Ay enerjisi taşıyan biri gizemli, sezgisel '
            've derindir. Rüyaları canlıdır; duygusal '
            'dalgalar yaşar.',
        shadow:
            'Gölge yönü paranoya, yanılsama ve '
            'korkularla yaşamaktır. Gerçek ile hayali '
            'karıştırmak yolunu kaybettirir.',
        advice:
            'Sezgine güven ama korkularına teslim olma. '
            'Ay ışığında her şey farklı görünür; sabırla '
            'gerçeği bekle.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Ay',
          icon: Icons.nightlight_round,
          description:
              'Bilinçaltını ve sezgisel bilgeliği simgeler; '
              'yarı aydınlık gerçeğin sembolüdür.',
        ),
        CardSymbolEntry(
          name: 'Kurt ve Köpek',
          icon: Icons.pets_rounded,
          description:
              'Vahşi ve evcil içgüdüleri simgeler; '
              'bilinçaltının iki yüzünü temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Yengeç',
          icon: Icons.water_rounded,
          description:
              'Bilinçaltından çıkan korkuları simgeler; '
              'derin suların gizemli yaratıklarını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Yol',
          icon: Icons.route_rounded,
          description:
              'İki kule arasındaki belirsiz yol, '
              'sezgiyle yürünmesi gereken gizemli '
              'patikayı simgeler.',
        ),
        CardSymbolEntry(
          name: 'Suy Yükseltisi',
          icon: Icons.waves_rounded,
          description:
              'Bilinçaltının yüzeye çıkışını simgeler; '
              'bastırılmış duyguların kabarmasını temsil eder.',
        ),
      ],
      aiInsight:
          'Ay kartı, görünmeyen dünyanın kapısını aralar. '
          'Bu kart seni sezgine güvenmeye davet eder. Her '
          'şey göründüğü gibi değil; korkuların seni '
          'aldatmasına izin verme. Ay ışığında yürümek '
          'cesaret ister.',
      relatedIds: [2, 9, 17],
      heroTag: 'card_detail_hero_18',
    ),
    CardDetailContent(
      id: 19,
      name: 'The Sun',
      displayNameTr: 'Güneş',
      imageAsset: '$_root/19_gunes.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Güneş',
      zodiac: 'Aslan',
      number: 19,
      keywords: ['Neşe', 'Başarı', 'Aydınlanma', 'Canlılık', 'Işık'],
      accentColor: Color(0xFFF0D77A),
      meanings: CardMeaningSections(
        general:
            'Güneş kartı saf neşe, başarı ve aydınlanmayı '
            'temsil eder. Çocuk figürü ve parlayan güneş, '
            'hayatın en parlak anlarını simgeler.',
        upright:
            'Düz konumda neşe, başarı ve canlılık '
            'müjdelenir. Her şey aydınlıkta; korkular '
            'dağılıyor. Kutla!',
        reversed:
            'Ters Güneş, geçici hayal kırıklığı, gecikmiş '
            'başarı veya iç ışığın gizlenmesini gösterir. '
            'Işık hâlâ orada; bulutlar geçici.',
        love:
            'Aşkta mutluluk, tutku ve açık iletişim '
            'hakim. İlişki parlıyor; kalbin güneş gibi '
            'sıcak.',
        career:
            'Kariyerde başarı, tanınma ve hedeflere '
            'ulaşma müjdelenir. Emeklerinin meyvesini '
            'topluyorsun.',
        money:
            'Maddi bolluk ve refah artıyor. Yatırımlar '
            'meyve veriyor; cömertlik bereketi çoğaltır.',
        spiritual:
            'Ruhsal aydınlanma ve iç ışığın parlaması '
            'mümkün. Meditasyon ve güneş banyosu derin '
            'huzur verir.',
        health:
            'Enerji yüksek, sağlık parlak. D vitamini '
            've açık hava bedeni canlandırır.',
        personality:
            'Güneş enerjisi taşıyan biri neşeli, '
            'canlı ve iyimserdir. Çevresine ışık saçar; '
            'herkes onunla parlar.',
        shadow:
            'Gölge yönü aşırı iyimserlik, gerçeklikten '
            'kopma veya ego şişkinliğidir. Işık '
            'gölgeyi reddetmek dengeyi bozar.',
        advice:
            'Parla ve kutla. Hayatın en güzel anlarından '
            'birindesin; neşeni paylaş, ışığın başkalarına '
            'da yol göstersin.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Güneş',
          icon: Icons.wb_sunny_rounded,
          description:
              'Yaşam kaynağını ve aydınlanmayı simgeler; '
              'tüm karanlığı dağıtan saf ışığı temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Çocuk',
          icon: Icons.child_care_rounded,
          description:
              'Saflığı ve masum neşeyi simgeler; '
              'iç çocuğun özgür ifadesini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Beyaz At',
          icon: Icons.pets_rounded,
          description:
              'Saflığı ve zaferi simgeler; bilinçli '
              'ruhun ilerleyişini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Ayçiçeği',
          icon: Icons.local_florist_rounded,
          description:
              'Güneşe dönüşü simgeler; yaşam '
              'enerjisinin en yüksek ifadesini temsil eder.',
        ),
      ],
      aiInsight:
          'Güneş kartı, tarot destesinin en aydınlık '
          'mesajıdır. Bu kart seni neşelenmeye ve '
          'başarını kutlamaya davet eder. Karanlık '
          'geçti; şimdi parlamanın zamanı. Içindeki '
          'çocuk özgürce dans etsin.',
      relatedIds: [0, 6, 17],
      heroTag: 'card_detail_hero_19',
    ),
    CardDetailContent(
      id: 20,
      name: 'Judgement',
      displayNameTr: 'Mahkeme',
      imageAsset: '$_root/20_yargi.png',
      arcanaType: 'Major Arcana',
      element: 'Ateş',
      planet: 'Plüton',
      zodiac: 'Akrep',
      number: 20,
      keywords: ['Yeniden doğuş', 'Çağrı', 'Değerlendirme', 'Affetme', 'Uyanış'],
      accentColor: Color(0xFFE8D5B7),
      meanings: CardMeaningSections(
        general:
            'Mahkeme kartı ruhsal uyanışı, içsel çağrıyı '
            've geçmişin değerlendirilmesini temsil eder. '
            'Mezarlardan kalkan figürler, yeniden doğuşu simgeler.',
        upright:
            'Düz konumda uyanış, çağrı ve yeniden doğuş '
            'müjdelenir. Geçmişi değerlendir; affet ve '
            'ilerle. Yeni bir hayat başlıyor.',
        reversed:
            'Ters Mahkeme, öz eleştiri eksikliği, çağrıyı '
            'duymama veya geçmişe takılı kalmayı gösterir. '
            'Kendini affet; ilerlemek için bırak.',
        love:
            'Aşkta geçmişin affedilmesi ve ilişkide '
            'yenilenme mümkün. Eski yaralar iyileşiyor; '
            'yeni bir sayfa açılıyor.',
        career:
            'Kariyerde değerlendirme, terfi veya '
            'hayat amacına uygun yeni bir yön gündeme '
            'gelebilir. Çağrını duy.',
        money:
            'Maddi geçmişi değerlendirme ve yeni '
            'planlar yapma zamanı. Eski borçları '
            'kapat; temiz sayfa aç.',
        spiritual:
            'Ruhsal uyanışın zirvesindesin. İlahi '
            'çağrıyı duy; hayat amacın netleşiyor.',
        health:
            'İyileşme ve yenilenme tamamlanıyor. '
            'Bedensel ve ruhsal sağlık bir arada '
            'güçleniyor.',
        personality:
            'Mahkeme enerjisi taşıyan biri derin, '
            'düşünceli ve dönüştürücüdür. Geçmişi '
            'değerlendirir; affetmeyi bilir.',
        shadow:
            'Gölge yönü aşırı yargı, affedememe '
            've geçmişe takılı kalma. Kendini affetmeden '
            'başkalarını affedemezsin.',
        advice:
            'Geçmişi değerlendir, affet ve uyan. '
            'Çağrın seni bekliyor; yeniden doğuş '
            'cesareti gerektirir.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Melek Trompeti',
          icon: Icons.campaign_rounded,
          description:
              'İlahi çağrıyı simgeler; uyanış '
              'anının habercisini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Mezarlardan Kalkanlar',
          icon: Icons.groups_rounded,
          description:
              'Yeniden doğuşu simgeler; geçmişin '
              'ağırlığından kurtularak yükselişi temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Dağlar',
          icon: Icons.terrain_rounded,
          description:
              'Ruhsal yükselişi simgeler; uyanışın '
              'getirdiği perspektif değişimini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Haç Bayrak',
          icon: Icons.flag_rounded,
          description:
              'Kurtuluşu simgeler; ruhsal '
              'zaferin sembolik işaretidir.',
        ),
      ],
      aiInsight:
          'Mahkeme kartı, hayatının en derin çağrısını '
          'fısıldar. Bu kart seni geçmişi değerlendirmeye '
          've yeniden doğuşa davet eder. Affetmek zayıflık '
          'değil, en büyük güçtür. Mezarlarından kalk; '
          'yeni hayatın seni bekliyor.',
      relatedIds: [10, 11, 21],
      heroTag: 'card_detail_hero_20',
    ),
    CardDetailContent(
      id: 21,
      name: 'The World',
      displayNameTr: 'Dünya',
      imageAsset: '$_root/21_dunya.png',
      arcanaType: 'Major Arcana',
      element: 'Toprak',
      planet: 'Satürn',
      zodiac: 'Oğlak',
      number: 21,
      keywords: ['Tamamlanma', 'Bütünlük', 'Başarı', 'Döngü', 'Kutlama'],
      accentColor: Color(0xFF5D8A66),
      meanings: CardMeaningSections(
        general:
            'Dünya kartı bir döngünün tamamlanmasını, '
            'bütünlüğü ve evrensel uyumu temsil eder. '
            'Major Arcana yolculuğunun sonu; başarı ve kutlama.',
        upright:
            'Düz konumda tamamlanma, başarı ve bütünlük '
            'müjdelenir. Uzun bir yolculuk sona eriyor; '
            'kutla ve yeni döngüye hazırlan.',
        reversed:
            'Ters Dünya, tamamlanmamış işler, eksik '
            'hissi veya son adımı atmaktan kaçınmayı '
            'gösterir. Bitirmek için son adımı at.',
        love:
            'Aşkta derin uyum, tamamlanma ve kalıcı '
            'bağ mümkün. İlişki olgunlaşıyor; ruhsal '
            'birliktelik hakim.',
        career:
            'Kariyerde büyük başarı, proje tamamlanması '
            'veya hedefe ulaşma müjdelenir. Emeklerinin '
            'karşılığını alıyorsun.',
        money:
            'Maddi bolluk ve güvenlik zirvede. '
            'Uzun vadeli yatırımlar meyve veriyor.',
        spiritual:
            'Ruhsal yolculuğun bir döngüsü tamamlanıyor. '
            'Evrensel bilinçle birleşme deneyimi mümkün.',
        health:
            'Bedensel ve zihinsel sağlık dengede. '
            'Holistik iyileşme tamamlanıyor.',
        personality:
            'Dünya enerjisi taşıyan biri bütün, '
            'başarılı ve uyumlu bir varlığa sahiptir. '
            'Her şeyi bir arada tutar.',
        shadow:
            'Gölge yönü tamamlanmaktan korkma, '
            'değişime direnç ve konfor alanında '
            'takılı kalmadır. Her son yeni bir başlangıçtır.',
        advice:
            'Kutla ve tamamla. Bu döngü bitti; yeni '
            'bir macera seni bekliyor. Bütünlük içinde '
            'parla.',
      ),
      symbols: [
        CardSymbolEntry(
          name: 'Laurel Halkası',
          icon: Icons.emoji_events_rounded,
          description:
              'Zaferi ve tamamlanmayı simgeler; '
              'başarıyla sona eren yolculuğu temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Dört Köşe Figür',
          icon: Icons.view_in_ar_rounded,
          description:
              'Dört elementi simgeler; evrenin '
              'tüm güçlerinin birleşimini temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Dans Eden Figür',
          icon: Icons.self_improvement_rounded,
          description:
              'Evrensel uyumu simgeler; özgür '
              'ruhun kutlamasını temsil eder.',
        ),
        CardSymbolEntry(
          name: 'Mor Peçe',
          icon: Icons.curtains_rounded,
          description:
              'Bilinçli ile bilinçsiz arasındaki '
              'örtüyü simgeler; bütünlüğün sembolüdür.',
        ),
      ],
      aiInsight:
          'Dünya kartı, Major Arcana yolculuğunun '
          'muhteşem finalidir. Bu kart seni kutlamaya '
          've bütünlüğü hissetmeye davet eder. Her '
          'döngü bir sonla biter ve yeni bir başlangıçla '
          'devam eder. Sen evrenin bir parçasısın.',
      relatedIds: [0, 1, 10],
      heroTag: 'card_detail_hero_21',
    ),
  ];
}
