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

  // Hafızaları kaydet
  Future<void> _saveMemories(List<MemoryItem> memories) async {
    final encoded = memories.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(_memoryKey, encoded);
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

  // Tek hafıza silme
  Future<void> removeMemory(String memory) async {
    final memories = await getAdvancedMemories();
    memories.removeWhere((item) => item.content == memory);
    await _saveMemories(memories);
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
