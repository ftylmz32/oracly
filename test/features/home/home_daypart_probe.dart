import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card_body.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_hero_plate.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero.dart';

Set<String> daypartTracePaths(WidgetTester tester) {
  return tester
      .widgetList<DailyRitualHeroPlate>(find.byType(DailyRitualHeroPlate))
      .map((plate) => plate.assetPath)
      .toSet();
}

String daypartTraceLabel(OraclyRitualTime time) => switch (time) {
      OraclyRitualTime.morning => 'Sabah',
      OraclyRitualTime.afternoon => 'Öğlen',
      OraclyRitualTime.evening => 'Akşam',
      OraclyRitualTime.night => 'Gece',
    };

class DaypartProbe extends StatelessWidget {
  const DaypartProbe({super.key, this.traceHeight = 128});

  final double traceHeight;

  @override
  Widget build(BuildContext context) {
    final universe = OraclyUniverseScope.of(context);
    final time = universe.ritualTime;
    return Column(
      children: [
        HomeReferenceHero(
          height: 150,
          hello: HomePersonalCopy.greeting(time: time),
          invite: HomePersonalCopy.ritualWelcome(time),
        ),
        SizedBox(
          height: traceHeight,
          child: DailyRitualCardBody(
            universe: universe,
            body: HomePersonalCopy.ritualWelcome(time),
            art: 96,
            energySize: 26,
            cardDrawn: false,
            onDraw: () {},
          ),
        ),
      ],
    );
  }
}
