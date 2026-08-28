from pathlib import Path
ROOT = Path(r"C:\Dev\oracly_new")

def patch(rel, old, new):
    p = ROOT / rel
    t = p.read_text(encoding="utf-8")
    if old not in t:
        raise SystemExit(f"MISSING {rel}: {old[:100]!r}")
    p.write_text(t.replace(old, new), encoding="utf-8", newline="\n")
    print("ok", rel)

# 1 Premium Privacy
patch(
    "lib/features/premium/presentation/reference/premium_reference_links.dart",
    '''import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../daily_rewards/copy/daily_rewards_copy.dart';
import '../../../gems/copy/gems_copy.dart';''',
    '''import '../../../../core/l10n/l10n.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../daily_rewards/copy/daily_rewards_copy.dart';
import '../../../gems/copy/gems_copy.dart';''',
)
patch(
    "lib/features/premium/presentation/reference/premium_reference_links.dart",
    '''        _Link(
          label: DailyRewardsCopy.screenTitle,
          onTap: () => OraclyNavigationService.openDailyRewards(context),
        ),
      ],
    );
  }
}''',
    '''        _Link(
          label: DailyRewardsCopy.screenTitle,
          onTap: () => OraclyNavigationService.openDailyRewards(context),
        ),
        Text(
          '·',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gold.withValues(alpha: 0.55),
          ),
        ),
        _Link(
          label: OraclyL10n.t(L10nKeys.privacy),
          onTap: () => OraclyNavigationService.openPrivacy(context),
        ),
      ],
    );
  }
}''',
)

# 2 Coffee retry
patch(
    "lib/features/coffee/presentation/reference/coffee_reference_body.dart",
    '''      CoffeePhase.error => CoffeeErrorView(
          message: controller.errorMessage ?? CoffeeCopy.analysisFailed,
          onRetry: controller.retryCapture,
          onBack: controller.backToEntry,
        ),''',
    '''      CoffeePhase.error => CoffeeErrorView(
          message: controller.errorMessage ?? CoffeeCopy.analysisFailed,
          onRetry: controller.image != null
              ? onAnalyze
              : controller.retryCapture,
          onBack: controller.backToEntry,
        ),''',
)

# 3 Dream — add key + copy + use it
# Find table_dream for a place to add key
dream_table = (ROOT / "lib/core/l10n/tables/table_dream.dart").read_text(encoding="utf-8")
if "dream.new" not in dream_table:
    # insert after dream.save_close if present
    needle = "'dream.save_close':"
    idx = dream_table.find(needle)
    if idx < 0:
        raise SystemExit("dream.save_close missing")
    # find end of that L10nTriple entry
    end = dream_table.find("\n", dream_table.find("),", idx)) + 1
    insert = """  'dream.new': L10nTriple('Yeni rüya', 'New dream', 'Новый сон'),
"""
    dream_table = dream_table[:end] + insert + dream_table[end:]
    (ROOT / "lib/core/l10n/tables/table_dream.dart").write_text(dream_table, encoding="utf-8", newline="\n")
    print("ok table_dream dream.new")

patch(
    "lib/features/dream/copy/dream_copy.dart",
    "  static String get saveAndClose => _t('dream.save_close');",
    "  static String get saveAndClose => _t('dream.save_close');\n  static String get newDream => _t('dream.new');",
)
patch(
    "lib/features/dream/presentation/reference/dream_reference_result_actions.dart",
    "          text: 'Yeni rüya',",
    "          text: DreamCopy.newDream,",
)

# 5 Journal error
patch(
    "lib/features/discovery_journal/presentation/screens/discovery_journal_screen.dart",
    '''import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';''',
    '''import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';''',
)
patch(
    "lib/features/discovery_journal/presentation/screens/discovery_journal_screen.dart",
    '''              child: async.when(
                loading: () => const OraclyCinematicLoading(compact: true),
                error: (_, _) => const DiscoveryJournalEmpty(),
                data: (items) => items.isEmpty
                    ? const DiscoveryJournalEmpty()
                    : DiscoveryJournalTimeline(
                        items: items,
                        focusTheme: focusTheme,
                      ),
              ),''',
    '''              child: async.when(
                loading: () => const OraclyCinematicLoading(compact: true),
                error: (_, _) => OraclyErrorState(
                  kind: OraclyLoadingKind.generic,
                  title: ResilienceCopy.historyLoadFailedTitle,
                  message: ResilienceCopy.historyLoadFailed,
                  onRetry: () =>
                      ref.invalidate(discoveryJournalEntriesProvider),
                ),
                data: (items) => items.isEmpty
                    ? const DiscoveryJournalEmpty()
                    : DiscoveryJournalTimeline(
                        items: items,
                        focusTheme: focusTheme,
                      ),
              ),''',
)

print("batch A done")
