/// Ninety real generation samples — 10×7 features + 20 OR.
library;

import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
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

export 'human_reader_blind_samples.dart' show fiftyBlindSamples;

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

String _polish(String text, AiOutputQualityKind kind) =>
    AiOutputQualityGate.polish(text, kind: kind);

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
        for (final n in cup.symbols)
          CoffeeSymbol(name: n, meaning: '', interpretation: ''),
      ],
    ),
    themes: cup.themes,
  );
  return BlindSample(
    feature: BlindFeature.coffee,
    text: _polish(reading.overall, AiOutputQualityKind.coffee),
    anchors: cup.symbols,
  );
}

BlindSample _palm(PalmEngineHand hand) {
  final reading = PalmFortuneComposer.compose(hand.toReading());
  return BlindSample(
    feature: BlindFeature.palm,
    text: _polish(reading.overall, AiOutputQualityKind.palm),
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
  return BlindSample(
    feature: BlindFeature.dream,
    text: _polish(text, AiOutputQualityKind.dream),
    anchors: understanding.symbols.map((s) => s.label).toList(),
  );
}

Future<BlindSample> _tarot(int seed) async {
  final session = ReadingSession(
    id: 'n90_$seed',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: const TarotIntention(text: 'Bugün neye dikkat etmeliyim'),
    shuffleSeed: seed,
    startedAt: DateTime(2026, 8, 17),
    drawnCards: [
      for (var i = 0; i < 3; i++)
        TarotDrawnCard(
          card: CardRevealSpread.forIndex((seed + i * 7) % 22).card,
          positionIndex: i,
          isReversed: i == 0 && seed.isOdd,
          positionLabel: const ['Geçmiş', 'Şimdi', 'Olası yön'][i],
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
    text: _polish(text, AiOutputQualityKind.tarot),
    anchors: [for (final c in session.drawnCards) c.localizedName],
  );
}

BlindSample _astro(String signId, DateTime day, {PersonalDiscoveryProfile? p}) {
  final sign = AstrologyContentCatalogue.signById(signId)!;
  final reading =
      AstrologyDailyReadingService.build(sign, now: day, profile: p);
  return BlindSample(
    feature: BlindFeature.astrology,
    text: _polish(reading.overall, AiOutputQualityKind.astrology),
    anchors: [sign.nameTr],
  );
}

BlindSample _star(ZodiacSignId sign, DateTime day, {PersonalDiscoveryProfile? p}) {
  final reading =
      StarMapReadingService.build(now: day, sunSign: sign, discovery: p);
  final text = [
    StarMapReadingPresentation.sunBody(reading),
    StarMapReadingPresentation.todayBody(reading),
    StarMapReadingPresentation.innerBody(reading),
  ].join('\n\n');
  return BlindSample(
    feature: BlindFeature.starMap,
    text: _polish(text, AiOutputQualityKind.starMap),
    anchors: [sign.labelTr],
  );
}

BlindSample _soul(SoulMateDrawRequest request) {
  return BlindSample(
    feature: BlindFeature.soulMate,
    text: _polish(
      SoulMateInterpretation.forRequest(request),
      AiOutputQualityKind.soulMate,
    ),
    anchors: [request.name.trim()],
  );
}

BlindSample _or(String prompt, {List<String> anchors = const []}) {
  final reply = const CompanionResponder().respond(
    request: InsightRequest(text: prompt),
    context: const ReflectionContext(),
  );
  return BlindSample(
    feature: BlindFeature.orCompanion,
    text: _polish(reply.body, AiOutputQualityKind.companion),
    anchors: anchors,
  );
}

Future<List<BlindSample>> ninetyBlindSamples() async {
  final p = _profile();
  final day = DateTime(2026, 8, 10);
  final tarot = await Future.wait(
    [3, 7, 11, 17, 23, 29, 37, 41, 47, 53].map(_tarot),
  );
  final signs = AstrologyContentCatalogue.signs.take(10).toList();
  final zSigns = ZodiacSignId.values.take(10).toList();
  return [
    ...coffeeFortuneEngineCups.take(10).map(_coffee),
    ...palmFortuneEngineHands.take(10).map(_palm),
    _dream('Yılan eşiğin altından geçti.'),
    _dream('Kapı açık duruyordu, içeri girmek istemedim.'),
    _dream(
      'Gece yarısı eski evin koridorundaydım. Uzun bir yılan eşiğin altından geçti.',
      emotions: [DreamEmotion(id: DreamEmotionId.anxious)],
    ),
    _dream('Kedimle denizin kenarında yürüdüm.'),
    _dream('Bir tren kaçırdım, peron boştu.'),
    _dream('Aynada kendimi daha yaşlı gördüm.'),
    _dream('Köprüde durdum, rüzgâr sertti.'),
    _dream('Küçük bir anahtar buldum, kapıya uymadı.'),
    _dream('Okul bahçesinde kayboldum.'),
    _dream('Yağmur altında bir mektup okudum.'),
    ...tarot,
    for (var i = 0; i < 10; i++)
      _astro(signs[i].id, day.add(Duration(days: i)), p: i.isEven ? p : null),
    for (var i = 0; i < 10; i++)
      _star(zSigns[i], day.add(Duration(days: i + 3)), p: i.isOdd ? p : null),
    _soul(SoulMateDrawRequest(name: 'Ayşe', birthDate: DateTime(1994, 3, 12), gender: SoulMateGenderPref.feminine, intention: 'sakin bir bağ')),
    _soul(SoulMateDrawRequest(name: 'Deniz', birthDate: DateTime(1995, 8, 15))),
    _soul(SoulMateDrawRequest(name: 'Selin', birthDate: DateTime(1990, 11, 2), gender: SoulMateGenderPref.feminine)),
    _soul(SoulMateDrawRequest(name: 'Ali', birthDate: DateTime(1988, 1, 20), gender: SoulMateGenderPref.masculine, intention: 'dürüst iletişim')),
    _soul(SoulMateDrawRequest(name: 'Mira', birthDate: DateTime(1997, 6, 30))),
    _soul(SoulMateDrawRequest(name: 'Can', birthDate: DateTime(1992, 9, 9), intention: 'yavaş güven')),
    _soul(SoulMateDrawRequest(name: 'Elif', birthDate: DateTime(1993, 4, 4), gender: SoulMateGenderPref.feminine)),
    _soul(SoulMateDrawRequest(name: 'Kerem', birthDate: DateTime(1991, 12, 1), gender: SoulMateGenderPref.masculine, intention: 'ortak ritim')),
    _soul(SoulMateDrawRequest(name: 'Zeynep', birthDate: DateTime(1996, 2, 14))),
    _soul(SoulMateDrawRequest(name: 'Emre', birthDate: DateTime(1989, 7, 21), intention: 'sakin ev')),
    _or('Bugün kafam karışık.', anchors: const ['karış']),
    _or('İş konusunda endişeliyim.', anchors: const ['iş']),
    _or('Rüyamda kapı vardı.', anchors: const ['kapı', 'rüya']),
    _or('Tarot kartları ne anlama gelir?', anchors: const ['kart']),
    _or('Kendimi yavaşlatmak istiyorum.', anchors: const ['yavaş']),
    _or('İlişkimde mesafeyi hissediyorum.', anchors: const ['mesafe', 'ilişki']),
    _or('Karar vermekte zorlanıyorum.', anchors: const ['karar']),
    _or('Bugün içimde bir sıkışma var.', anchors: const ['sıkış']),
    _or('Ne yapacağımı bilmiyorum.', anchors: const []),
    _or('Biraz yalnız kaldım.', anchors: const ['yalnız']),
    _or('İş değiştirmeyi düşünüyorum.', anchors: const ['iş']),
    _or('Eski bir konuşma aklıma geliyor.', anchors: const ['konuş']),
    _or('Sabahları ağır uyanıyorum.', anchors: const ['sabah']),
    _or('Bu okuma bana ne söylüyor?', anchors: const ['okuma']),
    _or('Korkumun adı ne?', anchors: const ['korku']),
    _or('Bir adım atmak istiyorum ama duruyorum.', anchors: const ['adım']),
    _or('Teşekkürler, bu yeterli.', anchors: const []),
    _or('Kendime nazik olmak zor geliyor.', anchors: const ['nazik']),
    _or('Bugün neye dikkat edeyim?', anchors: const ['dikkat']),
    _or('İçimde iki ses var.', anchors: const ['ses']),
  ];
}
