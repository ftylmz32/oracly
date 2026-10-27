/// Result-screen door to Fincan Haritası. Renders nothing unless this
/// reading has a map with at least one photo still on the device — so V1/V2
/// readings, older V3 readings and other owners never see it.
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
import 'coffee_cup_map_screen.dart';

class CoffeeCupMapEntry extends ConsumerStatefulWidget {
  const CoffeeCupMapEntry({super.key, required this.readingId});

  final String readingId;

  @override
  ConsumerState<CoffeeCupMapEntry> createState() => _CoffeeCupMapEntryState();
}

class _CoffeeCupMapEntryState extends ConsumerState<CoffeeCupMapEntry> {
  CoffeeCupMapRecord? _record;

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

  void _reload() {
    final record = ref.read(coffeeCupMapStoreProvider)?.load(widget.readingId);
    final usable =
        record != null && record.photos.any((p) => File(p.path).existsSync());
    _record = usable ? record : null;
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoffeeCupMapScreen(readingId: widget.readingId),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (record == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        color: OraclyChrome.cardSurface.withValues(alpha: 0.62),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderDefault),
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: OraclyChrome.glowSoft),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              CoffeeCupMapCopy.title,
              style: ReadingTypography.sectionTitle(color: OraclyChrome.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(CoffeeCupMapCopy.entryBody, style: ReadingTypography.secondary()),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final slot in coffeeV3CanonicalSlotOrder)
                  if (record.photoFor(slot) case final photo?)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _Thumb(photo: photo),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            CoffeeCupMapCopy.entryCount(record.pins.length),
            style: ReadingTypography.micro(),
          ),
          const SizedBox(height: 12),
          OraclyGoldButton(
            label: CoffeeCupMapCopy.entryOpen,
            expanded: true,
            onPressed: _open,
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});

  final CoffeeCupMapPhoto photo;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.path);
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: OraclyChrome.midnight),
          child: file.existsSync()
              ? Image.file(
                  file,
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                  excludeFromSemantics: true,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
