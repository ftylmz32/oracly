import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'tarot_oracle_header.dart';

class TarotReadingSection extends StatefulWidget {
  const TarotReadingSection({
    super.key,
    required this.loading,
    required this.reading,
  });

  final bool loading;
  final String reading;

  @override
  State<TarotReadingSection> createState() =>
      _TarotReadingSectionState();
}

class _TarotReadingSectionState extends State<TarotReadingSection> {
  double _contentOpacity = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.loading) _contentOpacity = 1;
  }

  @override
  void didUpdateWidget(covariant TarotReadingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading && !widget.loading) {
      Future.microtask(() {
        if (mounted) setState(() => _contentOpacity = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.glass,
              color: AppColors.surfaceDark.withValues(alpha: .62),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              child: widget.loading ? _buildLoading() : _buildReading(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.gold.withValues(alpha: .5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Yorum hazırlanıyor',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReading() {
    return AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOut,
      child: Column(
        children: [
          const TarotOracleHeader(),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.reading,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: .92),
                  fontSize: 15,
                  height: 1.85,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
