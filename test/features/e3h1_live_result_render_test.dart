/// E3H.1 — render real Coffee/Palm two-stage envelopes in result widgets.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  Future<void> pumpSizes(WidgetTester tester, Widget child) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      final box = tester.renderObject(find.byType(Scaffold)) as RenderBox;
      expect(box.hasSize, isTrue);
      expect(box.size.width, size.width);
    }
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('E3H.1 coffee live envelope renders without overflow', (tester) async {
    final envelope = jsonDecode(
      File('tool/e3e_private/evidence/coffee_analysis_e3h1_response.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(envelope['success'], isTrue);
    final data = Map<String, dynamic>.from(envelope['data'] as Map);
    data.remove('_e3h');
    final cup = File('tool/e3e_private/fixtures/e3f/coffee_e3f.jpg');
    expect(cup.existsSync(), isTrue);

    final reading = CoffeeReading(
      id: 'e3h1-coffee',
      createdAt: DateTime(2026, 9, 3),
      imagePath: cup.path,
      visualObservation: data['visualObservation'] as String,
      overall: data['overall'] as String,
      love: (data['love'] as String?) ?? '',
      career: (data['career'] as String?) ?? '',
      money: (data['money'] as String?) ?? '',
      nearFuture: (data['nearFuture'] as String?) ?? '',
      takeaway: (data['takeaway'] as String?) ?? '',
    );

    await pumpSizes(
      tester,
      CoffeeResultView(reading: reading, onNewCup: () {}),
    );
    expect(find.textContaining('Fincan'), findsWidgets);
  });

  testWidgets('E3H.1 palm live envelope renders without overflow', (tester) async {
    final envelope = jsonDecode(
      File('tool/e3e_private/evidence/palm_analysis_e3h1_response.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(envelope['success'], isTrue);
    final data = Map<String, dynamic>.from(envelope['data'] as Map);
    data.remove('_e3h');
    final palm = File('tool/e3e_private/fixtures/e3f/palm_e3f.jpg');
    expect(palm.existsSync(), isTrue);

    final reading = PalmReading(
      id: 'e3h1-palm',
      createdAt: DateTime(2026, 9, 3),
      hand: PalmHand.right,
      imagePath: palm.path,
      overall: [
        data['visualObservation'] as String? ?? '',
        data['overall'] as String? ?? '',
      ].where((e) => e.trim().isNotEmpty).join('\n\n'),
      heartLine: data['heartLine'] as String? ?? '',
      headLine: data['headLine'] as String? ?? '',
      lifeLine: data['lifeLine'] as String? ?? '',
      fateLine: data['fateLine'] as String? ?? '',
      takeaway: data['takeaway'] as String? ?? '',
    );

    await pumpSizes(
      tester,
      PalmResultView(reading: reading, onNewPalm: () {}),
    );
    expect(find.textContaining('avu'), findsWidgets);
  });
}