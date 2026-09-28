/// G1 — OR on account switch: the previous owner's reading handoff and any
/// reply still in flight never reach the next owner's chamber.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

import 'g1_or_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  test('an account switch drops the handoff and the in-flight reply', () async {
    final ai = G1ScriptedAi(
      replies: const ['A reply meant for the previous owner.'],
      delay: const Duration(milliseconds: 40),
    );
    final controller = g1Companion(ai: ai, repo: G1ThreadRepo());
    controller.applyReadingHandoff(g1FirstTarot);

    final pending = controller.send('About my star card');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.resetForAccountSwitch();
    await pending;

    expect(controller.readingContext, isNull);
    final shown = controller.state.conversation?.messages ?? const [];
    expect(
      shown.where((m) => m.content.contains('previous owner')),
      isEmpty,
    );
    expect(controller.state.isBusy, isFalse);
  });

  test('a fresh chamber after the switch answers without the old context',
      () async {
    final ai = G1ScriptedAi();
    final controller = g1Companion(ai: ai, repo: G1ThreadRepo());
    controller.applyReadingHandoff(g1FirstTarot);

    await controller.resetForAccountSwitch();
    await controller.send('Hello');

    expect(controller.readingContext, isNull);
    expect(ai.calls, 1);
    expect(controller.state.conversation!.messages.last.isAssistant, isTrue);
  });
}
