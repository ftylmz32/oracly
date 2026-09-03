/// Optional name, birth date, language, and OR style — all skippable.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../birth_chart/data/birth_chart_cities.dart';
import '../../../birth_chart/presentation/widgets/birth_chart_city_picker.dart';
import '../../../premium/models/personalization_models.dart';
import '../../data/onboarding_setup_draft.dart';
import 'onboarding_setup_form_content.dart';

class OnboardingSetupForm extends StatefulWidget {
  const OnboardingSetupForm({
    super.key,
    required this.language,
    required this.style,
    required this.onSkip,
    required this.onContinue,
    this.onLanguageLive,
    this.draft,
    this.onDraftChanged,
    this.busy = false,
  });

  final String language;
  final AiPersonality style;
  final void Function({required String language, required AiPersonality style})
  onSkip;
  final void Function({
    required String name,
    DateTime? birthDate,
    String? birthPlace,
    required String language,
    required AiPersonality style,
  })
  onContinue;
  final Future<void> Function(String language)? onLanguageLive;
  final OnboardingSetupDraft? draft;
  final ValueChanged<OnboardingSetupDraft>? onDraftChanged;
  final bool busy;

  @override
  State<OnboardingSetupForm> createState() => _OnboardingSetupFormState();
}

class _OnboardingSetupFormState extends State<OnboardingSetupForm> {
  late final TextEditingController _name;
  DateTime? _birth;
  BirthChartCity? _birthCity;
  late String _language;
  late AiPersonality _style;
  Timer? _nameDebounce;

  void _emitDraft() {
    final saver = widget.onDraftChanged;
    if (saver == null) return;
    saver(
      OnboardingSetupDraft(
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        birthDate: _birth,
        birthPlaceTr: _birthCity?.nameTr,
        language: _language,
        style: _style,
      ),
    );
  }

  Future<void> _setLanguage(String raw) async {
    final code = AppLocale.normalize(raw);
    OraclyL10n.bind(code);
    setState(() => _language = code);
    _emitDraft();
    await widget.onLanguageLive?.call(code);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft?.name ?? '');
    _birth = widget.draft?.birthDate;
    _birthCity = BirthChartCities.byName(widget.draft?.birthPlaceTr);
    _language = AppLocale.normalize(widget.draft?.language ?? widget.language);
    _style = widget.draft?.style ?? widget.style;
    _name.addListener(() {
      _nameDebounce?.cancel();
      _nameDebounce = Timer(const Duration(milliseconds: 220), _emitDraft);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitDraft());
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _birth = picked);
      _emitDraft();
    }
  }

  Future<void> _pickBirthCity() async {
    final picked = await showBirthChartCityPicker(
      context,
      selected: _birthCity,
    );
    if (picked != null && mounted) {
      setState(() => _birthCity = picked);
      _emitDraft();
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingSetupFormContent(
    nameController: _name,
    birth: _birth,
    birthCity: _birthCity,
    language: _language,
    style: _style,
    busy: widget.busy,
    onPickBirth: _pickBirth,
    onPickBirthCity: _pickBirthCity,
    onLanguage: _setLanguage,
    onStyle: (v) {
      setState(() => _style = v);
      _emitDraft();
    },
    onContinue: widget.busy
        ? null
        : () => widget.onContinue(
            name: _name.text.trim(),
            birthDate: _birth,
            birthPlace: _birthCity?.nameTr,
            language: _language,
            style: _style,
          ),
    onSkip: widget.busy
        ? null
        : () {
            _emitDraft();
            widget.onSkip(language: _language, style: _style);
          },
  );
}
