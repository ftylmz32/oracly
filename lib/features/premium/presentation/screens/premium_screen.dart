/// OR-1090 — Luxury OR Premium membership screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/copy/premium_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tarot/theme/tarot_tokens.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_benefits_grid.dart';
import '../widgets/premium_hero_section.dart';
import '../widgets/premium_unavailable_notice.dart';

/// Premium membership experience — purchase CTA disabled until real store IAP.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _loadState();
  }

  Future<void> _loadState() async {
    final active = await ref.read(premiumServiceProvider).isActive();
    if (!mounted) return;
    setState(() => _isPremium = active);
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final master = Curves.easeOutCubic.transform(_entrance.value);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background.withValues(alpha: 0.72),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.goldLight,
                  ),
                ),
                title: Text(
                  'Üyelik',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.goldLight,
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: TarotTokens.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppSpacing.md),
                        PremiumHeroSection(
                          entrance: premiumSectionEntrance(0, master),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        PremiumBenefitsGrid(
                          entrance: premiumSectionEntrance(1, master),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        if (_isPremium)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              PremiumCopy.ctaActive,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          )
                        else
                          PremiumUnavailableNotice(
                            entrance: premiumSectionEntrance(2, master),
                          ),
                        SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fade route for premium screen.
Route<T> premiumScreenRoute<T>({RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const PremiumScreen();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
        child: child,
      );
    },
  );
}
