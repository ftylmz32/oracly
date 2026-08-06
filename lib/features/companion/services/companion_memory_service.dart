/// SPRINT-003 — Transparent user memory bridge.
library;

import '../../../../models/memory_item.dart';
import '../../../../services/memory_service.dart';
import '../models/memory.dart';
import '../models/memory_permission.dart';

class CompanionMemoryService {
  CompanionMemoryService(this._legacy);

  final MemoryService _legacy;

  Future<List<Memory>> savedMemories() async {
    final items = await _legacy.getAdvancedMemories();
    return items
        .map(
          (item) => Memory(
            id: _idFor(item),
            content: item.content,
            category: item.category,
            permission: MemoryPermission.saved,
            createdAt: item.createdAt,
            source: MemorySource.user,
          ),
        )
        .toList();
  }

  Future<void> save(Memory memory) async {
    if (memory.permission != MemoryPermission.saved) return;
    await _legacy.addAdvancedMemory(
      MemoryItem(
        category: memory.category,
        content: memory.content,
        importance: 'normal',
        createdAt: memory.createdAt,
      ),
    );
  }

  Future<void> update(Memory memory) async {
    await deleteByContent(memory.content);
    await save(memory.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> delete(String content) async {
    await _legacy.removeMemory(content);
  }

  Future<void> deleteByContent(String content) async {
    await _legacy.removeMemory(content);
  }

  String _idFor(MemoryItem item) =>
      'mem_${item.createdAt.millisecondsSinceEpoch}_${item.content.hashCode}';
}
