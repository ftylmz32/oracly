/// Fincan Haritası — the three photos one reading was made from, with the
/// user's own pins and notes. Optional: the reading never waits on it.
///
/// The photo is the star: it sits first, in a stage of fixed height (so the
/// three views of different shapes never move the page), and crossfades
/// between views. Below it, the three real photos as a strip, one honest
/// line, the pin list and the settings.
library;

import 'dart:io';

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
import 'coffee_cup_map_consent_tile.dart';
import 'coffee_cup_map_motion.dart';
import 'coffee_cup_map_note_sheet.dart';
import 'coffee_cup_map_states.dart';

class CoffeeCupMapScreen extends ConsumerStatefulWidget {
  const CoffeeCupMapScreen({super.key, required this.readingId});

  final String readingId;

  @override
  ConsumerState<CoffeeCupMapScreen> createState() => _CoffeeCupMapScreenState();
}

class _CoffeeCupMapScreenState extends ConsumerState<CoffeeCupMapScreen>
    with SingleTickerProviderStateMixin {
  /// One key per view: during a crossfade both canvases are alive.
  final Map<CoffeeV3PhotoSlot, GlobalKey<CoffeeCupMapCanvasState>> _canvases = {
    for (final slot in CoffeeV3PhotoSlot.values) slot: GlobalKey(),
  };
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: CoffeeCupMapMotion.reveal,
  );
  CoffeeCupMapStore? _store;
  CoffeeCupMapRecord? _record;
  CoffeeV3PhotoSlot? _slot;
  String? _selectedPinId;
  bool _busy = false;
  bool _zoomed = false;
  bool _loading = true;

  /// Photo paths decoded for this screen; released when it closes.
  final Set<String> _decoded = {};

  /// Width / height of each view once its photo has decoded.
  final Map<CoffeeV3PhotoSlot, double> _aspects = {};

  @override
  void initState() {
    super.initState();
    _store = ref.read(coffeeCupMapStoreProvider);
    _load();
  }

  @override
  void dispose() {
    _reveal.dispose();
    // The photos are private and large: do not keep them decoded.
    for (final path in _decoded) {
      coffeeCupMapPhotoImage(path).evict();
    }
    super.dispose();
  }

  Future<void> _load() async {
    CoffeeCupMapRecord? record;
    try {
      record = await _store?.load(widget.readingId);
    } catch (_) {
      record = null;
    }
    if (!mounted) return;
    setState(() {
      _record = record;
      _slot = record?.photos.first.slot;
      _loading = false;
    });
    if (CoffeeCupMapMotion.reduced(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
    // Decode the other views now so switching is a clean crossfade.
    for (final photo in record?.photos ?? const <CoffeeCupMapPhoto>[]) {
      _decoded.add(photo.path);
      precacheImage(
        coffeeCupMapPhotoImage(photo.path),
        context,
        onError: (_, _) {},
      );
    }
  }

  CoffeeCupMapCanvasState? get _canvas => _canvases[_slot]?.currentState;

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
    final center = _canvas?.visibleCenter();
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

  Future<void> _deleteMap() async {
    final store = _store;
    final record = _record;
    if (store == null || record == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AlertDialog(
        backgroundColor: OraclyChrome.deepNavy,
        shape: RoundedRectangleBorder(
          borderRadius: OraclyChrome.cardRadius,
          side: BorderSide(
            color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderDefault),
          ),
        ),
        title: Text(
          CoffeeCupMapCopy.deleteConfirmTitle,
          style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
        ),
        content: Text(
          CoffeeCupMapCopy.deleteConfirmBody,
          style: ReadingTypography.secondary(),
        ),
        actions: [
          OraclyTextAction(
            label: CoffeeCupMapCopy.deleteCancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          OraclyTextAction(
            label: CoffeeCupMapCopy.deleteConfirm,
            destructive: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await store.deleteMap(record.readingId);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _say(CoffeeCupMapCopy.deleteFailed);
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop();
    messenger?.showSnackBar(
      const SnackBar(content: Text(CoffeeCupMapCopy.deleted)),
    );
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stage = _stageHeight(constraints.maxHeight);
                  if (_loading) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        CoffeeReferenceTokens.screenHorizontal,
                        16,
                        CoffeeReferenceTokens.screenHorizontal,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: CoffeeCupMapLoadingFrame(height: stage),
                      ),
                    );
                  }
                  if (_record == null) {
                    return CoffeeCupMapUnavailable(
                      onBack: () => Navigator.of(context).maybePop(),
                    );
                  }
                  return _body(
                    context,
                    stage,
                    constraints.maxWidth -
                        2 * CoffeeReferenceTokens.screenHorizontal,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The photo gets most of the screen; small phones keep room to scroll.
  double _stageHeight(double available) =>
      (available * (available < 560 ? 0.64 : 0.58)).clamp(200.0, 560.0);

  /// The stage for [slot]: as tall as its photo at [width], at most [max].
  double _fittedStage(CoffeeV3PhotoSlot slot, double width, double max) {
    final aspect = _aspects[slot];
    if (aspect == null || aspect <= 0 || width <= 0) return max;
    return (width / aspect).clamp(0.0, max);
  }

  /// Staggered first reveal: photo, then strip, then everything below.
  Widget _revealed(double from, double to, Widget child, {double lift = 10}) {
    final t = CurvedAnimation(
      parent: _reveal,
      curve: Interval(from, to, curve: CoffeeCupMapMotion.ease),
    );
    return FadeTransition(
      opacity: t,
      child: AnimatedBuilder(
        animation: t,
        child: child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, lift * (1 - t.value)),
          child: child,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, double stage, double width) {
    final record = _record!;
    final slot = _slot!;
    final pins = _pinsOf(slot);
    final photoDuration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.photo);
    // At most 12 pins a photo: everything is built, so the whole list is in
    // the semantics tree at once.
    return SingleChildScrollView(
      physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.fromLTRB(
        CoffeeReferenceTokens.screenHorizontal,
        16,
        CoffeeReferenceTokens.screenHorizontal,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _revealed(
            0,
            0.45,
            lift: 14,
            AnimatedContainer(
              // Follows the shape of the photo on show, so a square saucer
              // and a tall cup both sit flush, gliding between the two.
              duration: photoDuration,
              curve: CoffeeCupMapMotion.ease,
              height: _fittedStage(slot, width, stage),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: photoDuration,
                      switchInCurve: CoffeeCupMapMotion.ease,
                      switchOutCurve: CoffeeCupMapMotion.exit,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.center,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.985, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(slot),
                        child: _canvasFor(record, slot, pins, stage),
                      ),
                    ),
                  ),
                  if (pins.isEmpty && !_zoomed)
                    const Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: IgnorePointer(child: _PhotoHint()),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _ResetZoom(
                      visible: _zoomed,
                      onTap: () => _canvas?.resetZoom(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _revealed(
            0.18,
            0.7,
            _PhotoStrip(
              record: record,
              selected: slot,
              onSelect: (next) {
                if (next == slot) return;
                setState(() {
                  _slot = next;
                  _selectedPinId = null;
                  _zoomed = false;
                });
              },
            ),
          ),
          _revealed(
            0.32,
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 14),
                Text(
                  CoffeeCupMapCopy.intro,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.micro(),
                ),
                const SizedBox(height: 6),
                Center(
                  child: OraclyTextAction(
                    label: CoffeeCupMapCopy.pinAtCenter,
                    emphasized: true,
                    onPressed: _busy ? null : _addAtCenter,
                  ),
                ),
                const SizedBox(height: 10),
                _SectionRule(label: CoffeeCupMapCopy.listTitle),
                const SizedBox(height: 10),
                if (pins.isEmpty)
                  const _EmptyPins()
                else
                  for (var i = 0; i < pins.length; i++)
                    _PinRow(
                      key: ValueKey(pins[i].id),
                      number: i + 1,
                      pin: pins[i],
                      selected: pins[i].id == _selectedPinId,
                      onTap: () => _edit(pins[i], i + 1),
                    ),
                const SizedBox(height: 28),
                const CoffeeCupMapConsentTile(showFacts: false),
                const SizedBox(height: 12),
                Center(
                  child: OraclyTextAction(
                    label: CoffeeCupMapCopy.deleteMap,
                    destructive: true,
                    onPressed: _busy ? null : _deleteMap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvasFor(
    CoffeeCupMapRecord record,
    CoffeeV3PhotoSlot slot,
    List<CoffeeCupMapPin> pins,
    double stage,
  ) {
    return Semantics(
      label: CoffeeCupMapCopy.photoSemantics(slot, pins.length),
      onTap: _addAtCenter,
      child: CoffeeCupMapCanvas(
        key: _canvases[slot],
        photo: record.photoFor(slot)!,
        pins: pins,
        maxHeight: stage,
        selectedPinId: _selectedPinId,
        onTapAt: _addAt,
        onPinTap: (pin) => _edit(pin, pins.indexOf(pin) + 1),
        onZoomChanged: (zoomed) => setState(() => _zoomed = zoomed),
        onAspect: (aspect) {
          if (_aspects[slot] != aspect) setState(() => _aspects[slot] = aspect);
        },
      ),
    );
  }
}

/// A translucent caption on the photo until it has a pin.
class _PhotoHint extends StatelessWidget {
  const _PhotoHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: OraclyChrome.pillRadius,
          color: OraclyChrome.midnight.withValues(alpha: 0.72),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline),
          ),
        ),
        child: Text(
          CoffeeCupMapCopy.gestureHint,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.micro(color: OraclyChrome.cream),
        ),
      ),
    );
  }
}

/// Appears on the photo only while it is zoomed.
class _ResetZoom extends StatelessWidget {
  const _ResetZoom({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: CoffeeCupMapMotion.ease,
        child: Semantics(
          button: true,
          label: CoffeeCupMapCopy.resetZoom,
          excludeSemantics: true,
          onTap: visible ? onTap : null,
          child: Material(
            color: OraclyChrome.midnight.withValues(alpha: 0.78),
            shape: CircleBorder(
              side: BorderSide(
                color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderDefault),
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.zoom_out,
                  size: 20,
                  color: OraclyChrome.goldLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three real photos as a strip; the chosen one is lit, the others rest.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in coffeeV3CanonicalSlotOrder)
          if (record.photoFor(slot) case final photo?)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _PhotoTab(
                  photo: photo,
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
    required this.photo,
    required this.label,
    required this.pins,
    required this.selected,
    required this.onTap,
  });

  final CoffeeCupMapPhoto photo;
  final String label;
  final int pins;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $pins işaret',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: OraclyChrome.cardRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: selected ? 1 : 0.55,
                  duration: duration,
                  curve: CoffeeCupMapMotion.ease,
                  child: AnimatedContainer(
                    duration: duration,
                    curve: CoffeeCupMapMotion.ease,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? OraclyChrome.goldLight
                            : OraclyChrome.gold.withValues(
                                alpha: OraclyChrome.borderHairline,
                              ),
                        width: selected ? 1.6 : 1,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: OraclyChrome.gold.withValues(
                              alpha: OraclyChrome.glowMedium,
                            ),
                            blurRadius: 14,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox.expand(
                        child: ColoredBox(
                          color: OraclyChrome.midnight,
                          child: Image(
                            image: ResizeImage(
                              FileImage(File(photo.path)),
                              width: 240,
                            ),
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.hide_image_outlined,
                              size: 18,
                              color: OraclyChrome.gold.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pins == 0 ? label : '$label · $pins',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.label(
                    color: selected
                        ? OraclyChrome.goldLight
                        : OraclyChrome.cream.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A gold hairline with the section name, the app's quiet divider.
class _SectionRule extends StatelessWidget {
  const _SectionRule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline),
      ),
    );
    return Semantics(
      header: true,
      child: LayoutBuilder(
        // The label keeps short rules either side; at large text it wraps.
        builder: (context, constraints) => Row(
          children: [
            line,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (constraints.maxWidth - 48).clamp(0.0, double.infinity),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
                ),
              ),
            ),
            line,
          ],
        ),
      ),
    );
  }
}

class _EmptyPins extends StatelessWidget {
  const _EmptyPins();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        color: OraclyChrome.cardSurface.withValues(alpha: 0.32),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline * 0.7),
        ),
      ),
      child: Text(
        CoffeeCupMapCopy.listEmpty,
        textAlign: TextAlign.center,
        style: ReadingTypography.secondary(),
      ),
    );
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({
    super.key,
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
    final duration = CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.pinSelect);
    return Semantics(
      button: true,
      label: CoffeeCupMapCopy.pinSemantics(number, pin.note),
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: OraclyChrome.cardRadius,
          child: AnimatedContainer(
            duration: duration,
            curve: CoffeeCupMapMotion.ease,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.cardRadius,
              color: OraclyChrome.cardSurface.withValues(
                alpha: selected ? 0.7 : 0.46,
              ),
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
                CoffeeCupMapMedallion(number: number, size: 28),
                const SizedBox(width: 14),
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
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: OraclyChrome.gold.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
