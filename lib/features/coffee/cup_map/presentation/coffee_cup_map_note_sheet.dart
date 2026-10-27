/// Bottom sheet for one pin: an optional note, save, or remove the pin.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';

sealed class CoffeeCupMapNoteAction {
  const CoffeeCupMapNoteAction();
}

class CoffeeCupMapNoteSaved extends CoffeeCupMapNoteAction {
  const CoffeeCupMapNoteSaved(this.note);
  final String? note;
}

class CoffeeCupMapPinDeleted extends CoffeeCupMapNoteAction {
  const CoffeeCupMapPinDeleted();
}

Future<CoffeeCupMapNoteAction?> showCoffeeCupMapNoteSheet(
  BuildContext context, {
  required int number,
  required CoffeeCupMapPin pin,
}) {
  return showModalBottomSheet<CoffeeCupMapNoteAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: OraclyChrome.deepNavy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NoteSheet(number: number, pin: pin),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.number, required this.pin});

  final int number;
  final CoffeeCupMapPin pin;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _text =
      TextEditingController(text: widget.pin.note ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: OraclyChrome.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                '${CoffeeCupMapCopy.pinName(widget.number)} · '
                '${CoffeeCupMapCopy.noteTitle}',
                style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              autofocus: !widget.pin.hasNote,
              maxLength: CoffeeCupMapLimits.maxNoteLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: ReadingTypography.body(color: OraclyChrome.cream),
              cursorColor: OraclyChrome.gold,
              decoration: InputDecoration(
                hintText: CoffeeCupMapCopy.noteHint,
                hintStyle: ReadingTypography.secondary(),
                filled: true,
                fillColor: OraclyChrome.midnight.withValues(alpha: 0.6),
                counterStyle: ReadingTypography.micro(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: OraclyChrome.gold.withValues(
                      alpha: OraclyChrome.borderDefault,
                    ),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: OraclyChrome.gold.withValues(
                      alpha: OraclyChrome.borderDefault,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OraclyChrome.gold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OraclyGoldButton(
              label: CoffeeCupMapCopy.noteSave,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(
                CoffeeCupMapNoteSaved(normalizeCoffeeCupMapNote(_text.text)),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OraclyTextAction(
                  label: CoffeeCupMapCopy.noteDelete,
                  destructive: true,
                  onPressed: () => Navigator.of(context).pop(
                    const CoffeeCupMapPinDeleted(),
                  ),
                ),
                OraclyTextAction(
                  label: CoffeeCupMapCopy.noteClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
