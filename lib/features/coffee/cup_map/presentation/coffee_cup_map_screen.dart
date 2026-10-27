/// Fincan Haritası — the three photos one reading was made from, with the
/// user's own pins and notes. Optional: the reading never waits on it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../coffee_v3/models/coffee_v3_photo_slot.dart';
import '../../presentation/reference/coffee_reference_atmosphere.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';
import '../providers/coffee_cup_map_providers.dart';
import '../services/coffee_cup_map_store.dart';
import 'coffee_cup_map_canvas.dart';
import 'coffee_cup_map_note_sheet.dart';

class CoffeeCupMapScreen extends ConsumerStatefulWidget {
  const CoffeeCupMapScreen({super.key, required this.readingId});

  final String readingId;

  @override
  ConsumerState<CoffeeCupMapScreen> createState() => _CoffeeCupMapScreenState();
}

class _CoffeeCupMapScreenState extends ConsumerState<CoffeeCupMapScreen> {
  final GlobalKey<CoffeeCupMapCanvasState> _canvas = GlobalKey();
  CoffeeCupMapStore? _store;
  CoffeeCupMapRecord? _record;
  CoffeeV3PhotoSlot? _slot;
  String? _selectedPinId;
  bool _busy = false;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _store = ref.read(coffeeCupMapStoreProvider);
    _record = _store?.load(widget.readingId);
    _slot = _record?.photos.first.slot;
  }

  List<CoffeeCupMapPin> _pinsOf(CoffeeV3PhotoSlot slot) =>
      _record?.pinsFor(slot) ?? const [];

  Future<void> _addAt(double x, double y) async {
    final slot = _slot;
    final record = _record;
    final store = _store;
    if (slot == null || record == null || store == null || _busy) return;
    final pins = _pinsOf(slot);
    for (var i = 0; i < pins.length; i++) {
      if (pins[i].isSamePlace(slot, x, y)) {
        await _edit(pins[i], i + 1);
        return;
      }
    }
    final next = await _write(
      () => store.addPin(readingId: record.readingId, slot: slot, x: x, y: y),
    );
    if (next == null || !mounted) return;
    final added = next.pinsFor(slot).last;
    await _edit(added, next.pinsFor(slot).length);
  }

  Future<void> _addAtCenter() async {
    final center = _canvas.currentState?.visibleCenter();
    if (center == null) return;
    await _addAt(center.dx, center.dy);
  }

  Future<void> _edit(CoffeeCupMapPin pin, int number) async {
    final store = _store;
    final record = _record;
    if (store == null || record == null) return;
    setState(() => _selectedPinId = pin.id);
    final action = await showCoffeeCupMapNoteSheet(
      context,
      number: number,
      pin: pin,
    );
    if (!mounted) return;
    switch (action) {
      case CoffeeCupMapNoteSaved(:final note):
        if (note != pin.note) {
          await _write(
            () => store.setNote(
              readingId: record.readingId,
              pinId: pin.id,
              note: note,
            ),
          );
        }
      case CoffeeCupMapPinDeleted():
        await _write(
          () => store.removePin(readingId: record.readingId, pinId: pin.id),
        );
      case null:
        break;
    }
    if (mounted) setState(() => _selectedPinId = null);
  }

  /// Every change is written before it is shown; a failed write shows the
  /// reason and leaves the screen on the last saved state.
  Future<CoffeeCupMapRecord?> _write(
    Future<CoffeeCupMapRecord> Function() change,
  ) async {
    setState(() => _busy = true);
    try {
      final next = await change();
      if (mounted) setState(() => _record = next);
      return next;
    } on CoffeeCupMapException catch (error) {
      _say(switch (error.reason) {
        CoffeeCupMapRejection.samePlace => CoffeeCupMapCopy.samePlace,
        CoffeeCupMapRejection.limitReached => CoffeeCupMapCopy.limitReached,
        _ => CoffeeCupMapCopy.saveFailed,
      });
      return null;
    } catch (_) {
      _say(CoffeeCupMapCopy.saveFailed);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const CoffeeReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                CoffeeReferenceTokens.screenHorizontal,
                CoffeeReferenceTokens.screenTop,
                CoffeeReferenceTokens.screenHorizontal,
                0,
              ),
              child: OraclyAppBar(
                title: CoffeeCupMapCopy.title,
                leadingLabel: CoffeeCupMapCopy.back,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: _record == null ? const _Unavailable() : _body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final record = _record!;
    final slot = _slot!;
    final photo = record.photoFor(slot)!;
    final pins = _pinsOf(slot);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasMax = (constraints.maxHeight * 0.48).clamp(160.0, 520.0);
        // At most 12 pins a photo: everything is built, so the whole list
        // is in the semantics tree at once.
        return SingleChildScrollView(
          physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
          padding: EdgeInsets.fromLTRB(
            CoffeeReferenceTokens.screenHorizontal,
            12,
            CoffeeReferenceTokens.screenHorizontal,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              CoffeeCupMapCopy.intro,
              style: ReadingTypography.secondary(),
            ),
            const SizedBox(height: 14),
            _PhotoTabs(
              record: record,
              selected: slot,
              onSelect: (next) => setState(() {
                _slot = next;
                _selectedPinId = null;
                _zoomed = false;
              }),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: CoffeeCupMapCopy.photoSemantics(slot, pins.length),
              onTap: _addAtCenter,
              child: CoffeeCupMapCanvas(
                key: _canvas,
                photo: photo,
                pins: pins,
                maxHeight: canvasMax,
                selectedPinId: _selectedPinId,
                onTapAt: _addAt,
                onPinTap: (pin) => _edit(pin, pins.indexOf(pin) + 1),
                onZoomChanged: (zoomed) => setState(() => _zoomed = zoomed),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CoffeeCupMapCopy.gestureHint,
              textAlign: TextAlign.center,
              style: ReadingTypography.micro(),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OraclyTextAction(
                  label: CoffeeCupMapCopy.pinAtCenter,
                  emphasized: true,
                  onPressed: _busy ? null : _addAtCenter,
                ),
                OraclyTextAction(
                  label: CoffeeCupMapCopy.resetZoom,
                  onPressed: _zoomed
                      ? () => _canvas.currentState?.resetZoom()
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                CoffeeCupMapCopy.listTitle,
                style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
              ),
            ),
            const SizedBox(height: 8),
            if (pins.isEmpty)
              Text(
                CoffeeCupMapCopy.listEmpty,
                style: ReadingTypography.secondary(),
              )
            else
              for (var i = 0; i < pins.length; i++)
                _PinRow(
                  number: i + 1,
                  pin: pins[i],
                  selected: pins[i].id == _selectedPinId,
                  onTap: () => _edit(pins[i], i + 1),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoTabs extends StatelessWidget {
  const _PhotoTabs({
    required this.record,
    required this.selected,
    required this.onSelect,
  });

  final CoffeeCupMapRecord record;
  final CoffeeV3PhotoSlot selected;
  final ValueChanged<CoffeeV3PhotoSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final slot in coffeeV3CanonicalSlotOrder)
          if (record.photoFor(slot) != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PhotoTab(
                  label: CoffeeCupMapCopy.photoLabel(slot),
                  pins: record.pinsFor(slot).length,
                  selected: slot == selected,
                  onTap: () => onSelect(slot),
                ),
              ),
            ),
      ],
    );
  }
}

class _PhotoTab extends StatelessWidget {
  const _PhotoTab({
    required this.label,
    required this.pins,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int pins;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $pins işaret',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: OraclyChrome.pillRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.pillRadius,
            color: selected
                ? OraclyChrome.gold.withValues(alpha: 0.16)
                : OraclyChrome.cardSurface.withValues(alpha: 0.5),
            border: Border.all(
              color: OraclyChrome.gold.withValues(
                alpha: selected
                    ? OraclyChrome.borderSelected
                    : OraclyChrome.borderHairline,
              ),
            ),
          ),
          child: Text(
            pins == 0 ? label : '$label · $pins',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.label(
              color: selected ? OraclyChrome.goldLight : OraclyChrome.cream,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({
    required this.number,
    required this.pin,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final CoffeeCupMapPin pin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: CoffeeCupMapCopy.pinSemantics(number, pin.note),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: OraclyChrome.cardRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.cardRadius,
            color: OraclyChrome.cardSurface.withValues(alpha: 0.55),
            border: Border.all(
              color: OraclyChrome.gold.withValues(
                alpha: selected
                    ? OraclyChrome.borderSelected
                    : OraclyChrome.borderHairline,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OraclyChrome.midnight,
                  border: Border.all(color: OraclyChrome.gold, width: 1.6),
                ),
                child: Text(
                  '$number',
                  style: ReadingTypography.label(color: OraclyChrome.cream),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pin.note ?? CoffeeCupMapCopy.noNote,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: pin.hasNote
                      ? ReadingTypography.bodySmall(color: OraclyChrome.cream)
                      : ReadingTypography.secondary(),
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: OraclyChrome.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(CoffeeReferenceTokens.screenHorizontal),
      child: Center(
        child: Text(
          CoffeeCupMapCopy.mapUnavailable,
          textAlign: TextAlign.center,
          style: ReadingTypography.secondary(),
        ),
      ),
    );
  }
}
