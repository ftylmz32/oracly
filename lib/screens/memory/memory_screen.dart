import 'package:flutter/material.dart';



import '../../core/copy/resilience_copy.dart';
import '../../core/l10n/l10n.dart';
import '../../core/copy/transparency_copy.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import '../../models/memory_item.dart';

import '../../services/memory_service.dart';

import '../../core/constants/app_assets.dart';
import '../../shared/ui/oracly_dialog.dart';
import '../../shared/widgets/oracly_empty_state.dart';
import '../../shared/widgets/oracly_gold_button.dart';

import '../../shared/widgets/oracly_skeleton_loader.dart';

import '../../core/design_system/oracly_glass_card.dart';
import '../../core/design_system/oracly_header_action.dart';

import '../../widgets/oracly_icon.dart';

import '../../core/theme/craftsmanship_rhythm.dart';
import '../../shared/widgets/oracly_entrance.dart';
import '../../shared/widgets/oracly_scaffold.dart';



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
    final confirm = await OraclyDialog.confirm(
      context,
      title: TransparencyCopy.memoryDeleteTitle,
      message: TransparencyCopy.memoryDeleteBody,
      confirmLabel: TransparencyCopy.memoryDeleteConfirm,
      cancelLabel: TransparencyCopy.memoryDeleteCancel,
      destructive: true,
    );
    if (confirm != true) return;
    await _memoryService.removeMemory(memory.content);
    _loadMemories();
  }

  Future<void> _editMemory(MemoryItem memory) async {
    final updated = await OraclyDialog.prompt(
      context,
      title: OraclyL10n.t('memory.edit_title'),
      hint: OraclyL10n.t('memory.hint'),
      initial: memory.content,
      confirmLabel: OraclyL10n.t(L10nKeys.save),
      cancelLabel: OraclyL10n.t('trust.delete_cancel'),
    );
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(OraclyL10n.t('memory.title'), style: AppTextStyles.title),
        centerTitle: true,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            OraclyEntrance(
              child: OraclyGlassCard(

              padding: AppSpacing.card,

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      const OraclyIcon(Icons.psychology_rounded, size: 20),

                      SizedBox(width: AppSpacing.sm + AppSpacing.xs),

                      Text(OraclyL10n.t('memory.title'), style: AppTextStyles.title),

                    ],

                  ),

                  SizedBox(height: AppSpacing.sm),

                  Text(

                    _isLoading

                        ? OraclyL10n.t('resilience.generic_loading')

                        : OraclyL10n.t('memory.count').replaceAll(
                            '{n}',
                            '${_memories.length}',
                          ),

                    style: AppTextStyles.subtitle.copyWith(fontSize: 14),

                  ),

                ],

              ),

            ),

            ),
            SizedBox(height: AppSpacing.md),
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

            SizedBox(height: AppSpacing.md),
            OraclyGoldButton(
              label: ResilienceCopy.retryAction,
              onPressed: _loadMemories,
            ),

          ],

        ),

      );

    }



    if (_memories.isEmpty) {

      return OraclyEmptyState(
        imageAsset: AppAssets.heroOrbPremium,
        title: ResilienceCopy.memoryEmptyTitle,

        message: ResilienceCopy.memoryEmptyBody,

        ctaLabel: OraclyL10n.t('memory.talk'),

        onCta: () => OraclyNavigationService.openChat(context),

      );

    }



    return ListView.builder(
      physics: CraftsmanshipRhythm.scrollPhysics,
      itemCount: _memories.length,
      itemBuilder: (context, index) {
        final memory = _memories[index];
        return OraclyEntrance.staggered(
          index: index,
          child: Padding(

          padding: EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),

          child: OraclyGlassCard(

            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),

            borderRadius: AppRadius.xl,

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

                '${OraclyL10n.t('memory.cat.${memory.category}')} • ${OraclyL10n.t('memory.imp.${memory.importance}')}',

                style: AppTextStyles.small.copyWith(

                  color: _importanceColor(memory.importance),

                ),

              ),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: OraclyL10n.t('memory.edit'),
                    child: OraclyHeaderAction(
                      icon: Icons.edit_outlined,
                      label: OraclyL10n.t('memory.edit'),
                      size: 36,
                      iconSize: 18,
                      onTap: () => _editMemory(memory),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: OraclyL10n.t('memory.delete'),
                    child: OraclyHeaderAction(
                      icon: Icons.delete_outline,
                      label: OraclyL10n.t('memory.delete'),
                      size: 36,
                      iconSize: 18,
                      onTap: () => _deleteMemory(memory),
                    ),
                  ),
                ],
              ),

            ),

          ),
        ),
        );
      },
    );

  }

}

