/// Bottom sheet for one pin: an optional note, save, or remove the pin.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';
import 'coffee_cup_map_motion.dart';
import 'coffee_cup_map_states.dart';

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

const _sheetRadius = BorderRadius.vertical(top: Radius.circular(28));

Future<CoffeeCupMapNoteAction?> showCoffeeCupMapNoteSheet(
  BuildContext context, {
  required int number,
  required CoffeeCupMapPin pin,
}) {
  return showModalBottomSheet<CoffeeCupMapNoteAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
    clipBehavior: Clip.antiAlias,
    // Rises with the app's enter curve, leaves a little faster.
    sheetAnimationStyle: CoffeeCupMapMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: CoffeeCupMapMotion.sheetIn,
            reverseDuration: CoffeeCupMapMotion.sheetOut,
            curve: CoffeeCupMapMotion.ease,
            reverseCurve: CoffeeCupMapMotion.exit,
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

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _sheetRadius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [OraclyChrome.deepNavy, OraclyChrome.midnight],
        ),
        border: Border(
          top: BorderSide(
            color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderDefault),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 16 + inset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OraclyChrome.gold.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  header: true,
                  label: '${CoffeeCupMapCopy.pinName(widget.number)}, '
                      '${CoffeeCupMapCopy.noteTitle}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      CoffeeCupMapMedallion(
                        number: widget.number,
                        size: 34,
                        emphasized: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CoffeeCupMapCopy.pinName(widget.number),
                              style: ReadingTypography.sectionTitle(
                                color: OraclyChrome.gold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CoffeeCupMapCopy.noteTitle,
                              style: ReadingTypography.micro(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _text,
                  autofocus: !widget.pin.hasNote,
                  maxLength: CoffeeCupMapLimits.maxNoteLength,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: ReadingTypography.body(color: OraclyChrome.cream),
                  cursorColor: OraclyChrome.gold,
                  decoration: InputDecoration(
                    hintText: CoffeeCupMapCopy.noteHint,
                    hintStyle: ReadingTypography.secondary(),
                    filled: true,
                    fillColor: OraclyChrome.midnight.withValues(alpha: 0.7),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: ReadingTypography.micro(),
                    border: _border(OraclyChrome.gold.withValues(
                      alpha: OraclyChrome.borderHairline,
                    )),
                    enabledBorder: _border(OraclyChrome.gold.withValues(
                      alpha: OraclyChrome.borderHairline,
                    )),
                    focusedBorder: _border(
                      OraclyChrome.gold.withValues(alpha: OraclyChrome.borderEmphasis),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OraclyGoldButton(
                  label: CoffeeCupMapCopy.noteSave,
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(
                    CoffeeCupMapNoteSaved(normalizeCoffeeCupMapNote(_text.text)),
                  ),
                ),
                const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}
