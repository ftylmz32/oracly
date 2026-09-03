/// OR performance boundaries — windowed context, visible cache, no full-history scan.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thread_visible.dart';
import 'package:oracly_new/features/companion/services/companion_turn_window.dart';

void main() {
  AIMessage msg(String id, String text, {bool user = true}) => AIMessage(
        id: id,
        role: user ? AIMessageRole.user : AIMessageRole.assistant,
        content: text,
        createdAt: DateTime(2024, 1, 1),
      );

  test('turn window scans only a trailing cap before takeRecent', () {
    final many = [
      for (var i = 0; i < 80; i++) msg('m$i', 'turn $i content here'),
    ];
    final history = CompanionTurnWindow.history(many);
    expect(history.length, lessThanOrEqualTo(CompanionTurnWindow.scanCap));
    final recent = CompanionTurnWindow.fromMessages(many);
    expect(recent.length, lessThanOrEqualTo(ConversationTurn.maxWindow));
    expect(recent.last.text, contains('79'));
  });

  test('visible signature stable when list content unchanged', () {
    final a = [msg('1', 'Merhaba'), msg('2', 'Selam', user: false)];
    final b = [msg('1', 'Merhaba'), msg('2', 'Selam', user: false)];
    expect(companionVisibleSignature(a), companionVisibleSignature(b));
    expect(companionVisibleMessages(a), hasLength(2));
    final withWelcome = [
      msg('welcome_1', 'Hos geldin', user: false),
      ...a,
    ];
    expect(companionVisibleMessages(withWelcome), hasLength(2));
  });

  test('provider window size stays bounded', () {
    expect(ConversationTurn.maxWindow, 8);
    expect(CompanionTurnWindow.scanCap, 32);
  });
}

