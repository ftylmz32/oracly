/// OR-404 — Ceremonial confirm button for intention ritual.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class IntentionSelectionFooter extends StatefulWidget {
  const IntentionSelectionFooter({
    super.key,
    required this.enabled,
    required this.onConfirm,
  });

  final bool enabled;
  final VoidCallback? onConfirm;

  static const String _label = 'Niyetimi Mühürle';

  @override
  State<IntentionSelectionFooter> createState() =>
      _IntentionSelectionFooterState();
}

class _IntentionSelectionFooterState extends State<IntentionSelectionFooter> {
  bool _pressed = false;

  static const _pressDuration = OraclySignatureMotion.press;
  static const _pressRelease = OraclySignatureMotion.pressRelease;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final enabled = widget.enabled && widget.onConfirm != null;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.88),
                AppColors.background.withValues(alpha: 0.96),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.14),
                width: AppBorderWidth.hairline,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md + bottom,
            ),
            child: GestureDetector(
              onTap: enabled ? widget.onConfirm : null,
              onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
              child: AnimatedScale(
                scale: _pressed ? OraclySignatureMotion.pressScale : 1.0,
                duration: _pressed ? _pressDuration : _pressRelease,
                curve: _pressed
                    ? OraclySignatureMotion.curve
                    : OraclySignatureMotion.releaseCurve,
                child: AnimatedOpacity(
                  opacity: _pressed ? OraclySignatureMotion.pressOpacity : 1.0,
                  duration: _pressed ? _pressDuration : _pressRelease,
                  curve: _pressed
                      ? OraclySignatureMotion.curve
                      : OraclySignatureMotion.releaseCurve,
                  child: AnimatedContainer(
                  duration: _pressDuration,
                  height: AppSpacing.xxl + AppSpacing.sm,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.round,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: enabled
                          ? [
                              AppColors.goldLight,
                              AppColors.gold,
                              const Color(0xFFB8862E),
                            ]
                          : [
                              AppColors.goldLight.withValues(alpha: 0.28),
                              AppColors.gold.withValues(alpha: 0.28),
                            ],
                    ),
                    border: Border.all(
                      color: AppColors.goldLight.withValues(
                        alpha: enabled ? 0.55 : 0.18,
                      ),
                      width: AppBorderWidth.hairline,
                    ),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(
                                alpha: _pressed ? 0.26 : 0.38,
                              ),
                              blurRadius: _pressed ? 14 : 22,
                              offset: Offset(0, _pressed ? 2 : 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.transparent,
                                AppColors.white.withValues(alpha: 0.32),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: AppSpacing.md,
                            color: enabled
                                ? const Color(0xFF12071F)
                                : AppColors.textHint,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            IntentionSelectionFooter._label,
                            style: TextStyle(
                              color: enabled
                                  ? const Color(0xFF12071F)
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
