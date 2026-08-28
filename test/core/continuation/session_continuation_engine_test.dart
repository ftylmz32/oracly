/// Cross-feature session continuation — one action, evidence only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/continuation/copy/session_continuation_copy.dart';
import 'package:oracly_new/core/continuation/models/session_continuation.dart';
import 'package:oracly_new/core/continuation/services/session_continuation_engine.dart';
import 'package:oracly_new/core/continuation/services/session_continuation_focus_store.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

CrossDiscoveryInsight _cross(String theme, List<String> sources) {
  return CrossDiscoveryInsight(
    theme: theme,
    sources: sources,
    confidence: DiscoveryThemeStrength.recurring,
    lastObserved: DateTime(2026, 8, 18),
    sourceCount: sources.length,
    discoveryCount: 2,
    recencyWeight: 0.9,
  );
}

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('coffee decision theme stays with OR — never invents Tarot', () {
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.coffee,
      sessionThemes: const ['karar verme'],
    );
    expect(item?.target, SessionContinuationTarget.companion);
    expect(item?.theme, 'karar verme');
  });

  test('coffee decision is silent when Ask OR is already shown', () {
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.coffee,
      sessionThemes: const ['karar verme'],
      orAlreadyOffered: true,
    );
    expect(item, isNull);
    expect(
      SessionContinuationCopy.coffeeOrWhisperFor(const ['karar verme']),
      isNotNull,
    );
  });

  test('coffee career theme may open Tarot once', () {
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.coffee,
      sessionThemes: const ['kariyer'],
      orAlreadyOffered: true,
    );
    expect(item?.target, SessionContinuationTarget.tarot);
    expect(item?.theme, 'kariyer');
  });

  test('coffee without mapped theme stays silent', () {
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.coffee,
      sessionThemes: const ['sakin fincan'],
    );
    expect(item, isNull);
  });

  test('dream with cross-modal profile links to journal', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        _cross('değişim', const ['dream', 'tarot']),
      ],
    );
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.dream,
      profile: profile,
      sessionThemes: const ['değişim'],
    );
    expect(item?.target, SessionContinuationTarget.discoveryJournal);
    expect(item?.theme, 'değişim');
    expect(item?.line, contains('Değişim'));
  });

  test('star map with cross-modal theme points to journal', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        _cross('ilişki', const ['coffee', 'star']),
      ],
    );
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.starMap,
      profile: profile,
      sessionThemes: const ['ilişki'],
    );
    expect(item?.target, SessionContinuationTarget.discoveryJournal);
    expect(item?.theme, 'ilişki');
  });

  test('tarot skips duplicate OR when button already shown', () {
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.tarot,
      orAlreadyOffered: true,
    );
    expect(item, isNull);
  });

  test('tarot with cross-modal history may open journal after OR', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        _cross('değişim', const ['dream', 'tarot']),
      ],
    );
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.tarot,
      profile: profile,
      sessionThemes: const ['değişim'],
      orAlreadyOffered: true,
    );
    expect(item?.target, SessionContinuationTarget.discoveryJournal);
  });

  test('soul mate with cross-modal theme points to journal', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        _cross('bağ', const ['coffee', 'star']),
      ],
    );
    final item = SessionContinuationEngine.decide(
      from: SessionContinuationSource.soulMate,
      profile: profile,
      sessionThemes: const ['bağ'],
    );
    expect(item?.target, SessionContinuationTarget.discoveryJournal);
  });

  test('copy never suggests trying everything', () {
    final blob = [
      SessionContinuationCopy.coffeeToTarot(),
      SessionContinuationCopy.dreamToJournal('değişim'),
      SessionContinuationCopy.starToJournal('ilişki'),
      SessionContinuationCopy.tarotToOr(),
    ].join(' ');
    expect(blob.toLowerCase(), isNot(contains('her şeyi')));
    expect(blob.toLowerCase(), isNot(contains('try everything')));
  });

  test('focus store passes theme once to the next chamber', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final store = SessionContinuationFocusStore(storage);

    await store.write(
      const SessionContinuation(
        target: SessionContinuationTarget.discoveryJournal,
        line: 'Keşif Günlüğünde devam et',
        theme: 'değişim',
      ),
    );

    expect(store.peek()?.theme, 'değişim');
    final consumed = store.consumeFor(
      SessionContinuationTarget.discoveryJournal,
    );
    expect(consumed?.theme, 'değişim');
    expect(store.peek(), isNull);
  });
}
