import 'package:flutter/material.dart';

import '../../features/home/home_view.dart';
import '../../models/memory_item.dart';
import '../../services/greeting_service.dart';
import '../../services/memory_service.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MemoryService _memoryService = MemoryService();
  final GreetingService _greetingService = GreetingService();
  final ProfileService _profileService = ProfileService();
  final StorageService _storageService = StorageService();

  List<MemoryItem> _memories = [];
  String _greeting = '👋 Merhaba';
  String _message =
      'Bugün seni neler bekliyor keşfetmeye hazır mısın?';
  String? _lastConversation;

  @override
  void initState() {
    super.initState();
    _loadGreeting();
    _loadMemories();
    _loadLastConversation();
  }

  Future<void> _loadGreeting() async {
    final profile = await _profileService.getProfile();
    final name = profile['name']?.toString().trim();
    final userName =
        (name == null || name.isEmpty) ? 'Oracly kullanıcısı' : name;

    if (!mounted) return;

    setState(() {
      _greeting = _greetingService.getGreeting(userName);
      _message = _greetingService.getMessage();
    });
  }

  Future<void> _loadMemories() async {
    final memories = await _memoryService.getAdvancedMemories();
    if (!mounted) return;
    setState(() => _memories = memories);
  }

  Future<void> _loadLastConversation() async {
    final messages = await _storageService.loadMessages();
    if (!mounted) return;
    if (messages.isEmpty) {
      setState(() => _lastConversation = null);
      return;
    }
    final last = messages.last;
    final text = (last['content'] ?? last['text'] ?? last['message'])
        ?.toString()
        .trim();
    setState(() => _lastConversation = text?.isEmpty == true ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return HomeView(
      greeting: _greeting,
      message: _message,
      memories: _memories,
      lastConversation: _lastConversation,
    );
  }
}
