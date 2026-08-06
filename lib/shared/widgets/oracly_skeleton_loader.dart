/// OR-1100 — Premium glass shimmer skeleton loader.
library;

import 'dart:math' show sin;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/copy/resilience_copy.dart';

import 'oracly_error_state.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Glass shimmer skeleton — particles-friendly loading surface.
class OraclySkeletonLoader extends StatefulWidget {
  const OraclySkeletonLoader({
    super.key,
    this.message = 'Evren dinleniyor...',
    this.lines = 3,
  });

  final String message;
  final int lines;

  @override
  State<OraclySkeletonLoader> createState() => _OraclySkeletonLoaderState();
}

class _OraclySkeletonLoaderState extends State<OraclySkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            final phase = _shimmer.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        borderRadius: AppRadius.lg,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      child: Padding(
                        padding: AppSpacing.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ShimmerBar(phase: phase, widthFactor: 0.55),
                            SizedBox(height: AppSpacing.md),
                            for (var i = 0; i < widget.lines; i++) ...[
                              if (i > 0) SizedBox(height: AppSpacing.sm),
                              _ShimmerBar(
                                phase: phase + i * 0.15,
                                widthFactor: i == widget.lines - 1 ? 0.65 : 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.phase, required this.widthFactor});

  final double phase;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final tw = 0.35 + sin(phase * 6.28) * 0.25 + 0.4;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: AppSpacing.sm + 2,
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.08 * tw),
              AppColors.goldLight.withValues(alpha: 0.22 * tw),
              AppColors.gold.withValues(alpha: 0.08 * tw),
            ],
          ),
        ),
      ),
    );
  }
}

/// Async wrapper with skeleton / error / data states.
class OraclyAsyncView<T> extends StatelessWidget {
  const OraclyAsyncView({
    super.key,
    required this.state,
    required this.builder,
    this.loadingMessage,
    this.onRetry,
  });

  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final String? loadingMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => OraclySkeletonLoader(
        message: loadingMessage ?? ResilienceCopy.genericLoading,
      ),
      error: (e, _) => OraclyErrorState(
        message: ResilienceCopy.genericLoadFailed,
        onRetry: onRetry,
      ),
      data: builder,
    );
  }
}
