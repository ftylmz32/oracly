/// Phase 1 — profile is derived, never invented.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/core/domain/models/astrology_record.dart';
import 'package:oracly_new/core/domain/models/birth_chart_record.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/daily_message/models/daily_message.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  test('empty sources stay empty — no fake birth or zodiac', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
    );
    expect(profile.birthDate, isNull);
    expect(profile.zodiacSign, isNull);
    expect(profile.tarotThemes, isEmpty);
    expect(profile.soulmateGenerations, 0);
    expect(profile.hasHistory, isFalse);
  });

  test('birth date yields tropical sun only when a real profile exists', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        birth: BirthProfile(
          birthDate: DateTime(1995, 8, 15),
          birthPlace: 'İzmir',
        ),
      ),
    );
    expect(profile.birthDate, DateTime(1995, 8, 15));
    expect(profile.birthPlace, 'İzmir');
    expect(profile.zodiacSign, ZodiacSignId.leo);
  });

  test('blank birth place is stored as null', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        birth: BirthProfile(
          birthDate: DateTime(2019, 5, 26),
          birthPlace: '  ',
        ),
      ),
    );
    expect(profile.birthPlace, isNull);
    expect(profile.zodiacSign, ZodiacSignId.gemini);
  });

  test('counts and lastUpdated come only from real records', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        settings: const PersonalizationSettings(
          aiPersonality: AiPersonality.gentle,
        ),
        readings: [
          ReadingModel(
            id: 'r1',
            cardId: 0,
            cardName: 'The Moon',
            cardImageAsset: 'a',
            spreadType: 'Tek Kart',
            aiSummary: 'Sakin.',
            createdAt: DateTime(2026, 8, 10),
          ),
        ],
        dreams: [
          DreamRecord(
            id: 'd1',
            text: 'Deniz',
            analysis: '',
            createdAt: DateTime(2026, 8, 12),
          ),
        ],
        coffee: [
          CoffeeReading(
            id: 'c1',
            createdAt: DateTime(2026, 8, 11),
            overall: 'Durulmak.',
            love: '',
            career: '',
            money: '',
            nearFuture: '',
            takeaway: '',
          ),
        ],
        conversations: [
          ConversationRecord(
            id: 'or1',
            title: 'OR',
            kind: 'general',
            messagesJson: [
              {'role': 'user', 'text': 'merhaba'},
            ],
            createdAt: DateTime(2026, 8, 9),
            updatedAt: DateTime(2026, 8, 13, 18),
          ),
          ConversationRecord(
            id: 'empty',
            title: 'OR',
            kind: 'general',
            messagesJson: const [],
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
        ],
        astrology: [
          AstrologyRecord(
            id: 'a1',
            sign: 'Yengeç',
            horoscope: 'Değişim sakin bir adımla büyüyor.',
            date: DateTime(2026, 8, 14),
          ),
        ],
        dailyMessages: [
          DailyMessage(
            text: 'Değişim bugün sessiz bir çizgi gibi ilerliyor.',
            day: DateTime(2026, 8, 15),
            theme: 'değişim',
          ),
        ],
        starChart: BirthChartRecord(
          id: 'b1',
          createdAt: DateTime(2026, 8, 8),
          updatedAt: DateTime(2026, 8, 16),
          payload: const {
            'id': 'b1',
            'profile': {
              'birthDate': '1995-08-15T00:00:00.000',
              'birthPlace': 'İzmir',
            },
            'sun': {
              'id': 'sun',
              'name': 'Güneş',
              'sign': 'cancer',
              'degree': 1.0,
            },
            'planets': [],
            'houses': [],
            'aspects': [],
            'elementBalance': {
              'fire': 1,
              'earth': 1,
              'air': 1,
              'water': 2,
            },
            'dominantEnergy': {
              'label': 'İçe dönüş',
              'body': 'İçe dönüş ve değişim birlikte akıyor.',
            },
            'lifeThemes': [
              {
                'id': 'lt1',
                'title': 'Değişim',
                'body': 'Değişim seni yumuşak bir yön değiştirmeye çağırıyor.',
              },
            ],
            'insights': [
              {
                'kind': 'lifeThemes',
                'title': 'Yön değiştirme',
                'body': 'Yön değiştirme teması görünür.',
              },
            ],
            'generatedAt': '2026-08-08T00:00:00.000',
            'precision': 'partialNoTime',
            'fidelity': 'tropicalSunSign',
          },
        ),
      ),
    );
    expect(profile.preferredOrStyle, AiPersonality.gentle);
    expect(profile.tarotCount, 1);
    expect(profile.dreamCount, 1);
    expect(profile.coffeeCount, 1);
    expect(profile.reflectionCount, 1);
    expect(profile.astrologyCount, 1);
    expect(profile.dailyMessageCount, 1);
    expect(profile.starMapCount, 1);
    expect(profile.lastUpdated, DateTime(2026, 8, 16));
    expect(profile.hasHistory, isTrue);
  });

  test('soulmate count is only the persisted value — never invented', () {
    final none = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(),
    );
    final counted = PersonalDiscoveryProfileBuilder.from(
      const PersonalDiscoverySources(soulmateGenerationCount: 2),
    );
    expect(none.soulmateGenerations, 0);
    expect(counted.soulmateGenerations, 2);
  });
}
