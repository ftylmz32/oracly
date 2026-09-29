import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/features/home/theme/home_ritual_visuals.dart';

void main() {
  test('ritual hours change on the existing boundaries', () {
    expect(OraclyRitualAtmosphere.fromHour(4), OraclyRitualTime.night);
    expect(OraclyRitualAtmosphere.fromHour(5), OraclyRitualTime.morning);
    expect(OraclyRitualAtmosphere.fromHour(11), OraclyRitualTime.morning);
    expect(OraclyRitualAtmosphere.fromHour(12), OraclyRitualTime.afternoon);
    expect(OraclyRitualAtmosphere.fromHour(16), OraclyRitualTime.afternoon);
    expect(OraclyRitualAtmosphere.fromHour(17), OraclyRitualTime.evening);
    expect(OraclyRitualAtmosphere.fromHour(20), OraclyRitualTime.evening);
    expect(OraclyRitualAtmosphere.fromHour(21), OraclyRitualTime.night);
  });

  test('greeting period and visual period are the same ritual time', () {
    const expected = <int, String>{
      4: 'İyi geceler',
      5: 'İyi sabahlar',
      11: 'İyi sabahlar',
      12: 'İyi günler',
      16: 'İyi günler',
      17: 'İyi akşamlar',
      20: 'İyi akşamlar',
      21: 'İyi geceler',
    };
    for (final entry in expected.entries) {
      final time = OraclyRitualAtmosphere.fromHour(entry.key);
      expect(HomeRitualVisuals.of(time).time, time);
      expect(HomePersonalCopy.greeting(time: time), entry.value);
    }
  });

  test('the four Home profiles are visibly different', () {
    final plates = OraclyRitualTime.values
        .map((time) => HomeRitualVisuals.of(time).heroPlateOpacity)
        .toSet();
    final washes = OraclyRitualTime.values
        .map((time) => HomeRitualVisuals.of(time).pageWashAlpha)
        .toSet();
    final skies = OraclyRitualTime.values
        .map((time) => HomeRitualVisuals.of(time).skyTop)
        .toSet();
    expect(plates, hasLength(4));
    expect(washes, hasLength(4));
    expect(skies, hasLength(4));

    expect(HomeRitualVisuals.morning.heroPlateOpacity, lessThan(0.4));
    expect(
      HomeRitualVisuals.afternoon.heroPlateOpacity,
      lessThan(HomeRitualVisuals.morning.heroPlateOpacity),
    );
    expect(HomeRitualVisuals.afternoon.heroPlateOpacity, lessThan(0.2));
    expect(
      HomeRitualVisuals.evening.heroPlateOpacity,
      greaterThan(HomeRitualVisuals.afternoon.heroPlateOpacity),
    );
    expect(
      HomeRitualVisuals.evening.heroPlateOpacity,
      lessThan(HomeRitualVisuals.night.heroPlateOpacity),
    );
    expect(HomeRitualVisuals.night.heroPlateOpacity, 1);
    expect(
      HomeRitualVisuals.night.nightDepthAlpha,
      greaterThan(HomeRitualVisuals.evening.nightDepthAlpha),
    );
    expect(
      HomeRitualVisuals.afternoon.nightDepthAlpha,
      lessThan(HomeRitualVisuals.morning.nightDepthAlpha),
    );
    expect(HomeRitualVisuals.night.starBias, greaterThan(0.9));
    expect(
      HomeRitualVisuals.morning.roseAlpha,
      greaterThan(HomeRitualVisuals.afternoon.roseAlpha),
    );
    expect(
      HomeRitualVisuals.afternoon.pageWashAlpha,
      greaterThan(HomeRitualVisuals.night.pageWashAlpha),
    );
  });
}
