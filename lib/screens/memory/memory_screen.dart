import 'package:flutter/material.dart';



import '../../core/copy/resilience_copy.dart';
import '../../core/copy/transparency_copy.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import '../../models/memory_item.dart';

import '../../services/memory_service.dart';

import '../../shared/widgets/oracly_empty_state.dart';

import '../../shared/widgets/oracly_skeleton_loader.dart';

import '../../widgets/glass_card.dart';

import '../../widgets/oracly_icon.dart';

import '../../widgets/oracly_scaffold.dart';



class MemoryScreen extends StatefulWidget {

  const MemoryScreen({super.key});



  @override

  State<MemoryScreen> createState() => _MemoryScreenState();

}



class _MemoryScreenState extends State<MemoryScreen> {

  final MemoryService _memoryService = MemoryService();

  List<MemoryItem> _memories = [];

  bool _isLoading = true;

  String? _loadError;



  @override

  void initState() {

    super.initState();

    _loadMemories();

  }



  Future<void> _loadMemories() async {

    setState(() {

      _isLoading = true;

      _loadError = null;

    });



    try {

      final memories = await _memoryService.getAdvancedMemories();

      if (!mounted) return;

      setState(() {

        _memories = memories;

        _isLoading = false;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() {

        _isLoading = false;

        _loadError = ResilienceCopy.genericLoadFailed;

      });

    }

  }



  Future<void> _deleteMemory(MemoryItem memory) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(TransparencyCopy.memoryDeleteTitle, style: AppTextStyles.title),
        content: Text(
          TransparencyCopy.memoryDeleteBody,
          style: AppTextStyles.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TransparencyCopy.memoryDeleteCancel, style: AppTextStyles.button),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              TransparencyCopy.memoryDeleteConfirm,
              style: AppTextStyles.button.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _memoryService.removeMemory(memory.content);
    _loadMemories();
  }

  Future<void> _editMemory(MemoryItem memory) async {
    final controller = TextEditingController(text: memory.content);
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Notu düzenle', style: AppTextStyles.title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Hafıza notu',
            border: OutlineInputBorder(borderRadius: AppRadius.md),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Vazgeç', style: AppTextStyles.button),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Kaydet', style: AppTextStyles.button),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated == null || updated.isEmpty || updated == memory.content) return;
    await _memoryService.removeMemory(memory.content);
    await _memoryService.addAdvancedMemory(
      MemoryItem(
        category: memory.category,
        content: updated,
        importance: memory.importance,
        createdAt: memory.createdAt,
      ),
    );
    _loadMemories();
  }



  IconData _categoryIcon(String category) {

    switch (category) {

      case 'goal':

        return Icons.flag_rounded;

      case 'interest':

        return Icons.favorite_rounded;

      case 'job':

        return Icons.work_rounded;

      case 'technology':

        return Icons.computer_rounded;

      default:

        return Icons.psychology_rounded;

    }

  }



  Color _importanceColor(String importance) {

    switch (importance) {

      case 'high':

        return AppColors.danger;

      case 'medium':

        return AppColors.gold;

      default:

        return AppColors.textSecondary;

    }

  }



  @override

  Widget build(BuildContext context) {

    return OraclyScaffold(

      appBar: AppBar(

        title: Text('OR Hafızası', style: AppTextStyles.title),

        centerTitle: true,

      ),

      body: Padding(

        padding: EdgeInsets.all(AppSpacing.lg),

        child: Column(

          children: [

            GlassCard(

              padding: AppSpacing.card,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      const OraclyIcon(Icons.psychology_rounded, size: 20),

                      SizedBox(width: AppSpacing.sm + AppSpacing.xs),

                      Text('OR Hafızası', style: AppTextStyles.title),

                    ],

                  ),

                  SizedBox(height: AppSpacing.sm),

                  Text(

                    _isLoading

                        ? 'Yükleniyor…'

                        : '${_memories.length} bilgi kayıtlı',

                    style: AppTextStyles.subtitle.copyWith(fontSize: 14),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            Expanded(

              child: _buildBody(),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildBody() {

    if (_isLoading) {

      return OraclySkeletonLoader(message: ResilienceCopy.memoryLoading);

    }



    if (_loadError != null) {

      return Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(

              _loadError!,

              textAlign: TextAlign.center,

              style: AppTextStyles.subtitle,

            ),

            const SizedBox(height: 16),

            TextButton(

              onPressed: _loadMemories,

              child: Text(ResilienceCopy.retryAction),

            ),

          ],

        ),

      );

    }



    if (_memories.isEmpty) {

      return OraclyEmptyState(

        icon: Icons.psychology_rounded,

        title: ResilienceCopy.memoryEmptyTitle,

        message: ResilienceCopy.memoryEmptyBody,

        ctaLabel: 'OR ile konuş',

        onCta: () => OraclyNavigationService.openChat(context),

      );

    }



    return ListView.builder(

      physics: const BouncingScrollPhysics(),

      itemCount: _memories.length,

      itemBuilder: (context, index) {

        final memory = _memories[index];

        return Padding(

          padding: EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),

          child: GlassCard(

            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),

            radius: AppRadius.xlValue,

            child: ListTile(

              leading: CircleAvatar(

                backgroundColor: AppColors.card,

                child: OraclyIcon(_categoryIcon(memory.category), size: 18),

              ),

              title: Text(

                memory.content,

                style: AppTextStyles.body.copyWith(fontSize: 15),

              ),

              subtitle: Text(

                '${memory.category} • ${memory.importance}',

                style: AppTextStyles.small.copyWith(

                  color: _importanceColor(memory.importance),

                ),

              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: 'Hafızayı düzenle',
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: AppColors.gold.withValues(alpha: 0.85),
                        size: 20,
                      ),
                      onPressed: () => _editMemory(memory),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Hafızayı sil',
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.danger.withValues(alpha: 0.85),
                        size: 20,
                      ),
                      onPressed: () => _deleteMemory(memory),
                    ),
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

