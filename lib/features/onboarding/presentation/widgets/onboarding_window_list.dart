/// Soft discovery-window chips — short labels, subtle stagger.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';

class OnboardingWindowList extends StatefulWidget {
  const OnboardingWindowList({super.key, required this.labels});

  final List<String> labels;

  @override
  State<OnboardingWindowList> createState() => _OnboardingWindowListState();
}

class _OnboardingWindowListState extends State<OnboardingWindowList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: AppMotionDuration.medium,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (OraclyReducedMotion.of(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < widget.labels.length; i++)
          _WindowChip(
            label: widget.labels[i],
            animation: _enter,
            index: i,
            total: widget.labels.length,
          ),
      ],
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.animation,
    required this.index,
    required this.total,
  });

  final String label;
  final Animation<double> animation;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final start = (index / (total + 1)).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: AppMotionCurve.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: OraclyChrome.midnight.withValues(alpha: 0.42),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
