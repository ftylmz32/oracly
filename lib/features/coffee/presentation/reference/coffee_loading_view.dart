/// Coffee analysis wait — real cup, amber breath, honest slow recovery.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import 'coffee_cup_wait.dart';

class CoffeeLoadingView extends StatelessWidget {
  const CoffeeLoadingView({
    super.key,
    required this.message,
    this.subtitle,
    this.imagePath,
    this.onRetry,
  });

  final String message;
  final String? subtitle;
  final String? imagePath;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasCup = path != null && File(path).existsSync();
    return OraclyLoadingCinema(
      kind: OraclyLoadingKind.coffee,
      message: message,
      subtitle: subtitle,
      imagePath: path,
      onRetry: onRetry,
      stage: hasCup
          ? CoffeeCupWait(message: '', path: path, fixedHeight: 268)
          : null,
    );
  }
}
