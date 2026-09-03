/// OR-V1 Luna reference-parity widget coverage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_day_separator.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_feature_shortcuts.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_luna_intro_card.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_prompts.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thread_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child, {Size size = const Size(390, 844), String lang = 'tr'}) {
    OraclyL10n.bind(lang);
    return MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: true),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('first opening shows hero, prompts, shortcuts, privacy', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(wrap(Column(children: [
      Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
      CompanionReferenceInputBar(controller: c, onSend: () {}),
    ])));
    await t.pump();
    expect(find.byType(CompanionLunaIntroCard), findsOneWidget);
    expect(find.byType(CompanionFeatureShortcuts), findsOneWidget);
    expect(find.text(CompanionCopy.privacyNote), findsOneWidget);
    expect(testerOverflow(t), isFalse);
  });

  testWidgets('conversation list has hero + day separator + bubbles', (t) async {
    final sc = ScrollController();
    addTearDown(sc.dispose);
    final messages = [
      AIMessage(
        id: 'u1',
        role: AIMessageRole.user,
        content: 'Line one\nLine two\nLine three',
        createdAt: DateTime(2026, 9, 1, 18, 42),
      ),
      AIMessage(
        id: 'a1',
        role: AIMessageRole.assistant,
        content: List.filled(8, 'Luna yaniti uzun metin. ').join(),
        createdAt: DateTime(2026, 9, 1, 18, 43),
      ),
    ];
    await t.pumpWidget(wrap(CompanionReferenceThreadList(
      scrollController: sc,
      visible: messages,
      lastOrId: 'a1',
      showActions: false,
      onSpeak: (_) {},
      onRegenerate: () {},
      allowSpeak: false,
    )));
    await t.pump();
    expect(find.byType(CompanionLunaIntroCard), findsOneWidget);
    expect(find.byType(CompanionDaySeparator), findsOneWidget);
    expect(find.text(CompanionCopy.dayToday), findsOneWidget);
    expect(find.textContaining('Line one'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('compact 320x568 idle has no overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(wrap(
      Column(children: [
        Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
        CompanionReferenceInputBar(controller: c, onSend: () {}),
      ]),
      size: const Size(320, 568),
    ));
    await t.pump();
    expect(testerOverflow(t), isFalse);
  });

  testWidgets('tall 412x915 idle has no overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(wrap(
      Column(children: [
        Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
        CompanionReferenceInputBar(controller: c, onSend: () {}),
      ]),
      size: const Size(412, 915),
    ));
    await t.pump();
    expect(testerOverflow(t), isFalse);
  });

  testWidgets('EN and RU idle titles render without overflow', (t) async {
    for (final lang in ['en', 'ru']) {
      OraclyL10n.bind(lang);
      final c = TextEditingController();
      await t.pumpWidget(wrap(
        Column(children: [
          Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
          CompanionReferenceInputBar(controller: c, onSend: () {}),
        ]),
        lang: lang,
      ));
      await t.pump();
      expect(find.textContaining('Luna'), findsWidgets);
      expect(find.text(CompanionCopy.dayToday), findsNothing);
      expect(testerOverflow(t), isFalse);
      expect(find.text(CompanionCopy.privacyNote), findsOneWidget);
      c.dispose();
    }
  });

  testWidgets('large text scale keeps composer reachable', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.6),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: Column(children: [
            Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
            CompanionReferenceInputBar(controller: c, onSend: () {}),
          ]),
        ),
      ),
    ));
    await t.pump();
    expect(find.byType(CompanionReferenceInputBar), findsOneWidget);
    expect(testerOverflow(t), isFalse);
  });

  testWidgets('keyboard inset keeps composer on screen', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: 280),
          disableAnimations: true,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Column(children: [
            const Expanded(child: SizedBox()),
            CompanionReferenceInputBar(
              controller: c,
              onSend: () {},
              onMicTap: () {},
              onPlusTap: () {},
            ),
          ]),
        ),
      ),
    ));
    await t.pump();
    final bar = t.getRect(find.byType(CompanionReferenceInputBar));
    expect(bar.bottom, lessThanOrEqualTo(844));
  });

  testWidgets('quick prompt send contract fires onSelected', (t) async {
    String? got;
    await t.pumpWidget(wrap(CompanionReferencePrompts(
      onSelected: (v) => got = v,
      horizontal: true,
      limit: 3,
    )));
    await t.pump();
    await t.tap(find.byType(CompanionPromptInvitation).first);
    await t.pump();
    expect(got, isNotNull);
    expect(got!.isNotEmpty, isTrue);
  });

  testWidgets('shortcuts expose five feature labels', (t) async {
    await t.pumpWidget(wrap(const CompanionFeatureShortcuts()));
    await t.pump();
    expect(find.text(CompanionCopy.shortcutTarot), findsOneWidget);
    expect(find.text(CompanionCopy.shortcutCoffee), findsOneWidget);
    expect(find.text(CompanionCopy.shortcutDream), findsOneWidget);
    expect(find.text(CompanionCopy.shortcutAstrology), findsOneWidget);
    expect(find.text(CompanionCopy.shortcutSoulMate), findsOneWidget);
  });

  testWidgets('chat shortcuts include prompts above feature row', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    var sent = 0;
    await t.pumpWidget(wrap(CompanionReferenceInputBar(
      controller: c,
      onSend: () => sent++,
      showShortcuts: true,
      onPromptSelected: (text) {
        c.text = text;
        sent++;
      },
    )));
    await t.pump();
    expect(find.byType(CompanionReferencePrompts), findsOneWidget);
    expect(find.byType(CompanionFeatureShortcuts), findsOneWidget);
    await t.tap(find.byType(CompanionPromptInvitation).first);
    await t.pump();
    expect(sent, 1);
  });

  testWidgets('user bubble shows double-check; assistant has avatar row', (t) async {
    await t.pumpWidget(wrap(ListView(children: [
      CompanionReferenceMessageBubble(
        message: AIMessage(
          id: 'u',
          role: AIMessageRole.user,
          content: 'Merhaba',
          createdAt: DateTime(2026, 9, 1, 18, 42),
        ),
      ),
      CompanionReferenceMessageBubble(
        message: AIMessage(
          id: 'a',
          role: AIMessageRole.assistant,
          content: 'Yanit',
          createdAt: DateTime(2026, 9, 1, 18, 43),
        ),
      ),
    ])));
    await t.pump();
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });
}

bool testerOverflow(WidgetTester t) {
  final err = t.takeException();
  if (err == null) return false;
  return err.toString().contains('overflowed') ||
      err.toString().contains('RenderFlex');
}
