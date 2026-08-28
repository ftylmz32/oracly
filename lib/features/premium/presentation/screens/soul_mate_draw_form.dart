/// One-screen intake — required name and birth, one presence choice, optional note.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/l10n/oracly_format.dart';
import '../../../../features/tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../copy/soul_mate_copy.dart';
import '../../services/soul_mate_draw_port.dart';
import 'soul_mate_draw_fields.dart';
import 'soul_mate_gender_choice.dart';

class SoulMateDrawForm extends StatelessWidget {
  const SoulMateDrawForm({
    super.key,
    required this.nameController,
    required this.intentionController,
    required this.birthDate,
    required this.onPickBirth,
    required this.gender,
    required this.onGender,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController intentionController;
  final DateTime? birthDate;
  final VoidCallback onPickBirth;
  final SoulMateGenderPref? gender;
  final ValueChanged<SoulMateGenderPref?> onGender;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final birthText = birthDate == null
        ? SoulMateCopy.birthHint
        : OraclyFormat.dateNumeric(birthDate!);

    return OraclyGlassCard(
      premium: true,
      glowStrength: 1.08,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoulMateFieldWhy(SoulMateCopy.formWhy),
          const SizedBox(height: 10),
          SoulMateFieldLabel(SoulMateCopy.nameLabel),
          const SizedBox(height: 6),
          SoulMateTextField(
            controller: nameController,
            hint: SoulMateCopy.nameHint,
          ),
          const SizedBox(height: 8),
          SoulMateFieldLabel(SoulMateCopy.birthLabel),
          const SizedBox(height: 6),
          SoulMateTapField(
            text: birthText,
            empty: birthDate == null,
            onTap: onPickBirth,
          ),
          const SizedBox(height: 8),
          SoulMateFieldLabel(SoulMateCopy.genderLabel),
          const SizedBox(height: 6),
          SoulMateGenderChoice(selected: gender, onSelected: onGender),
          const SizedBox(height: 8),
          SoulMateFieldLabel(SoulMateCopy.intentionLabel),
          const SizedBox(height: 6),
          SoulMateTextField(
            controller: intentionController,
            hint: SoulMateCopy.intentionHint,
          ),
          const SizedBox(height: 12),
          TarotEpic031PrimaryButton(
            label: SoulMateCopy.drawCta,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
