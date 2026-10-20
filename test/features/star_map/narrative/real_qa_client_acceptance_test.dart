/// Runs the recorded REAL provider outputs through the device-side gates
/// (QA_RESULTS=<results.json>). A text the client refuses would reach the
/// reader as an error, so acceptance here is part of quality.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/astrology/sky/astrology_daily_result.dart';
import 'package:oracly_new/features/astrology/sky/astrology_natal_sky.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_validator.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';

import '../../astrology/sky_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real outputs pass the device-side gates', () {
    final path = Platform.environment['QA_RESULTS'];
    if (path == null || path.isEmpty) return;
    final doc = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final byName = {for (final p in skyPeople) p.name: p};
    final report = <String>[];
    for (final r in (doc['results'] as List).cast<Map<String, dynamic>>()) {
      final id = r['id'] as String;
      if (r['ok'] != true) {
        report.add('$id: provider/server refused (${r['error']})');
        continue;
      }
      final person = byName[id.split('.').last]!;
      final data = Map<String, dynamic>.from(r['data'] as Map);
      try {
        if (id.startsWith('yildizname.')) {
          final plan = YildiznameLivePlanBuilder.build(
            featureEnabled: true,
            ownerId: 'synthetic-${person.name}',
            chart: person.chart,
            languageCode: 'tr',
            addressName: person.name,
          );
          YildiznameQualityValidator.validate(
            request: plan.request!,
            result: YildiznameResultParser.parse(data),
          );
        } else {
          AstrologyDailyResult.validate(
            data,
            depth: person.sky.depth == NatalSkyDepth.full
                ? NatalSkyDepth.full
                : NatalSkyDepth.dayOnly,
            addressName: person.name,
          );
        }
        report.add('$id: ACCEPTED by client');
      } catch (e) {
        report.add('$id: REFUSED by client: $e');
      }
    }
    // ignore: avoid_print
    print(report.join('\n'));
  });
}
