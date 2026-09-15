/// UI hardening — dream result rendering with realistic long AI text.
///
/// Builds a Dream with hand-written multi-paragraph sections (bypassing the
/// AI grounding guard, which is engine logic out of scope here) so the
/// widget renders realistic long content, then checks common device
/// viewports and larger text-scale settings for clipping, duplicate
/// headers, and an unreachable footer CTA.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_result_view.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dream_honesty_fakes.dart' show MemDreamRepository;

const _longSummary = '''
Rüyanda beliren koridor, bilinçaltının seni yüzleşmeye hazır olmadığın '''
    'bir konuya doğru yönlendirdiğinin işareti. Duvarların nefes alması, '
    'içinde taşıdığın gerilimin artık görmezden gelinemeyecek kadar '
    'canlandığını gösteriyor. Bahçeye ulaştığında karşılaştığın tuhaf gökyüzü '
    'ise, tanıdık bir yerin bile artık eskisi gibi güvenli hissettirmediğine '
    'işaret ediyor — bu, büyümenin ve değişimin doğal bir yan etkisi.';

const _longEmotional = '''
Bu sahnede baskın duygu belirsizlik: hem tanıdık hem yabancı bir yerde '''
    'olmanın verdiği gerilim. Annenin sesini duyup onu görememen, ihtiyaç '
    'duyduğun güvenceyi şu an tam olarak bulamadığını, ama onun hâlâ '
    'çevrende, ulaşılabilir bir yerde olduğunu hissettiğini gösteriyor. '
    'Bu duygu seni ürkütmemeli; tam tersine, içindeki çocuğun hâlâ '
    'sesini duyurabildiğinin bir kanıtı.';

const _longInterpretation = '''
Bu rüyanın anlattığı hikaye, geçmiş ile şimdiki zaman arasında kurulan '''
    'köprüde geziniyor. Koridor, iki hâl arasındaki geçişi simgeliyor: eski '
    'güvenli alanından çıkıp, hâlâ tam olarak tanımlayamadığın yeni bir '
    'alana doğru ilerliyorsun. Mor ve turuncu gökyüzü, bu geçişin ne '
    'tamamen karanlık ne de tamamen aydınlık olduğunu, ikisinin bir arada '
    'var olabileceğini hatırlatıyor.\n\n'
    'İkinci olarak, bu rüya sana kontrolü tamamen bırakmadan da '
    'değişime izin verebileceğini gösteriyor. Anlamadığın bir şeyin '
    'ortasında olmak seni tanımlamıyor; sadece o anki deneyimin bir '
    'parçası.';

const _longLifeReflection = '''
Bugün küçük bir adım at: eskiden güvenli hissettiren ama artık seni '''
    'sıkan bir alışkanlığı fark et ve ona nazikçe veda etmeyi dene. '
    'Kendine zaman tanı, cevapları hemen bulman gerekmiyor.';

const _longClosing =
    'Bu rüya bir uyarı değil, bir davet: bilinmeyene karşı biraz daha '
    'sabırlı olman için nazik bir hatırlatma.';

Dream _longDream() {
  return Dream(
    id: 'd-long-1',
    narrative:
        'Uzun, karanlık bir koridorda yürüyordum; duvarlar nefes '
        'alıyormuş gibi yavaşça daralıp genişliyordu. Sonunda bir kapıya '
        'vardım ve açtığımda çocukluk evimin bahçesindeydim, ama gökyüzü '
        'mor ve turuncuydu. Annemin sesini duydum ama onu göremedim.',
    recordedAt: DateTime(2026, 8, 30, 23, 15),
    fromAi: true,
    understanding: const DreamUnderstanding(
      symbols: [
        DreamSymbol(
          token: 'corridor',
          label: 'Koridor',
          kind: DreamSymbolKind.object,
          observedContext: 'Geçiş ve dönüşüm anlamına gelir.',
        ),
        DreamSymbol(
          token: 'garden',
          label: 'Bahçe',
          kind: DreamSymbolKind.nature,
          observedContext: 'Tanıdık ama değişmiş bir güvenli alan.',
        ),
        DreamSymbol(
          token: 'sky',
          label: 'Gökyüzü',
          kind: DreamSymbolKind.nature,
          observedContext: 'Belirsizlik içinde barınan umut.',
        ),
      ],
      emotions: ['Belirsizlik', 'Özlem', 'Merak'],
      locations: ['Koridor', 'Bahçe'],
      relationships: [],
      recurringElements: [],
      summary: _longSummary,
    ),
    insights: [
      DreamInsight(
        kind: DreamInsightKind.summary,
        title: DreamCopy.summaryTitle,
        body: _longSummary,
      ),
      DreamInsight(
        kind: DreamInsightKind.emotionalMeaning,
        title: DreamCopy.emotionalMeaningTitle,
        body: _longEmotional,
      ),
      DreamInsight(
        kind: DreamInsightKind.mainInterpretation,
        title: DreamCopy.interpretationTitle,
        body: _longInterpretation,
      ),
      DreamInsight(
        kind: DreamInsightKind.personalConnection,
        title: DreamCopy.lifeReflectionTitle,
        body: _longLifeReflection,
      ),
      DreamInsight(
        kind: DreamInsightKind.closingTakeaway,
        title: DreamCopy.optionalQuestionTitle,
        body: _longClosing,
      ),
    ],
  );
}

/// Exposes a fixed [Dream] without driving the real AI/guard pipeline —
/// this test is about rendering, not the interpretation engine.
class _FixedDreamController extends DreamAnalysisController {
  _FixedDreamController(this._fixed)
      : super(
          DreamExperienceService(
            repository: MemDreamRepository(),
            ai: const UnconfiguredOraclyAiService(allowsLocalFallback: true),
          ),
        );

  final Dream _fixed;

  @override
  Dream? get dream => _fixed;

  @override
  DreamJourneyPhase get phase => DreamJourneyPhase.complete;
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
      'dream result renders long AI text without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final storage = await _storage();
        final controller = _FixedDreamController(_longDream());
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localStorageProvider.overrideWithValue(storage)],
            child: MaterialApp(
              home: Scaffold(
                body: DreamReferenceResultView(
                  controller: controller,
                  onNewDream: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);

        // Full interpretation text is present, not silently clipped.
        expect(
          find.textContaining('İkinci olarak, bu rüya sana kontrolü'),
          findsWidgets,
        );

        // Footer CTA reachable via scroll, not permanently pushed off.
        await tester.dragUntilVisible(
          find.textContaining('bilinmeyene karşı biraz daha'),
          find.byType(Scrollable).first,
          const Offset(0, -400),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'dream result stays usable at 1.3x text scale',
    (tester) async {
      final storage = await _storage();
      final controller = _FixedDreamController(_longDream());
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
                  body: DreamReferenceResultView(
                    controller: controller,
                    onNewDream: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
    },
  );
}
