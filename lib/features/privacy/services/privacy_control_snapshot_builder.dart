/// Builds read-only privacy snapshot from real stored data.
library;

import '../../../core/domain/models/user_profile.dart';
import '../../../core/intelligence/domain/models/personal_memory_summary.dart';
import '../../../core/intelligence/services/personal_memory_service.dart';
import '../../../core/voice/oracly_voice_copy.dart';
import '../../../core/voice/oracly_voice_id.dart';
import '../../../features/companion/models/or_chat_output_mode.dart';
import '../../../features/favorite_moments/services/favorite_moments_service.dart';
import '../../../features/premium/models/personalization_models.dart';
import '../../../services/memory_service.dart';
import '../copy/privacy_control_copy.dart';
import '../models/privacy_control_snapshot.dart';

abstract final class PrivacyControlSnapshotBuilder {
  PrivacyControlSnapshotBuilder._();

  static Future<PrivacyControlSnapshot> build({
    required FavoriteMomentsService favorites,
    required PersonalMemoryService personalMemory,
    required MemoryService legacyMemory,
    required UserProfileModel profile,
    required PersonalizationSettings settings,
    required int discoveryCount,
    required String languageCode,
  }) async {
    final favoriteItems = await favorites.all();
    final summary = personalMemory.load();
    final legacy = await legacyMemory.getAdvancedMemories();
    final memoryLine = _memorySummary(
      summary,
      legacy.length,
      personalMemory.observationalLine(lang: languageCode),
    );
    final voiceId = OraclyVoiceId.parse(settings.orVoiceId);
    final output = OrChatOutputMode.fromStorage(settings.orOutputMode);
    final voiceLabel = output.isVoice
        ? OraclyVoiceCopy.title(voiceId, languageCode)
        : PrivacyControlCopy.off;

    return PrivacyControlSnapshot(
      profileLabel: _profileLabel(profile),
      favoriteCount: favoriteItems.length,
      discoveryCount: discoveryCount,
      memorySummary: memoryLine,
      notificationsLabel: settings.notificationsEnabled
          ? PrivacyControlCopy.on
          : PrivacyControlCopy.off,
      voiceLabel: voiceLabel,
    );
  }

  static String _profileLabel(UserProfileModel profile) {
    final name = profile.name.trim();
    if (name.isNotEmpty) return name;
    final job = profile.job.trim();
    if (job.isNotEmpty) return job;
    return PrivacyControlCopy.empty;
  }

  static String _memorySummary(
    PersonalMemorySummary summary,
    int legacyCount,
    String? observationalLine,
  ) {
    final trimmed = observationalLine?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (summary.isEmpty && legacyCount == 0) {
      return PrivacyControlCopy.memoryEmpty;
    }
    final themes = summary.themes
        .take(2)
        .map((t) => t.label)
        .where((label) => label.isNotEmpty);
    if (themes.isNotEmpty) return themes.join(' · ');
    if (summary.latestMeaningfulDiscovery?.trim().isNotEmpty == true) {
      return summary.latestMeaningfulDiscovery!.trim();
    }
    if (legacyCount > 0) return PrivacyControlCopy.count(legacyCount);
    return PrivacyControlCopy.memoryEmpty;
  }
}
