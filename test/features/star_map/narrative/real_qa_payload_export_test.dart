/// Exports the exact wire payloads for the real-provider QA run
/// (QA_EXPORT=<path> to write). Synthetic people only; no provider call.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/sky/astrology_daily_request.dart';
import 'package:oracly_new/features/astrology/sky/astrology_transit_engine.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';

import '../../astrology/sky_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('export real QA payloads', () {
    final path = Platform.environment['QA_EXPORT'];
    if (path == null || path.isEmpty) return;
    final day = DateTime(2026, 10, 20);
    final out = <Map<String, dynamic>>[];
    for (final p in skyPeople) {
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'synthetic-${p.name}',
        chart: p.chart,
        languageCode: 'tr',
        addressName: p.name,
      );
      out.add({
        'id': 'yildizname.${p.name}',
        'operation': 'yildizname_reading',
        'scope': plan.kind.name,
        'payload': YildiznameWireContract.payload(plan.request!),
      });
    }
    for (final p in skyPeople) {
      final req = AstrologyDailyRequest.build(
        sky: AstrologyTransitEngine.compute(
          natal: p.sky,
          day: day,
          ephemeris: skyEphemeris,
        ),
        day: day,
        addressName: p.name,
        themes: p == ayse ? const ['İlişki'] : const [],
      );
      out.add({
        'id': 'astrology.${p.name}',
        'operation': 'astrology_daily',
        'operationId': req.operationId,
        'payload': req.payload,
      });
    }
    File(path).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(out),
    );
  });
}
