/// Tarot module root — single persistent mystical table.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ritual/table/tarot_table_scene.dart';

class TarotHomeScreen extends ConsumerWidget {
  const TarotHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TarotTableScene();
  }
}
