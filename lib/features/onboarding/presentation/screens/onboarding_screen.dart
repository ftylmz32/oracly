/// OR-1120 — Premium first-launch onboarding flow.

library;



import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../app/providers/app_providers.dart';

import '../../../../core/copy/onboarding_copy.dart';

import '../../../../core/first_session/first_session_intent.dart';

import '../../../../core/navigation/oracly_page_transitions.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/navigation/oracly_navigation.dart';

import '../../../../shared/widgets/oracly_button.dart';

import '../../../../widgets/cosmic_background.dart';

import '../widgets/onboarding_page.dart';



class OnboardingScreen extends ConsumerStatefulWidget {

  const OnboardingScreen({super.key});



  @override

  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();

}



class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {

  final PageController _pageController = PageController();

  int _index = 0;



  static final _pages = OnboardingCopy.pages;



  bool get _isLast => _index == _pages.length - 1;



  Future<void> _complete() async {

    await ref.read(onboardingRepositoryProvider).markCompleted();

    FirstSessionIntent.requestFirstReading();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(

      OraclyPageTransitions.fade(

        page: const OraclyAppShell(initialTab: OraclyTab.tarot),

      ),

    );

  }



  void _next() {

    if (_isLast) {

      _complete();

      return;

    }

    _pageController.nextPage(

      duration: AppDuration.normal,

      curve: Curves.easeOutCubic,

    );

  }



  void _skip() => _complete();



  @override

  void initState() {

    super.initState();

    _pageController.addListener(() {

      if (mounted) setState(() {});

    });

  }



  double _pageProgress(int index) {

    if (!_pageController.hasClients) return index == _index ? 1.0 : 0.0;

    final page = _pageController.page ?? _index.toDouble();

    return (1 - (page - index).abs()).clamp(0.0, 1.0);

  }



  @override

  void dispose() {

    _pageController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return CosmicBackground(

      showHeroGlow: true,

      child: Scaffold(

        backgroundColor: Colors.transparent,

        body: SafeArea(

          child: Column(

            children: [

              Padding(

                padding: EdgeInsets.symmetric(

                  horizontal: AppSpacing.md,

                  vertical: AppSpacing.sm,

                ),

                child: Row(

                  children: [

                    if (!_isLast)

                      TextButton(

                        onPressed: _skip,

                        child: Text(

                          OnboardingCopy.skip,

                          style: AppTextStyles.labelMedium.copyWith(

                            color: AppColors.textHint,

                          ),

                        ),

                      )

                    else

                      const SizedBox(width: 64),

                    Expanded(

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: List.generate(_pages.length, (i) {

                          final active = i == _index;

                          return AnimatedContainer(

                            duration: Duration(

                              milliseconds: AppDuration.fast.inMilliseconds +

                                  (i % 3) * 17,

                            ),

                            margin: EdgeInsets.symmetric(

                              horizontal: AppSpacing.xs / 2,

                            ),

                            width: active ? 22 + (i % 2) : 8,

                            height: 8 + (i % 3) * 0.5,

                            decoration: BoxDecoration(

                              borderRadius: AppRadius.round,

                              color: active

                                  ? AppColors.gold

                                  : AppColors.gold.withValues(alpha: 0.25),

                            ),

                          );

                        }),

                      ),

                    ),

                    const SizedBox(width: 64),

                  ],

                ),

              ),

              Expanded(

                child: PageView.builder(

                  controller: _pageController,

                  itemCount: _pages.length,

                  onPageChanged: (i) => setState(() => _index = i),

                  itemBuilder: (context, index) {

                    return OnboardingPage(

                      data: _pages[index],

                      progress: _pageProgress(index),

                    );

                  },

                ),

              ),

              Padding(

                padding: EdgeInsets.fromLTRB(

                  AppSpacing.lg,

                  AppSpacing.sm,

                  AppSpacing.lg,

                  AppSpacing.lg,

                ),

                child: OraclyButton(

                  text: _isLast

                      ? OnboardingCopy.startFirstReading

                      : OnboardingCopy.continueLabel,

                  isExpanded: true,

                  icon: _isLast ? Icons.arrow_forward_rounded : null,

                  onPressed: _next,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


