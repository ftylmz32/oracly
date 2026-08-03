import 'package:flutter/material.dart';

import '../../../../models/memory_item.dart';
import '../../../../widgets/memory_card.dart';

class MemorySection extends StatelessWidget {
  const MemorySection({
    super.key,
    required this.memories,
  });

  final List<MemoryItem> memories;

  @override
  Widget build(BuildContext context) {
    return MemoryCard(memories: memories);
  }
}
