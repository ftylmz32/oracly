/// G1 — OR first-reading deepen: spent exactly once, for the reading it was
/// asked about, as soon as a real reply is on screen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';

import 'g1_or_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  Future<LocalStorage> eligible() async {
    final storage = LocalStorage.ephemeral();
    await FirstReadingOrDeepen.markEligible(storage, g1FirstTarot.sessionId);
    return storage;
  }

  test('the deepen is spent even if the reading context is cleared while the '
      'reply is in flight', () async {
    final storage = await eligible();
    final ai = G1ScriptedAi(delay: const Duration(milliseconds: 40));
    final controller = g1Companion(ai: ai, repo: G1ThreadRepo(), storage: storage);
    controller.applyReadingHandoff(g1FirstTarot);
    expect(FirstReadingOrDeepen.allows(storage, g1FirstTarot), isTrue);

    final pending = controller.send('What does the star ask of me?');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.clearReadingContext();
    await pending;

    expect(ai.calls, 1);
    expect(FirstReadingOrDeepen.isConsumed(storage), isTrue);
    expect(FirstReadingOrDeepen.allows(storage, g1FirstTarot), isFalse);
  });

  test('the deepen is spent when the reply shows but saving it fails',
      () async {
    final storage = await eligible();
    final repo = G1ThreadRepo()..failAssistant = true;
    final controller =
        g1Companion(ai: G1ScriptedAi(), repo: repo, storage: storage);
    controller.applyReadingHandoff(g1FirstTarot);

    await controller.send('What does the star ask of me?');

    expect(controller.state.errorMessage, CompanionCopy.saveFailed);
    expect(controller.state.conversation!.messages.last.isAssistant, isTrue);
    expect(FirstReadingOrDeepen.isConsumed(storage), isTrue);
  });

  test('an unusable reply leaves the deepen available', () async {
    final storage = await eligible();
    final ai = G1ScriptedAi(replies: const ['']);
    final controller = g1Companion(ai: ai, repo: G1ThreadRepo(), storage: storage);
    controller.applyReadingHandoff(g1FirstTarot);

    await controller.send('What does the star ask of me?');

    expect(controller.state.lastFailedText, isNotNull);
    expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
    expect(FirstReadingOrDeepen.allows(storage, g1FirstTarot), isTrue);
  });
}
