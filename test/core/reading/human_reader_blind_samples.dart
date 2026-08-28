/// Fifty blind prose samples — feature labels stripped at review time.
library;

import 'package:oracly_new/core/reading/human_reader_blind_review.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_composer.dart';
import 'package:oracly_new/features/dream/services/dream_reading_presentation.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reading_presentation.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';

import '../../coffee_fortune_engine_cups.dart';
import '../../palm_fortune_engine_hands.dart';

PersonalDiscoveryProfile _profile() {
  CrossDiscoveryInsight hit(String theme) => CrossDiscoveryInsight(
        theme: theme,
        sources: const ['tarot', 'coffee'],
        confidence: DiscoveryThemeStrength.recurring,
        lastObserved: DateTime(2026, 8, 17),
        sourceCount: 2,
        discoveryCount: 2,
        recencyWeight: 1,
      );
  return PersonalDiscoveryProfile(
    crossInsights: [hit('ilişki'), hit('kariyer'), hit('sınırlar')],
  );
}

BlindSample _coffee(CoffeeFortuneEngineCup cup) {
  final reading = CoffeeFortuneComposer.compose(
    CoffeeReading(
      id: cup.id,
      createdAt: DateTime(2026, 8, 17),
      overall: cup.overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      visualObservation: cup.observation,
      symbols: [
        for (final n in cup.symbols) CoffeeSymbol(name: n, meaning: '', interpretation: ''),
      ],
    ),
    themes: cup.themes,
  );
  return BlindSample(
    feature: BlindFeature.coffee,
    text: reading.overall,
    anchors: cup.symbols,
  );
}

BlindSample _palm(PalmEngineHand hand) {
  final reading = PalmFortuneComposer.compose(hand.toReading());
  return BlindSample(
    feature: BlindFeature.palm,
    text: reading.overall,
    anchors: [...hand.symbols, ...hand.mustContain],
  );
}

BlindSample _dream(String narrative, {List<DreamEmotion> emotions = const []}) {
  final understanding = DreamUnderstandingService().build(
    narrative: narrative,
    selectedEmotions: emotions,
  );
  final dream = Dream(
    id: narrative.hashCode.toString(),
    narrative: narrative,
    recordedAt: DateTime(2026, 8, 18),
    selectedEmotions: emotions,
    understanding: understanding,
  );
  final text = DreamReadingPresentation.interpretation(
    dream.copyWith(
      insights: DreamAnalysisComposer.compose(
        dream: dream,
        understanding: understanding,
      ),
    ),
  );
  final anchors = understanding.symbols.map((s) => s.label).toList();
  return BlindSample(feature: BlindFeature.dream, text: text, anchors: anchors);
}

Future<BlindSample> _tarot(int seed) async {
  final session = ReadingSession(
    id: 'blind_$seed',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: const TarotIntention(text: 'Bugün neye dikkat etmeliyim'),
    shuffleSeed: seed,
    startedAt: DateTime(2026, 8, 17),
    drawnCards: [
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(seed % 22).card,
        positionIndex: 0,
        isReversed: seed.isOdd,
        positionLabel: 'Geçmiş',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex((seed + 7) % 22).card,
        positionIndex: 1,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex((seed + 13) % 22).card,
        positionIndex: 2,
        isReversed: seed.isEven,
        positionLabel: 'Olası yön',
      ),
    ],
  );
  final content = await TarotInterpretationService().generateContent(session);
  final text = [
    content.generalMeaning,
    content.cardReadings,
    content.dailyAdvice,
  ].join('\n\n');
  return BlindSample(
    feature: BlindFeature.tarot,
    text: text,
    anchors: [
      for (final card in session.drawnCards) card.localizedName,
    ],
  );
}

BlindSample _astro(String signId, DateTime day, {PersonalDiscoveryProfile? profile}) {
  final sign = AstrologyContentCatalogue.signById(signId)!;
  final reading = AstrologyDailyReadingService.build(sign, now: day, profile: profile);
  return BlindSample(
    feature: BlindFeature.astrology,
    text: reading.overall,
    anchors: [sign.nameTr],
  );
}

BlindSample _starMap(ZodiacSignId sign, DateTime day, {PersonalDiscoveryProfile? profile}) {
  final reading = StarMapReadingService.build(now: day, sunSign: sign, discovery: profile);
  final text = [
    StarMapReadingPresentation.sunBody(reading),
    StarMapReadingPresentation.todayBody(reading),
    StarMapReadingPresentation.innerBody(reading),
  ].join('\n\n');
  return BlindSample(
    feature: BlindFeature.starMap,
    text: text,
    anchors: [sign.labelTr],
  );
}

BlindSample _soulMate(SoulMateDrawRequest request) {
  return BlindSample(
    feature: BlindFeature.soulMate,
    text: SoulMateInterpretation.forRequest(request),
    anchors: [request.name.trim()],
  );
}

BlindSample _or(String prompt, {List<String> anchors = const []}) {
  const responder = CompanionResponder();
  final reply = responder.respond(
    request: InsightRequest(text: prompt),
    context: const ReflectionContext(),
  );
  return BlindSample(
    feature: BlindFeature.orCompanion,
    text: reply.body,
    anchors: anchors,
  );
}

Future<List<BlindSample>> fiftyBlindSamples() async {
  final profile = _profile();
  final tarot = await Future.wait([7, 19, 31, 42, 55, 68].map(_tarot));
  return [
    ...coffeeFortuneEngineCups.take(7).map(_coffee),
    ...palmFortuneEngineHands.take(6).map(_palm),
    _dream('Yılan vardı.'),
    _dream('Kapı açık duruyordu.'),
    _dream(
      'Gece yarısı eski evin koridorundaydım. Uzun bir yılan eşiğin altından geçti.',
      emotions: [DreamEmotion(id: DreamEmotionId.anxious)],
    ),
    _dream('Kedimle denizin kenarında yürüdüm.'),
    _dream('Bir şey vardı ama ne olduğu belirsizdi.'),
    _dream('   '),
    ...tarot,
    _astro('aries', DateTime(2026, 8, 17), profile: profile),
    _astro('gemini', DateTime(2026, 8, 18), profile: profile),
    _astro('scorpio', DateTime(2026, 8, 19)),
    _astro('taurus', DateTime(2026, 8, 20)),
    _astro('leo', DateTime(2026, 8, 21), profile: profile),
    _astro('aquarius', DateTime(2026, 8, 22)),
    _starMap(ZodiacSignId.aries, DateTime(2026, 8, 17), profile: profile),
    _starMap(ZodiacSignId.gemini, DateTime(2026, 8, 18), profile: profile),
    _starMap(ZodiacSignId.scorpio, DateTime(2026, 8, 19)),
    _starMap(ZodiacSignId.leo, DateTime(2026, 8, 20), profile: profile),
    _starMap(ZodiacSignId.capricorn, DateTime(2026, 8, 21)),
    _starMap(ZodiacSignId.pisces, DateTime(2026, 8, 22)),
    _soulMate(SoulMateDrawRequest(name: 'Ayşe', birthDate: DateTime(1994, 3, 12), gender: SoulMateGenderPref.feminine, intention: 'sakin bir bağ')),
    _soulMate(SoulMateDrawRequest(name: 'Deniz', birthDate: DateTime(1995, 8, 15))),
    _soulMate(SoulMateDrawRequest(name: 'Selin', birthDate: DateTime(1990, 11, 2), gender: SoulMateGenderPref.feminine)),
    _soulMate(SoulMateDrawRequest(name: 'Ali', birthDate: DateTime(1988, 1, 20), gender: SoulMateGenderPref.masculine, intention: 'dürüst iletişim')),
    _soulMate(SoulMateDrawRequest(name: 'Mira', birthDate: DateTime(1997, 6, 30))),
    _soulMate(SoulMateDrawRequest(name: 'Can', birthDate: DateTime(1992, 9, 9), intention: 'yavaş güven')),
    _or('Selam.', anchors: const []),
    _or('Bugün kafam karışık.', anchors: const ['karış']),
    _or('İş konusunda endişeliyim.', anchors: const ['iş']),
    _or('Rüyamda kapı vardı.', anchors: const ['kapı', 'rüya']),
    _or('Tarot kartları ne anlama gelir?', anchors: const ['kart']),
    _or('Kendimi yavaşlatmak istiyorum.', anchors: const ['yavaş']),
    _or('Teşekkürler, bu yeterli.', anchors: const []),
  ];
}
