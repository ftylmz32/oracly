/// Prints the Yıldızname request each synthetic person would send
/// (YZ_SAMPLES=1 to show). No provider is called.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_wire_contract.dart';

import '../../astrology/sky_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sample Yıldızname requests', () {
    if (Platform.environment['YZ_SAMPLES'] != '1') return;
    for (final p in skyPeople) {
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: 'synthetic-${p.name}',
        chart: p.chart,
        languageCode: 'tr',
        addressName: p.name,
      );
      final wire = YildiznameWireContract.payload(plan.request!);
      // ignore: avoid_print
      print('==== ${p.name} · ${plan.kind.name}\n'
          '${const JsonEncoder.withIndent(' ').convert(wire['narrative'])}');
    }
  });
}
