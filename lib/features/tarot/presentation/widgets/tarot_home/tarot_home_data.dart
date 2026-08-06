/// OR-1010 — Spread type data for Tarot Home.

library;



import 'package:flutter/material.dart';



import 'spread_visual_style.dart';



/// Spread card content — production copy, no placeholders.

@immutable

class TarotSpreadOption {

  const TarotSpreadOption({

    required this.title,

    required this.description,

    required this.icon,

    required this.cardCount,

    required this.visualStyle,

  });



  final String title;

  final String description;

  final IconData icon;

  final int cardCount;

  final SpreadVisualStyle visualStyle;

}



abstract final class TarotHomeSpreads {

  TarotHomeSpreads._();



  static const List<TarotSpreadOption> options = [

    TarotSpreadOption(

      title: 'Tek Kart',

      description: 'Hızlı bir içgörü için tek kart çek.',

      icon: Icons.filter_1_rounded,

      cardCount: 1,

      visualStyle: SpreadVisualStyle.single,

    ),

    TarotSpreadOption(

      title: 'Üç Kart Açılımı',

      description: 'Geçmiş, şimdi ve gelecek — üç kart birbirine bağlı.',

      icon: Icons.filter_3_rounded,

      cardCount: 3,

      visualStyle: SpreadVisualStyle.threeCard,

    ),

    TarotSpreadOption(

      title: 'Beş Kart',

      description: 'Derinlemesine beş kartlı rehberlik.',

      icon: Icons.filter_5_rounded,

      cardCount: 5,

      visualStyle: SpreadVisualStyle.fiveCard,

    ),

    TarotSpreadOption(

      title: 'Kelt Haçı',

      description: 'Kapsamlı on kartlı kadim ritüel açılımı.',

      icon: Icons.grid_view_rounded,

      cardCount: 10,

      visualStyle: SpreadVisualStyle.celticCross,

    ),

  ];

}



/// Recent reading preview for Continue Reading section.

@immutable

class TarotRecentReading {

  const TarotRecentReading({

    required this.title,

    required this.cardName,

    required this.timeAgo,

    required this.icon,

  });



  final String title;

  final String cardName;

  final String timeAgo;

  final IconData icon;

}



abstract final class TarotHomeRecentReadings {

  TarotHomeRecentReadings._();



  static const List<TarotRecentReading> samples = [

    TarotRecentReading(

      title: 'Aşk Açılımı',

      cardName: 'Aşıklar',

      timeAgo: '2 gün önce',

      icon: Icons.favorite_rounded,

    ),

    TarotRecentReading(

      title: 'Kariyer Rehberi',

      cardName: 'Yıldız',

      timeAgo: '5 gün önce',

      icon: Icons.work_outline_rounded,

    ),

    TarotRecentReading(

      title: 'Günlük Enerji',

      cardName: 'Güneş',

      timeAgo: '1 hafta önce',

      icon: Icons.wb_sunny_rounded,

    ),

  ];

}


