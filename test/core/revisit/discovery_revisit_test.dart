/// Smart reopen — privacy and relevance gates.

library;



import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/l10n/l10n.dart';

import 'package:oracly_new/core/revisit/copy/discovery_revisit_copy.dart';

import 'package:oracly_new/features/tarot/copy/tarot_revisit_copy.dart';

import 'package:oracly_new/features/tarot/revisit/tarot_revisit_context.dart';

import 'package:oracly_new/core/domain/models/reading.dart';



void main() {

  setUp(() => OraclyL10n.bind('tr'));



  test('prompt and actions match product copy', () {

    expect(

      DiscoveryRevisitCopy.prompt,

      'Bu konuya daha önce de bakmıştın.\n'

          'Bu kez başka bir açıdan inceleyebiliriz.',

    );

    expect(DiscoveryRevisitCopy.newSpread, 'Yeni açılım');

    expect(DiscoveryRevisitCopy.openPrior, 'Öncekini aç');

    expect(DiscoveryRevisitCopy.newAngle, 'Farklı açı');

    expect(TarotRevisitCopy.actionNewSpread, 'Yeni açılım');

    expect(TarotRevisitCopy.actionOpenPrior, 'Öncekini aç');

    expect(TarotRevisitCopy.actionAngle, 'Farklı açı');

  });



  test('context line exposes topic and spread only', () {

    final context = TarotRevisitContext(

      reading: ReadingModel(

        id: 'r1',

        cardId: 0,

        cardName: 'The Star',

        cardImageAsset: 'a',

        spreadType: 'Üç Kart',

        aiSummary: 'Gizli özet metni burada duruyor.',

        createdAt: DateTime(2026, 8, 10),

        intention: 'İş değiştirmeli miyim?',

      ),

      topicLabel: 'Kariyer',

      spreadLabel: '3 Kart Açılımı',

    );

    final line = TarotRevisitCopy.contextLine(context);

    expect(line, contains('Kariyer'));

    expect(line, contains('3 Kart'));

    expect(line, isNot(contains('2026')));

    expect(line, isNot(contains('Gizli özet')));

    expect(line, isNot(contains('değiştirmeli')));

  });

}


