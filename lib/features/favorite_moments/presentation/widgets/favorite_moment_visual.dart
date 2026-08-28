/// Visual thumbnail — editorial frame, gold edge, photo or quiet icon.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_entry_icon.dart';
import '../../models/favorite_moment.dart';

class FavoriteMomentVisual extends StatelessWidget {
  const FavoriteMomentVisual({super.key, required this.moment, this.size = 64});

  final FavoriteMoment moment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = moment.visualAsset?.trim();
    final cacheW = oraclyDecodeCachePx(
      size,
      MediaQuery.devicePixelRatioOf(context),
      maxPx: 512,
    );
    Widget inner;
    if (asset != null && asset.isNotEmpty) {
      if (asset.startsWith('assets/')) {
        inner = Image.asset(
          asset,
          fit: BoxFit.cover,
          width: size,
          height: size,
          gaplessPlayback: true,
          cacheWidth: cacheW,
          errorBuilder: (_, error, stack) => _Icon(kind: moment.source, size: size),
        );
      } else {
        inner = Image.file(
          File(asset),
          fit: BoxFit.cover,
          width: size,
          height: size,
          gaplessPlayback: true,
          cacheWidth: cacheW,
          errorBuilder: (_, error, stack) => _Icon(kind: moment.source, size: size),
        );
      }
    } else {
      inner = _Icon(kind: moment.source, size: size);
    }
    return _Frame(size: size, child: inner);
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.kind, required this.size});

  final FavoriteMomentSource kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        DiscoveryJournalEntryIcon.of(kind.journalKind),
        size: size * 0.36,
        color: OraclyChrome.goldLight.withValues(alpha: 0.84),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: 0.35),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: child,
        ),
      ),
    );
  }
}
