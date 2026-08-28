library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../features/companion/services/companion_session_bootstrap.dart';
import '../../../features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import '../../../features/onboarding/data/onboarding_setup_draft_store.dart';

enum ContinueWhereYouLeftOffKind {
  tarot,
  orChat,
  onboardingProfileSetup,
}

class ContinueWhereYouLeftOffTarget {
  const ContinueWhereYouLeftOffTarget({
    required this.kind,
    required this.updatedAt,
    this.sessionId,
  });

  final ContinueWhereYouLeftOffKind kind;
  final DateTime updatedAt;

  /// Optional identifier for the unfinished experience.
  final String? sessionId;
}

/// One resolver for all safely resumable “continue where you left off” states.
///
/// Decision logic lives here (not in UI widgets).
final continueWhereYouLeftOffProvider =
    FutureProvider<ContinueWhereYouLeftOffTarget?>((ref) async {
  try {
    final storage = ref.read(localStorageProvider);

    // ── Tarot unfinished (active session) ──────────────────────────────
    final tarotRepo = TarotReadingRepositoryImpl.fromStorage(storage);
    final tarotActive = await tarotRepo.loadActiveSession();
    final tarotCandidate = tarotActive == null
        ? null
        : ContinueWhereYouLeftOffTarget(
            kind: ContinueWhereYouLeftOffKind.tarot,
            updatedAt: tarotActive.startedAt,
            sessionId: tarotActive.id,
          );

    // ── OR unfinished (last saved message is a user message) ─────────
    final record = await ref
        .read(aiConversationRepositoryProvider)
        .getById(CompanionSessionBootstrap.sessionId);

    final last = record?.messagesJson.isNotEmpty == true
        ? record!.messagesJson.last
        : null;
    final lastRole = last?['role']?.toString();
    final lastContent = last?['content']?.toString().trim() ?? '';
    final orCandidate = record != null &&
            lastRole == 'user' &&
            lastContent.isNotEmpty
        ? ContinueWhereYouLeftOffTarget(
            kind: ContinueWhereYouLeftOffKind.orChat,
            updatedAt: record.updatedAt,
            sessionId: record.id,
          )
        : null;

    // ── Onboarding profile setup draft ────────────────────────────────
    final onboardingCompleted = await ref
        .read(onboardingRepositoryProvider)
        .isCompleted();
    final draft = OnboardingSetupDraftStore(storage).load();
    final onboardingCandidate = (!onboardingCompleted && draft != null)
        ? ContinueWhereYouLeftOffTarget(
            kind: ContinueWhereYouLeftOffKind.onboardingProfileSetup,
            updatedAt: draft.updatedAt,
          )
        : null;

    final candidates = [
      tarotCandidate,
      orCandidate,
      onboardingCandidate,
    ].whereType<ContinueWhereYouLeftOffTarget>().toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return candidates.first;
  } catch (_) {
    // Fail-closed: if we cannot reliably detect unfinished state,
    // we hide the resume CTA rather than risking wrong resumption.
    return null;
  }
});

