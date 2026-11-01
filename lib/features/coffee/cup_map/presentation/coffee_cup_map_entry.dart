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
import '../../../../shared/widgets/oracly_quiet_link.dart';
import '../../../premium/models/premium_entitlement_state.dart';
import '../../../premium/providers/premium_providers.dart';
import '../../../reading_access/copy/freemium_copy.dart';
import '../../../reading_access/freemium_rollout.dart';
import '../../../reading_access/presentation/reading_allowance_navigation.dart';
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

  /// Freemium V1, not a verified member: the photos, marks and notes stay
  /// on the device until the user removes them here.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FreemiumCopy.cupMapDeleteTitle),
        content: Text(FreemiumCopy.cupMapDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(FreemiumCopy.cupMapDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(FreemiumCopy.cupMapDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(coffeeCupMapStoreProvider)?.deleteMap(widget.readingId);
    } catch (_) {
      // Kept as it was: nothing is reported gone that is not gone.
    }
    if (mounted) await _reload();
  }

  _DoorAccess _access() {
    if (!FreemiumRollout.enabled) return _DoorAccess.open;
    final premium = ref.watch(premiumStatusProvider);
    if (premium.loaded && premium.isPremium) return _DoorAccess.open;
    if (!premium.loaded || premium.busy) return _DoorAccess.checking;
    if (premium.entitlement == PremiumEntitlementState.error) {
      return _DoorAccess.failed;
    }
    return _DoorAccess.locked;
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final access = record == null ? _DoorAccess.open : _access();
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
          : access == _DoorAccess.open
          ? _DoorCard(key: const ValueKey('door'), record: record, onOpen: _open)
          : _DoorCard(
              key: const ValueKey('door-premium'),
              record: record,
              onOpen: null,
              access: access,
              onPremium: () => ReadingAllowanceNavigation.openPremium(context),
              onRetry: () => ref.read(premiumStatusProvider).refresh(),
              onDelete: _delete,
            ),
    );
  }
}

/// Freemium V1: whether the door opens. `open` is the approved card as is.
enum _DoorAccess { open, checking, locked, failed }

class _DoorCard extends StatelessWidget {
  const _DoorCard({
    super.key,
    required this.record,
    required this.onOpen,
    this.access = _DoorAccess.open,
    this.onPremium,
    this.onRetry,
    this.onDelete,
  });

  final CoffeeCupMapRecord record;
  final VoidCallback? onOpen;
  final _DoorAccess access;
  final VoidCallback? onPremium;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

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
          // The reading's own photos, the way they were taken. Each keeps
          // its full name for screen readers; the open action is below.
          GestureDetector(
              onTap: onOpen,
              excludeFromSemantics: true,
              child: Opacity(
                opacity: access == _DoorAccess.open ? 1 : 0.5,
                child: Row(
                children: [
                  for (final slot in coffeeV3CanonicalSlotOrder)
                    if (record.photoFor(slot) case final photo?)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Semantics(
                            image: true,
                            label: CoffeeCupMapCopy.photoLabel(slot),
                            child: ExcludeSemantics(
                              child: _Thumb(
                                photo: photo,
                                label: CoffeeCupMapCopy.photoLabel(slot),
                                shortLabel: CoffeeCupMapCopy.photoShortLabel(slot),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
                ),
              ),
          ),
          const SizedBox(height: 14),
          if (access == _DoorAccess.open) ...[
            Text(CoffeeCupMapCopy.entryBody, style: ReadingTypography.secondary()),
            const SizedBox(height: 16),
            OraclyGoldButton(
              label: CoffeeCupMapCopy.entryOpen,
              expanded: true,
              onPressed: onOpen,
            ),
          ] else
            ..._premiumDoor(),
        ],
      ),
    );
  }
}

extension on _DoorCard {
  List<Widget> _premiumDoor() {
    final (String body, Widget? action) = switch (access) {
      _DoorAccess.checking => (FreemiumCopy.cupMapChecking, null),
      _DoorAccess.failed => (
        FreemiumCopy.cupMapCheckFailed,
        OraclyQuietLink(label: FreemiumCopy.retry, onTap: onRetry ?? () {}),
      ),
      _ => (
        FreemiumCopy.cupMapLockedBody,
        _OutlinePill(
          label: FreemiumCopy.cupMapLockedCta,
          icon: Icons.lock_outline_rounded,
          onTap: onPremium,
        ),
      ),
    };
    return [
      Text(body, style: ReadingTypography.secondary()),
      const SizedBox(height: 14),
      ?action,
      if (access != _DoorAccess.checking && onDelete != null)
        Center(
          child: OraclyQuietLink(
            label: FreemiumCopy.cupMapDelete,
            muted: true,
            onTap: onDelete!,
          ),
        ),
    ];
  }
}

/// A quiet gold outline: an invitation, not a sale.
class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: OraclyChrome.pillRadius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.pillRadius,
              border: Border.all(
                color: OraclyChrome.gold.withValues(
                  alpha: OraclyChrome.borderEmphasis,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: OraclyChrome.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.label(color: OraclyChrome.goldLight),
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo, required this.label, this.shortLabel});

  final CoffeeCupMapPhoto photo;
  final String label;

  /// Shown with a cup glyph when [label] does not fit (narrow screen,
  /// large text); the full name stays in the semantics label.
  final String? shortLabel;

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
        LayoutBuilder(
          builder: (context, constraints) {
            final style = ReadingTypography.micro();
            final scaler = MediaQuery.textScalerOf(context);
            // Measure with the same inherited font the Text below draws in.
            final drawn = DefaultTextStyle.of(context).style.merge(style);
            final fits = (TextPainter(
              text: TextSpan(text: label, style: drawn),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout(maxWidth: constraints.maxWidth)).didExceedMaxLines == false;
            final short = shortLabel;
            if (fits || short == null) {
              return Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: scaler.scale(style.fontSize ?? 12),
                  color: style.color,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    short,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
