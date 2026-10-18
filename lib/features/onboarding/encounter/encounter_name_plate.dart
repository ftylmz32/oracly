/// The journal plate is the only name field. No second frame.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/copy/onboarding_copy.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/theme/reading_typography.dart';

class EncounterNamePlate extends StatelessWidget {
  const EncounterNamePlate({super.key, required this.controller});

  final TextEditingController controller;

  static const _image = Size(720, 1280);
  static const _plate = Rect.fromLTRB(158, 768, 640, 884);

  @override
  Widget build(BuildContext context) {
    final keyboard = View.of(context).viewInsets.bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final view = Size(constraints.maxWidth, constraints.maxHeight);
        final alignment = keyboard ? _keyboardAlignment(view) : Alignment.center;
        final field = _fieldRect(view, alignment, keyboard: keyboard);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.encounterJournal,
              fit: BoxFit.cover,
              alignment: alignment,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF07060E)),
            ),
            Positioned.fromRect(
              rect: field,
              child: _Inscription(controller: controller),
            ),
          ],
        );
      },
    );
  }

  static Alignment _keyboardAlignment(Size view) {
    final scale = math.max(view.width / _image.width, view.height / _image.height);
    final sourceH = view.height / scale;
    final overflow = _image.height - sourceH;
    if (overflow <= 1) return Alignment.center;
    const plateCenter = 826.0;
    final target = view.height * 0.28;
    final sourceTop = plateCenter - (target / view.height) * sourceH;
    final y = ((sourceTop / overflow) * 2 - 1).clamp(-1.0, 1.0).toDouble();
    return Alignment(0, y);
  }

  static Rect _fieldRect(Size view, Alignment alignment, {required bool keyboard}) {
    final scale = math.max(view.width / _image.width, view.height / _image.height);
    final source = Size(view.width / scale, view.height / scale);
    final window = alignment.inscribe(source, Offset.zero & _image);
    double mapX(double x) => (x - window.left) / window.width * view.width;
    double mapY(double y) => (y - window.top) / window.height * view.height;
    var raw = Rect.fromLTRB(
      mapX(_plate.left),
      mapY(_plate.top),
      mapX(_plate.right),
      mapY(_plate.bottom),
    ).deflate(8);
    final reserve = keyboard ? math.min(168.0, view.height * 0.42) : 96.0;
    if (raw.bottom > view.height - reserve) {
      raw = raw.shift(Offset(0, view.height - reserve - raw.bottom));
    }
    if (raw.top < 8) raw = raw.shift(Offset(0, 8 - raw.top));
    final left = raw.left.clamp(12.0, math.max(12.0, view.width - 96)).toDouble();
    final width = math.min(raw.width, view.width - left - 12);
    final height = raw.height.clamp(36.0, 96.0).toDouble();
    return Rect.fromLTWH(left, raw.top, width, height);
  }
}

class _Inscription extends StatelessWidget {
  const _Inscription({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: OnboardingCopy.nameField,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        textCapitalization: TextCapitalization.words,
        maxLines: 1,
        cursorColor: AppColors.goldLight,
        style: ReadingTypography.reflection(color: AppColors.goldLight)
            .copyWith(fontSize: 26, height: 1.1, shadows: const [
          Shadow(color: Color(0x66000000), blurRadius: 6),
        ]),
        decoration: InputDecoration(
          hintText: OnboardingCopy.nameField,
          hintStyle: ReadingTypography.reflection(
            color: AppColors.goldDeep.withValues(alpha: 0.85),
          ).copyWith(fontSize: 22, height: 1.1),
          filled: false,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
