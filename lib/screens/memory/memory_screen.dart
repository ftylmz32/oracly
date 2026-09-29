import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/auth/user_local_data_isolation.dart';
import '../../core/providers/backend_providers.dart' as backend;
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
import '../../shared/ui/oracly_snackbar.dart';
import '../../shared/widgets/oracly_empty_state.dart';
import '../../shared/widgets/oracly_gold_button.dart';

import '../../shared/widgets/oracly_skeleton_loader.dart';

import '../../core/design_system/oracly_glass_card.dart';
import '../../core/design_system/oracly_header_action.dart';

import '../../widgets/oracly_icon.dart';

import '../../core/theme/craftsmanship_rhythm.dart';
import '../../shared/widgets/oracly_entrance.dart';
import '../../shared/widgets/oracly_scaffold.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  // Canonical injected instance — never construct MemoryService() directly
  // here (that would bypass the shared LocalStorage boundary).
  MemoryService get _memoryService => ref.read(memoryServiceProvider);

  List<MemoryItem> _memories = [];

  bool _isLoading = true;

  String? _loadError;

  int _shownEpoch = UserLocalDataIsolation.accountSwitchEpoch.value;

  int _loadTicket = 0;

  @override
  void initState() {
    super.initState();

    _loadMemories();
  }

  void _noteEpoch(int epoch) {
    if (epoch == _shownEpoch) return;
    _shownEpoch = epoch;
    _loadTicket++;
    _memories = const [];
    _isLoading = true;
    _loadError = null;
    final ticket = _loadTicket;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMemories(ticket);
    });
  }

  Future<void> _loadMemories([int? ticket]) async {
    final current = ticket ?? ++_loadTicket;
    if (ticket == null) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final memories = await _memoryService.getAdvancedMemories();

      if (!mounted || current != _loadTicket) return;

      setState(() {
        _memories = memories;

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || current != _loadTicket) return;

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
    final removed = await _memoryService.removeMemory(memory.content);
    if (!mounted) return;
    if (!removed) {
      OraclySnackBar.show(context, message: ResilienceCopy.genericLoadFailed);
    }
    await _loadMemories();
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
    if (updated == null ||
        updated.trim().isEmpty ||
        updated == memory.content) {
      return;
    }
    final saved = await _memoryService.updateMemory(
      memory,
      MemoryItem(
        category: memory.category,
        content: updated,
        importance: memory.importance,
        createdAt: memory.createdAt,
      ),
    );
    if (!mounted) return;
    if (!saved) {
      OraclySnackBar.show(context, message: ResilienceCopy.genericLoadFailed);
    }
    await _loadMemories();
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
    _noteEpoch(ref.watch(backend.localDataOwnerEpochProvider));
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

                        Text(
                          OraclyL10n.t('memory.title'),
                          style: AppTextStyles.title,
                        ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.sm),

                    Text(
                      _isLoading
                          ? OraclyL10n.t('resilience.generic_loading')
                          : OraclyL10n.t(
                              'memory.count',
                            ).replaceAll('{n}', '${_memories.length}'),

                      style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Expanded(child: _buildBody()),
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
                    OraclyHeaderAction(
                      icon: Icons.edit_outlined,
                      label: OraclyL10n.t('memory.edit'),
                      iconSize: 18,
                      onTap: () => _editMemory(memory),
                    ),
                    OraclyHeaderAction(
                      icon: Icons.delete_outline,
                      label: OraclyL10n.t('memory.delete'),
                      iconSize: 18,
                      onTap: () => _deleteMemory(memory),
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
