/// When Home gently asks to finish the introduction — name or birth date only.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import 'home_invite_preview.dart';
import 'home_invite_store.dart';

/// What the introduction still lacks. Time and city never count.
class HomeInviteGaps {
  const HomeInviteGaps({required this.name, required this.birth});

  final bool name;
  final bool birth;

  bool get any => name || birth;
}

final homeInviteClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

final homeInvitePreviewProvider = FutureProvider<HomeInvitePreview?>(
  (_) => HomeInvitePreview.requested(),
);

/// Preview "Şimdi değil" lives in memory only.
final homeInvitePreviewDismissedProvider = StateProvider<bool>((_) => false);

/// Null until both profile and birth stores have answered — no flash.
final homeInviteGapsProvider = Provider<HomeInviteGaps?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final birth = ref.watch(birthInformationProvider);
  if (profile == null || !birth.hasValue) return null;
  // Without an owner the birth store cannot save; never ask for what won't keep.
  final owner = ref
      .watch(localStorageProvider)
      .getString(UserLocalDataIsolation.ownerKey)
      ?.trim();
  return HomeInviteGaps(
    name: profile.name.trim().isEmpty,
    birth: birth.value == null && owner != null && owner.isNotEmpty,
  );
});

class HomeInviteSnoozeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final storage = ref.watch(localStorageProvider);
    final epoch = UserLocalDataIsolation.accountSwitchEpoch;
    void reread() => ref.invalidateSelf();
    epoch.addListener(reread);
    ref.onDispose(() => epoch.removeListener(reread));
    return HomeInviteStore(storage).until();
  }

  Future<void> dismiss() async {
    final now = ref.read(homeInviteClockProvider)();
    state = await HomeInviteStore(ref.read(localStorageProvider)).dismiss(now);
  }
}

final homeInviteSnoozeProvider =
    NotifierProvider<HomeInviteSnoozeNotifier, DateTime?>(
      HomeInviteSnoozeNotifier.new,
    );

final homeInviteVisibleProvider = Provider<bool>((ref) {
  final preview = ref.watch(homeInvitePreviewProvider).valueOrNull;
  if (preview == HomeInvitePreview.complete) return false;
  if (preview == HomeInvitePreview.guest) {
    return !ref.watch(homeInvitePreviewDismissedProvider);
  }
  // The first reading speaks first; the invite waits its turn.
  if (ref.watch(firstReadingPendingProvider)) return false;
  final gaps = ref.watch(homeInviteGapsProvider);
  if (gaps == null || !gaps.any) return false;
  final until = ref.watch(homeInviteSnoozeProvider);
  final now = ref.watch(homeInviteClockProvider)();
  return until == null || !now.isBefore(until);
});
