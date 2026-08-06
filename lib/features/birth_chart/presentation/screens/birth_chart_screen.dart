/// SPRINT-002 — Complete Birth Chart journey.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/home/widgets/home_cinematic_background.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../controllers/birth_chart_controller.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_profile.dart';
import '../../providers/birth_chart_providers.dart';
import '../widgets/chart_insight_panel.dart';
import '../widgets/chart_journey_progress.dart';

class BirthChartScreen extends ConsumerStatefulWidget {
  const BirthChartScreen({super.key});

  @override
  ConsumerState<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends ConsumerState<BirthChartScreen> {
  final _placeController = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  var _timeUnknown = false;

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.gold,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthTime = picked;
        _timeUnknown = false;
      });
    }
  }

  Future<void> _submit(BirthChartController controller) async {
    if (_birthDate == null) {
      OraclySnackBar.show(context, message: BirthChartCopy.birthDateRequired);
      return;
    }
    final place = _placeController.text.trim();
    if (place.isEmpty) {
      OraclySnackBar.show(context, message: BirthChartCopy.birthPlaceRequired);
      return;
    }

    DateTime? birthTime;
    if (!_timeUnknown && _birthTime != null) {
      birthTime = DateTime(
        _birthDate!.year,
        _birthDate!.month,
        _birthDate!.day,
        _birthTime!.hour,
        _birthTime!.minute,
      );
    }

    await controller.generate(
      BirthProfile(
        birthDate: _birthDate!,
        birthPlace: place,
        birthTime: birthTime,
        birthTimeKnown: !_timeUnknown && _birthTime != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(birthChartControllerProvider);

    return OraclyScaffold(
      backgroundOverlay: const HomeCosmicBackground(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(BirthChartCopy.screenTitle),
        centerTitle: true,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        child: switch (controller.phase) {
          BirthChartPhase.onboarding => _OnboardingView(
              key: const ValueKey('onboarding'),
              birthDate: _birthDate,
              birthTime: _birthTime,
              timeUnknown: _timeUnknown,
              placeController: _placeController,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
              onTimeUnknownChanged: (v) => setState(() {
                _timeUnknown = v;
                if (v) _birthTime = null;
              }),
              onSubmit: () => _submit(controller),
            ),
          BirthChartPhase.generating => _LoadingView(
              key: const ValueKey('generating'),
              message: BirthChartCopy.generating,
            ),
          BirthChartPhase.journey => _JourneyView(
              key: ValueKey('journey-${controller.stepIndex}'),
              controller: controller,
            ),
          BirthChartPhase.complete => _CompleteView(
              key: const ValueKey('complete'),
              onDone: () => Navigator.of(context).pop(),
              onNewChart: controller.reset,
            ),
          BirthChartPhase.error => _ErrorView(
              key: const ValueKey('error'),
              message: controller.errorMessage ?? BirthChartCopy.generating,
              onRetry: () => _submit(controller),
              onBack: controller.reset,
            ),
        },
      ),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    super.key,
    required this.birthDate,
    required this.birthTime,
    required this.timeUnknown,
    required this.placeController,
    required this.onPickDate,
    required this.onPickTime,
    required this.onTimeUnknownChanged,
    required this.onSubmit,
  });

  final DateTime? birthDate;
  final TimeOfDay? birthTime;
  final bool timeUnknown;
  final TextEditingController placeController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<bool> onTimeUnknownChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            BirthChartCopy.onboardingHeadline,
            style: ReadingTypography.cardTitle(),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            BirthChartCopy.onboardingDescription,
            style: ReadingTypography.opening(),
          ),
          SizedBox(height: AppSpacing.lg),
          _FieldButton(
            label: BirthChartCopy.birthDateLabel,
            value: birthDate == null
                ? 'Seç'
                : '${birthDate!.day}.${birthDate!.month}.${birthDate!.year}',
            onTap: onPickDate,
          ),
          SizedBox(height: AppSpacing.sm),
          _FieldButton(
            label: BirthChartCopy.birthTimeLabel,
            value: timeUnknown
                ? BirthChartCopy.birthTimeUnknown
                : birthTime?.format(context) ?? 'Seç',
            onTap: timeUnknown ? null : onPickTime,
            muted: timeUnknown,
          ),
          CheckboxListTile(
            value: timeUnknown,
            onChanged: (v) => onTimeUnknownChanged(v ?? false),
            title: Text(
              BirthChartCopy.birthTimeUnknown,
              style: ReadingTypography.bodySmall(),
            ),
            activeColor: AppColors.gold,
            contentPadding: EdgeInsets.zero,
          ),
          if (timeUnknown)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                BirthChartCopy.birthTimeUnknownNote,
                style: ReadingTypography.footnote(),
              ),
            ),
          TextField(
            controller: placeController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: BirthChartCopy.birthPlaceLabel,
              hintText: BirthChartCopy.birthPlaceHint,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.65),
              border: OutlineInputBorder(borderRadius: AppRadius.md),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          OraclyButton(
            text: BirthChartCopy.generateChart,
            isExpanded: true,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _JourneyView extends StatelessWidget {
  const _JourneyView({super.key, required this.controller});

  final BirthChartController controller;

  @override
  Widget build(BuildContext context) {
    final insight = controller.currentInsight;
    final chart = controller.chart;
    if (insight == null || chart == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartJourneyProgress(
            current: controller.stepIndex,
            total: chart.insights.length,
          ),
          SizedBox(height: AppSpacing.lg),
          ChartInsightPanel(insight: insight, chart: chart),
          SizedBox(height: AppSpacing.xl),
          OraclyButton(
            text: controller.isLastStep
                ? BirthChartCopy.finishJourney
                : BirthChartCopy.continueJourney,
            isExpanded: true,
            onPressed: controller.nextStep,
          ),
          if (controller.stepIndex > 0) ...[
            SizedBox(height: AppSpacing.sm),
            OraclyButton(
              text: 'Geri',
              type: OraclyButtonType.ghost,
              isExpanded: true,
              onPressed: controller.previousStep,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    super.key,
    required this.onDone,
    required this.onNewChart,
  });

  final VoidCallback onDone;
  final VoidCallback onNewChart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Yolculuk tamamlandı',
            style: ReadingTypography.cardTitle(),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            BirthChartCopy.closingNote,
            style: ReadingTypography.closing(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          OraclyButton(text: 'Kapat', isExpanded: true, onPressed: onDone),
          SizedBox(height: AppSpacing.sm),
          OraclyButton(
            text: 'Yeni harita',
            type: OraclyButtonType.ghost,
            isExpanded: true,
            onPressed: onNewChart,
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ChamberWaitingOrb(),
          SizedBox(height: AppSpacing.lg),
          Text(message, style: ReadingTypography.bodyCore()),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: ReadingTypography.bodyCore()),
            SizedBox(height: AppSpacing.lg),
            OraclyButton(text: 'Tekrar dene', onPressed: onRetry),
            SizedBox(height: AppSpacing.sm),
            OraclyButton(
              text: 'Geri',
              type: OraclyButtonType.ghost,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.65),
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: muted
                            ? AppColors.textHint
                            : AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gold.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
