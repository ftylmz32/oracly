/// Compact birth-info form shown when no saved chart exists.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/oracly_format.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/birth_chart_copy.dart';
import '../../models/birth_profile.dart';
import 'birth_chart_birth_pickers.dart';
import 'birth_chart_city_picker.dart';
import 'birth_chart_onboarding_actions.dart';
import 'birth_chart_onboarding_draft.dart';
import 'birth_chart_onboarding_form.dart';

class BirthChartOnboardingView extends StatefulWidget {
  const BirthChartOnboardingView({
    super.key,
    this.initialProfile,
    this.isEditing = false,
    required this.onSubmit,
    this.onCancel,
  });

  final BirthProfile? initialProfile;
  final bool isEditing;
  final Future<void> Function(BirthProfile profile) onSubmit;
  final VoidCallback? onCancel;

  @override
  State<BirthChartOnboardingView> createState() =>
      _BirthChartOnboardingViewState();
}

class _BirthChartOnboardingViewState extends State<BirthChartOnboardingView> {
  final _draft = BirthChartOnboardingDraft();

  @override
  void initState() {
    super.initState();
    _draft.apply(widget.initialProfile);
  }

  @override
  void didUpdateWidget(covariant BirthChartOnboardingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile != widget.initialProfile) {
      _draft.apply(widget.initialProfile);
    }
  }

  Future<void> _pickDate() async {
    final v = await pickBirthDate(context, current: _draft.date);
    if (v != null) setState(() => _draft.date = v);
  }

  Future<void> _pickTime() async {
    if (_draft.timeKnown != true) return;
    final v = await pickBirthTime(context, current: _draft.time);
    if (v != null) setState(() => _draft.time = v);
  }

  Future<void> _pickCity() async {
    final v = await showBirthChartCityPicker(context, selected: _draft.city);
    if (v != null) setState(() => _draft.setCity(v));
  }

  Future<void> _submit() async {
    final error = _draft.validate();
    if (error != null) {
      OraclySnackBar.show(context, message: error);
      return;
    }
    await widget.onSubmit(_draft.buildProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BirthChartOnboardingForm(
      dateLabel: _draft.date == null
          ? BirthChartCopy.selectValue
          : OraclyFormat.date(_draft.date!),
      timeLabel: _draft.timeLabel(context),
      placeLabel: _draft.placeLabel(),
      submitLabel: widget.isEditing
          ? BirthChartCopy.updateChart
          : BirthChartCopy.generateChart,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onPickPlace: _pickCity,
      onSkipPlace: () => setState(_draft.skipPlace),
      placeSkipped: _draft.placeUnknown,
      onSubmit: _submit,
      onCancel: widget.onCancel,
      timeKnown: _draft.timeKnown,
      onTimeKnown: () => setState(() => _draft.setTimeKnown(true)),
      onTimeUnknown: () => setState(() => _draft.setTimeKnown(false)),
      showTimeField: _draft.timeKnown == true,
      timeNote: _draft.timeNote(),
      showReview: _draft.date != null,
      reviewTimeLabel: BirthChartOnboardingActions.reviewTimeLabel(
        timeKnown: _draft.timeKnown,
        time: _draft.time,
      ),
    );
  }
}
