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

  test(
    'BATCH 3A.2: coffee never invents a life from symbols alone when the '
    'backend wrote no real overall — a raw vision-dump "overall" is a '
    'failed interpretation, not a story to weave',
    () {
      final reading = CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'no-backend-overall',
          createdAt: DateTime(2026, 8, 18),
          overall: 'Kuş = haber.',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: 'Ağızda kuş, yanında açık bir çizgi.',
          symbols: const [
            CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'yol', meaning: '', interpretation: ''),
          ],
        ),
      );
      expect(reading, isNull);
    },
  );

  test(
    'BATCH 3A.2: an ambiguous/low-trust mark never gets named as fact via '
    'a client-fabricated story — a missing backend overall stays a '
    'failure, hedged or not',
    () {
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
      expect(reading, isNull);
    },
  );

  test(
    'BATCH 3A.1: topic lanes trust the backend\'s own decision, not a '
    'client symbol lexicon — the backend already evidence-binds each '
    'subject before writing it (see BATCH 3A), so real backend text for a '
    'lane is authoritative and a lane the backend left empty stays empty, '
    'independent of which symbols the client happens to recognize',
    () {
      final love = _compose(
        symbols: const ['kalp'],
        observation: 'Kulpa yakın kalp.',
        love: 'Bu iz yakınlığın tonunu daha görünür kılıyor.',
        career: 'İş dosyası ayrı durmuyor.',
      );
      // Backend wrote real content for both — both are shown as-is.
      expect(love.love, contains('yakınlığın'));
      expect(love.career, contains('İş dosyası'));

      final noCareerEvidence = _compose(
        symbols: const ['kalp'],
        observation: 'Kulpa yakın kalp.',
        love: 'Bu iz yakınlığın tonunu daha görünür kılıyor.',
      );
      // Backend deliberately left career empty (no evidence) — stays empty.
      expect(noCareerEvidence.career, isEmpty);

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
    },
  );

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

// BATCH 3A.2: a real backend overall is required for compose() to return
// a reading at all — this default stands in for a validated backend
// interpretation (long enough, no dump, no robotic/certainty phrasing)
// so tests below can focus on the optional lanes/UI, not on overall
// itself.
const _validOverall =
    'Fincanda görünen izler, son zamanlarda ertelenen bir konunun yeniden '
    'gündeme geldiğine işaret ediyor; bu süreci zorlamadan, kendi hızında '
    'ilerletmek sana iyi gelebilir.';

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
      overall: _validOverall,
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
  )!;
}
