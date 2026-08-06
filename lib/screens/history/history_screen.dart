import 'package:flutter/material.dart';

import '../../core/copy/resilience_copy.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/reading_typography.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/oracly_empty_state.dart';
import '../../shared/widgets/oracly_skeleton_loader.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final messages = await _storageService.loadMessages();
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await _storageService.clearMessages();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sohbet Geçmişi', style: AppTextStyles.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Geçmişi temizle',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return OraclySkeletonLoader(message: ResilienceCopy.historyLoading);
    }

    if (_messages.isEmpty) {
      return OraclyEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: ResilienceCopy.chatHistoryEmptyTitle,
        message: ResilienceCopy.chatHistoryEmptyBody,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['isUser'] ?? false;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'Sen' : 'OR',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    message['text'] ?? '',
                    style: ReadingTypography.bodySmall(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
