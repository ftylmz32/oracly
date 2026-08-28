/// Quiet strip — selected halo only. Never the page's visual hero.
library;

import 'package:flutter/material.dart';

import '../../../content/astrology/models/astrology_content.dart';
import 'astrology_reference_tokens.dart';
import 'astrology_reference_zodiac_tab.dart';

class AstrologyReferenceZodiacTabs extends StatelessWidget {
  const AstrologyReferenceZodiacTabs({
    super.key,
    required this.signs,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ZodiacSignContent> signs;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AstrologyReferenceTokens.tabRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: signs.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: AstrologyReferenceTokens.tabGap),
        itemBuilder: (context, i) {
          final selected = signs[i].id == selectedId;
          return SizedBox(
            width: selected ? 56 : 46,
            child: AstrologyReferenceZodiacTab(
              sign: signs[i],
              selected: selected,
              onTap: () => onSelected(signs[i].id),
            ),
          );
        },
      ),
    );
  }
}
