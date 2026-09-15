import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_map.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/services/soul_mate_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/premium/services/soul_mate_journal_link.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';

void main() {
  test('A complete Soulmate becomes one journal entry', () {
    final saved = _saved('op-1');
    final items = DiscoveryJournalAggregator.merge(soulMate: saved);
    expect(items, hasLength(1));
    expect(items.single.kind, DiscoveryJournalKind.soulMate);
    expect(items.single.id, 'op-1');
    expect(items.single.preview, contains('yakinlik'));
    expect(items.single.preview, isNot(contains('soft oval')));
  });

  test('B same logical id cannot duplicate', () {
    final saved = _saved('op-1');
    final first = DiscoveryJournalMap.soulMate(saved);
    final second = DiscoveryJournalMap.soulMate(saved);
    expect(first?.id, second?.id);
    expect(
      DiscoveryJournalAggregator.merge(soulMate: saved)
          .where((e) => e.kind == DiscoveryJournalKind.soulMate),
      hasLength(1),
    );
    expect(SoulMateJournalLink.sameEntry('op-1', 'op-1'), isTrue);
  });

  test('C provider retry stays one entry', () {
    expect(SoulMateJournalLink.sameEntry('op-1', 'op-1'), isTrue);
    expect(
      SoulMateJournalLink.isUserInitiatedNewGeneration(
        previousId: 'op-1',
        logicalId: 'op-1',
        internalRetry: true,
      ),
      isFalse,
    );
  });

  test('D uniqueness retry stays one entry', () {
    expect(
      SoulMateJournalLink.isUserInitiatedNewGeneration(
        previousId: 'op-1',
        logicalId: 'op-1',
        internalRetry: true,
      ),
      isFalse,
    );
  });

  test('E interpretation retry upserts the same id', () {
    final partial = _saved('op-1', authoritative: false);
    expect(DiscoveryJournalMap.soulMate(partial), isNull);
    final done = _saved('op-1');
    expect(DiscoveryJournalMap.soulMate(done)?.id, 'op-1');
    expect(
      DiscoveryJournalAggregator.merge(soulMate: done)
          .where((e) => e.id == 'op-1'),
      hasLength(1),
    );
  });

  test('F user-initiated generation is distinct from internal retry', () {
    expect(
      SoulMateJournalLink.isUserInitiatedNewGeneration(
        previousId: 'op-1',
        logicalId: 'op-2',
        internalRetry: false,
      ),
      isTrue,
    );
    expect(
      SoulMateJournalLink.isUserInitiatedNewGeneration(
        previousId: 'op-1',
        logicalId: 'op-1',
        internalRetry: false,
      ),
      isFalse,
    );
  });

  test('G H reopen does not require a new generation', () {
    expect(
      SoulMateJournalLink.canReopen(
        savedId: 'op-1',
        entryId: 'op-1',
        authoritative: true,
        hasPortraitBytes: true,
      ),
      isTrue,
    );
  });

  test('I J reopen requires the same saved portrait and text', () {
    expect(
      SoulMateJournalLink.canReopen(
        savedId: 'op-1',
        entryId: 'op-1',
        authoritative: true,
        hasPortraitBytes: true,
      ),
      isTrue,
    );
    expect(
      SoulMateJournalLink.canReopen(
        savedId: 'op-1',
        entryId: 'op-2',
        authoritative: true,
        hasPortraitBytes: true,
      ),
      isFalse,
    );
  });

  test('K failed generation creates no complete entry', () {
    expect(DiscoveryJournalMap.soulMate(_saved('op-1', authoritative: false)), isNull);
    expect(DiscoveryJournalAggregator.merge(soulMate: _saved('op-1', authoritative: false)), isEmpty);
  });

  test('L journal projection cannot erase the saved result', () {
    final saved = _saved('op-1');
    expect(SoulMateJournalLink.isComplete(saved), isTrue);
    expect(DiscoveryJournalMap.soulMate(saved)?.id, saved.id);
    expect(saved.portraitPath, isNotEmpty);
  });

  test('M another account does not inherit the entry', () {
    final other = DiscoveryJournalAggregator.merge();
    expect(other.where((e) => e.id == 'op-1'), isEmpty);
    expect(
      SoulMateJournalLink.canReopen(
        savedId: null,
        entryId: 'op-1',
        authoritative: true,
        hasPortraitBytes: false,
      ),
      isFalse,
    );
  });

  test('N legacy migration is one idempotent projection', () {
    final legacy = _saved('legacy-1');
    final once = DiscoveryJournalAggregator.merge(soulMate: legacy);
    final twice = DiscoveryJournalAggregator.merge(soulMate: legacy);
    expect(once.single.id, 'legacy-1');
    expect(twice.single.id, once.single.id);
    expect(DiscoveryJournalMap.soulMate(_saved('legacy-1', authoritative: false)), isNull);
  });

  test('O missing portrait reference does not reopen', () {
    expect(
      SoulMateJournalLink.canReopen(
        savedId: 'op-1',
        entryId: 'op-1',
        authoritative: true,
        hasPortraitBytes: false,
      ),
      isFalse,
    );
    expect(SoulMateJournalLink.isComplete(_saved('op-1', path: '')), isFalse);
  });

  test('P local template is not journal content', () {
    final template = SoulMateInterpretation.partsFor(
      SoulMateDrawRequest(name: 'Ayse', birthDate: DateTime.utc(1994, 3, 12)),
    );
    expect(template.authoritative, isFalse);
    final saved = _saved('op-1', parts: template);
    expect(DiscoveryJournalMap.soulMate(saved), isNull);
  });
}

SoulMateSavedResult _saved(
  String id, {
  bool authoritative = true,
  String path = '/tmp/soulmate.jpg',
  SoulMateReadingParts? parts,
}) {
  return SoulMateSavedResult(
    id: id,
    createdAt: DateTime.utc(2026, 9, 8),
    name: 'Ayse',
    birthDate: DateTime.utc(1994, 3, 12),
    portraitPath: path,
    parts: parts ??
        SoulMateReadingParts(
          energy: 'sakin bir durus',
          attraction: 'sessiz dikkat',
          dynamics: 'yavas tempo',
          feeling: 'acele etmeyen bir yakinlik',
          yourSide: 'olgunluk',
          authoritative: authoritative,
        ),
    identity: const SoulMateIdentity(
      nonce: 'render',
      presence: 'feminine-presenting adult',
      mood: 'reserved',
      faceShape: 'soft oval',
    ),
  );
}
