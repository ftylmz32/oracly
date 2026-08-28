/// Read-only snapshot for the privacy control center.
library;

class PrivacyControlSnapshot {
  const PrivacyControlSnapshot({
    required this.profileLabel,
    required this.favoriteCount,
    required this.discoveryCount,
    required this.memorySummary,
    required this.notificationsLabel,
    required this.voiceLabel,
  });

  final String profileLabel;
  final int favoriteCount;
  final int discoveryCount;
  final String memorySummary;
  final String notificationsLabel;
  final String voiceLabel;
}
