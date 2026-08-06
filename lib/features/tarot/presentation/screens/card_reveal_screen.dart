/// OR-1170 — Cinematic card reveal screen.

library;



import 'package:flutter/material.dart';



import '../../../../core/copy/reading_flow_copy.dart';

import '../../../../core/theme/app_colors.dart';

import '../../shared/constants/tarot_routes.dart';

import '../../shared/tarot_scope.dart';

import '../../theme/tarot_tokens.dart';

import '../animations/tarot_transition.dart';

import '../widgets/card_reveal/card_reveal_experience.dart';

import '../widgets/card_reveal/card_reveal_spread.dart';

import '../../components/tarot_error_state.dart';

import 'card_selection_screen.dart';

import 'reading_screen.dart';



/// Full cinematic reveal — continues from card selection.

class CardRevealScreen extends StatefulWidget {

  const CardRevealScreen({super.key});



  @override

  State<CardRevealScreen> createState() => _CardRevealScreenState();

}



class _CardRevealScreenState extends State<CardRevealScreen>

    with SingleTickerProviderStateMixin {

  late final AnimationController _enter;

  RevealCardData? _data;



  @override

  void initState() {

    super.initState();

    _enter = AnimationController(

      vsync: this,

      duration: TarotTokens.screenSettle,

    )..forward();

  }



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    final drawn = TarotScope.of(context).reading.session?.currentCard;

    if (drawn != null) {

      _data = RevealCardData.fromDrawnCard(drawn);

    }

  }



  @override

  void dispose() {

    _enter.dispose();

    super.dispose();

  }



  Future<void> _openNext() async {

    final reading = TarotScope.of(context).reading;

    await reading.advanceAfterReveal();

    if (!mounted) return;



    final session = reading.session;

    if (session != null && !session.allCardsDrawn) {

      Navigator.of(context).pushReplacement(

        cardSelectionRitualRoute<void>(

          page: const CardSelectionScreen(),

          settings: const RouteSettings(name: TarotRoutes.cardSelection),

        ),

      );

      return;

    }



    Navigator.of(context).push(

      readingRitualRoute<void>(

        page: const ReadingScreen(),

        settings: const RouteSettings(name: TarotRoutes.reading),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final data = _data;

    if (data == null) {

      return Scaffold(

        backgroundColor: AppColors.background,

        body: TarotErrorState(

          message: ReadingFlowCopy.revealSessionMissing,

          onRetry: () => Navigator.of(context).pop(),

        ),

      );

    }



    return PopScope(

      canPop: true,

      child: Scaffold(

        backgroundColor: AppColors.background,

        body: AnimatedBuilder(

          animation: _enter,

          builder: (context, child) {

            final enterT = TarotTokens.revealCurve.transform(_enter.value);

            final settleOpacity = TarotTokens.screenSettleOpacityBegin +

                (1.0 - TarotTokens.screenSettleOpacityBegin) * enterT;

            return Opacity(opacity: settleOpacity, child: child);

          },

          child: CardRevealExperience(

            data: data,

            onContinue: _openNext,

          ),

        ),

      ),

    );

  }

}



/// Smooth transition from card selection into reveal.

PageRouteBuilder<T> cardRevealRitualRoute<T>({

  required Widget page,

  RouteSettings? settings,

}) {

  return tarotRitualDepthHandoffRoute<T>(

    page: page,

    settings: settings,

  );

}

