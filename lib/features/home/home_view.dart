import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/memory_item.dart';
import '../../widgets/cosmic_background.dart';
import 'widgets/home_entrance.dart';
import 'sections/energy_section.dart';
import 'sections/greeting_section.dart';
import 'sections/home_header_section.dart';
import 'sections/memory_section.dart';
import 'sections/quick_actions_section.dart';

class HomeView extends StatelessWidget {
  final String greeting;
  final String message;
  final List<MemoryItem> memories;

  const HomeView({
    super.key,
    required this.greeting,
    required this.message,
    required this.memories,
  });

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CosmicBackground(
        showParticles: true,
        showHeroGlow: true,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HomeEntrance(
                        delay: Duration.zero,
                        child: const HomeHeaderSection(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: GreetingSection(
                          greeting: greeting,
                          message: message,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: MemorySection(
                          memories: memories,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: const EnergySection(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: const QuickActionsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
