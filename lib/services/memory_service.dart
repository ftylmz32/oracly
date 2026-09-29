import 'dart:convert';

import '../core/data/datasources/local_storage.dart';
import '../models/memory_item.dart';

class MemoryService {
  /// Canonical storage boundary — same [LocalStorage] instance every other
  /// feature uses. No fallback, no second `SharedPreferences.getInstance()`
  /// acquisition path — every caller must go through `memoryServiceProvider`
  /// (or otherwise supply the app's one real [LocalStorage]).
  MemoryService(this._storage);

  final LocalStorage _storage;

  static const String _nameKey = "user_name";
  static const String _memoryKey = "user_memories";

  // Kullanıcı adını kaydet
  Future<void> saveUserName(String name) async {
    await _storage.setString(_nameKey, name);
  }

  // Kullanıcı adını getir
  Future<String?> getUserName() async {
    return _storage.getString(_nameKey);
  }

  // Yeni hafıza ekleme
  // Aynı bilgi varsa tekrar kaydetmez
  Future<void> addAdvancedMemory(MemoryItem item) async {
    final memories = await getAdvancedMemories();
    final exists = memories.any(
      (memory) =>
          memory.content.toLowerCase().trim() ==
          item.content.toLowerCase().trim(),
    );
    if (exists) return;
    memories.add(item);
    await _saveMemories(memories);
  }

  /// Replaces one row in a single write. A failed write leaves [previous].
  Future<bool> updateMemory(MemoryItem previous, MemoryItem next) async {
    final memories = await getAdvancedMemories();
    final index = memories.indexWhere(
      (item) => item.content == previous.content,
    );
    if (index < 0) return false;
    final nextKey = next.content.toLowerCase().trim();
    if (nextKey.isEmpty) return false;
    final duplicate = memories.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.content.toLowerCase().trim() == nextKey,
    );
    if (duplicate) return false;
    memories[index] = next;
    return _saveMemories(memories);
  }

  Future<bool> _saveMemories(List<MemoryItem> memories) {
    final encoded = memories.map((e) => jsonEncode(e.toJson())).toList();
    return _storage.setStringList(_memoryKey, encoded);
  }

  // Gelişmiş hafızaları getir — bozuk/eski satırlar atılmaz, ham metin
  // olarak korunur; tek bir satırın bozuk olması diğerlerini etkilemez.
  Future<List<MemoryItem>> getAdvancedMemories() async {
    final data = _storage.getStringList(_memoryKey) ?? [];
    return data.map((item) {
      try {
        return MemoryItem.fromJson(jsonDecode(item));
      } catch (e) {
        return MemoryItem(
          category: "general",
          content: item,
          importance: "normal",
          createdAt: DateTime.now(),
        );
      }
    }).toList();
  }

  // Hafıza var mı kontrol
  Future<bool> memoryExists(String content) async {
    final memories = await getAdvancedMemories();
    return memories.any(
      (memory) =>
          memory.content.toLowerCase().trim() == content.toLowerCase().trim(),
    );
  }

  // Eski sistem uyumluluğu
  Future<List<String>> getMemories() async {
    final memories = await getAdvancedMemories();
    return memories.map((e) => e.content).toList();
  }

  // Eski addMemory uyumluluğu
  Future<void> addMemory(String memory) async {
    await addAdvancedMemory(
      MemoryItem(
        category: "general",
        content: memory,
        importance: "normal",
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Removes one row. `false` means storage still holds [memory].
  Future<bool> removeMemory(String memory) async {
    final memories = await getAdvancedMemories();
    final next = [
      for (final item in memories)
        if (item.content != memory) item,
    ];
    if (next.length == memories.length) return false;
    return _saveMemories(next);
  }

  // Tüm hafızayı temizle
  Future<void> clearMemory() async {
    await _storage.remove(_memoryKey);
    await _storage.remove(_nameKey);
    // Personal Memory Core — compact summary, not raw chat.
    await _storage.remove('or_personal_memory_v1');
    await _storage.remove('discovery_surface_memory_v1');
  }
}
