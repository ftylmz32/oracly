/// Small Home invite: finish the introduction, or quietly not now.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../../onboarding/encounter/encounter_complete_screen.dart';
import '../reference/home_reference_card_shell.dart';
import '../reference/home_reference_tokens.dart';
import 'home_invite_copy.dart';
import 'home_invite_preview.dart';
import 'home_invite_providers.dart';

class HomeInviteCard extends ConsumerWidget {
  const HomeInviteCard({super.key});

  bool _preview(WidgetRef ref) =>
      ref.read(homeInvitePreviewProvider).valueOrNull ==
      HomeInvitePreview.guest;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final preview = _preview(ref);
    final gaps = ref.read(homeInviteGapsProvider);
    // Full screen above the tab bar, like the first encounter.
    await Navigator.of(context, rootNavigator: true).push(
      OraclyPageTransitions.fade(
        page: EncounterCompleteScreen(
          askName: preview || (gaps?.name ?? true),
          askBirth: preview || (gaps?.birth ?? true),
          preview: preview,
        ),
      ),
    );
  }

  Future<void> _later(WidgetRef ref) async {
    if (_preview(ref)) {
      ref.read(homeInvitePreviewDismissedProvider.notifier).state = true;
      return;
    }
    await ref.read(homeInviteSnoozeProvider.notifier).dismiss();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(homeInviteVisibleProvider)) return const SizedBox.shrink();
    final compact = MediaQuery.sizeOf(context).height < 720;
    final gold = OraclyA11y.goldReadable(OraclyChrome.goldLight);
    return Padding(
      padding: EdgeInsets.only(top: compact ? 8 : 10),
      child: Semantics(
        container: true,
        label: '${HomeInviteCopy.title}. ${HomeInviteCopy.body}',
        child: HomeReferenceCardShell(
          key: const ValueKey('home-invite-card'),
          premium: false,
          glowStrength: 0.72,
          borderRadius: HomeReferenceTokens.orGuideRadius,
          padding: EdgeInsets.fromLTRB(14, compact ? 12 : 14, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.55),
                        ),
                        image: const DecorationImage(
                          image: AssetImage(AppAssets.encounterSky),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HomeInviteCopy.title,
                          style: ReadingTypography.reflection(
                            color: gold,
                          ).copyWith(fontSize: compact ? 16 : 17, height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HomeInviteCopy.body,
                          style:
                              ReadingTypography.bodyCore(
                                color: OraclyChrome.cream.withValues(
                                  alpha: 0.86,
                                ),
                              ).copyWith(
                                fontSize: compact ? 12.5 : 13,
                                height: 1.38,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  _Action(
                    label: HomeInviteCopy.later,
                    color: OraclyChrome.cream.withValues(alpha: 0.62),
                    onTap: () => _later(ref),
                  ),
                  _Action(
                    label: HomeInviteCopy.cta,
                    color: gold,
                    strong: true,
                    onTap: () => _open(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            widthFactor: 1,
            child: Container(
              padding: strong
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: strong
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withValues(alpha: 0.7)),
                      color: OraclyChrome.goldLight.withValues(alpha: 0.10),
                    )
                  : null,
              child: Text(
                label,
                style: ReadingTypography.bodyCore(color: color).copyWith(
                  fontSize: 13,
                  letterSpacing: 0.3,
                  fontStyle: FontStyle.normal,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
