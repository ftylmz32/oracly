/// Günün Mesajı — one local ritual note per day, no fake history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/daily_message/copy/daily_message_copy.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_message/presentation/widgets/daily_return_cta.dart';
import 'package:oracly_new/features/daily_message/services/daily_message_service.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  setUpAll(() async {
    await OraclyFormat.ensureInitialized();
  });

  test('same day and name always return the same message', () {
    OraclyL10n.bind('tr');
    final day = DateTime(2026, 8, 13, 20, 12);
    final a = DailyMessageService.forDay(day: day, profileName: 'Fatih');
    final b = DailyMessageService.forDay(
      day: DateTime(2026, 8, 13, 8),
      profileName: 'Fatih',
    );
    expect(a.text, b.text);
    expect(a.dateLabel, '13 Ağustos 2026');
    expect(a.text.toLowerCase(), isNot(contains('yapay zek')));
    expect(a.text.toLowerCase(), isNot(contains('kehanet')));
    expect(a.text, isNot(contains('güzel gelişmeler')));
  });

  test('empty name does not invent a personal identity', () {
    final note = DailyMessageService.forDay(day: DateTime(2026, 8, 13));
    expect(note.text, isNotEmpty);
    expect(note.text.toLowerCase(), isNot(contains('fatih')));
    expect(note.text, isNot(contains('son yorumlarında')));
    expect(note.sunSign, isNull);
    expect(note.theme, isNull);
  });

  test('real themes add a personal daily reflection, not a random slogan', () {
    final day = DateTime(2026, 8, 16);
    final plain = DailyMessageService.forDay(day: day, profileName: 'Fatih');
    final themed = DailyMessageService.forDay(
      day: day,
      profileName: 'Fatih',
      themes: const ['sınırlar'],
    );
    expect(themed.text, isNot(equals(plain.text)));
    expect(themed.text, contains('sınırlar'));
    expect(themed.text, isNot(contains('güzel gelişmeler')));
    final next = DailyMessageService.forDay(
      day: DateTime(2026, 8, 17),
      profileName: 'Fatih',
      themes: const ['sınırlar'],
      previousTheme: themed.theme,
      previousText: themed.text,
    );
    expect(themed.text, isNot(equals(next.text)));
  });

  test('feature is live and not on the Home 3x2 grid', () {
    final module = OraclyFeatureRegistry.byId(OraclyFeatureId.dailyMessage);
    expect(module?.isLive, isTrue);
    expect(module?.routeName, OraclyRoutes.dailyMessage);
    expect(module?.homeBand, isNull);
    expect(
      HomeReferenceModules.list().map((m) => HomeDiscoveryCopy.title(m.id).toLowerCase()),
      isNot(contains('günün mesajı')),
    );
  });

  testWidgets('screen shows ritual title, date, and one working action',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: DailyMessageScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(DailyMessageCopy.screenTitle), findsOneWidget);
    expect(find.text(DailyMessageCopy.prompt), findsOneWidget);
    expect(find.text(DailyMessageCopy.honesty), findsOneWidget);
    expect(find.byType(DailyReturnCta), findsOneWidget);
    expect(find.text(DailyMessageCopy.copyCta), findsOneWidget);
    expect(find.textContaining('yapay zek'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('OR personality changes tone without inventing facts', () {
    final day = DateTime(2026, 8, 16);
    const themes = ['iletişim'];
    final gentle = DailyMessageService.forDay(
      day: day,
      themes: themes,
      personality: AiPersonality.gentle,
    );
    final direct = DailyMessageService.forDay(
      day: day,
      themes: themes,
      personality: AiPersonality.direct,
    );
    expect(gentle.text.toLowerCase(), contains('konuş'));
    expect(direct.text.toLowerCase(), contains('konuş'));
    expect(gentle.text, isNot(equals(direct.text)));
  });
}
