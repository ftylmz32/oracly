/// Localized symbolism for major-arcana card detail — static catalogue.
library;


import '../../../../../core/l10n/l10n_triple.dart';
import 'card_detail_models.dart';

class CardDetailSymbolCopy {
  const CardDetailSymbolCopy({
    required this.name,
    required this.description,
  });

  final L10nTriple name;
  final L10nTriple description;
}

/// Per-card localized symbolism (icons stay on [CardDetailContent.symbols]).
abstract final class CardDetailSymbols {
  CardDetailSymbols._();

  static List<CardDetailSymbolCopy>? of(int cardId) => _byId[cardId];

  static final Map<int, List<CardDetailSymbolCopy>> _byId = {
    0: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Beyaz Köpek', 'White Dog', 'Белая собака'),
        description: L10nTriple('Sadakat ve içgüdüsel rehberliği simgeler; bilinçaltının tehlikelere karşı uyarısını temsil eder.', 'Symbolizes loyalty and instinctive guidance; represents the subconscious warning against dangers.', 'Символизирует верность и инстинктивное руководство; представляет предупреждение подсознания об опасностях.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Uçurum Kenarı', 'Cliff Edge', 'Край обрыва'),
        description: L10nTriple('Bilinmeyene atılan adımı anlatır; cesaret ile dikkatsizlik arasındaki ince çizgiyi hatırlatır.', 'Describes the step into the unknown; reminds of the fine line between courage and carelessness.', 'Описывает шаг в неизвестное; напоминает о тонкой грани между смелостью и неосторожностью.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Güneş', 'Sun', 'Солнце'),
        description: L10nTriple('Saf iyimserlik ve yeni bir günün başlangıcını temsil eder; henüz gölgeye düşmemiş potansiyeli simgeler.', 'Represents pure optimism and the beginning of a new day; symbolizes potential that has not yet fallen into shadow.', 'Представляет чистый оптимизм и начало нового дня; символизирует потенциал, ещё не попавший в тень.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Beyaz Gül', 'White Rose', 'Белая роза'),
        description: L10nTriple('Saflık ve masum niyeti işaret eder; kalbin temiz motivasyonlarla hareket etmesi gerektiğini hatırlatır.', 'Points to purity and innocent intention; reminds that the heart should act with clean motivations.', 'Указывает на чистоту и невинное намерение; напоминает, что сердце должно действовать с чистыми мотивами.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Deri Çanta', 'Leather Bag', 'Кожаная сумка'),
        description: L10nTriple('Yolculuk için taşınan deneyimleri simgeler; geçmişten öğrenilenleri yeni maceraya taşımayı anlatır.', 'Symbolizes experiences carried for the journey; describes carrying what was learned from the past into a new adventure.', 'Символизирует опыт, взятый в путь; описывает перенос изученного из прошлого в новое приключение.'),
      ),
    ],
    1: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Sonsuzluk İşareti', 'Infinity Sign', 'Знак бесконечности'),
        description: L10nTriple('Başın üzerindeki lemniskat, sınırsız potansiyeli ve enerjinin döngüsel doğasını simgeler.', 'The lemniscate above the head symbolizes unlimited potential and the cyclical nature of energy.', 'Лемниската над головой символизирует безграничный потенциал и циклическую природу энергии.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dört Element', 'Four Elements', 'Четыре элемента'),
        description: L10nTriple('Kupa, değnek, kılıç ve pentagram masadaki dört suiti temsil eder; tüm kaynakların elinin altında olduğunu anlatır.', 'Cup, wand, sword, and pentagram represent the four suits on the table; describe that all resources are at hand.', 'Кубок, жезл, меч и пентаграмма представляют четыре масти на столе; говорят о том, что все ресурсы под рукой.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Asa', 'Wand', 'Жезл'),
        description: L10nTriple('Yaratıcı iradeyi ve niyetin maddi dünyaya indirilmesini simgeleyen güçlü bir semboldür.', 'A powerful symbol that represents creative will and bringing intention down into the material world.', 'Мощный символ, представляющий творческую волю и низведение намерения в материальный мир.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kırmızı Beyaz Robe', 'Red and White Robe', 'Красно-белая мантия'),
        description: L10nTriple('Tutku ile saflığın birleşimini temsil eder; hem arzu hem bilgelikle hareket etmeyi hatırlatır.', 'Represents the union of passion and purity; reminds one to act with both desire and wisdom.', 'Представляет соединение страсти и чистоты; напоминает действовать и с желанием, и с мудростью.'),
      ),
    ],
    2: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Ay Tahtı', 'Moon Throne', 'Лунный трон'),
        description: L10nTriple('Ay döngülerini ve bilinçaltının dalgalı doğasını simgeler; sezgisel bilgeliğin kaynağıdır.', 'Symbolizes the moon cycles and the fluctuating nature of the subconscious; is the source of intuitive wisdom.', 'Символизирует лунные циклы и изменчивую природу подсознания; является источником интуитивной мудрости.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Torah Tomarı', 'Torah Scroll', 'Свиток Торы'),
        description: L10nTriple('Gizli bilgi ve kutsal öğretileri temsil eder; henüz açılmamış sırların bekçisidir.', 'Represents hidden knowledge and sacred teachings; is the guardian of secrets not yet opened.', 'Представляет скрытое знание и священные учения; является хранителем ещё не открытых тайн.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('İki Sütun', 'Two Pillars', 'Две колонны'),
        description: L10nTriple('Bilinen ile bilinmeyen, bilinçli ile bilinçsiz arasındaki sınırı işaret eder.', 'Marks the boundary between the known and the unknown, the conscious and the unconscious.', 'Отмечает границу между известным и неизвестным, сознательным и бессознательным.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Nar Perde', 'Pomegranate Veil', 'Гранатовая завеса'),
        description: L10nTriple('Örtülü gerçekleri ve henüz açığa çıkmamış bilgiyi simgeler; sabırla beklemeyi hatırlatır.', 'Symbolizes veiled truths and knowledge not yet revealed; reminds one to wait with patience.', 'Символизирует сокрытые истины и ещё не раскрытое знание; напоминает терпеливо ждать.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Su', 'Water', 'Вода'),
        description: L10nTriple('Duygusal derinliği ve bilinçaltının akışkan doğasını temsil eden temel semboldür.', 'A fundamental symbol representing emotional depth and the fluid nature of the subconscious.', 'Основной символ, представляющий эмоциональную глубину и текучую природу подсознания.'),
      ),
    ],
    3: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Buğday Tarlaları', 'Wheat Fields', 'Пшеничные поля'),
        description: L10nTriple('Hasat ve bereketi simgeler; emeğin somut meyvelerini verdiğini hatırlatır.', 'Symbolize harvest and abundance; remind that labor yields tangible fruits.', 'Символизируют урожай и изобилие; напоминают, что труд даёт осязаемые плоды.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Venüs Tahtı', 'Venus Throne', 'Трон Венеры'),
        description: L10nTriple('Aşk, güzellik ve sanatsal yaratıcılığın gezegenini temsil eder; duyusal zenginliği simgeler.', 'Represents the planet of love, beauty, and artistic creativity; symbolizes sensory richness.', 'Представляет планету любви, красоты и художественного творчества; символизирует чувственное богатство.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Nar Kalkanı', 'Pomegranate Shield', 'Гранатовый щит'),
        description: L10nTriple('Bolluk ve doğurganlığı simgeleyen kadim bir semboldür; yaşamın sürekliliğini temsil eder.', 'An ancient symbol of abundance and fertility; represents the continuity of life.', 'Древний символ изобилия и плодородия; представляет непрерывность жизни.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Orman', 'Forest', 'Лес'),
        description: L10nTriple('Doğanın ana enerjisini ve vahşi yaratıcılığı temsil eder; doğayla uyum içinde yaşamayı hatırlatır.', 'Represents nature\'s mother energy and wild creativity; reminds one to live in harmony with nature.', 'Представляет материнскую энергию природы и дикое творчество; напоминает жить в гармонии с природой.'),
      ),
    ],
    4: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Taş Taht', 'Stone Throne', 'Каменный трон'),
        description: L10nTriple('Kalıcı otoriteyi ve sağlam temelleri simgeler; geçici değil köklü gücü temsil eder.', 'Symbolizes lasting authority and solid foundations; represents rooted power, not temporary.', 'Символизирует прочную власть и крепкие основы; представляет укоренённую, а не временную силу.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Koç Başlıkları', 'Ram Heads', 'Головы барана'),
        description: L10nTriple('Mars enerjisini ve cesur liderliği temsil eder; savaşçı ruhun koruyucu yönünü simgeler.', 'Represent Mars energy and bold leadership; symbolize the protective aspect of the warrior spirit.', 'Представляют энергию Марса и смелое лидерство; символизируют защитную сторону воинственного духа.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kırmızı Cüppe', 'Red Robe', 'Красная мантия'),
        description: L10nTriple('Tutku, güç ve yaşam enerjisini simgeler; aktif ve kararlı eylemi temsil eder.', 'Symbolizes passion, power, and life energy; represents active and determined action.', 'Символизирует страсть, силу и жизненную энергию; представляет активное и решительное действие.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Asa', 'Scepter', 'Скипетр'),
        description: L10nTriple('Yönetim gücünü ve düzen kurma yeteneğini temsil eder; dünyayı şekillendiren iradeyi simgeler.', 'Represents the power of rule and the ability to establish order; symbolizes the will that shapes the world.', 'Представляет власть управления и способность устанавливать порядок; символизирует волю, формирующую мир.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dağlar', 'Mountains', 'Горы'),
        description: L10nTriple('Zorlukların üstesinden gelinmiş otoriteyi simgeler; deneyimle kazanılmış bilgeliği temsil eder.', 'Symbolize authority that has overcome difficulties; represent wisdom gained through experience.', 'Символизируют власть, преодолевшую трудности; представляют мудрость, обретённую через опыт.'),
      ),
    ],
    5: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Üçlü Taç', 'Triple Crown', 'Тройная корона'),
        description: L10nTriple('Ruhsal, zihinsel ve maddi otoriteyi simgeler; kutsal bilginin taşıyıcısını temsil eder.', 'Symbolizes spiritual, mental, and material authority; represents the bearer of sacred knowledge.', 'Символизирует духовную, умственную и материальную власть; представляет носителя священного знания.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('İki Anahtar', 'Two Keys', 'Два ключа'),
        description: L10nTriple('Gizli bilgiye erişimi simgeler; öğretinin kapılarını açan ruhsal anahtarları temsil eder.', 'Symbolize access to hidden knowledge; represent the spiritual keys that open the doors of teaching.', 'Символизируют доступ к скрытому знанию; представляют духовные ключи, открывающие двери учения.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('İki Takipçi', 'Two Followers', 'Два последователя'),
        description: L10nTriple('Öğretinin aktarımını ve topluluk bağını simgeler; bilgeliğin paylaşıldığı ilişkiyi temsil eder.', 'Symbolize the transmission of teaching and community bond; represent the relationship in which wisdom is shared.', 'Символизируют передачу учения и общинную связь; представляют отношения, в которых делится мудрость.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Asa', 'Staff', 'Посох'),
        description: L10nTriple('Ruhsal otoriteyi ve kutsal görevi simgeler; dünyevi ile ruhsal arasındaki köprüyü temsil eder.', 'Symbolizes spiritual authority and sacred duty; represents the bridge between the worldly and the spiritual.', 'Символизирует духовную власть и священный долг; представляет мост между мирским и духовным.'),
      ),
    ],
    6: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Adem ve Havva', 'Adam and Eve', 'Адам и Ева'),
        description: L10nTriple('İnsan birliğini ve bilinçli seçimi simgeler; ruhsal eşleşmenin sembolik temsilidir.', 'Symbolize human unity and conscious choice; are the symbolic representation of spiritual pairing.', 'Символизируют человеческое единство и сознательный выбор; являются символическим представлением духовного союза.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Melek', 'Angel', 'Ангел'),
        description: L10nTriple('İlahi rehberliği ve kutsal korumayı simgeler; seçimlerin üstünde duran bilgeliği temsil eder.', 'Symbolizes divine guidance and sacred protection; represents wisdom that stands above choices.', 'Символизирует божественное руководство и священную защиту; представляет мудрость, стоящую выше выборов.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Elma Ağacı', 'Apple Tree', 'Яблоня'),
        description: L10nTriple('Bilgi ağacını ve bilinçli seçimin bedelini simgeler; özgür iradenin sembolüdür.', 'Symbolizes the tree of knowledge and the cost of conscious choice; is the symbol of free will.', 'Символизирует древо познания и цену сознательного выбора; является символом свободной воли.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dağ', 'Mountain', 'Гора'),
        description: L10nTriple('Arkada duran volkanik dağ, tutkulu enerjiyi simgeler; ilişkideki derin duygusal gücü temsil eder.', 'The volcanic mountain in the background symbolizes passionate energy; represents deep emotional power in the relationship.', 'Вулканическая гора на заднем плане символизирует страстную энергию; представляет глубокую эмоциональную силу в отношениях.'),
      ),
    ],
    7: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Sphinx Atları', 'Sphinx Horses', 'Кони Сфинкса'),
        description: L10nTriple('Siyah ve beyaz atlar zıt güçleri simgeler; bunları bir arada yönlendirmek irade gerektirir.', 'Black and white horses symbolize opposing forces; directing them together requires will.', 'Чёрный и белый кони символизируют противоположные силы; направлять их вместе требует воли.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Yıldızlı Gökyüzü', 'Starry Sky', 'Звёздное небо'),
        description: L10nTriple('İlahi korumayı ve kaderin desteğini simgeler; doğru yolda olduğunu hatırlatır.', 'Symbolizes divine protection and the support of destiny; reminds that one is on the right path.', 'Символизирует божественную защиту и поддержку судьбы; напоминает, что человек на верном пути.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Zırh', 'Armor', 'Доспехи'),
        description: L10nTriple('Koruma ve savaşçı ruhu simgeler; dış dünyadan gelene karşı direnci temsil eder.', 'Symbolizes protection and warrior spirit; represents resistance against what comes from the outer world.', 'Символизируют защиту и воинственный дух; представляют сопротивление тому, что приходит из внешнего мира.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Taç', 'Crown', 'Корона'),
        description: L10nTriple('Zaferi ve başarıyı simgeler; hedefe ulaşmanın sembolik ödülünü temsil eder.', 'Symbolizes victory and success; represents the symbolic reward of reaching the goal.', 'Символизирует победу и успех; представляет символическую награду за достижение цели.'),
      ),
    ],
    8: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Aslan', 'Lion', 'Лев'),
        description: L10nTriple('Vahşi içgüdüleri ve tutkuyu simgeler; nazik dokunuşla kontrol edilmesi gereken gücü temsil eder.', 'Symbolizes wild instincts and passion; represents power that must be controlled with a gentle touch.', 'Символизирует дикие инстинкты и страсть; представляет силу, которую нужно контролировать мягким прикосновением.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Sonsuzluk İşareti', 'Infinity Sign', 'Знак бесконечности'),
        description: L10nTriple('Başın üzerindeki lemniskat, sınırsız içsel gücü ve ruhsal dayanıklılığı simgeler.', 'The lemniscate above the head symbolizes unlimited inner strength and spiritual endurance.', 'Лемниската над головой символизирует безграничную внутреннюю силу и духовную стойкость.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Beyaz Elbise', 'White Dress', 'Белое платье'),
        description: L10nTriple('Saflık ve ruhsal gücü simgeler; fiziksel güçten üstün olan içsel cesareti temsil eder.', 'Symbolizes purity and spiritual strength; represents inner courage superior to physical power.', 'Символизирует чистоту и духовную силу; представляет внутреннее мужество, превосходящее физическую силу.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Çiçek Taç', 'Flower Crown', 'Цветочный венец'),
        description: L10nTriple('Doğayla uyumu ve yumuşak gücü simgeler; merhametin zaferini temsil eder.', 'Symbolizes harmony with nature and soft power; represents the victory of compassion.', 'Символизирует гармонию с природой и мягкую силу; представляет победу сострадания.'),
      ),
    ],
    9: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Fener', 'Lantern', 'Фонарь'),
        description: L10nTriple('İçsel bilgeliğin ışığını simgeler; karanlıkta yol gösteren sezgisel rehberliği temsil eder.', 'Symbolizes the light of inner wisdom; represents intuitive guidance that shows the way in darkness.', 'Символизирует свет внутренней мудрости; представляет интуитивное руководство, указывающее путь во тьме.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Asa', 'Staff', 'Посох'),
        description: L10nTriple('Ruhsal otoriteyi ve yolculuğun desteğini simgeler; deneyimle kazanılmış bilgeliği temsil eder.', 'Symbolizes spiritual authority and support on the journey; represents wisdom gained through experience.', 'Символизирует духовную власть и опору в пути; представляет мудрость, обретённую через опыт.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dağ Zirvesi', 'Mountain Peak', 'Горная вершина'),
        description: L10nTriple('Ruhsal yükselişi ve yalnız arayışı simgeler; dünyevi gürültüden uzaklaşmayı temsil eder.', 'Symbolizes spiritual ascent and solitary seeking; represents distancing from worldly noise.', 'Символизирует духовный подъём и одиночный поиск; представляет отдаление от мирского шума.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Gri Cüppe', 'Gray Robe', 'Серая мантия'),
        description: L10nTriple('Mütevazılığı ve dünyevi arzulardan arınmayı simgeler; içsel zenginliğin sembolüdür.', 'Symbolizes humility and purification from worldly desires; is the symbol of inner richness.', 'Символизирует скромность и очищение от мирских желаний; является символом внутреннего богатства.'),
      ),
    ],
    10: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Dönen Çark', 'Turning Wheel', 'Вращающееся колесо'),
        description: L10nTriple('Hayatın döngüsel doğasını simgeler; yükseliş ve düşüşlerin geçiciliğini hatırlatır.', 'Symbolizes the cyclical nature of life; reminds of the transience of rises and falls.', 'Символизирует циклическую природу жизни; напоминает о преходящести взлётов и падений.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Sfenks', 'Sphinx', 'Сфинкс'),
        description: L10nTriple('Bilgeliği ve bilinmeyeni simgeler; çarkın üstündeki gizemli figür kaderin sırlarını korur.', 'Symbolizes wisdom and the unknown; the mysterious figure atop the wheel guards the secrets of destiny.', 'Символизирует мудрость и неизвестное; таинственная фигура на вершине колеса хранит тайны судьбы.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Yılan', 'Snake', 'Змей'),
        description: L10nTriple('Düşüşü temsil eden figür; her yükselişin bir düşüşe, her düşüşün bir yükselişe bağlı olduğunu anlatır.', 'The figure representing descent; describes that every rise is linked to a fall, every fall to a rise.', 'Фигура, представляющая падение; говорит о том, что каждый подъём связан с падением, каждое падение — с подъёмом.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Anubis', 'Anubis', 'Анубис'),
        description: L10nTriple('Yükselişi temsil eden figür; ölüm ve yeniden doğuş döngüsünü simgeler.', 'The figure representing ascent; symbolizes the cycle of death and rebirth.', 'Фигура, представляющая подъём; символизирует цикл смерти и возрождения.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dört Harf', 'Four Letters', 'Четыре буквы'),
        description: L10nTriple('Tetragrammaton — kutsal ismi simgeler; evrenin ilahi düzenini temsil eder.', 'Tetragrammaton — symbolizes the sacred name; represents the divine order of the universe.', 'Тетраграмматон — символизирует священное имя; представляет божественный порядок вселенной.'),
      ),
    ],
    11: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Terazi', 'Scales', 'Весы'),
        description: L10nTriple('Denge ve adaleti simgeler; kararların tartılarak verilmesi gerektiğini hatırlatır.', 'Symbolize balance and justice; remind that decisions should be weighed carefully.', 'Символизируют баланс и справедливость; напоминают, что решения следует взвешивать.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kılıç', 'Sword', 'Меч'),
        description: L10nTriple('Gerçeği keskin bir şekilde ortaya koymayı simgeler; adaletin kesin ve net olması gerektiğini anlatır.', 'Symbolizes revealing the truth sharply; describes that justice must be firm and clear.', 'Символизирует остро выявлять истину; говорит о том, что справедливость должна быть твёрдой и ясной.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kırmızı Cüppe', 'Red Robe', 'Красная мантия'),
        description: L10nTriple('Tutku ve eylemi simgeler; adaletin pasif değil aktif bir süreç olduğunu hatırlatır.', 'Symbolizes passion and action; reminds that justice is an active process, not a passive one.', 'Символизирует страсть и действие; напоминает, что справедливость — активный, а не пассивный процесс.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Taht', 'Throne', 'Трон'),
        description: L10nTriple('Otoriteyi ve karar verme gücünü simgeler; adaletin yüksek bir sorumluluk olduğunu temsil eder.', 'Symbolizes authority and the power to decide; represents that justice is a high responsibility.', 'Символизирует власть и силу принимать решения; представляет, что справедливость — высокая ответственность.'),
      ),
    ],
    12: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Ters Asılı Figür', 'Inverted Hanging Figure', 'Перевёрнутая висящая фигура'),
        description: L10nTriple('Perspektif değişimini simgeler; dünyayı farklı açıdan görmek bilgelik getirir.', 'Symbolizes a change of perspective; seeing the world from a different angle brings wisdom.', 'Символизирует смену перспективы; видеть мир под другим углом приносит мудрость.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Hale', 'Halo', 'Нимб'),
        description: L10nTriple('Başın etrafındaki ışık halesi, ruhsal aydınlanmayı ve gönüllü fedakarlığı simgeler.', 'The light halo around the head symbolizes spiritual enlightenment and voluntary sacrifice.', 'Световой нимб вокруг головы символизирует духовное просветление и добровольную жертву.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Ağaç', 'Tree', 'Дерево'),
        description: L10nTriple('Yaşam ağacını simgeler; duraklama döneminin büyümenin parçası olduğunu hatırlatır.', 'Symbolizes the tree of life; reminds that a period of pause is part of growth.', 'Символизирует древо жизни; напоминает, что период паузы — часть роста.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Bağlı Ayak', 'Bound Foot', 'Связанная нога'),
        description: L10nTriple('Gönüllü bağlılığı simgeler; zorla değil seçerek teslim olmayı temsil eder.', 'Symbolizes voluntary binding; represents surrendering by choice, not by force.', 'Символизирует добровольную связанность; представляет подчинение по выбору, а не по принуждению.'),
      ),
    ],
    13: const [
      CardDetailSymbolCopy(
        name: L10nTriple('İskelet Binici', 'Skeleton Rider', 'Скелет-всадник'),
        description: L10nTriple('Ölümün kaçınılmazlığını simgeler; tüm canlıların geçiş noktasını temsil eder.', 'Symbolizes the inevitability of death; represents the transition point of all living beings.', 'Символизирует неизбежность смерти; представляет точку перехода всех живых существ.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Siyah Bayrak', 'Black Flag', 'Чёрный флаг'),
        description: L10nTriple('Dönüşümün bayrağını simgeler; eski dönemin resmen sona erdiğini anlatır.', 'Symbolizes the flag of transformation; describes that the old era has formally ended.', 'Символизирует знамя преобразования; говорит о том, что старая эпоха официально завершилась.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Güneş', 'Sun', 'Солнце'),
        description: L10nTriple('Ufukta doğan güneş, yeniden doğuşu simgeler; her sonun ardında yeni bir gün vardır.', 'The sun rising on the horizon symbolizes rebirth; behind every ending there is a new day.', 'Солнце, восходящее на горизонте, символизирует возрождение; за каждым концом есть новый день.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Papa', 'Pope', 'Папа'),
        description: L10nTriple('Ruhsal otoriteyi simgeler; ölümün ruhsal anlamını ve kutsal geçişi temsil eder.', 'Symbolizes spiritual authority; represents the spiritual meaning of death and the sacred passage.', 'Символизирует духовную власть; представляет духовный смысл смерти и священный переход.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Çocuklar', 'Children', 'Дети'),
        description: L10nTriple('Masumiyeti simgeler; dönüşümün ardından gelene saf yeniden doğuşu temsil eder.', 'Symbolize innocence; represent pure rebirth that comes after transformation.', 'Символизируют невинность; представляют чистое возрождение, приходящее после преобразования.'),
      ),
    ],
    14: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Melek', 'Angel', 'Ангел'),
        description: L10nTriple('İlahi rehberliği ve ruhsal dengeyi simgeler; dünyevi ile ruhsal arasındaki köprüyü temsil eder.', 'Symbolizes divine guidance and spiritual balance; represents the bridge between the worldly and the spiritual.', 'Символизирует божественное руководство и духовный баланс; представляет мост между мирским и духовным.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('İki Kupa', 'Two Cups', 'Два кубка'),
        description: L10nTriple('Zıt enerjilerin birleşimini simgeler; su aktarımı alkimyanın sembolüdür.', 'Symbolize the union of opposing energies; the transfer of water is the symbol of alchemy.', 'Символизируют соединение противоположных энергий; переливание воды — символ алхимии.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Ayak Su', 'Foot in Water', 'Нога в воде'),
        description: L10nTriple('Bir ayağın sudaki, birinin karadaki olması dünyevi ile ruhsal arasındaki dengeyi simgeler.', 'One foot in water and one on land symbolizes the balance between the worldly and the spiritual.', 'Одна нога в воде, другая на суше символизирует баланс между мирским и духовным.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Güneş Yolu', 'Sun Path', 'Солнечный путь'),
        description: L10nTriple('Arkada yükselen dağa giden yol, ruhsal yükselişi ve aydınlanmayı simgeler.', 'The path leading to the rising mountain in the background symbolizes spiritual ascent and enlightenment.', 'Путь, ведущий к поднимающейся горе на заднем плане, символизирует духовный подъём и просветление.'),
      ),
    ],
    15: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Baphomet', 'Baphomet', 'Бафомет'),
        description: L10nTriple('Maddi ve ruhsal dünyanın birleşimini simgeler; karanlık bilgeliğin sembolik figürüdür.', 'Symbolizes the union of the material and spiritual worlds; is the symbolic figure of dark wisdom.', 'Символизирует соединение материального и духовного миров; является символической фигурой тёмной мудрости.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Zincirler', 'Chains', 'Цепи'),
        description: L10nTriple('Bağımlılık ve kısıtlamayı simgeler; ancak gevşek oldukları için kurtulmak mümkündür.', 'Symbolize addiction and restriction; yet because they are loose, escape is possible.', 'Символизируют зависимость и ограничение; однако, поскольку они ослаблены, освободиться возможно.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Meşale', 'Torch', 'Факел'),
        description: L10nTriple('Ters tutulmuş meşale, bastırılmış tutkuyu simgeler; arzuların gölgede kalmasını temsil eder.', 'An inverted torch symbolizes suppressed passion; represents desires remaining in shadow.', 'Перевёрнутый факел символизирует подавленную страсть; представляет желания, оставшиеся в тени.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Boynuzlar', 'Horns', 'Рога'),
        description: L10nTriple('Hayvan içgüdülerini simgeler; vahşi ve kontrol edilmemiş arzuları temsil eder.', 'Symbolize animal instincts; represent wild and uncontrolled desires.', 'Символизируют животные инстинкты; представляют дикие и неконтролируемые желания.'),
      ),
    ],
    16: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Yıldırım', 'Lightning', 'Молния'),
        description: L10nTriple('Ani ilahi müdahaleyi simgeler; sahte yapıları yıkan sarsıcı gerçeği temsil eder.', 'Symbolizes sudden divine intervention; represents the shocking truth that topples false structures.', 'Символизирует внезапное божественное вмешательство; представляет потрясающую истину, разрушающую ложные структуры.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Yıkılan Kule', 'Falling Tower', 'Падающая башня'),
        description: L10nTriple('Ego ve sahte otoritenin çöküşünü simgeler; temeli sağlam olmayanın sonu gelmiştir.', 'Symbolizes the collapse of ego and false authority; the end has come for what lacks a solid foundation.', 'Символизирует крушение эго и ложной власти; конец пришёл тому, чья основа непрочна.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Taç', 'Crown', 'Корона'),
        description: L10nTriple('Düşen taç, yıkılan otoriteyi simgeler; gurur ve kibirin bedelini temsil eder.', 'The falling crown symbolizes toppled authority; represents the cost of pride and arrogance.', 'Падающая корона символизирует рухнувшую власть; представляет цену гордыни и высокомерия.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Alevler', 'Flames', 'Пламя'),
        description: L10nTriple('Yıkımın ardından gelen arınmayı simgeler; ateş eskiyi yakarak yeniye yer açar.', 'Symbolize the purification that follows destruction; fire burns the old to make room for the new.', 'Символизируют очищение, следующее за разрушением; огонь сжигает старое, освобождая место новому.'),
      ),
    ],
    17: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Sekiz Yıldız', 'Eight Stars', 'Восемь звёзд'),
        description: L10nTriple('İlahi rehberliği simgeler; büyük yıldız umut ve hedefi, küçükler yol göstericileri temsil eder.', 'Symbolize divine guidance; the large star represents hope and the goal, the small ones the guides along the way.', 'Символизируют божественное руководство; большая звезда представляет надежду и цель, малые — путеводители.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Su Dökme', 'Pouring Water', 'Излияние воды'),
        description: L10nTriple('Ruhsal arınmayı simgeler; bilinçli ve bilinçsiz arasındaki akışı temsil eder.', 'Symbolizes spiritual purification; represents the flow between the conscious and the unconscious.', 'Символизирует духовное очищение; представляет поток между сознательным и бессознательным.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Çıplak Figür', 'Nude Figure', 'Обнажённая фигура'),
        description: L10nTriple('Saflığı ve savunmasızlığı simgeler; gerçek benliğin maskesiz ortaya çıkışını temsil eder.', 'Symbolizes purity and vulnerability; represents the unmasked emergence of the true self.', 'Символизирует чистоту и уязвимость; представляет появление истинного «я» без маски.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kuş', 'Bird', 'Птица'),
        description: L10nTriple('İlahi mesajcıyı simgeler; ruhsal rehberliğin sembolik temsilidir.', 'Symbolizes the divine messenger; is the symbolic representation of spiritual guidance.', 'Символизирует божественного посланника; является символическим представлением духовного руководства.'),
      ),
    ],
    18: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Ay', 'Moon', 'Луна'),
        description: L10nTriple('Bilinçaltını ve sezgisel bilgeliği simgeler; yarı aydınlık gerçeğin sembolüdür.', 'Symbolizes the subconscious and intuitive wisdom; is the symbol of half-lit truth.', 'Символизирует подсознание и интуитивную мудрость; является символом полуосвещённой истины.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Kurt ve Köpek', 'Wolf and Dog', 'Волк и собака'),
        description: L10nTriple('Vahşi ve evcil içgüdüleri simgeler; bilinçaltının iki yüzünü temsil eder.', 'Symbolize wild and domesticated instincts; represent the two faces of the subconscious.', 'Символизируют дикие и одомашненные инстинкты; представляют два лица подсознания.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Yengeç', 'Crab', 'Краб'),
        description: L10nTriple('Bilinçaltından çıkan korkuları simgeler; derin suların gizemli yaratıklarını temsil eder.', 'Symbolizes fears emerging from the subconscious; represents the mysterious creatures of deep waters.', 'Символизирует страхи, выходящие из подсознания; представляет таинственных существ глубоких вод.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Yol', 'Path', 'Путь'),
        description: L10nTriple('İki kule arasındaki belirsiz yol, sezgiyle yürünmesi gereken gizemli patikayı simgeler.', 'The uncertain path between two towers symbolizes the mysterious trail that must be walked by intuition.', 'Неясный путь между двумя башнями символизирует таинственную тропу, по которой нужно идти интуицией.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Suy Yükseltisi', 'Rising Waters', 'Подъём вод'),
        description: L10nTriple('Bilinçaltının yüzeye çıkışını simgeler; bastırılmış duyguların kabarmasını temsil eder.', 'Symbolizes the subconscious rising to the surface; represents the surging of suppressed emotions.', 'Символизирует выход подсознания на поверхность; представляет подъём подавленных эмоций.'),
      ),
    ],
    19: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Güneş', 'Sun', 'Солнце'),
        description: L10nTriple('Yaşam kaynağını ve aydınlanmayı simgeler; tüm karanlığı dağıtan saf ışığı temsil eder.', 'Symbolizes the source of life and enlightenment; represents pure light that disperses all darkness.', 'Символизирует источник жизни и просветление; представляет чистый свет, рассеивающий всю тьму.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Çocuk', 'Child', 'Ребёнок'),
        description: L10nTriple('Saflığı ve masum neşeyi simgeler; iç çocuğun özgür ifadesini temsil eder.', 'Symbolizes purity and innocent joy; represents the free expression of the inner child.', 'Символизирует чистоту и невинную радость; представляет свободное выражение внутреннего ребёнка.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Beyaz At', 'White Horse', 'Белый конь'),
        description: L10nTriple('Saflığı ve zaferi simgeler; bilinçli ruhun ilerleyişini temsil eder.', 'Symbolizes purity and victory; represents the advance of the conscious spirit.', 'Символизирует чистоту и победу; представляет продвижение сознательного духа.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Ayçiçeği', 'Sunflower', 'Подсолнух'),
        description: L10nTriple('Güneşe dönüşü simgeler; yaşam enerjisinin en yüksek ifadesini temsil eder.', 'Symbolizes turning toward the sun; represents the highest expression of life energy.', 'Символизирует обращение к солнцу; представляет высшее выражение жизненной энергии.'),
      ),
    ],
    20: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Melek Trompeti', 'Angel\'s Trumpet', 'Труба ангела'),
        description: L10nTriple('İlahi çağrıyı simgeler; uyanış anının habercisini temsil eder.', 'Symbolizes the divine call; represents the herald of the moment of awakening.', 'Символизирует божественный зов; представляет вестника момента пробуждения.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Mezarlardan Kalkanlar', 'Those Rising from Graves', 'Восстающие из могил'),
        description: L10nTriple('Yeniden doğuşu simgeler; geçmişin ağırlığından kurtularak yükselişi temsil eder.', 'Symbolize rebirth; represent rising by freeing oneself from the weight of the past.', 'Символизируют возрождение; представляют подъём через освобождение от груза прошлого.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dağlar', 'Mountains', 'Горы'),
        description: L10nTriple('Ruhsal yükselişi simgeler; uyanışın getirdiği perspektif değişimini temsil eder.', 'Symbolize spiritual ascent; represent the change of perspective that awakening brings.', 'Символизируют духовный подъём; представляют смену перспективы, которую приносит пробуждение.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Haç Bayrak', 'Cross Flag', 'Флаг с крестом'),
        description: L10nTriple('Kurtuluşu simgeler; ruhsal zaferin sembolik işaretidir.', 'Symbolizes salvation; is the symbolic mark of spiritual victory.', 'Символизирует спасение; является символическим знаком духовной победы.'),
      ),
    ],
    21: const [
      CardDetailSymbolCopy(
        name: L10nTriple('Laurel Halkası', 'Laurel Wreath', 'Лавровый венок'),
        description: L10nTriple('Zaferi ve tamamlanmayı simgeler; başarıyla sona eren yolculuğu temsil eder.', 'Symbolizes victory and completion; represents a journey that has ended successfully.', 'Символизирует победу и завершённость; представляет успешно оконченный путь.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dört Köşe Figür', 'Four Corner Figures', 'Фигуры по четырём углам'),
        description: L10nTriple('Dört elementi simgeler; evrenin tüm güçlerinin birleşimini temsil eder.', 'Symbolize the four elements; represent the union of all forces of the universe.', 'Символизируют четыре элемента; представляют соединение всех сил вселенной.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Dans Eden Figür', 'Dancing Figure', 'Танцующая фигура'),
        description: L10nTriple('Evrensel uyumu simgeler; özgür ruhun kutlamasını temsil eder.', 'Symbolizes universal harmony; represents the celebration of the free spirit.', 'Символизирует вселенскую гармонию; представляет празднование свободного духа.'),
      ),
      CardDetailSymbolCopy(
        name: L10nTriple('Mor Peçe', 'Purple Veil', 'Пурпурная вуаль'),
        description: L10nTriple('Bilinçli ile bilinçsiz arasındaki örtüyü simgeler; bütünlüğün sembolüdür.', 'Symbolizes the veil between the conscious and the unconscious; is the symbol of wholeness.', 'Символизирует завесу между сознательным и бессознательным; является символом целостности.'),
      ),
    ],
  };
}
