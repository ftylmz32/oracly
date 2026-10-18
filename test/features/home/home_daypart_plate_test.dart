import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/features/home/theme/home_ritual_plates.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';

import 'home_daypart_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('greeting and plate follow one injected clock', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cases = <int, String>{
      8: 'İyi sabahlar',
      14: 'İyi günler',
      19: 'İyi akşamlar',
      23: 'İyi geceler',
    };
    for (final entry in cases.entries) {
      final moment = DateTime(2026, 6, 15, entry.key, 30);
      final time = OraclyRitualAtmosphere.fromHour(entry.key);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 3,
            ),
            child: OraclyUniverseTicker(
              now: () => moment,
              child: const DaypartProbe(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text(daypartTraceLabel(time)), findsOneWidget);
      expect(
        tester.widget<OraclyAssetImage>(find.byType(OraclyAssetImage)).assetPath,
        AppAssets.homeHeroMoon,
      );
      expect(daypartTracePaths(tester), {HomeRitualPlates.of(time)});
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('open app updates the trace when the injected hour crosses', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var moment = DateTime(2026, 6, 15, 11, 59);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: OraclyUniverseTicker(
          now: () => moment,
          child: const DaypartProbe(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('İyi sabahlar'), findsOneWidget);
    moment = DateTime(2026, 6, 15, 12, 1);
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('İyi günler'), findsOneWidget);
    expect(daypartTracePaths(tester), {
      HomeRitualPlates.of(OraclyRitualTime.afternoon),
    });
    expect(
      tester.widget<OraclyAssetImage>(find.byType(OraclyAssetImage)).assetPath,
      AppAssets.homeHeroMoon,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('resume re-reads the clock', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var moment = DateTime(2026, 6, 15, 19);
    await tester.pumpWidget(
      MaterialApp(
        home: OraclyUniverseTicker(
          now: () => moment,
          child: const DaypartProbe(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('İyi akşamlar'), findsOneWidget);
    moment = DateTime(2026, 6, 15, 23);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('İyi geceler'), findsOneWidget);
    expect(daypartTracePaths(tester), {
      HomeRitualPlates.of(OraclyRitualTime.night),
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion uses no crossfade', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: OraclyUniverseTicker(
            now: () => DateTime(2026, 6, 15, 23),
            child: const DaypartProbe(),
          ),
        ),
      ),
    );
    await tester.pump();
    final fade = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(fade.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });
}
