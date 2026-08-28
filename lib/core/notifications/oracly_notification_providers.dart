/// Riverpod wiring for the device notification sink.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../features/personal_discovery/providers/personal_discovery_providers.dart';
import 'local_notification_port.dart';
import 'oracly_notification_coordinator.dart';
import 'oracly_notification_port.dart';

final oraclyNotificationPortProvider = Provider<OraclyNotificationPort>((ref) {
  return LocalNotificationPort();
});

final oraclyNotificationCoordinatorProvider =
    Provider<OraclyNotificationCoordinator>((ref) {
  return OraclyNotificationCoordinator(
    port: ref.watch(oraclyNotificationPortProvider),
    loadProfile: () async {
      try {
        return await ref.read(personalDiscoveryProfileProvider.future);
      } catch (_) {
        return PersonalDiscoveryProfile.empty;
      }
    },
  );
});
