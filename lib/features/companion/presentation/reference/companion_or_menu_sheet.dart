/// OR header menu — functional actions only.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/companion_copy.dart';
import '../../providers/companion_providers.dart';
import '../../../premium/providers/premium_providers.dart';
import 'companion_or_menu_row.dart';

Future<void> showCompanionOrMenu(
  BuildContext context, {
  VoidCallback? onPremiumTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final controller = ref.read(companionControllerProvider);
          final hasReading = controller.readingContext != null;
          final isPremium = ref.watch(premiumStatusProvider).isPremium;
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF120E18).withValues(alpha: 0.94),
                  border: Border(
                    top: BorderSide(
                      color: OraclyChrome.gold.withValues(alpha: 0.18),
                      width: 0.6,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: OraclyChrome.cream.withValues(alpha: 0.14),
                          ),
                          child: const SizedBox(width: 36, height: 4),
                        ),
                        SizedBox(height: AppSpacing.md),
                        CompanionOrMenuRow(
                          label: CompanionCopy.menuNewChat,
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await controller.startFreshConversation();
                          },
                        ),
                        if (hasReading)
                          CompanionOrMenuRow(
                            label: CompanionCopy.menuRemoveReading,
                            icon: Icons.link_off_rounded,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              controller.clearReadingContext();
                              OraclySnackBar.show(
                                context,
                                message: CompanionCopy.contextCleared,
                              );
                            },
                          ),
                        if (!isPremium)
                          CompanionOrMenuRow(
                            label: CompanionCopy.menuPremium,
                            icon: Icons.auto_awesome_outlined,
                            premium: true,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              (onPremiumTap ??
                                      () => OraclyNavigationService.openPremium(
                                            context,
                                          ))();
                            },
                          ),
                        CompanionOrMenuRow(
                          label: CompanionCopy.menuSettings,
                          icon: Icons.tune_rounded,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            OraclyNavigationService.openSettings(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
