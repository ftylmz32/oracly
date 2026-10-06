import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_sections.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets(
    'C2.1: overall is first and visualObservation is not rendered',
    (tester) async {
      const observation =
          'Fincanın dibindeki yoğun tortu, alt iç yüzeye doğru iki yandan uzanıyor.';
      const overall =
          'Bu ağırlık ile üstteki ferahlık, bir yükün henüz dağılmadığını ama taşınabilir hale geldiğini düşündürüyor.';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoffeeResultSections(
              reading: CoffeeReading(
                id: 'lead',
                createdAt: DateTime.utc(2026, 9, 7),
                overall: overall,
                love: '',
                career: '',
                money: '',
                nearFuture: '',
                takeaway: '',
                visualObservation: observation,
              ),
            ),
          ),
        ),
      );

      expect(find.text(overall), findsOneWidget);
      expect(find.text(observation), findsNothing);
      expect(find.text(CoffeeCopy.loveTitle), findsNothing);
      expect(find.text(CoffeeCopy.careerTitle), findsNothing);
      expect(find.text(CoffeeCopy.moneyTitle), findsNothing);
    },
  );

  testWidgets(
    'C2.1: compatibility caption remains hidden with unsupported lanes',
    (tester) async {
      const overall =
          'Dipte toplanan yoğunluk, henüz dağılmamış bir iç ağırlığa işaret ediyor.';
      const caption =
          'Fincanın dibinde yoğun bir tortu, çevresinde kıvrımlı bir bant var.';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoffeeResultSections(
              reading: CoffeeReading(
                id: 'lead-3a5',
                createdAt: DateTime.utc(2026, 9, 8),
                overall: overall,
                love: '',
                career: '',
                money: '',
                nearFuture: '',
                takeaway: 'Günün sırasını kendi adımınla kurmak, dışarıdaki tempoya bırakmamak.',
                visualObservation: caption,
              ),
            ),
          ),
        ),
      );

      expect(find.text(overall), findsOneWidget);
      expect(find.text(caption), findsNothing);
      expect(find.text(CoffeeCopy.loveTitle), findsNothing);
      expect(find.text(CoffeeCopy.careerTitle), findsNothing);
      expect(find.text(CoffeeCopy.moneyTitle), findsNothing);
      expect(find.text(CoffeeCopy.newsTitle), findsNothing);
    },
  );
}
