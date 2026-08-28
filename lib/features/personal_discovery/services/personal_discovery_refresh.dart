/// Invalidate derived discovery state after real record changes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery_journal/providers/discovery_journal_providers.dart';
import '../providers/personal_discovery_providers.dart';

abstract final class PersonalDiscoveryRefresh {
  PersonalDiscoveryRefresh._();

  static void invalidate(WidgetRef ref) {
    ref.invalidate(personalDiscoveryProfileProvider);
    ref.invalidate(discoveryJournalEntriesProvider);
  }
}
