/// OR-1080 — Premium Card Detail encyclopedia screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/animations/tarot_transition.dart';

import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/content/providers/content_providers.dart';
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../../../features/discovery_share/widgets/discovery_share_action.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../navigation/tarot_navigator.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../theme/tarot_tokens.dart';
import '../widgets/card_detail/card_detail_ai_insight.dart';
import '../widgets/card_detail/card_detail_background.dart';
import '../widgets/card_detail/card_detail_bottom_actions.dart';
import '../widgets/card_detail/card_detail_catalogue.dart';
import '../widgets/card_detail/card_detail_hero_header.dart';
import '../widgets/card_detail/card_detail_info_chips.dart';
import '../widgets/card_detail/card_detail_meanings_accordion.dart';
import '../widgets/card_detail/card_detail_models.dart';
import '../widgets/card_detail/card_detail_related_carousel.dart';
import '../widgets/card_detail/card_detail_symbolism.dart';

/// Wikipedia-style deep dive for a single tarot card.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({
    super.key,
    this.cardId = 0,
  });

  final int cardId;

  static const double heroExpandedHeight = 420;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scroll;
  late final AnimationController _entrance;
  late CardDetailContent _content;

  double _scrollOffset = 0;
  String? _expandedMeaning;
  bool _favorite = false;
  bool _favoriteBusy = false;

  String get _contentId => 'tarot_${widget.cardId}';

  @override
  void initState() {
    super.initState();
    _content = CardDetailCatalogue.forId(widget.cardId);
    _scroll = ScrollController()..addListener(_onScroll);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFavorite());
  }

  @override
  void didUpdateWidget(covariant CardDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardId != widget.cardId) {
      _content = CardDetailCatalogue.forId(widget.cardId);
      _expandedMeaning = null;
      _loadFavorite();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scroll.offset);
  }

  void _toggleMeaning(String key) {
    setState(() {
      _expandedMeaning = _expandedMeaning == key ? null : key;
    });
  }

  Future<void> _loadFavorite() async {
    final stored = await ref
        .read(contentFavoritesStoreProvider)
        .isFavorite('tarot', _contentId);
    if (!mounted) return;
    setState(() => _favorite = stored);
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    _favoriteBusy = true;
    try {
      await ref
          .read(contentFavoritesStoreProvider)
          .toggleFavorite('tarot', _contentId);
      final stored = await ref
          .read(contentFavoritesStoreProvider)
          .isFavorite('tarot', _contentId);
      if (!mounted) return;
      setState(() => _favorite = stored);
      OraclySnackBar.success(
        context,
        stored
            ? OraclyL10n.t('tarot.fav_added')
                .replaceAll('{name}', _content.displayName)
            : OraclyL10n.t('tarot.fav_removed')
                .replaceAll('{name}', _content.displayName),
      );
    } finally {
      _favoriteBusy = false;
    }
  }

  Future<void> _share() async {
    await invokeDiscoveryShare(
      context,
      DiscoveryShareBuilder.tarot(
        cardName: _content.displayName,
        cardAsset: _content.imageAsset,
      ),
    );
  }

  void _openReading() {
    TarotNavigator.pushNamed(context, TarotRoutes.deckSelection);
  }

  void _openRelated(CardDetailContent related) {
    Navigator.of(context).push(
      cardDetailRoute(cardId: related.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = Curves.easeOutCubic.transform(
      _entrance.value.clamp(0.0, 1.0),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CardDetailBackground(),
          CustomScrollView(
            controller: _scroll,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: CardDetailScreen.heroExpandedHeight,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.background.withValues(alpha: 0.72),
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: CardDetailHeroHeader(
                    content: _content,
                    scrollOffset: _scrollOffset,
                    isFavorite: _favorite,
                    onBack: () => Navigator.of(context).pop(),
                    onFavorite: _toggleFavorite,
                    onShare: _share,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: TarotTokens.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppSpacing.lg),
                        CardDetailInfoChips(
                          content: _content,
                          entrance: cardDetailSectionEntrance(0, master),
                        ),
                        SizedBox(height: AppSpacing.xl),
                        CardDetailMeaningsAccordion(
                          meanings: _content.meanings,
                          expandedKey: _expandedMeaning,
                          onToggle: _toggleMeaning,
                          entrance: cardDetailSectionEntrance(1, master),
                          accent: _content.accentColor,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        CardDetailSymbolism(
                          symbols: _content.symbols,
                          entrance: cardDetailSectionEntrance(2, master),
                          accent: _content.accentColor,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        CardDetailAiInsight(
                          insight: _content.aiInsight,
                          entrance: cardDetailSectionEntrance(3, master),
                          accent: _content.accentColor,
                        ),
                        SizedBox(height: AppSpacing.xl),
                        CardDetailRelatedCarousel(
                          relatedIds: _content.relatedIds,
                          entrance: cardDetailSectionEntrance(4, master),
                          onCardTap: _openRelated,
                        ),
                        SizedBox(
                          height: AppSpacing.xxl + AppSpacing.xxl + AppSpacing.lg,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: TarotTokens.maxContentWidth,
                ),
                child: CardDetailBottomActions(
                  isFavorite: _favorite,
                  entrance: cardDetailSectionEntrance(5, master),
                  onReading: _openReading,
                  onFavorite: _toggleFavorite,
                  onShare: _share,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero page route for card detail navigation.
Route<T> cardDetailRoute<T>({required int cardId}) {
  return tarotRitualRoute<T>(
    page: CardDetailScreen(cardId: cardId),
    settings: RouteSettings(name: '/tarot/card/$cardId'),
  );
}
