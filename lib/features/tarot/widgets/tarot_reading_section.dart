import 'package:flutter/material.dart';



import '../models/tarot_card.dart';

import '../utils/tarot_reading_parser.dart';

import 'tarot_interpretation_sections.dart';

import 'tarot_ornament_frame.dart';

import 'tarot_typography.dart';



class TarotReadingSection extends StatefulWidget {

  const TarotReadingSection({

    super.key,

    required this.loading,

    required this.reading,

    required this.primaryCard,

  });



  final bool loading;

  final String reading;

  final TarotCard primaryCard;



  @override

  State<TarotReadingSection> createState() => _TarotReadingSectionState();

}



class _TarotReadingSectionState extends State<TarotReadingSection> {

  double _contentOpacity = 0;



  @override

  void initState() {

    super.initState();

    if (!widget.loading) _contentOpacity = 1;

  }



  @override

  void didUpdateWidget(covariant TarotReadingSection oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.loading && !widget.loading) {

      Future.microtask(() {

        if (mounted) setState(() => _contentOpacity = 1);

      });

    }

  }



  @override

  Widget build(BuildContext context) {

    if (widget.loading) {

      return const TarotOrnamentFrame(child: TarotInterpretationLoading());

    }



    final sections = TarotReadingParser.parseSections(

      widget.reading,

      widget.primaryCard,

    );



    return AnimatedOpacity(

      opacity: _contentOpacity,

      duration: const Duration(milliseconds: 560),

      curve: Curves.easeOutCubic,

      child: TarotInterpretationSections(sections: sections),

    );

  }

}



/// Intention ribbon beneath interpretation content.

class TarotIntentionRibbon extends StatelessWidget {

  const TarotIntentionRibbon({super.key, required this.intention});



  final String intention;



  @override

  Widget build(BuildContext context) {

    if (intention.trim().isEmpty) return const SizedBox.shrink();



    return Padding(

      padding: const EdgeInsets.only(top: 14),

      child: Text(

        'Niyet · $intention',

        textAlign: TextAlign.center,

        style: TarotTypography.captionMuted(size: 11),

      ),

    );

  }

}

