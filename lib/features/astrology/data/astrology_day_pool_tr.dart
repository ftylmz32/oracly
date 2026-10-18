/// Turkish daily astrology pools — sun-sign temperament only.
///
/// Each line is a character leaning for a calendar day, not a sky report.
/// The app has no ephemeris for the reader, so nothing here names a transit,
/// an aspect, a modality lecture, or a body-part forecast.
library;

class AstrologyDayPool {
  const AstrologyDayPool({
    required this.overall,
    required this.love,
    required this.career,
    required this.money,
    required this.energy,
    required this.emotion,
    required this.advice,
    required this.opportunity,
    required this.caution,
  });

  final List<String> overall;
  final List<String> love;
  final List<String> career;
  final List<String> money;
  final List<String> energy;
  final List<String> emotion;
  final List<String> advice;
  final List<String> opportunity;
  final List<String> caution;
}

const kAstrologyDayPoolTr = <String, AstrologyDayPool>{
  'aries': AstrologyDayPool(
    overall: [
      'Koç, bugün aklındaki işi başkası başlatmadan senin başlatman gerekiyormuş gibi bir his taşıyabilirsin. Bu acelenin bir kısmı gerçek bir fırsattan, bir kısmı da beklemeye tahammülsüzlükten geliyor. Hangisinin hangisi olduğunu ayırt ettiğinde ilk adımın çok daha isabetli olur.',
      'Koç, düşündüğünle yaptığın arasında çoğu zaman kısa bir mesafe vardır. Bugün elinde bekleyen bir cevap ya da bir alışveriş varsa onu bir saat kenarda bırak. O saatten sonra gönderdiğin hali, aceleyle gidenden daha az tamir ister.',
      'Koç, bugün enerjin yüksek ama nereye akacağı belli değil. Bir tartışmaya, bir spor salonuna ya da yarım kalmış bir projeye gidebilir. Seçimi sen yapmazsan, ilk sinirlendiğin konu senin yerine yapar.',
      'Koç, bugün birinin seni yavaşlattığını düşünebilirsin. Belki de o kişi senin göremediğin bir ayrıntıyı görüyor. Rekabete girmeden önce ne söylediğini sonuna kadar dinlemek, kazanmanın daha kısa yolu olabilir.',
      'Koç, başlamakta ustasın; bitirmek ise seni daha az heyecanlandırıyor. Bugün listende en eski duran işe bak. Onu kapatmanın verdiği rahatlık, yeni bir başlangıcın heyecanından daha uzun sürebilir.',
      'Koç, bugün bir konuda haklı olduğunu biliyorsun ama bunu kanıtlamak için harcayacağın enerji sonuçtan daha pahalı olabilir. Bazen haklı çıkmak yerine işi yürütmeyi seçmek, öncü olmanın daha olgun hali.',
      'Koç, cesaretin en çok başkaları tereddüt ederken parlıyor. Bugün çevrende kimsenin söylemeye cesaret edemediği bir şey varsa, onu kırmadan söyleyecek kişi sen olabilirsin.',
      'Koç, yorulduğunu kabul etmek senin için kolay değil; durmayı kaybetmekle karıştırabilirsin. Bugün kısa bir mola, ertesi gün iki kat hızla dönmeni sağlayan şey olabilir.',
    ],
    love: [
      'İlişkide hızlı ısınıp hızlı sıkılma eğilimin bugün sınanabilir. Karşındaki kişinin ritmi senden yavaşsa bunu ilgisizlik sanma; bazı insanlar yakınlığı adım adım kurar.',
      'Bir şeyi kafana taktıysan imalarla değil açıkça söylemek sana daha çok yakışır. Koç dürüstlüğü kırıcı olmadan da net olabilir; tonunu biraz yumuşatman yeterli.',
      'Yalnızsan, seni heyecanlandıran kişiyle seni rahatlatan kişi arasındaki farkı düşünmeye değer bir gün. Koç çoğu zaman ilkine koşar; uzun vadede yanında kalan genelde ikincisidir.',
    ],
    career: [
      'İş yerinde inisiyatif alma isteğin güçlü. Kimsenin sahiplenmediği bir sorunu üstlenirsen bu enerji takdir görür; başkasının alanına girersen sürtüşmeye dönüşür.',
      'Bugün sabırsızlıkla gönderilen bir e-posta, iki gün sürecek bir açıklama trafiği yaratabilir. Önemli bir yazışmayı göndermeden önce bir kez yüksek sesle oku.',
      'Bir rekabet hissediyorsan onu kişisel bir meseleye çevirme. Koç en iyi işini birini yenmeye değil, kendi çıtasını yükseltmeye odaklandığında çıkarır.',
    ],
    money: [
      'Ani alışveriş isteği bugün daha güçlü olabilir. Sepeti bir gece bekletmek, o şeyi gerçekten isteyip istemediğini gösterir.',
      'Gelirini artıracak bir fikir aklına gelebilir. Hemen harekete geçmek yerine önce kaba bir hesap çıkar; Koç hevesi rakamlarla desteklenince çok daha ikna edici olur.',
    ],
    energy: [
      'Bedenin hareket istiyor. Uzun süre oturduğunda gerginliğin artar; kısa da olsa tempolu bir yürüyüş zihnini toparlar.',
      'Gün içinde enerjin dalgalı olabilir; sabah fazla harcarsan akşam çabuk tükenirsin. Gücünün bir kısmını günün ikinci yarısına sakla.',
    ],
    emotion: [
      'Öfke bugün yüzeye yakın olabilir. Çoğu zaman altında hayal kırıklığı ya da görülmeme hissi yatar; asıl konuyu adlandırmak öfkeyi hızla söndürür.',
      'Bir şeyi kontrol edemediğinde huzursuzlanıyorsun. Her şeyi kendi hızında ilerletemeyeceğini kabul etmek, sana beklenmedik bir hafiflik verebilir.',
    ],
    advice: [
      'Bugün başladığın her işe bir de bitiş saati koy.',
      'Bir tartışmada son sözü söyleme ihtiyacını bir kez bırak ve ne olduğunu gözle.',
      'En çok ertelediğin küçük işi öğleden önce bitir; günün geri kalanı daha hafif geçer.',
    ],
    opportunity: [
      'Kimsenin cesaret edemediği bir teklifte bulunmak için uygun bir gün. Küçük ve somut başlarsan karşı taraf da kolay evet der.',
      'Yeni bir beceriye başlamak için hevesin yüksek. İlk deneme kötü geçse bile ikinci denemeye bir tarih koyarsan bu heves alışkanlığa dönüşebilir.',
    ],
    caution: [
      'Sinirliyken verilen kararlar bugün daha pahalıya patlayabilir. Bir şey seni kızdırdıysa cevabını en az bir saat sonra ver.',
      'Kızgınken mutfakta, sporda ya da yolda tempon hızlanır. O tempoyu bir kademe düşürmek, o anki hırsından daha çok işe yarar; acele bir sakarlığa dönebilir.',
      'Haklı olduğun bir konuda bile sert tonun, asıl söylediğinin önüne geçebilir.',
    ],
  ),
  'taurus': AstrologyDayPool(
    overall: [
      'Boğa, bugün seni rahatsız eden şey büyük bir sorun değil, düzenini bozan küçük bir değişiklik olabilir. Buna direnmek yerine neyin gerçekten değiştiğine bakarsan, korktuğun kadar sarsıcı olmadığını görürsün.',
      'Boğa, bir şeye değer verdiğinde onu bırakmakta zorlanırsın. Bugün elinde tuttuğun bir alışkanlığın, bir eşyanın ya da bir fikrin hâlâ işine yarayıp yaramadığını sakin kafayla tartmak için iyi bir gün.',
      'Boğa, acele ettirilmekten hoşlanmazsın ve bugün biri seni tam da buna zorlayabilir. Kendi hızını korumak hakkın; yalnızca neden beklediğini karşı tarafa bir cümleyle açıklaman yeterli.',
      'Boğa, uzun süredir emek verdiğin bir işin sonucunu bu hafta göremeyebilirsin. Sonuç gecikmesi, emeğin boşa gittiği anlamına gelmez. Bugün yalnızca nerede kaldığını bir cümleyle yazmak, "hiç ilerlemiyor" hissini küçültür.',
      'Boğa, yorucu bir günün sonunda kendini iyi bir yemekle, tanıdık bir kokuyla ya da rahat bir köşeyle toparlayabilirsin. Bunu şımarıklık sayma. Küçük bir konfor, ertesi sabah aynı işe daha düzgün dönmeni sağlar.',
      'Boğa, bugün biri senden hızlı bir karar isteyebilir ve içinden "biraz düşüneyim" demek gelecek. Bu içgüdüne güven; ama düşünme süresine bir sınır koymak, karşındakinin seni oyalanıyor sanmasını önler.',
      'Boğa, sahip olduklarının değerini bilmek senin en sağlam yanın. Elindekileri kafanda bir kez saymak, eksik hissettiğin bir konuda sana beklenmedik bir huzur verebilir.',
      'Boğa, uzun süredir aynı şekilde yaptığın bir işin daha kolay bir yolu olabilir. Değişime temkinli yaklaşman doğal, ama bugün tek bir küçük adımı farklı denemek sana zaman kazandırabilir.',
    ],
    love: [
      'Sevgini sözle değil emekle gösterirsin; bugün karşı taraf ise biraz söz duymak isteyebilir. Uzun cümlelere gerek yok, içten bir "iyi ki varsın" yeter.',
      'Kıskançlık ya da sahiplenme hissi bugün yüzeye çıkabilir. Altında çoğu zaman kaybetme korkusu vardır; korkunu söylemek, karşındakini kontrol etmeye çalışmaktan çok daha yakınlaştırıcıdır.',
      'Yalnızsan, birine ilk günden güvenemediğin için kendini suçlama. Üç sıradan konuşmadan sonra hâlâ rahatsan, bu bir kusur değil, senin ölçün. Acele etmeni dert eden biri, sana uyum sağlayacak kişi olmayabilir.',
    ],
    career: [
      'İşte istikrarlı ve güvenilir olman fark ediliyor, ama sen söylemedikçe herkes fark etmeyebilir. Bugün yaptığın işi kısa ve somut bir şekilde görünür kılmayı dene.',
      'Yeni bir yöntem ya da sistem önüne geldiğinde ilk tepkin itiraz olabilir. Denemeden reddetmek yerine küçük bir parçasını test etmek hem seni hem ekibi korur.',
      'Bugün kaliteye odaklanman avantajın. Hızlı ama özensiz bir iş yerine biraz geç ama sağlam bir teslim seni daha ileri taşır.',
    ],
    money: [
      'Para konusunda temkinli olman genelde işine yarar, ama gereğinden fazla tutunduğun bir harcama kalemi olabilir. Hiç kullanmadığın bir abonelik varsa kapatma zamanı.',
      'Güzel ve kaliteli bir şeye harcama isteğin artabilir. Almadan önce kendine sor: bu bir ihtiyaç mı, yoksa yorucu bir günün tesellisi mi.',
    ],
    energy: [
      'Enerjin yavaş ama dayanıklı. Günü küçük ve düzenli molalarla bölersen akşam yorgunluğunu daha az hissedersin.',
      'Gergin bir konuşmada yerinde oturdukça çenen ve omzun kilitlenebilir. Ayağa kalkıp bir bardak su almak, o sıradaki cümleyi iterek bitirmekten daha çok işe yarar.',
    ],
    emotion: [
      'Bir şeyi içine attığında uzun süre taşıyabiliyorsun. Seni kıran ama söylemediğin bir konu varsa, onu sakin bir dille dile getirmek yükünü hafifletir.',
      'Güvende hissetmek senin için her şeyden önemli. Seni güvende hissettiren üç küçük şeyi fark etmek, belirsizliğe karşı iyi bir çapa olur.',
    ],
    advice: [
      'Değiştirmekten çekindiğin küçük bir alışkanlığı bir günlüğüne değiştir ve sonucuna bak.',
      'Birine hayır demen gerekiyorsa bunu uzun gerekçelerle değil, kısa ve sakin bir cümleyle yap.',
      'Masanı ya da çevreni on dakikalığına toparla; Boğa düzeni dışarıda kurunca içeride de rahatlar.',
    ],
    opportunity: [
      'Uzun vadeli bir birikim planı yapmak için verimli bir gün. Büyük adım şart değil, ilk küçük kalemi yazman yeter.',
      'El emeği, zanaat ya da estetik bir konuda yeteneğin görünür olabilir. Yaptığın bir işi paylaşmaktan çekinme.',
    ],
    caution: [
      'İnat, haklı olduğun bir konuda bile seni yalnız bırakabilir. Fikrini korurken karşı tarafın bir noktasını kabul etmek seni zayıflatmaz.',
      'Bir fiyatı, bir misafiri ya da bir planı değiştirmek ayıp gelebilir diye olduğundan pahalı bir evete yapışabilirsin. Uygun olmayan şeyi nazikçe düzeltmek, sonradan içinden saymaktan daha ucuzdur.',
      'Yorgunken yemekle ya da alışverişle rahatlama isteği artabilir; gerçekten neye ihtiyacın olduğuna bak.',
    ],
  ),
  'gemini': AstrologyDayPool(
    overall: [
      'İkizler, bugün zihnin aynı anda birkaç sekmeyi açık tutuyor. Bu merak senin en büyük gücün, ama hepsini aynı anda kapatmaya çalışırsan hiçbiri bitmez. Gün sonunda gerçekten bitirmek istediğin tek konuyu şimdiden seç.',
      'İkizler, iki seçenek arasında gidip geliyorsan bunun sebebi kararsızlık değil, iki tarafı da gerçekten görebilmen. Yine de bir noktada seçmek gerekiyor; seçeneklerini birine sesli anlattığında içinden geçen cevap netleşebilir.',
      'İkizler, bugün bir sohbet beklediğinden fazla şey açabilir. Rastgele başlayan bir konuşma, uzun zamandır kafanda dolaşan bir soruya cevap verebilir; dinlerken aklına geleni not etmeyi unutma.',
      'İkizler, havadan sudan konuşmakta ustasın ama bugün biri senden daha derin bir şey duymak isteyebilir. Espriyle geçiştirmek yerine bir kez gerçekten ne hissettiğini söylemek bağını güçlendirir.',
      'İkizler, bilgi toplamayı seversin ve bugün okuduğun, duyduğun her şey seni başka bir yere götürebilir. Ekranda geçirdiğin süreyi biraz sınırlarsan zihnin daha az yorulur, fikirlerin daha net olur.',
      'İkizler, bugün söylemek istediğin şeyi kafanda birkaç farklı şekilde prova edebilirsin. Mükemmel cümleyi beklemek yerine aklına gelen ilk samimi hali söylemek çoğu zaman en doğrusudur.',
      'İkizler, merakın seni bugün beklenmedik bir konuya sürükleyebilir. Okuduğun bir yazı ya da duyduğun bir yorum, uzun süredir çözemediğin bir soruna yan kapıdan bakmanı sağlayabilir.',
      'İkizler, insanlarla bağ kurmak senin için kolay, ama bugün herkesle biraz konuşup kimseyle derinleşmeme riski var. Bir kişiye gerçekten zaman ayırmak, on kısa sohbetten daha çok iyi gelir.',
    ],
    love: [
      'İlişkide seni en çok yoran şey tekdüzelik. Bugün partnerinle alışılmışın dışında küçük bir şey yapmak ikinizi de canlandırabilir; yeni bir yer, yeni bir konu, hatta yeni bir şaka.',
      'Mesajlaşmada kurduğun yakınlık yüz yüze aynı derinliğe ulaşmayabilir. Önemli bir konuyu yazıyla değil, sesli konuşarak açmak yanlış anlaşılmaları azaltır.',
      'Yalnızsan, seni zihinsel olarak heyecanlandıran biri ilgini çekebilir. Sohbet akıyorsa acele etme; İkizler için iyi bir konuşma, iyi bir bağın ilk işaretidir.',
    ],
    career: [
      'İletişim gerektiren işlerde güçlüsün: sunum, yazışma, pazarlık. Bugün bir fikri anlatman gerekiyorsa onu üç kısa cümleye indir; dağınık uzun açıklamalar etkini azaltır.',
      'Aynı anda birden fazla projeyle uğraşmak sana iyi geliyor, ama bugün biri bir teslim tarihini hatırlatabilir. Önce takvimine bak, sonra yeni işe evet de.',
      'Öğrenmek istediğin yeni bir araç ya da konu varsa başlamak için uygun bir gün. Hızlı kavrayışın ilk adımı kolaylaştırır; asıl iş, ikinci haftada bırakmamak.',
    ],
    money: [
      'Küçük ve sık harcamalar fark etmeden birikebilir. Son bir haftadaki küçük ödemelerine bakmak seni şaşırtabilir.',
      'Birden fazla gelir fikri aklında dolaşıyor olabilir. Hepsini aynı anda denemek yerine en az emek isteyenle başla.',
    ],
    energy: [
      'Zihnin bedeninden hızlı çalışıyor; bu da sinirsel yorgunluk yaratabilir. Gün içinde ekransız beş dakikalık aralar dikkatini toparlar.',
      'Uykuya geçmekte zorlanabilirsin. Yatmadan önce aklındakileri kısa bir listeye dökmek zihnini boşaltır.',
    ],
    emotion: [
      'Duygularını analiz etmeye çalışırken onları yaşamayı atlayabilirsin. Bir şey seni etkilediyse önce hissetmeye, sonra açıklamaya izin ver.',
      'Ruh halin gün içinde birkaç kez değişebilir. Bu tutarsızlık değil; yalnızca hızlı tepki veren bir iç dünyan var.',
    ],
    advice: [
      'Bugün yarım bıraktığın bir konuşmayı tamamla.',
      'Bir saatliğine bildirimleri kapat ve tek bir işe odaklan.',
      'Aklına gelen en iyi fikri hemen not al; akşama kadar başka on fikir onu gölgeleyebilir.',
    ],
    opportunity: [
      'Yazma, anlatma ve öğretme yeteneğin dikkat çekebilir. Bir bilgiyi paylaşmak sana beklemediğin bir bağlantı getirebilir.',
      'Kısa bir yolculuk ya da yeni bir mekân zihnine taze fikirler getirir. Rutinini küçük bir değişiklikle kırmak verimli olabilir.',
    ],
    caution: [
      'Duyduğun bir bilgiyi doğrulamadan aktarmak bugün yanlış anlaşılmalara yol açabilir.',
      'Her şeye yetişmeye çalışırken sözünü unuttuğun biri olabilir; verdiğin küçük sözleri gözden geçir.',
      'İki ayrı kişiye aynı saati söylemiş olabilirsin. Akşamdan önce takvime bak; küçük bir çakışma, iki kişiyi birden bekletir.',
    ],
  ),
  'cancer': AstrologyDayPool(
    overall: [
      'Yengeç, bugün sevdiğin insanların ruh halini kendi ruh halinden önce fark edebilirsin. Bu duyarlılık çok değerli, ama başkalarının yükünü üstlenirken kendi ihtiyacını sona bırakma.',
      'Yengeç, geçmişten bir anı, bir koku ya da bir mesaj bugün seni beklemediğin kadar etkileyebilir. Bu özlem, o dönemde sende olan ve bugün yeniden aradığın bir şeye işaret ediyor olabilir.',
      'Yengeç, bugün kimseye görünmeden evde kalmak isteyebilirsin. Bu, kaçmak değil toparlanmak da olabilir. Kapıyı tamamen kapatmak yerine bir kişiye "bugün az konuşacağım" demek, hem seni hem o bağı korur.',
      'Yengeç, için rahatsız eden bir konu varsa onu gün boyu taşıyıp akşama hiçbir adım atmamış olabilirsin. İlk hareketi sen seçersen, beklemekten daha az yorulursun. Bu büyük bir konuşma olmak zorunda değil; bir cümle ya da bir tarih yeter.',
      'Yengeç, yaşadığın yer ve yakın çevren bugün enerjini doğrudan etkiliyor. Dağınık bir oda ya da çözülmemiş bir aile meselesi zihnini meşgul ediyorsa, küçük bir düzenleme bile içini rahatlatır.',
      'Yengeç, bugün birine "iyiyim" derken aslında öyle olmadığını hissedebilirsin. Her şeyi anlatmak zorunda değilsin, ama güvendiğin birine yarısını söylemek bile yükü hafifletir.',
      'Yengeç, sevdiklerini korumak senin için bir refleks. Bugün birinin kendi hatasından öğrenmesine izin vermek, onu her zaman korumaktan daha büyük bir sevgi göstergesi olabilir.',
      'Yengeç, ruh halin gün içinde gelgitler yaşayabilir. Bunu bastırmaya çalışmak yerine sabah, öğle ve akşam kendine nasıl olduğunu sormak dalgayı yönetmeni kolaylaştırır.',
    ],
    love: [
      'Sevdiğin birinin sana ne kadar değer verdiğini küçük işaretlerden okumaya çalışabilirsin. Emin değilsen tahmin etmek yerine sormak ikinizi de yorulmaktan kurtarır.',
      'Koruyucu tarafın bugün partnerine aşırı ilgi gibi gelebilir. Desteğini sunarken kararı ona bırakmak bağınızı güçlendirir.',
      'Yalnızsan, geçmişte kalmış birini düşünmek bugün daha olası. Onu mu özlüyorsun, yoksa o dönemki kendini mi; bu ayrımı yapmak sana netlik verir.',
    ],
    career: [
      'İş ortamındaki duygusal hava performansını doğrudan etkiliyor. Gergin bir toplantıdan sonra kendine birkaç dakika vermek, işe daha sağlıklı dönmeni sağlar.',
      'Bir işin nasıl yürüdüğünü en iyi sen biliyor olabilirsin. Bunu yalnızca sende tutmak yerine üç maddelik bir not bırakmak, yokken de işin sürmesini sağlar.',
      'Eleştiri aldığında bunu kişisel algılama eğilimin olabilir. Söyleneni işin kendisiyle ilgili bir not olarak okursan çok daha kolay kullanırsın.',
    ],
    money: [
      'Güvende hissetmek için birikim yapmak istiyorsun. Bugün küçük de olsa bir kenara para ayırmak içini rahatlatır.',
      'Sevdiklerin için harcama yapma isteğin artabilir. Cömertliğin güzel, ama kendi bütçeni zorlayacak bir söz vermeden önce bir kez düşün.',
    ],
    energy: [
      'Enerjin ruh haline çok bağlı. İyi hissetmediğin bir anda kendini zorlamak yerine kısa bir dinlenme, gücünü daha hızlı geri getirir.',
      'Gergin bir günde iştahın kapanabilir ya da tam tersine ağır bir şeyler isteyebilirsin. Karar vermeden önce sade ve sıcak bir şey ye; günün fazla gelmesi bazen yalnızca açlıktır.',
    ],
    emotion: [
      'Kırgınlığını hemen göstermek yerine içinde biriktirebilirsin. Küçük bir alınganlığı sakin bir dille söylemek, büyümesini engeller.',
      'Duygusal hafızan güçlü; eski bir yara bugünkü bir olayla karışabilir. Şu an olanla geçmişte olanı ayırmak sana iyi gelir.',
    ],
    advice: [
      'Bugün kendine de başkalarına davrandığın kadar şefkatli davran.',
      'Yaşadığın alanda tek bir köşeyi toparla ve orayı sadece sana ait bir dinlenme yeri yap.',
      'Merak ettiğin birine kısa bir mesaj at; bağ kurmak için büyük bir sebebe gerek yok.',
    ],
    opportunity: [
      'Aileyle ya da yakın çevrenle ilgili ertelediğin bir konuşma için uygun bir gün. Yumuşak ama açık başlarsan karşılık bulursun.',
      'Yemek, bakım ya da düzenle ilgili bir yeteneğin bugün birine gerçekten yardımcı olabilir.',
    ],
    caution: [
      'Başkasının sorununu kendi sorunun gibi taşıma eğilimin seni gereksiz yere yorabilir.',
      'Alındığın bir konuda sessizliğe gömülmek, karşı tarafın seni yanlış anlamasına yol açabilir.',
      'Geçmişteki bir hayal kırıklığının faturasını bugünkü kişiye kesmemeye dikkat et.',
    ],
  ),
  'leo': AstrologyDayPool(
    overall: [
      'Aslan, bugün emeğinin görülmesini istiyorsun ve bu çok doğal. Ama takdir beklediğin kişi sessiz kalırsa bunu değersizlik olarak okuma; insanlar bazen fark eder ama söylemeyi unutur.',
      'Aslan, cömertliğin ve sıcaklığın etrafındaki insanları kendine çekiyor. Bugün bu enerjiyi gösteriş için değil, gerçekten değer verdiğin biri için kullandığında karşılığını daha derin alırsın.',
      'Aslan, bir işe tutunduğunda onu yarıda bırakmak sana yenilgi gibi gelebilir. Bu inat bugün bir projeyi ileri taşıyabilir. Takıldığın yer hatayı göstermenin gururuna dokunmasıysa, düzeltmeyi erteleme.',
      'Aslan, sahnede olmayı seversin ama bugün sahnenin arkasında yapılacak işler daha önemli olabilir. Görünmeyen bir hazırlık, yarın çok daha parlak bir sonuç verir.',
      'Aslan, yaratıcı tarafın bugün dışarı çıkmak istiyor. Yazmak, çizmek, bir şey tasarlamak ya da sadece kendini ifade etmek; hangisi olursa olsun, ortaya koyduğun şey moralini yükseltir.',
      'Aslan, bugün biri senden yardım istediğinde bunu bir onur gibi karşılayabilirsin. Yardım ederken ışığı tamamen kendine çekmemeye dikkat et; karşındakinin de kendi başarısını yaşamasına alan bırak.',
      'Aslan, kalbin sıcak ama gururun incindiğinde mesafe koymakta hızlısın. Seni kıran bir konuda geri çekilmeden önce, karşı tarafın niyetinin gerçekten kırıcı olup olmadığını düşün.',
      'Aslan, bugün kendini olduğundan daha az parlak hissedebilirsin. Bu his geçici; her gün sahne günü değil. Sakin bir gün, enerjini bir sonraki büyük an için toplamaya da yarar.',
    ],
    love: [
      'Sevdiğin kişiden ilgi ve hayranlık görmek istiyorsun. Aynı ilgiyi önce senin göstermen, karşılıklı bir sıcaklığı başlatabilir.',
      'Gururun incindiğinde geri çekilip karşı tarafın gelmesini bekleyebilirsin. Bu sefer ilk adımı atmak seni küçültmez, aksine ilişkiyi rahatlatır.',
      'Yalnızsan, kendini iyi hissettiğin ve parladığın ortamlarda tanışma ihtimalin artar. Sevdiğin bir etkinliğe katılmak, zorlamadan yeni biriyle tanışmanın en doğal yolu.',
    ],
    career: [
      'Liderlik etme isteğin güçlü. Bugün bir grubu yönlendirmen gerekirse herkesin fikrini dinledikten sonra karar ver; böylece hem otoriten hem saygınlığın artar.',
      'Yaptığın işin sahiplenilmesi senin için önemli. Ortak bir projede kendi katkını sakin ve net bir şekilde belirtmek, sonradan kırgınlık yaşamanı önler.',
      'Yaratıcı bir fikir rutin bir işi bambaşka bir hale getirebilir. Fikrini paylaşırken ayrıntılarını da hazırla; Aslan coşkusu planla birleşince ikna edicidir.',
    ],
    money: [
      'Kendini ödüllendirmek için büyük bir harcama yapma isteğin olabilir. Hak ettiğin bir şey olsa bile, bütçeni zorlamayan bir versiyonu da aynı keyfi verebilir.',
      'Cömertliğin bugün hesapsız harcamaya dönüşebilir. Vermek güzel, ama kendi dengen de önemli.',
    ],
    energy: [
      'Enerjin güçlü ama gösterişli başlangıçlar yapıp çabuk yorulabilirsin. Gücünü gün boyuna yaymak için tempolu ama sürdürülebilir bir ritim seç.',
      'Sırtını dinlendirmek için dik oturmaya ve derin nefes almaya dikkat et; küçük bir duruş değişikliği bile fark yaratır.',
    ],
    emotion: [
      'Takdir görmediğinde içten içe kırılabilirsin. Kendi emeğini önce sen tanırsan, başkalarının onayına daha az ihtiyaç duyarsın.',
      'Güçlü görünmek zorunda olduğunu hissedebilirsin. Güvendiğin birine yorgun olduğunu söylemek seni küçültmez.',
    ],
    advice: [
      'Bugün birinin başarısını içtenlikle kutla.',
      'Bir işi kimse görmese bile en iyi şekilde bitir; içindeki gurur bunu fark eder.',
      'Kendini ifade edebileceğin küçük bir yaratıcı iş için yarım saat ayır.',
    ],
    opportunity: [
      'Bir sunum, paylaşım ya da sahne anı için uygun bir gün. Kendine güvenin dinleyenlere de geçer.',
      'Bir ekibi ya da arkadaş grubunu bir araya getirecek bir fikir başlatabilirsin; insanlar senin enerjine kolayca katılır.',
    ],
    caution: [
      'Eleştiriye anında savunmayla cevap vermek, haklı olduğun noktaları da gölgede bırakabilir.',
      'Masada söz sende uzadıkça, sessiz kalan kişinin elindeki notu göremeyebilirsin. Bir kez "sen ne eklerdin" demek, odayı sana kapatmadan büyütür.',
      'Verdiğin sözün büyüklüğünü abartma; yapabileceğinden biraz azını vaat et.',
    ],
  ),
  'virgo': AstrologyDayPool(
    overall: [
      'Başak, bugün gözünden kaçmayan küçük hatalar seni rahatsız edebilir. Her ayrıntıyı düzeltmeye çalışmak yerine gerçekten önemli olan üçünü seç; geri kalanı zaten kimsenin fark etmeyeceği kadar küçük.',
      'Başak, yardım etmeyi seversin ve bugün birinin işini kolaylaştırmak sana iyi gelebilir. Yalnız, istenmeden verilen tavsiye eleştiri gibi algılanabilir; önce yardım isteyip istemediğini sor.',
      'Başak, zihnin bugün planlar ve listelerle dolu. Bu düzen sana güven veriyor, ama plan bozulduğunda kaygın artabilir. Gün içinde boş bırakacağın bir saat ayırmak seni rahatlatır.',
      'Başak, kendine karşı başkalarına olduğundan çok daha sert olabiliyorsun. Bugün yaptığın bir işe dışarıdan bakan biri gibi bakmayı dene; muhtemelen sandığından çok daha iyi.',
      'Başak, gün ortasında plan değişirse ilk his "gün bozuldu" olabilir. Birkaç dakika sonra aklın zaten yeni bir sıra kurar. O ilk sıkışmayı, işi yapamayacağın anlamına yorma.',
      'Başak, bugün herkesin işini toparlamaya çalışırken kendi işin arkada kalabilir. Önce kendi önceliğini bitirmek bencillik değil; ancak o zaman başkalarına gerçekten yardım edebilirsin.',
      'Başak, ayrıntıları görmen bir yetenek, ama bugün büyük resmi kaçırmana neden olabilir. Bir adım geri çekilip "bu iş aslında neye hizmet ediyor" diye sormak sana yön verir.',
      'Başak, içindeki eleştirmen bugün sesini yükseltebilir. Onu susturmaya çalışmak yerine ona tek bir görev ver: yalnızca bir şeyi iyileştirsin, gerisini rahat bıraksın.',
    ],
    love: [
      'Sevgini çoğu zaman pratik yardımlarla gösterirsin. Karşı taraf ise bugün biraz daha duygusal bir yakınlık bekliyor olabilir; bir işi halletmek yerine yanında oturmak yeter.',
      'Partnerinin küçük kusurlarını fark etmek senin için kolay. Bugün onları düzeltmeye değil, sevdiğin yanlarını söylemeye odaklanmak ilişkiye nefes aldırır.',
      'Yalnızsan, birini tanırken fazla analiz edip anı kaçırabilirsin. İlk izlenimde kusur aramak yerine kendini biraz daha rahat bırakmayı dene.',
    ],
    career: [
      'Ayrıntılara dikkatin bir hatayı büyümeden yakalamanı sağlayabilir. Bulduğun sorunu çözümüyle birlikte sunmak seni ekipte vazgeçilmez kılar.',
      'Kusursuz olsun diye bir işi teslim etmeyi geciktirmek bugün sana zarar verebilir. Yeterince iyi bir teslim, mükemmel ama geç olandan daha değerli.',
      'Düzen ve sistem kurma yeteneğin fark edilebilir. Dağınık bir süreci sadeleştirmeyi önermek için iyi bir zaman.',
    ],
    money: [
      'Bütçe takibi senin için doğal. Harcamalarını gözden geçirirken kendine küçük bir keyif payı bırakmayı unutma.',
      'İndirimli diye ihtiyacın olmayan bir şeyi almak kolay bir tuzak olabilir; listede yoksa sepete ekleme.',
    ],
    energy: [
      'Endişe bugün bedenine gerginlik olarak yansıyabilir. Kısa bir yürüyüş ya da düzenli nefes, zihninde dönüp duran düşünceleri yavaşlatır.',
      'Kaygı birikince öğünü atlayıp sonra daha dağınık hissedebilirsin. Listeye bir tur daha bakmak yerine her zamanki saatte sade bir öğün, öğleden sonrayı toplar.',
    ],
    emotion: [
      'Her şeyin kontrol altında olması gerektiğini hissettiğinde huzursuzlanabilirsin. Bir şeyi kendi haline bırakmak sana beklemediğin bir rahatlık verebilir.',
      'Seni eleştiren iç ses bugün yüksek olabilir. Ona, bir arkadaşına nasıl cevap verirsen öyle cevap ver.',
    ],
    advice: [
      'Bugün yapılacaklar listenden bir maddeyi bilinçli olarak sil.',
      'Bitirdiğin bir işi düzeltmek için yeniden açma; teslim et ve devam et.',
      'Yardım etmeden önce karşındakine ne istediğini sor.',
    ],
    opportunity: [
      'Sağlık, düzen ya da verimlilikle ilgili yeni bir alışkanlığa başlamak için verimli bir gün. Küçük başla ki sürdürebilesin.',
      'Analiz yeteneğin birinin karmaşık bir sorununu çözmesine yardımcı olabilir; bu da sana yeni bir bağlantı getirebilir.',
    ],
    caution: [
      'Birinin dağınık anlattığı şeyi cümle cümle düzeltirken asıl sorusunu kaçırabilirsin. Önce cevap ver; düzeni, iş bittikten sonra konuş.',
      'Evin ya da çantanın içinde "lazım olur" diye biriktirdiğin bir şeyi bugün yerine koy ya da çıkar. Dağınık bir yığın, yapılacak iş kadar yer kaplar.',
      'Her olasılığı önceden düşünmeye çalışmak kaygını artırır; bazı şeyleri geldiğinde çözmek yeterli.',
    ],
  ),
  'libra': AstrologyDayPool(
    overall: [
      'Terazi, bugün herkesi memnun etmeye çalışırken kendi fikrini söylemeyi erteleyebilirsin. Denge kurmak senin doğanda var, ama dengenin bir tarafında senin de durman gerekiyor.',
      'Terazi, iki seçenek arasında kaldığında her birinin artısını ve eksisini sonsuz kez tartabilirsin. Bugün bir karar için kendine net bir süre ver; süre bittiğinde içinden gelene güven.',
      'Terazi, dağınık bir masa ya da rastgele bir kıyafet bugün moralini olduğundan fazla düşürebilir. On dakikalık bir toparlama, sevdiğin bir koku ya da tanıdık bir müzik, ruh halini büyük bir plandan daha çabuk düzeltir.',
      'Terazi, iki kişi birbirine sertleşince bakışlar sana dönebilir. Arayı yumuşatabilirsin; bunun için bir tarafı seçmen gerekmez. İkisinin de duyduğu tek soru, "şu an aynı şeyi mi istiyorsunuz", çoğu zaman yeter.',
      'Terazi, adaletsizlik gördüğünde içinde güçlü bir rahatsızlık uyanır. Bunu sessizce taşımak yerine sakin ama net bir dille söylemek, sandığından fazla etki yaratabilir.',
      'Terazi, birinin seni sevmesini ya da onaylamasını istemek bugün kararlarını etkileyebilir. Bir seçim yapmadan önce, kimse ne düşüneceğini bilmeseydi ne yapacağını kendine sor.',
      'Terazi, insanların iyi yanını görmekte ustasın. Birinin sana verdiği bir sözü tutmadığını fark edersen, bunu görmezden gelmek yerine nazikçe hatırlatmak ilişkiyi daha sağlıklı kılar.',
      'Terazi, uyumlu bir ortam sana iyi geliyor ama her anlaşmazlık bir kriz değil. Küçük bir fikir ayrılığını dile getirmek, aranızdaki bağı zayıflatmak yerine daha dürüst hale getirebilir.',
    ],
    love: [
      'İlişkide uyumu korumak için kendi isteklerini geri planda bırakabilirsin. Küçük de olsa bir tercihini açıkça söylemek, karşındakinin seni daha iyi tanımasını sağlar.',
      'Romantik jestler ve güzel anlar senin için önemli. Özel bir plan için büyük bir sebebe gerek yok; sıradan bir akşamı biraz özenle güzelleştirmek yeter.',
      'Yalnızsan, birinden hoşlanıp hoşlanmadığına karar vermek uzun sürebilir. Belirsizlik seni yoruyorsa, bir sonraki buluşmada kendini nasıl hissettiğine odaklan.',
    ],
    career: [
      'İş ilişkilerinde diplomatik tarafın bugün işe yarar. Zor bir müşteriyle ya da gergin bir ekip arkadaşıyla konuşman gerekiyorsa önce ortak noktayı bul, oradan başla.',
      'Karar verme sorumluluğu sana düştüğünde erteleme eğilimin olabilir. En azından ilk adımın ne olacağına karar vermek işi hızlandırır.',
      'Ortaklık ve iş birliği sana iyi geliyor. Tek başına uğraştığın bir konuda doğru kişiden destek istemek sonucu hem hızlandırır hem güzelleştirir.',
    ],
    money: [
      'Güzel şeylere harcama yapma isteğin artabilir. Alacağın şeyin seni gerçekten mutlu edip etmeyeceğini görmek için bir gün beklemek akıllıca.',
      'Ortak harcamalarda adil bir paylaşım konusunu açmak bugün daha kolay olabilir.',
    ],
    energy: [
      'Ortamdaki gerginlik enerjini hızla düşürür. Çatışmalı bir ortamdan sonra sakin bir yerde kısa bir mola vermek dengeni geri getirir.',
      'İnsanların sürtüştüğü bir odada uzun süre oturmak, az konuşsan bile seni yorar. Sonraki görüşmeden önce yerini değiştirmek ya da bir dakikalığına dışarı çıkmak, aynı tartışmaya daha düzgün dönmeni sağlar.',
    ],
    emotion: [
      'Birinin sana kırıldığını düşünmek seni olduğundan fazla meşgul edebilir. Emin değilsen sormak, içinde kurduğun senaryodan çok daha az yorar.',
      'Kendi duygunu karşı tarafın duygusundan ayırmakta zorlanabilirsin. "Ben ne hissediyorum" sorusunu kendine bir kez sor.',
    ],
    advice: [
      'Ertelediğin küçük bir kararı akşama kadar ver.',
      'Bir konuda gerçekten ne düşündüğünü kimseye danışmadan önce kendine yaz.',
      'Çevrende sana iyi gelen bir şeyi güzelleştirmek için on dakika ayır.',
    ],
    opportunity: [
      'Bir anlaşma, uzlaşma ya da ortaklık konuşması için verimli bir gün; iki tarafın da kazandığı bir çözüm bulma ihtimalin yüksek.',
      'Sanat, tasarım ya da estetikle ilgili bir yeteneğin takdir görebilir.',
    ],
    caution: [
      'Bir şeyi yalnızca güzel durduğu için seçmek, kullanmayacağın bir eşyayla bitebilir. Almaktan önce onu nerede kullanacağını bir cümleyle söyle.',
      '"Bakarız" dediğin bir şey karşı tarafta söz gibi durabilir. Net değilsen, "yarın öğlene kadar haber veririm" demek, belirsiz bir evetten daha az kırar.',
      'Daha derli toplu görünen birinin yanında kendi önerini küçültebilirsin. Yarım kalan fikrini de masaya koy; karşılaştırma, senin katkını silmesin.',
    ],
  ),
  'scorpio': AstrologyDayPool(
    overall: [
      'Akrep, bugün yüzeyde söylenenle altında yatan şey arasındaki farkı kolayca fark edebilirsin. Bu sezgi güçlü bir pusula, ama her sezgiyi kesin bilgi saymadan önce küçük bir doğrulama yapmak seni yanılmaktan korur.',
      'Akrep, bir konuya bağlandığında derinine inmeden bırakmazsın. Kafanı meşgul eden bir soru varsa ona zaman ayır; yarım bırakılan sorular sende uzun süre yankı yapar.',
      'Akrep, kontrolü elinde tutmak sana güven veriyor. Bugün kontrol edemediğin bir durumla karşılaşırsan, neyi değiştirebileceğini ve neyi bırakman gerektiğini ayırmak gücünü korur.',
      'Akrep, haftalar önce duyduğun bir cümle bugün hâlâ aklına takılabilir. Konuşmadan önce kendine sor: bu yük bugünkü olaydan mı kaldı, yoksa o eski cümleden mi. Ayırınca verilecek cevap daha kısa olur.',
      'Akrep, bitmiş bir sohbeti, bir rolü ya da bir alışkanlığı sürdürmek bazen yalnızca alışkanlıktan olur. Bırakmanın vakti geldiğini hissediyorsan bunu bugün tek bir kesikle yap: bir yazışmayı kapatmak ya da bir taahhüdü küçültmek.',
      'Akrep, bugün birinin sana tam olarak ne istediğini söylemediğini hissedebilirsin. Sezgine güvenmek güzel, ama doğrudan sormak ikinizi de gereksiz bir tahmin oyunundan kurtarır.',
      'Akrep, sırlarını korumak senin için önemli ve buna hakkın var. Bugün yalnızca küçük bir şeyi paylaşmak, sana duyulan güveni ve yakınlığı beklediğinden fazla artırabilir.',
      'Akrep, bir hedefe kilitlendiğinde çok güçlüsün. Bugün bu odağı bir kişiyi değiştirmeye değil, kendi elindeki bir konuyu sonuna kadar götürmeye harcamak sana daha çok kazandırır.',
    ],
    love: [
      'Karşındaki kişi gününü anlatırken sen çözümü hazırlıyor olabilirsin. Çözümü bir tur ertele. "Sonra ne oldu?" diye sormak, o akşam için hazır bir tavsiyeden daha yakın bir cevaptır.',
      'Kıskançlık ya da güvensizlik hissi yüzeye çıkarsa, karşı tarafı sınamak yerine neden böyle hissettiğini açıkça söyle. Sınamak güveni azaltır, açıklık artırır.',
      'Yalnızsan, birine kolay açılmaman seni koruyor ama bazen fırsatları da kaçırtıyor. Küçük bir kişisel ayrıntı paylaşmak, karşındakinin de açılmasını sağlar.',
    ],
    career: [
      'Araştırma, analiz ya da kriz yönetimi gerektiren işlerde güçlüsün. Başkalarının pes ettiği bir soruna sabırla eğilmek seni öne çıkarabilir.',
      'İş yerinde güç dengelerini iyi okuyorsun. Bu bilgiyi kimseyi zorlamak için değil, doğru zamanda doğru adımı atmak için kullan.',
      'Bir projeye tam odaklandığında çevreni unutabilirsin. Önemli bir gelişmeyi ekiple paylaşmak emeğinin görünür olmasını sağlar.',
    ],
    money: [
      'Ortak paralar, borçlar ya da paylaşılan kaynaklar bugün dikkat isteyebilir. Belirsiz kalan bir hesabı netleştirmek içini rahatlatır.',
      'Uzun vadeli bir birikim kararını aceleyle değil, araştırarak vermek senin doğana uygun.',
    ],
    energy: [
      'Duygusal yoğunluk bedenine yorgunluk olarak yansıyabilir. Bol su, biraz hareket ya da derin bir uyku seni yeniler.',
      'Enerjini içe dönük ve yoğun işlere harcıyorsun; gün içinde biraz hafif ve eğlenceli bir şeye de yer aç.',
    ],
    emotion: [
      'Hissettiğini göstermemek seni güvende tutuyor gibi görünse de, güvendiğin biriyle bir duygunu paylaşmak yükünü hafifletir.',
      'Birine öfken varsa onu bastırmak yerine yazıya dökmek ne hissettiğini daha net görmeni sağlar.',
    ],
    advice: [
      'Bırakman gereken bir şeyi bugün kendine sessizce adlandır.',
      'Şüphelendiğin bir konuyu tahmin etmek yerine doğrudan sor.',
      'Kendini yenilemek için yalnız kalabileceğin kısa bir zaman yarat.',
    ],
    opportunity: [
      'Gözden kaçmış bir bilgiyi ya da ayrıntıyı ortaya çıkarmak için iyi bir gün; dikkatli bakışın bir sorunu çözebilir.',
      'Derin bir konuşma, uzun süredir mesafeli olduğun biriyle aranızdaki buzları eritebilir.',
    ],
    caution: [
      'Bir şüpheyi kesin gerçek gibi kabul edip harekete geçmek yanlış anlaşılmalara yol açabilir.',
      'Kırgınlığını sessiz bir hesaplaşmaya dönüştürmek seni de yorar; söylenmesi gerekeni söyle ve bırak.',
      'Her şeyi kontrol etmeye çalışmak, güvendiğin insanları uzaklaştırabilir.',
    ],
  ),
  'sagittarius': AstrologyDayPool(
    overall: [
      'Yay, bugün rutinin dışına çıkma isteğin güçlü. Uzak bir yolculuğa çıkamasan bile yeni bir yer görmek, yeni bir konu öğrenmek ya da farklı biriyle konuşmak zihnini açar.',
      'Yay, açık sözlülüğün seni dürüst ve güvenilir kılıyor. Bugün bir gerçeği söylemen gerekirse, ne söylediğin kadar nasıl söylediğine de dikkat et; aynı doğru, nazikçe söylendiğinde daha çok dinlenir.',
      'Yay, büyük resmi görmekte ustasın ama bugün ayrıntılar seni sınayabilir. Heyecanla başladığın bir planın küçük adımlarını yazmak onu hayalden gerçeğe taşır.',
      'Yay, iyimserliğin çevrendeki insanlara umut veriyor. Bugün birine cesaret vermek için doğru kişi sen olabilirsin; yalnızca tutamayacağın sözler vermemeye dikkat et.',
      'Yay, özgürlüğün kısıtlandığını hissettiğinde huzursuzlanırsın. Seni bağladığını düşündüğün bir sorumluluğa farklı bir açıdan bakmak onu bir yük olmaktan çıkarabilir.',
      'Yay, bugün birinin seni kısıtladığını düşünüp sabırsızlanabilirsin. Belki de o kişi senin heyecanının göremediği bir riski görüyor; bir dakika dinlemek yolculuğunu daha güvenli kılar.',
      'Yay, anlam arayışı seni her zaman ileri taşıyor. Bugün yaptığın sıradan bir işin bile neden önemli olduğunu bulursan, sıkıcı görünen saatler daha kolay geçer.',
      'Yay, mizah anlayışın zor anları hafifletmekte ustaca. Ciddi bir konuşmada esprinin yerini iyi seç; doğru anda yapılan şaka rahatlatır, yanlış anda yapılan geçiştirir.',
    ],
    love: [
      'İlişkide alan ve özgürlük senin için önemli. Buna ihtiyaç duyduğunu suçluluk duymadan, ama karşı tarafı da dışarıda bırakmadan söylemek bağınızı güçlendirir.',
      'Birlikte yeni bir şey keşfetmek sizi yakınlaştırır. Küçük bir macera planı, rutin bir akşamdan çok daha unutulmaz olabilir.',
      'Yalnızsan, farklı bir kültürden ya da farklı bir dünya görüşünden biri ilgini çekebilir. Merakın en iyi yanın; sohbeti derinleştirmekten çekinme.',
    ],
    career: [
      'Yeni bir fikir, eğitim ya da büyüme planı seni heyecanlandırabilir. Ekibe sunmadan önce gerçekçi bir zaman çizelgesi eklemek ikna gücünü artırır.',
      'Rutin işler bugün sana sıkıcı gelebilir. Onları daha hızlı bitirmenin bir yolunu bulursan asıl ilgini çeken işe daha çok zaman kalır.',
      'Öğretmek, yönlendirmek ya da bilgi paylaşmak konusunda doğal bir yeteneğin var. Birine yol göstermek senin de konuyu daha iyi anlamanı sağlar.',
    ],
    money: [
      'İyimserliğin harcamalarında da kendini gösterebilir. "Nasılsa bir şekilde hallolur" düşüncesiyle yapılacak büyük bir harcamayı ertelemek akıllıca.',
      'Eğitime, seyahate ya da kişisel gelişime yapılan harcamalar uzun vadede geri dönebilir; yine de bütçeni aşmadan planla.',
    ],
    energy: [
      'Hareket etmek ve açık havada olmak enerjini hızla yükseltir. Kısa da olsa dışarıda vakit geçirmeyi dene.',
      'Çok fazla şeyi aynı anda yapmaya çalışmak seni yorabilir; bugün enerjini iki ana işe ayırmak yeterli.',
    ],
    emotion: [
      'Ağır duygulardan kaçmak için espriye ya da hareketliliğe sığınabilirsin. Bir duyguyla biraz daha kalmak onu daha çabuk geçirir.',
      'Hayal kırıklığı yaşadığında hemen yeni bir hedefe atlamak isteyebilirsin. Önce ne olduğunu anlamak bir sonraki adımını daha sağlam kılar.',
    ],
    advice: [
      'Bugün merak ettiğin bir konuya yarım saat ayır ve gerçekten öğren.',
      'Verdiğin bir sözü yerine getirmeden yenisini verme.',
      'Gün içinde bir süreliğine telefonunu bırakıp açık havaya çık.',
    ],
    opportunity: [
      'Yeni bir kurs, seyahat planı ya da farklı bir bakış açısı getiren bir sohbet için uygun bir gün.',
      'Aklında bir yol, bir ders ya da uzaktaki bir kişi varsa, heyecanı ayırmak için tarih, para ve kimin üstleneceği sorularını bir kâğıda yaz. Ayrıntı duruyorsa plan da durur.',
    ],
    caution: [
      'Doğru bir şeyi, karşı tarafın yeni duyduğu bir haberin üstüne hemen söylemek kırıcı olabilir. Aynı cümle bir saat sonra, haber sindikten sonra daha az iz bırakır.',
      'Abartılı vaatler vermek seni sonradan zor durumda bırakabilir; yapabileceğin kadarını söyle.',
      'Sıkıldığın bir işi yarım bırakmak cazip gelebilir, ama bitmemiş işler bir gün yine önüne çıkar.',
    ],
  ),
  'capricorn': AstrologyDayPool(
    overall: [
      'Oğlak, bugün omuzlarındaki sorumluluklar tek bir yığına dönüşmüş gibi durabilir. Hepsini tek başına taşımak zorunda değilsin; birini devretmek ya da yardım istemek gücünü azaltmaz, korur.',
      'Oğlak, uzun vadeli hedeflerin seni ayakta tutuyor. Sonuca henüz yakın olmadığını hissedersen, bir yıl önce nerede olduğuna bakmak ne kadar yol aldığını gösterir.',
      'Oğlak, bugün de işi bitirmeden kalkmak sana savurganlık gibi gelebilir. Yirmi dakikalık bir ara, aynı tempoyu akşama kadar taşımandan daha çok iş bitirir. Disiplin, hiç durmamak değildir.',
      'Oğlak, kafanda uzun süredir duran bir planın ilk görünür adımı bugün atılabilir. Bu adım bütün yapıyı kurmak değil; bir arama, bir sayfa ya da bir tarih. Küçük olması, ciddiyetini azaltmaz.',
      'Oğlak, başarıyı çoğu zaman sonuçla ölçersin. Bugün ilerlemeyi yalnızca hedefe varıp varmadığınla değil, ne kadar istikrarlı devam ettiğinle değerlendirmeyi dene.',
      'Oğlak, bugün birinin işini senin kadar iyi yapmadığını düşünüp işi devralma isteği duyabilirsin. Bunu yapmadan önce, ona nasıl yapacağını göstermenin uzun vadede daha çok zaman kazandıracağını düşün.',
      'Oğlak, sabrın ve dayanıklılığın seni çoğu kişiden ileri taşıyor. Yavaş ilerleyen bir süreç bugün seni sıkabilir; ama senin gücün her zaman acelede değil, süreklilikte oldu.',
      'Oğlak, çalışmak sana kontrol hissi veriyor. Bugün işle ilgisi olmayan küçük bir keyfe zaman ayırmak, aynı güven duygusunu başka bir yerden bulmanı sağlayabilir.',
    ],
    love: [
      'Duygularını göstermekte temkinli olabilirsin ama sevdiğin insanlar için çok şey yaparsın. Bunu bugün sözle de ifade etmek, karşı tarafın seni daha iyi anlamasını sağlar.',
      'İşin ya da sorumlulukların ilişkine ayırdığın zamanı daraltıyor olabilir. Kısa ama tamamen orada olduğun bir zaman, uzun ama dalgın geçen bir akşamdan daha değerli.',
      'Yalnızsan, güvenilir ve olgun birine ilgi duyman doğal. Acele etmeden tanımak sana uygun; ama her şeyi bir kontrol listesiyle değerlendirmek kimyayı gölgeleyebilir.',
    ],
    career: [
      'Emek verdiğin bir konu fark edilebilir. Fırsat çıkarsa katkını açıkça söylemekten çekinme; sessiz çalışkanlık her zaman kendiliğinden görünmez.',
      'Yönetim, planlama ya da yapı kurma gerektiren işlerde güçlüsün. Dağınık bir süreci düzene sokmak bugün senin için doğal bir fırsat.',
      'Kendine çok yüksek standartlar koyduğunda yorulabilirsin. Bir işi "yeterince iyi" seviyesinde bırakmak enerjini daha önemli bir işe saklar.',
    ],
    money: [
      'Uzun vadeli bir para planı yapmak için verimli bir gün. Küçük ama düzenli bir birikim kararı zamanla büyük bir güven sağlar.',
      'Paranı korumak konusunda dikkatlisin; kendine küçük bir keyif harcaması yapmak da bu dengenin bir parçası olabilir.',
    ],
    energy: [
      'Yorgunluğu fark etmeyip işe devam etmek sana disiplin gibi gelebilir. Bugün bitiş saatini öne çekmek, yarınki işin parçasıdır; iki dakika esnemek de buna dahildir.',
      'Yorgunluğu görmezden gelip devam etme eğilimin var; bugün erken yatmak yarınki performansını artırır.',
    ],
    emotion: [
      'Güçlü görünme ihtiyacın duygularını bastırmana yol açabilir. Kendine "yorgunum" demeye izin ver.',
      'Endişelerini plan yaparak yönetiyorsun. Planın dışında kalan bir şey olursa bunu başarısızlık değil, hayatın doğal akışı olarak gör.',
    ],
    advice: [
      'Bugün bir işi devret ya da birinden yardım iste.',
      'Ulaştığın küçük bir başarıyı not et ve kendini takdir et.',
      'Uzun vadeli hedefine giden yolda bu hafta atacağın tek somut adımı belirle.',
    ],
    opportunity: [
      'Yeni bir sorumluluk ya da rol konusunda adım atmak için uygun bir gün; deneyimin senin yerine konuşur.',
      'Daha deneyimli biriyle yapacağın bir konuşma sana uzun vadede işine yarayacak bir yol gösterebilir.',
    ],
    caution: [
      'İşe kendini fazla adamak, yakınlarının kendini ihmal edilmiş hissetmesine yol açabilir.',
      'Her şeyi kontrol altında tutma isteği başkalarının katkısına alan bırakmamana neden olabilir.',
      'Bir ara hedefi kutlamadan bir sonrakine geçersen, haftanın içinde "bu emek işe yaradı" diyecek bir iz kalmaz. Küçük bir bitişi akşama not etmek, kendini azarlamaktan daha çok işe yarar.',
    ],
  ),
  'aquarius': AstrologyDayPool(
    overall: [
      'Kova, bugün kalıplara uymayan bir fikir seni heyecanlandırabilir. Çevren hemen anlamasa bile fikrini not al; zamanından önce gelen düşünceler çoğu zaman sonradan değer kazanır.',
      'Kova, bağımsızlığın senin için vazgeçilmez. Bugün biri sana fazla yakın gelirse geri çekilmek isteyebilirsin; mesafe koymak yerine neye ihtiyacın olduğunu açıklamak ilişkiyi korur.',
      'Kova, topluluk ve arkadaşlık sana enerji veriyor. Bir grup içinde ya da ortak bir amaç etrafında olmak, tek başına uğraştığın bir sorunu çözmene yardımcı olabilir.',
      'Kova, seninle zıt sonuca varan biriyle konuşurken haklı çıkmak ilk refleksin olabilir. Karşı tarafın elinde, senin atladığın tek bir bilgi varsa onu almak, tartışmayı kazanmaktan daha çok işine yarar.',
      'Kova, duygularını mantıkla açıklamaya çalışabilirsin. Bugün içinde net bir açıklaması olmayan bir his varsa, onu çözmeden önce yalnızca fark etmen yeterli.',
      'Kova, bir odada herkes aynı yöne bakıyorsa senin aklın başka bir ayrıntıya takılabilir. Bunu hemen itiraz diye söylemek zorunda değilsin. "Şu kısmı henüz kimse kontrol etmedi" demek, karşı çıkmak değil, eksik bir parçayı masaya koymaktır.',
      'Kova, büyük fikirlere duyduğun ilgi bazen yanındaki kişiyi görmeni zorlaştırabilir. Bugün yakın çevrendeki birinin küçük bir ihtiyacını fark etmek, büyük bir değişim kadar değerli.',
      'Kova, rutin bugün seni sıkabilir ve her şeyi değiştirme isteği uyanabilir. Her şeyi baştan kurmak yerine tek bir şeyi farklı yapmak bu isteği daha sağlıklı karşılar.',
    ],
    love: [
      'İlişkide arkadaşlık temeli senin için çok önemli. Partnerinle birlikte yeni bir fikir ya da proje üzerine konuşmak, klasik romantik bir akşamdan daha çok yakınlaştırabilir.',
      'Duygusal konularda mesafeli görünebilirsin. Karşındaki kişiye değer verdiğini açık ve sade bir cümleyle söylemek beklediğinden fazla etki yaratır.',
      'Tanıştığın kişi alıştığın tipe benzemese bile, sohbet üçüncü konuda hâlâ yeni bir şey öğretiyorsa erken kapatma. Ortak merak, ilk dakikadaki heyecandan daha çok şey söyler.',
    ],
    career: [
      'Yenilikçi ve sıra dışı fikirlerin bir sorunu çözmenin anahtarı olabilir. Fikrini sunarken pratik faydasını da göstermek kabul görmesini kolaylaştırır.',
      'Tekrar eden bir işi herkes katlanıyor diye sen de katlanmak zorunda değilsin. Bir adımı kısaltan somut bir önerin varsa bugün onu yaz. "Sistem böyle" demek, o adımı haklı çıkarmaz.',
      'Kurallara ve hiyerarşiye karşı sabırsızlık hissedebilirsin. Değiştirmek istediğin bir şey varsa, önce nasıl işlediğini anlamak seni daha ikna edici kılar.',
    ],
    money: [
      'Sıra dışı bir gelir fikri ya da yeni bir finansal araç ilgini çekebilir. Merakın güzel, ama araştırmadan para yatırma.',
      'Ortak bir amaç için destek olma isteğin olabilir; cömertliğini bütçene uygun şekilde planla.',
    ],
    energy: [
      'Zihinsel enerjin yüksek ama bedenini ihmal edebilirsin. Gün içinde biraz hareket etmek düşüncelerini de tazeler.',
      'Düzensiz uyku saatleri enerjini dalgalandırabilir; bugün düzenli bir saatte yatmaya özen göster.',
    ],
    emotion: [
      'Kalabalık içinde bile kendini farklı ya da yalnız hissedebilirsin. Bu his, seni gerçekten anlayan birkaç kişiyle vakit geçirme ihtiyacına işaret ediyor olabilir.',
      'Bir hisse hemen ad koymak zorunda değilsin. Önce onun hangi anda geldiğini fark et; açıklama, hissettikten sonra da gelebilir.',
    ],
    advice: [
      'Aklına gelen sıra dışı bir fikri not al ve bir kişiyle paylaş.',
      'Mesafeli göründüğün birine kısa ve sıcak bir mesaj gönder.',
      'Bir grup ya da topluluk etkinliğinde bir saat geçir.',
    ],
    opportunity: [
      'Yeni bir topluluk, çevre ya da ortak proje kapısı açılabilir; insanlarla bağlantı kurmak sana beklemediğin fırsatlar getirir.',
      'Teknolojiyle ilgili yeni bir beceri öğrenmek bugün sana daha kolay gelebilir.',
    ],
    caution: [
      'Kulağa özgün geldiği için bir plana, bir ortaklığa ya da bir harcamaya hızlı evet diyebilirsin. Sıkıcı kısmı da sor: bunu kim sürdürecek, ne kadara patlar, ne zaman biter.',
      'Kısa cevapların, karşı taraf için "meşgulüm" değil "ilgilenmiyorum" diye duyulabilir. "Akşam konuşalım" gibi tek cümle, sessizliğin açtığı boşluğu kapatır.',
      'Bir fikir sana fazla sıradan göründüğü için grupta suskun kalabilirsin. Söylenmeyen pratik parça, o fikri çalışır hale getirecek olan olabilir.',
    ],
  ),
  'pisces': AstrologyDayPool(
    overall: [
      'Balık, bir mesajı ya da bir konuşmayı gün içinde birkaç kez aklından geçirebilirsin. Buna hemen anlam yüklemek zorunda değilsin. Akşama kadar aynı ayrıntı mı duruyor, yoksa yeni bir şey mi eklendi; onu ayırmak yeter.',
      'Balık, uzun bir sohbetten sonra hangi kaygının sende başladığını, hangisinin karşındakinden geçtiğini karıştırabilirsin. Eve gelince on dakika hiçbir şey anlatmadan oturmak bu karışıklığı ayırır. Yorgunluğun hepsi senin olmak zorunda değil.',
      'Balık, aklındaki bir sahne bugün dağınık duruyor olabilir. Onu bir şarkıya, bir paragrafa ya da bir defter sayfasına dökmek, içinde döndürmekten daha az yorar. Bitmiş bir iş bekleme; bir taslak yeter.',
      'Balık, üç kişinin planına birden uyum sağlarsan kendi öğleden sonran kaybolabilir. Akışa uymak kolayına gelir. Bugün bir saati baştan kendine ayırırsan, diğer evetler daha hafif kalır.',
      'Balık, gerçeklerle yüzleşmek bazen zor gelir ve hayal dünyası güvenli bir sığınak olur. Ertelediğin pratik bir işi küçük bir adımla bitirmek, hayal gücüne daha çok alan açar.',
      'Balık, bugün birinin derdini dinlerken kendi sınırlarını unutabilirsin. Şefkatin değerli, ama dinledikten sonra kendini yeniden toplayacak bir zaman ayırmak da en az onun kadar önemli.',
      'Balık, bir kararda içinden gelen ilk eğilim ile elindeki somut bilgi çatışabilir. İkisini de yok sayma. Önce eğilimi bir cümleyle yaz, sonra ona uymayan tek gerçeği yanına koy.',
      'Balık, gerçek hayatın yükü ağır gelirse bir süreliğine hayallere kaçmak isteyebilirsin. Bu kaçış kısa bir mola olarak iyi gelir; yeter ki geri dönmeyi unutma.',
    ],
    love: [
      'Sevdiğin kişiyle akşamı özel kılmak için bir yer ayırtmana gerek yok. Günün tek somut anısını, iyi ya da zor, ona anlatman yeter. Büyük bir jest, bu cümlenin yerini tutmaz.',
      'Karşındaki kişiyi idealize etme eğilimin olabilir. Onu olduğu gibi görmek hayal kırıklıklarını önler ve gerçek yakınlığı derinleştirir.',
      'Yalnızsan, iyi geçen tek bir sohbetten sonra karşı tarafın niyetini büyütmek kolayına gelebilir. İkinci buluşmadan önce, hoşuna giden şeyin kişi mi yoksa o akşamki ilgi mi olduğunu ayır.',
    ],
    career: [
      'Bir yazışmada listedeki maddeler tamam olsa bile ton bir şeyi kaçırıyor olabilir. Cevabı göndermeden önce karşı tarafın neyi merak ettiğini bir satırla eklemek, işi yeniden yapmaktan kısa sürer.',
      'Belirsiz talimatlar bugün kafanı karıştırabilir. Ne beklendiğinden emin değilsen sormak, sonradan yeniden yapmaktan çok daha az zaman alır.',
      'Başkalarına yardım etmek isterken kendi işlerini geciktirebilirsin. Önce kendi önceliklerini netleştir, sonra destek ol.',
    ],
    money: [
      'Duygusal kararla yapılan harcamalar bugün daha olası. Bir şey almadan önce bunun bir ihtiyaç mı yoksa bir teselli mi olduğunu düşün.',
      'Para konularındaki belirsizlik seni yorabilir; tek bir hesabı netleştirmek bile içini rahatlatır.',
    ],
    energy: [
      'Gürültülü ya da gergin bir yerden çıkınca hemen yeni bir işe geçmek seni daha da dağıtabilir. Sessiz bir köşede kısa bir ara, yer aramadan da seni toplar.',
      'Uyku senin için önemli bir yenilenme kaynağı; bugün yeterince dinlenmeye özen göster.',
    ],
    emotion: [
      'Duyguların bugün dalga dalga gelebilir. Hangisinin sana, hangisinin çevrene ait olduğunu ayırt etmek seni rahatlatır.',
      'Kırıldığında içine kapanıp hayallere çekilme isteğin artabilir. Güvendiğin birine bunu anlatmak seni daha çabuk toparlar.',
    ],
    advice: [
      'Bugün bir "hayır"ı suçluluk duymadan söyle.',
      'Hayal ettiğin bir şeyi gerçeğe dönüştürecek en küçük adımı yaz.',
      'Kendini yorgun hissettiğinde sessiz bir köşede on dakika dinlen.',
    ],
    opportunity: [
      'Yazıyla, müzikle ya da bir çizimle ilgili ertelediğin bir deneme varsa, bugün yarım saatlik bir taslak yeter. Bitmiş bir eser bekleme.',
      'Birine gerçekten yardım edebileceğin bir an çıkabilir; bu da sana derin bir anlam duygusu verebilir.',
    ],
    caution: [
      'Başkalarının sorunlarını kendi sorunun gibi üstlenmek seni tüketebilir.',
      'Açmadığın bir fatura, bir mesaj ya da bir tarih bugün de duruyorsa, akşama bir satır daha büyür. Açıp yalnızca ne olduğunu yazmak, onu hemen çözmek zorunda olduğun anlamına gelmez.',
      'Yorgunken verdiğin yumuşak bir "hallederim", yarın aynı sıcaklıkla hatırlanmayabilir. O an evet diyeceksen, neyi ve ne zamana kadar üstlendiğini bir kelimeyle bağla.',
    ],
  ),
};
