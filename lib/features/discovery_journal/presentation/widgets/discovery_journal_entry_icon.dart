/// Maps a journal kind to a quiet archival icon.
library;

import 'package:flutter/material.dart';

import '../../models/discovery_journal_kind.dart';

abstract final class DiscoveryJournalEntryIcon {
  DiscoveryJournalEntryIcon._();

  static DiscoveryJournalKind? fromSource(String raw) => switch (raw) {
        'tarot' => DiscoveryJournalKind.tarot,
        'dream' => DiscoveryJournalKind.dream,
        'coffee' => DiscoveryJournalKind.coffee,
        'reflection' => DiscoveryJournalKind.companion,
        'palm' => DiscoveryJournalKind.palm,
        'astrology' => DiscoveryJournalKind.astrology,
        'star' || 'starMap' || 'star_map' => DiscoveryJournalKind.starMap,
        'daily' || 'dailyMessage' => DiscoveryJournalKind.dailyMessage,
        _ => null,
      };

  static IconData of(DiscoveryJournalKind kind) => switch (kind) {
        DiscoveryJournalKind.tarot => Icons.style_outlined,
        DiscoveryJournalKind.dream => Icons.nights_stay_outlined,
        DiscoveryJournalKind.coffee => Icons.coffee_outlined,
        DiscoveryJournalKind.companion => Icons.auto_awesome_outlined,
        DiscoveryJournalKind.palm => Icons.back_hand_outlined,
        DiscoveryJournalKind.astrology => Icons.brightness_2_outlined,
        DiscoveryJournalKind.starMap => Icons.blur_circular_outlined,
        DiscoveryJournalKind.dailyMessage => Icons.wb_twilight_outlined,
      };
}
