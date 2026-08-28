/// Coffee result experience — cup hero, grounded story, optional topics.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_photo.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('cup story stays one narrative and never invents a life', () {
    final reading = _compose(
      symbols: const ['kuş', 'yol'],
      observation: 'Ağızda kuş, yanında açık bir çizgi.',
    );
    expect(reading.overall.toLowerCase(), contains('kuş'));
    expect(reading.overall.toLowerCase(), contains('yol'));
    expect(
      reading.overall.toLowerCase().contains('yan yana') ||
          reading.overall.toLowerCase().contains('yanında') ||
          reading.overall.toLowerCase().contains('yanındaki'),
      isTrue,
    );
    expect(reading.overall.toLowerCase(), isNot(contains('tekrar eden')));
    expect(reading.overall.toLowerCase(), isNot(contains('kuş = ')));
    expect(reading.love, isEmpty);
    expect(reading.career, isEmpty);
    expect(reading.money, isEmpty);
    expect(reading.nearFuture, isEmpty);
    expect(reading.takeaway, isEmpty);
  });

  test('ambiguous marks stay faint, never named as facts', () {
    final reading = CoffeeFortuneComposer.compose(
      CoffeeReading(
        id: 'faint',
        createdAt: DateTime(2026, 8, 18),
        overall: 'Kuş = haber.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: '',
        visualObservation: 'Ağızda belirsiz bir iz.',
        symbols: const [
          CoffeeSymbol(
            name: 'kuş',
            meaning: '',
            interpretation: '',
            trust: CoffeeMarkTrust.low,
          ),
        ],
      ),
    );
    expect(reading.overall.toLowerCase(), contains('kuşa benzeyen'));
    expect(reading.overall.toLowerCase(), contains('net değil'));
    expect(reading.overall, isNot(contains('=')));
    expect(reading.takeaway, isEmpty);
  });

  test('real decision theme binds only when the cup has a path mark', () {
    final withPath = _compose(
      id: 'decision-path',
      symbols: const ['yol'],
      observation: 'Açık bir yol.',
      themes: const ['karar verme'],
    );
    final noPath = _compose(
      id: 'decision-empty',
      observation: 'Fincanda duruluk var.',
      themes: const ['karar verme'],
    );
    expect(withPath.overall.toLowerCase(), contains('karar verme'));
    expect(withPath.overall.toLowerCase(), contains('canlıysa'));
    expect(noPath.overall.toLowerCase(), isNot(contains('karar verme')));
    expect(noPath.overall.toLowerCase(), isNot(contains('tekrar eden')));
    expect(noPath.overall.toLowerCase(), isNot(contains('canlıysa')));
  });

  test('topic lanes stay optional and grounded', () {
    final love = _compose(
      symbols: const ['kalp'],
      observation: 'Kulpa yakın kalp.',
      love: 'Bu iz yakınlığın tonunu daha görünür kılıyor.',
      career: 'İş dosyası ayrı durmuyor.',
    );
    expect(love.love, contains('yakınlığın'));
    expect(love.career, isEmpty);

    final work = _compose(
      symbols: const ['anahtar'],
      observation: 'Duvarda anahtar.',
      career: 'Bu anahtar bekleyen bir işi yerinden oynatabilir.',
    );
    expect(work.career, contains('işi'));
    expect(work.love, isEmpty);

    final news = _compose(
      symbols: const ['mektup'],
      observation: 'Ağızda mektup.',
      nearFuture: 'Küçük bir haber önce gelebilir.',
    );
    expect(news.nearFuture, contains('haber'));

    final caution = _compose(
      symbols: const ['dağ'],
      observation: 'Dipte dağ.',
      takeaway: 'Burada acele etmeden durmakta fayda var.',
    );
    expect(caution.takeaway, contains('acele'));
    expect(caution.career, isEmpty);
  });

  testWidgets('real cup photo sits above the spoken reading', (tester) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}oracly_cup_hero.jpg',
    );
    file.writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xD9]);
    addTearDown(() {
      try {
        if (file.existsSync()) file.deleteSync();
      } on FileSystemException {
        // Windows keeps decoded image bytes locked; a 4-byte temp file is fine.
      }
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final reading = _compose(
      symbols: const ['kuş', 'yol'],
      observation: 'Ağızda kuş, yanında yol.',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CoffeeResultView(
              reading: CoffeeReading(
                id: reading.id,
                createdAt: reading.createdAt,
                imagePath: file.path,
                overall: reading.overall,
                love: reading.love,
                career: reading.career,
                money: reading.money,
                nearFuture: reading.nearFuture,
                takeaway: reading.takeaway,
                visualObservation: reading.visualObservation,
                symbols: reading.symbols,
              ),
              onNewCup: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final photo = tester.getTopLeft(find.byType(CoffeeResultPhoto));
    final heading = tester.getTopLeft(find.text(CoffeeCopy.overallTitle));
    expect(photo.dy, lessThan(heading.dy));
    expect(find.text(CoffeeCopy.loveTitle), findsNothing);
    expect(find.text(CoffeeCopy.careerTitle), findsNothing);
    expect(find.text(CoffeeCopy.newsTitle), findsNothing);
    expect(find.text(CoffeeCopy.pathTitle), findsNothing);
    expect(find.text(CoffeeCopy.cautionTitle), findsNothing);
  });
}

CoffeeReading _compose({
  String id = 'cup',
  List<String> symbols = const [],
  String observation = '',
  List<String> themes = const [],
  String love = '',
  String career = '',
  String nearFuture = '',
  String takeaway = '',
}) {
  return CoffeeFortuneComposer.compose(
    CoffeeReading(
      id: id,
      createdAt: DateTime(2026, 8, 18),
      overall: 'Kuş = haber.',
      love: love,
      career: career,
      money: 'Para kartı.',
      nearFuture: nearFuture,
      takeaway: takeaway,
      visualObservation: observation,
      symbols: [
        for (final name in symbols)
          CoffeeSymbol(name: name, meaning: '', interpretation: ''),
      ],
    ),
    themes: themes,
  );
}
