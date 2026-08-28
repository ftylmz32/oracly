/// Phase 2 — anti-repetition + structured personal insights.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_insight_presenter.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/surfaced_theme_record.dart';
import 'package:oracly_new/features/personal_discovery/services/anti_repetition_engine.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_insight_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 15);

  test('G overused theme is skipped when another exists', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Kariyer görünüyor.'),
          pdeTarot('r2', 'Değişim kapıda.'),
        ],
        coffee: [
          pdeCoffee('c1', 'Kariyer sabır ister.'),
          pdeCoffee('c2', 'Bu değişim yumuşak.'),
        ],
      ),
      now: now,
    );
    final recent = [
      SurfacedThemeRecord(
        theme: 'kariyer',
        surface: 'daily',
        at: now.subtract(const Duration(hours: 6)),
      ),
    ];
    final insights = PersonalInsightService.fromProfile(
      p,
      day: now,
      recent: recent,
      surface: 'daily',
    );
    expect(insights.map((i) => i.theme), isNot(contains('kariyer')));
    expect(insights.map((i) => i.theme), contains('değişim'));
  });

  test('H no alternative theme yields empty insights for neutral copy', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [pdeTarot('r1', 'Kariyer görünüyor.')],
        coffee: [pdeCoffee('c1', 'Kariyer sabır ister.')],
      ),
      now: now,
    );
    final recent = [
      SurfacedThemeRecord(
        theme: 'kariyer',
        surface: 'daily',
        at: now.subtract(const Duration(hours: 1)),
      ),
    ];
    final insights = PersonalInsightService.fromProfile(
      p,
      day: now,
      recent: recent,
      surface: 'daily',
    );
    expect(insights, isEmpty);
    expect(
      PersonalInsightPresenter.line(null),
      PersonalThemeCopy.accumulating,
    );
  });

  test('observational explanation uses evidence window, not personality claim', () {
    final p = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('r1', 'Değişim görünüyor.', at: now),
          pdeTarot('r2', 'Bu değişim yine geldi.', at: now.subtract(const Duration(days: 2))),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim yumuşak akıyor.', at: now.subtract(const Duration(days: 3))),
        ],
      ),
      now: now,
    );
    final insight = PersonalInsightService.primary(
      p,
      day: now,
      surface: 'daily',
    );
    expect(insight, isNotNull);
    expect(insight!.explanation, contains('Son 30 günde'));
    expect(insight.explanation, contains('keşfinde'));
    expect(insight.explanation, contains('farklı alanda'));
    expect(insight.explanation.toLowerCase(), isNot(contains('birisin')));
    expect(PersonalInsightPresenter.line(insight).toLowerCase(),
        isNot(contains('kişiliğin')));
  });

  test('Q daily anti-repetition select drops overused label', () {
    final picked = AntiRepetitionEngine.select(
      candidates: ['aşk', 'değişim'],
      recent: [
        SurfacedThemeRecord(
          theme: 'aşk',
          surface: 'daily',
          at: now.subtract(const Duration(hours: 2)),
        ),
      ],
      now: now,
      surface: 'daily',
    );
    expect(picked, ['değişim']);
  });

  test('surface memory persists without secrets', () async {
    SharedPreferences.setMockInitialValues({});
    final memory = DiscoverySurfaceMemory(await LocalStorage.open());
    await memory.record(
      SurfacedThemeRecord(
        theme: 'iletişim',
        surface: 'astrology',
        at: now,
      ),
    );
    expect(memory.all().single.theme, 'iletişim');
    expect(memory.all().toString(), isNot(contains('sk-')));
    expect(memory.all().toString(), isNot(contains('Bearer')));
  });
}
