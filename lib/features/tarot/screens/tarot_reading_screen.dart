import 'package:flutter/material.dart';

import '../models/tarot_card.dart';
import '../services/tarot_ai_service.dart';
import '../utils/tarot_reading_parser.dart';
import '../widgets/tarot_card_hero.dart';
import '../widgets/tarot_cards_revealed_row.dart';
import '../widgets/tarot_cinematic_background.dart';
import '../widgets/tarot_insight_chips.dart';
import '../widgets/tarot_reading_actions.dart';
import '../widgets/tarot_reading_section.dart';
import '../widgets/tarot_screen_header.dart';
import '../widgets/tarot_secondary_cards_row.dart';

class TarotReadingScreen extends StatefulWidget {
  final List<TarotCard> cards;
  final String intention;

  const TarotReadingScreen({
    super.key,
    required this.cards,
    required this.intention,
  });

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  final TarotAiService _tarotAiService = TarotAiService();

  bool _loading = true;
  String _reading = '';

  static const _threeCardLabels = ['Geçmiş', 'Şimdi', 'Gelecek'];
  static const _contentMaxWidth = 520.0;

  @override
  void initState() {
    super.initState();
    _generateReading();
  }

  Future<void> _generateReading() async {
    final reading = await _tarotAiService.generateReading(
      cards: widget.cards,
      intention: widget.intention,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _reading = reading;
    });
  }

  String get _shareText {
    final cards = widget.cards.map((c) => c.name).join(', ');
    return 'Tarot Yorumu\nKartlar: $cards\n\n$_reading';
  }

  String? _positionLabel(int index) {
    if (widget.cards.length != 3 || index > 2) return null;
    return _threeCardLabels[index];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return TarotCinematicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Text(
                'Kart bulunamadı',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final primary = widget.cards.first;
    final secondary =
        widget.cards.length > 1 ? widget.cards.sublist(1) : const <TarotCard>[];
    final insights = TarotReadingParser.parseInsights(primary, _reading);

    return TarotCinematicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TarotReadingHeader(),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _contentMaxWidth),
                    child: SizedBox(
                      width: double.infinity,
                      child: TarotCardsRevealedRow(
                        cardCount: widget.cards.length,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: _contentMaxWidth),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TarotCardHero(
                                card: primary,
                                positionLabel: _positionLabel(0),
                              ),
                              const SizedBox(height: 20),
                              TarotInsightChips(insights: insights),
                              if (secondary.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                TarotSecondaryCardsRow(
                                  cards: secondary,
                                  positionLabels: [
                                    for (var i = 1; i < widget.cards.length; i++)
                                      _positionLabel(i),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              TarotReadingSection(
                                loading: _loading,
                                reading: _reading,
                                primaryCard: primary,
                              ),
                              TarotIntentionRibbon(
                                intention: widget.intention,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _contentMaxWidth),
                    child: SizedBox(
                      width: double.infinity,
                      child: TarotReadingActions(shareText: _shareText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
