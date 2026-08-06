import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/memory_item.dart';
import 'sections/daily_insight_section.dart';
import 'sections/greeting_section.dart';
import 'sections/memory_section.dart';
import 'sections/quick_actions_section.dart';
import 'sections/recent_section.dart';
import 'sections/spirit_orb_section.dart';
import 'widgets/home_cinematic_background.dart';
import 'widgets/home_entrance.dart';

class HomeView extends StatefulWidget {
  final String greeting;
  final String message;
  final List<MemoryItem> memories;
  final String? lastConversation;

  const HomeView({
    super.key,
    required this.greeting,
    required this.message,
    required this.memories,
    this.lastConversation,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeOutQuart),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: HomeCinematicBackground(
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GreetingSection(
                        greeting: widget.greeting,
                        message: widget.message,
                      ),
                      const SizedBox(height: 8),
                      HomeEntrance(
                        delay: Duration.zero,
                        child: const SpiritOrbSection(),
                      ),
                      const SizedBox(height: 36),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 120),
                        child: const DailyInsightSection(),
                      ),
                      const SizedBox(height: 52),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 220),
                        child: const QuickActionsSection(),
                      ),
                      const SizedBox(height: 48),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: MemorySection(memories: widget.memories),
                      ),
                      const SizedBox(height: 44),
                      HomeEntrance(
                        delay: const Duration(milliseconds: 420),
                        child: RecentSection(
                          lastConversation: widget.lastConversation,
                        ),
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
