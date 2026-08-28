/// Shared fixtures for Personal Discovery Engine tests.
library;

import 'package:oracly_new/core/domain/models/astrology_record.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/astrology/models/astrology_daily_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';

ReadingModel pdeTarot(String id, String summary, {DateTime? at}) =>
    ReadingModel(
      id: id,
      cardId: 0,
      cardName: 'The Moon',
      cardImageAsset: 'a',
      spreadType: 'Tek Kart',
      aiSummary: summary,
      createdAt: at ?? DateTime(2026, 8, 10),
    );

CoffeeReading pdeCoffee(String id, String overall, {DateTime? at}) =>
    CoffeeReading(
      id: id,
      createdAt: at ?? DateTime(2026, 8, 11),
      overall: overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      imagePath: '/tmp/secret-cup.jpg',
    );

DreamRecord pdeDream(String id, String text, {DateTime? at}) => DreamRecord(
      id: id,
      text: text,
      analysis: '',
      createdAt: at ?? DateTime(2026, 8, 12),
    );

ConversationRecord pdeOr(String id, String text, {DateTime? at}) {
  final stamp = at ?? DateTime(2026, 8, 12);
  return ConversationRecord(
    id: id,
    title: 'OR',
    kind: 'companion',
    messagesJson: [
      {'text': text},
    ],
    createdAt: stamp,
    updatedAt: stamp,
  );
}

PalmReading pdePalm(String id, String overall, {DateTime? at}) => PalmReading(
      id: id,
      createdAt: at ?? DateTime(2026, 8, 11),
      hand: PalmHand.right,
      overall: overall,
    );

AstrologyRecord pdeSky(String id, String horoscope, {DateTime? at}) =>
    AstrologyRecord(
      id: id,
      sign: 'Koç',
      horoscope: horoscope,
      date: at ?? DateTime(2026, 8, 10),
    );

const pdeAstroBase = AstrologyDailyReading(
  personality: 'Sakin.',
  overall: 'Sakin bir gün.',
  love: 'Yakınlık yumuşak.',
  career: 'İşte ölçülü adım.',
  money: 'Tempo sakin.',
  advice: 'Nefes al.',
  energy: 'Dengeli.',
  emotion: 'Yumuşak.',
  opportunity: 'Bir adım.',
  caution: 'Acele etme.',
  innerTheme: '',
);
