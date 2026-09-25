/// Daily invitations — one payload, public theme names only.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_coordinator.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_planner.dart';
import 'package:oracly_new/core/notifications/oracly_notification_privacy.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/core/domain/models/conversation_record.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';

import '../../features/personal_discovery/pde_test_fixtures.dart';

void main() {
  final now = DateTime(2026, 8, 16);

  setUp(() => OraclyL10n.bind('tr'));

  test('preview never leaks secrets, dates, or chat fragments', () {
    expect(OraclyNotificationPrivacy.isSafePreview('sk-live-secret'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('Bearer abc'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('1995-08-15'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('a@b.com'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('path/secret'), isFalse);
    expect(
      OraclyNotificationPrivacy.isSafePreview('Bugünün mesajı hazır.'),
      isTrue,
    );
    expect(OraclyNotificationPrivacy.isSafePreview('private dream text'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('keşif günlüğü notu'), isFalse);
    expect(OraclyNotificationPrivacy.isSafePreview('doğum tarihi 1990'), isFalse);
  });

  test('off never plans a payload', () {
    expect(
      OraclyNotificationPlanner.plan(
        enabled: false,
        profile: PersonalDiscoveryProfile.empty,
        now: now,
      ),
      isNull,
    );
  });

  test('empty history uses the daily message invitation', () {
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: PersonalDiscoveryProfile.empty,
      now: now,
    )!;
    expect(payload.kind, OraclyNotificationKind.daily);
    expect(payload.body, 'Bugünün mesajı hazır.');
    expect(OraclyNotificationPrivacy.isSafePreview(payload.body), isTrue);
  });

  test('recurring recent theme can be named without private text', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        coffee: [
          pdeCoffee('c1', 'Değişim kapıda.', at: DateTime(2026, 8, 10)),
          pdeCoffee('c2', 'Bu değişim yumuşak.', at: DateTime(2026, 8, 14)),
        ],
        dreams: [
          pdeDream(
            'secret',
            'Annemin evi 1995-08-15 ve rüya metni gizli.',
            at: DateTime(2026, 8, 14),
          ),
        ],
      ),
      now: now,
    );
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: profile,
      now: now,
    )!;
    expect(payload.kind, OraclyNotificationKind.discovery);
    expect(payload.body, contains('değişim'));
    expect(payload.body, isNot(contains('Annemin')));
    expect(payload.body, isNot(contains('1995')));
    expect(payload.body, isNot(contains('gizli')));
    expect(payload.body.toLowerCase(), isNot(contains('@')));
  });

  test('unresolved theme falls back to generic discovery copy', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        CrossDiscoveryInsight(
          theme: 'özel tema metni',
          sources: const ['coffee', 'palm'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime(2026, 8, 14),
          sourceCount: 2,
          discoveryCount: 3,
          recencyWeight: 0.9,
        ),
      ],
    );
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: profile,
      now: now,
    )!;
    expect(payload.kind, OraclyNotificationKind.discovery);
    expect(payload.body, 'Son keşiflerinde bir iz yeniden karşına çıkıyor.');
  });

  test('named recurring theme stays observational and public', () {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        CrossDiscoveryInsight(
          theme: 'değişim',
          sources: const ['coffee', 'dream'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime(2026, 8, 14),
          sourceCount: 2,
          discoveryCount: 3,
          recencyWeight: 0.9,
        ),
      ],
    );
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: profile,
      now: now,
    )!;
    expect(payload.kind, OraclyNotificationKind.discovery);
    expect(payload.body, contains('değişim'));
    expect(payload.body, isNot(contains('rüya')));
  });

  test('recent OR conversation recommends continuing with OR', () {
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        conversations: [
          ConversationRecord(
            id: 'or1',
            title: 'OR',
            kind: 'general',
            messagesJson: [
              {'role': 'user', 'text': 'gizli sohbet metni'},
            ],
            createdAt: DateTime(2026, 8, 14),
            updatedAt: DateTime(2026, 8, 14, 18),
          ),
        ],
      ),
      now: now,
    );
    final payload = OraclyNotificationPlanner.plan(
      enabled: true,
      profile: profile,
      now: now,
    )!;
    expect(payload.kind, OraclyNotificationKind.companion);
    expect(payload.body, 'OR ile konuşmaya devam edebilirsin.');
    expect(payload.body, isNot(contains('gizli')));
  });

  test('coordinator cancels when disabled and schedules one when enabled',
      () async {
    final port = MemoryNotificationPort();
    final coordinator = OraclyNotificationCoordinator(
      port: port,
      loadProfile: () async => PersonalDiscoveryProfile.empty,
    );
    await coordinator.sync(const PersonalizationSettings());
    expect(port.scheduled, isNull);
    expect(port.cancelCount, 1);

    await coordinator.sync(
      const PersonalizationSettings(notificationsEnabled: true),
    );
    expect(port.scheduled?.kind, OraclyNotificationKind.daily);
    expect(port.scheduled?.body, isNot(contains('/')));
  });

  group('RELIABILITY BATCH 2A — Fix 5: never silently swallowed', () {
    test('successful schedule reports success, not just "no exception"', () async {
      final port = MemoryNotificationPort();
      final coordinator = OraclyNotificationCoordinator(
        port: port,
        loadProfile: () async => PersonalDiscoveryProfile.empty,
      );
      final outcome = await coordinator.sync(
        const PersonalizationSettings(notificationsEnabled: true),
      );
      expect(outcome, OraclyApplyOutcome.success);
    });

    test('a real scheduling failure is reported, not swallowed', () async {
      final port = MemoryNotificationPort()..scheduleShouldFail = true;
      final coordinator = OraclyNotificationCoordinator(
        port: port,
        loadProfile: () async => PersonalDiscoveryProfile.empty,
      );
      final outcome = await coordinator.sync(
        const PersonalizationSettings(notificationsEnabled: true),
      );
      expect(outcome, OraclyApplyOutcome.failure);
      expect(port.scheduled, isNull);
    });

    test('a real cancellation failure is reported, not swallowed', () async {
      final port = MemoryNotificationPort()..cancelShouldFail = true;
      final coordinator = OraclyNotificationCoordinator(
        port: port,
        loadProfile: () async => PersonalDiscoveryProfile.empty,
      );
      final outcome = await coordinator.sync(
        const PersonalizationSettings(),
      );
      expect(outcome, OraclyApplyOutcome.failure);
    });

    test(
      'LocalNotificationPort always cancels the single fixed daily id '
      'before rescheduling — architecturally no duplicate schedule',
      () {
        final source = File(
          'lib/core/notifications/local_notification_port.dart',
        ).readAsStringSync();
        expect(source, contains("static const _id = 4101;"));
        final scheduleBody = source.substring(
          source.indexOf('Future<OraclyApplyOutcome> scheduleDaily'),
        );
        final cancelIndex = scheduleBody.indexOf('_plugin.cancel(id: _id)');
        final zonedScheduleIndex = scheduleBody.indexOf('_plugin.zonedSchedule(');
        expect(cancelIndex, greaterThan(-1));
        expect(zonedScheduleIndex, greaterThan(cancelIndex));
      },
    );
  });
}
