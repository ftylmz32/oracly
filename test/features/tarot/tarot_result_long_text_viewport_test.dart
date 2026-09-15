/// UI hardening — tarot result rendering with realistic long AI text.
///
/// Guards against: text clipping, duplicate section headers, unreachable
/// footer CTAs, and RenderFlex overflow across common device viewports and
/// larger text-scale settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_footer_actions.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_scroll.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longLove = '''
Bu açılımda kalp meselesi, geçmişten taşınan bir sessizlikle başlıyor. '''
    'Kartın enerjisi, karşındaki kişiyle aranızdaki iletişimin son haftalarda '
    'nasıl yüzeyselleştiğini işaret ediyor. Bu bir bitişten çok, iki tarafın '
    'da birbirini yeniden tanımaya ihtiyaç duyduğu bir eşik anı. Duygularını '
    'ertelemek yerine, bugün küçük ve dürüst bir cümleyle başlamak, '
    'ilişkinin gidişatını yumuşatacak. Kendine karşı da aynı nezareti göster; '
    'bir başkasının onayını beklemeden iç sesini duyabilirsin. '
    'Bu dönemde yalnızlık hissi artabilir, ama bu senin eksikliğin değil, '
    'sadece bir geçiş evresinin doğal ağırlığı. Sabırla ilerlediğinde, '
    'kalbindeki bu ağırlık yerini daha berrak bir bağa bırakacak.';

const _longCareer = '''
Kariyer alanında kart, uzun süredir ertelediğin bir kararın artık '''
    'olgunlaştığını gösteriyor. Şu anki pozisyonun sana güvenli geliyor '
    'olabilir, fakat içindeki huzursuzluk aslında büyümek istediğinin bir '
    'işareti. Yeni bir sorumluluk almak ya da bambaşka bir yöne adım atmak '
    'seni ürkütse de, bu ürkeklik başarısızlık korkusundan değil, bilinmeyene '
    'duyulan doğal bir tedirginlikten geliyor. Önümüzdeki haftalarda '
    'karşına çıkacak bir teklif ya da fırsat, ilk bakışta küçük görünse de '
    'uzun vadede seni bambaşka bir kapıya taşıyabilir. Bu fırsatı '
    'değerlendirirken aceleci davranma, ama gereğinden fazla da bekletme.';

const _longMoney = '''
Maddi konularda kart, dengeyi yeniden kurma zamanının geldiğini '''
    'söylüyor. Son dönemde harcamalarında ya da gelir beklentilerinde bir '
    'tutarsızlık hissetmiş olabilirsin. Bu tutarsızlık, aslında önceliklerini '
    'yeniden gözden geçirmen için sana verilen sakin bir uyarı. Kısa vadeli '
    'bir çözüm yerine, üç ay sonrasını düşünen bir plan senin lehine işleyecek.';

const _longSpiritual = '''
Ruhsal düzlemde bu kart, içsel bir arınmanın eşiğinde olduğunu '''
    'gösteriyor. Geçmişte taşıdığın bazı inançlar artık sana hizmet etmiyor '
    've bunları bırakmak seni zayıflatmayacak, tam tersine daha da '
    'güçlendirecek. Meditasyon, günlük tutma ya da sessizce yürüyüş yapmak '
    'gibi basit ritüeller, bu dönemde sana beklediğinden çok daha fazla '
    'netlik getirecek. Kendine sorman gereken soru şu: hangi inancı hâlâ '
    'taşıyorum ama artık ona ihtiyacım yok?';

const _longNarrative = '''
Kartların bir araya gelişi, hayatının şu an tam bir dönüm noktasında '''
    'olduğunu anlatıyor. Geçmiş, şimdi ve gelecek pozisyonlarındaki kartlar '
    'birbirine kenetlenerek tek bir hikâye örüyor: bırakma, yeniden inşa etme '
    've güvenle ilerleme. Bu üçlü, senin hayatındaki döngüsel bir örüntüyü '
    'yansıtıyor — her seferinde aynı korkuyla yüzleşip, her seferinde biraz '
    'daha cesur çıkıyorsun bu yüzleşmeden.\n\n'
    'İkinci paragraf olarak, bu hikâyenin senin için taşıdığı anlam şudur: '
    'artık eski örüntüye geri dönmek yerine, öğrendiklerini yeni bir '
    'başlangıca taşıma zamanı geldi. Bu açılım seni suçlamıyor, sadece '
    'nazikçe hatırlatıyor.';

const _longClosing = '''
Bu okumanın sana bıraktığı yön açık: net bir adım, gösterişli bir '''
    'karardan daha değerli. Bugün atacağın en küçük dürüst hareket, '
    'yarının büyük değişikliklerinin temelini oluşturacak. Kendine zaman '
    'tanı, ama kendini de unutma.';

AiReadingContent _longContent() {
  final drawn = [
    TarotDrawnCard(
      card: CardRevealSpread.forIndex(0).card,
      positionIndex: 0,
      isReversed: false,
      positionLabel: 'Geçmiş',
    ),
    TarotDrawnCard(
      card: CardRevealSpread.forIndex(1).card,
      positionIndex: 1,
      isReversed: true,
      positionLabel: 'Şimdi',
    ),
    TarotDrawnCard(
      card: CardRevealSpread.forIndex(2).card,
      positionIndex: 2,
      isReversed: false,
      positionLabel: 'Gelecek',
    ),
  ];
  return AiReadingContent(
    cardName: 'Üç Kart Açılımı',
    tagline: 'Aşk ve İş Hayatı',
    generalMeaning: _longNarrative,
    love: _longLove,
    career: _longCareer,
    money: _longMoney,
    spiritualGuidance: _longSpiritual,
    luckyEnergy: _longNarrative,
    dailyAdvice: _longClosing,
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: drawn,
    spreadLabel: 'Üç Kart',
    closingMessage: _longClosing,
    cardReadings: '$_longLove\n\n$_longCareer',
    userQuestion:
        'İş hayatımda büyük bir karar vermem gerekiyor, doğru zamanlama bu mu?',
    readingTheme: 'career',
  );
}

Widget _resultTree(AiReadingContent content) {
  return ReadingPremiumScrollView(
    padding: const EdgeInsets.only(bottom: 24),
    child: Align(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadingPremiumBody(
            content: content,
            sectionMaster: 1,
            panelOpacity: 1,
            ambientPhase: 0,
          ),
          ReadingFooterActions(
            progress: 1,
            onNewReading: () {},
            onAskOracle: () {},
          ),
        ],
      ),
    ),
  );
}

Future<LocalStorage> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
  ];

  for (final size in viewports) {
    testWidgets(
      'tarot result renders long AI text without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final storage = await _storage();
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localStorageProvider.overrideWithValue(storage)],
            child: MaterialApp(
              home: Scaffold(body: SafeArea(child: _resultTree(_longContent()))),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        // Full body text is present (no silent clipping to a preview).
        expect(find.textContaining('en küçük dürüst hareket'), findsWidgets);

        // Footer CTA reachable via scroll, not pushed off permanently.
        await tester.dragUntilVisible(
          find.byType(ReadingFooterActions),
          find.byType(Scrollable).first,
          const Offset(0, -300),
        );
        expect(find.byType(ReadingFooterActions), findsOneWidget);
      },
    );
  }

  testWidgets(
    'tarot result stays usable at 1.3x text scale (footer CTA reachable)',
    (tester) async {
      final storage = await _storage();
      const size = Size(360, 800);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: SafeArea(child: _resultTree(_longContent())),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      await tester.dragUntilVisible(
        find.byType(ReadingFooterActions),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      expect(find.byType(ReadingFooterActions), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tarot result does not duplicate section titles from long-text wrapping',
    (tester) async {
      final storage = await _storage();
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final content = _longContent();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Scaffold(body: SafeArea(child: _resultTree(content))),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Each section label appears exactly once even though bodies wrap
      // across many lines.
      for (final label in const [
        "ORACLY'nin Yorumu",
        'Duygular',
        'Kariyer',
      ]) {
        final matches = find.text(label);
        if (matches.evaluate().isEmpty) continue;
        expect(
          matches.evaluate().length,
          lessThanOrEqualTo(1),
          reason: '"$label" should not repeat from a wrapping bug',
        );
      }
    },
  );
}
