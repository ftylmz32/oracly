/// OR Sesi — four expressions of one OR, persisted, previewed with real speech.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/voice/oracly_tts_gate.dart';
import '../../../core/voice/oracly_voice_copy.dart';
import '../../../core/voice/oracly_voice_id.dart';
import '../../../core/widgets/oracly_signature_motifs.dart';
import '../../../features/premium/models/personalization_models.dart';
import 'settings_or_speech_speed.dart';
import 'settings_or_voice_card.dart';
import 'settings_reference_tokens.dart';

class SettingsOrVoiceSection extends StatefulWidget {
  const SettingsOrVoiceSection({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final PersonalizationSettings settings;
  final Future<void> Function(
    PersonalizationSettings Function(PersonalizationSettings),
  ) onSave;

  @override
  State<SettingsOrVoiceSection> createState() => _SettingsOrVoiceSectionState();
}

class _SettingsOrVoiceSectionState extends State<SettingsOrVoiceSection> {
  OraclyVoiceId? _busy;

  String get _lang => AppLocale.normalize(widget.settings.language);

  OraclyVoiceId get _selected => OraclyVoiceId.parse(widget.settings.orVoiceId);

  @override
  void dispose() {
    OraclyTtsGate.interrupt();
    super.dispose();
  }

  Future<void> _select(OraclyVoiceId id) async {
    if (id == _selected) return;
    await widget.onSave((s) => s.copyWith(orVoiceId: id.wire));
  }

  Future<void> _preview(OraclyVoiceId id) async {
    if (_busy != null) await OraclyTtsGate.stop();
    if (!mounted) return;
    setState(() => _busy = id);
    await OraclyTtsGate.preview(
      OraclyVoiceCopy.previewPhrase(_lang),
      identity: id,
    );
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          OraclyVoiceCopy.sectionTitle(_lang),
          style: ReadingTypography.sectionLabel(fontSize: 11),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          OraclyVoiceCopy.sectionHint(_lang),
          style: ReadingTypography.bodySmall(
            color: palette.textSecondary.withValues(alpha: 0.78),
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: SettingsReferenceTokens.sectionLabelToCard),
        SettingsOrSpeechSpeed(settings: widget.settings, onSave: widget.onSave),
        SizedBox(height: SettingsReferenceTokens.sectionGap),
        for (final id in OraclyVoiceId.values) ...[
          if (id != OraclyVoiceId.values.first)
            SizedBox(height: SettingsReferenceTokens.headerToProfile),
          SettingsOrVoiceCard(
            key: ValueKey('or-voice-${id.wire}'),
            id: id,
            languageCode: _lang,
            selected: id == _selected,
            preparing: _busy == id,
            onSelect: () => _select(id),
            onPreview: () => _preview(id),
          ),
        ],
      ],
    );
  }
}
