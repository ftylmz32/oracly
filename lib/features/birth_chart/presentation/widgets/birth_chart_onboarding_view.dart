/// Compact birth-info form shown when no saved chart exists.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/oracly_format.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../copy/birth_chart_copy.dart';
import '../../data/birth_chart_cities.dart';
import '../../models/birth_profile.dart';
import 'birth_chart_birth_pickers.dart';
import 'birth_chart_city_picker.dart';
import 'birth_chart_onboarding_actions.dart';
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
  DateTime? _date;
  TimeOfDay? _time;
  BirthChartCity? _city;
  bool? _timeKnown;

  @override
  void initState() {
    super.initState();
    _apply(widget.initialProfile);
  }

  @override
  void didUpdateWidget(covariant BirthChartOnboardingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile != widget.initialProfile) {
      _apply(widget.initialProfile);
    }
  }

  void _apply(BirthProfile? profile) {
    if (profile == null) return;
    _date = profile.birthDate;
    _timeKnown = profile.birthTimeKnown;
    _time = profile.hasKnownTime
        ? TimeOfDay.fromDateTime(profile.birthTime!)
        : null;
    _city = BirthChartCities.byName(profile.birthPlace);
  }

  Future<void> _pickDate() async {
    final picked = await pickBirthDate(context, current: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    if (_timeKnown != true) return;
    final picked = await pickBirthTime(context, current: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickCity() async {
    final picked = await showBirthChartCityPicker(context, selected: _city);
    if (picked != null) setState(() => _city = picked);
  }

  void _setTimeKnown(bool known) {
    setState(() {
      _timeKnown = known;
      if (!known) _time = null;
    });
  }

  String _timeDisplay(BuildContext context) {
    if (_timeKnown == false) return BirthChartCopy.timeUnknownValue;
    if (_time == null) return BirthChartCopy.selectValue;
    return _time!.format(context);
  }

  Future<void> _submit() async {
    final error = BirthChartOnboardingActions.validate(
      date: _date,
      timeKnown: _timeKnown,
      time: _time,
    );
    if (error != null) {
      OraclySnackBar.show(context, message: error);
      return;
    }
    await widget.onSubmit(
      BirthChartOnboardingActions.buildProfile(
        date: _date!,
        timeKnown: _timeKnown!,
        time: _time,
        city: _city,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _date == null
        ? BirthChartCopy.selectValue
        : OraclyFormat.date(_date!);
    final placeLabel = _city?.label() ?? BirthChartCopy.birthPlaceHint;
    final timeNote = _timeKnown == false
        ? BirthChartCopy.timeUnknownNote
        : _timeKnown == true
            ? BirthChartCopy.timeImportance
            : null;

    return BirthChartOnboardingForm(
      dateLabel: dateLabel,
      timeLabel: _timeDisplay(context),
      placeLabel: placeLabel,
      submitLabel: widget.isEditing
          ? BirthChartCopy.updateChart
          : BirthChartCopy.generateChart,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onPickPlace: _pickCity,
      onSubmit: _submit,
      onCancel: widget.onCancel,
      timeKnown: _timeKnown,
      onTimeKnown: () => _setTimeKnown(true),
      onTimeUnknown: () => _setTimeKnown(false),
      showTimeField: _timeKnown == true,
      timeNote: timeNote,
      showReview: _date != null,
      reviewTimeLabel: BirthChartOnboardingActions.reviewTimeLabel(
        timeKnown: _timeKnown,
        time: _time,
      ),
    );
  }
}
