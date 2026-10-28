/// Result-screen door to Fincan Haritası. Renders nothing unless this
/// reading has a map with at least one photo still on the device — so V1/V2
/// readings, older V3 readings and other owners never see it.
///
/// The reading's own three photos lead the card; it unfolds into the result
/// once the photos are known, instead of popping in.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../coffee_v3/models/coffee_v3_photo_slot.dart';
import '../copy/coffee_cup_map_copy.dart';
import '../models/coffee_cup_map_record.dart';
import '../providers/coffee_cup_map_providers.dart';
import 'coffee_cup_map_motion.dart';
import 'coffee_cup_map_screen.dart';

class CoffeeCupMapEntry extends ConsumerStatefulWidget {
  const CoffeeCupMapEntry({super.key, required this.readingId});

  final String readingId;

  @override
  ConsumerState<CoffeeCupMapEntry> createState() => _CoffeeCupMapEntryState();
}

class _CoffeeCupMapEntryState extends ConsumerState<CoffeeCupMapEntry> {
  CoffeeCupMapRecord? _record;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Re-read on every parent rebuild: a live V3 result is shown first and
  /// its photos are kept a moment later, followed by a rebuild.
  @override
  void didUpdateWidget(covariant CoffeeCupMapEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reload();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final readingId = widget.readingId;
    CoffeeCupMapRecord? record;
    try {
      record = await ref.read(coffeeCupMapStoreProvider)?.load(readingId);
    } catch (_) {
      record = null;
    }
    final usable =
        record != null && record.photos.any((p) => File(p.path).existsSync());
    if (!mounted || generation != _generation) return;
    setState(() => _record = usable ? record : null);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      coffeeCupMapRoute<void>(
        context,
        CoffeeCupMapScreen(readingId: widget.readingId),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    return AnimatedSwitcher(
      duration: CoffeeCupMapMotion.of(context, CoffeeCupMapMotion.door),
      switchInCurve: CoffeeCupMapMotion.ease,
      switchOutCurve: CoffeeCupMapMotion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: record == null
          ? const SizedBox.shrink(key: ValueKey('none'))
          : _DoorCard(key: const ValueKey('door'), record: record, onOpen: _open),
    );
  }
}

class _DoorCard extends StatelessWidget {
  const _DoorCard({super.key, required this.record, required this.onOpen});

  final CoffeeCupMapRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.heroRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclyChrome.deepNavy.withValues(alpha: 0.78),
            OraclyChrome.cardSurface.withValues(alpha: 0.62),
          ],
        ),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderDefault),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Semantics(
                header: true,
                child: Text(
                  CoffeeCupMapCopy.title,
                  style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
                ),
              ),
              Text(
                CoffeeCupMapCopy.entryCount(record.pins.length),
                style: ReadingTypography.micro(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // The reading's own photos, the way they were taken.
          ExcludeSemantics(
            child: GestureDetector(
              onTap: onOpen,
              child: Row(
                children: [
                  for (final slot in coffeeV3CanonicalSlotOrder)
                    if (record.photoFor(slot) case final photo?)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _Thumb(
                            photo: photo,
                            label: CoffeeCupMapCopy.photoLabel(slot),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(CoffeeCupMapCopy.entryBody, style: ReadingTypography.secondary()),
          const SizedBox(height: 16),
          OraclyGoldButton(
            label: CoffeeCupMapCopy.entryOpen,
            expanded: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.label});

  final CoffeeCupMapPhoto photo;
  final String label;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.path);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: OraclyChrome.midnight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderHairline),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: file.existsSync()
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.micro(),
        ),
      ],
    );
  }
}
