/// Feature plate emblem for empty / error / offline — never Material icons.
library;

import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../loading_cinema/oracly_loading_kind.dart';
import 'oracly_async_atmosphere.dart';

class OraclyAsyncEmblem extends StatelessWidget {
  const OraclyAsyncEmblem({
    super.key,
    required this.kind,
    this.size = 112,
    this.offline = false,
    this.amber = false,
    this.assetPath,
    this.warm,
  });

  final OraclyLoadingKind kind;
  final double size;
  final bool offline;
  final bool amber;
  final String? assetPath;
  final bool? warm;

  @override
  Widget build(BuildContext context) {
    final ring = OraclyAsyncAtmosphere.ring(kind, offline: offline || amber);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ring.withValues(alpha: amber || offline ? 0.55 : 0.28),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: ring.withValues(alpha: amber || offline ? 0.18 : 0.10),
              blurRadius: 18,
            ),
          ],
        ),
        child: OraclyEmptyAtmosphere(
          assetPath: assetPath ?? OraclyAsyncAtmosphere.plate(kind),
          size: size * 0.92,
          warm: warm ?? OraclyAsyncAtmosphere.warm(kind),
        ),
      ),
    );
  }
}
