import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/navigation/oracly_navigation.dart';

class GreetingSection extends StatefulWidget {
  const GreetingSection({
    super.key,
    required this.greeting,
    required this.message,
  });

  final String greeting;
  final String message;

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection>
    with SingleTickerProviderStateMixin {
  static const _phrases = {
    'Günaydın': 'Good morning',
    'İyi günler': 'Good afternoon',
    'İyi akşamlar': 'Good evening',
    'Geç saatlerde buradasın': 'Good evening',
  };

  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _englishGreeting(String raw) {
    final text = raw
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    for (final e in _phrases.entries) {
      if (text.startsWith(e.key)) {
        final name = text.substring(e.key.length).trim();
        return name.isEmpty ? e.value : '${e.value}, $name';
      }
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 28, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _englishGreeting(widget.greeting),
                    style: AppTextStyles.hero.copyWith(
                      fontSize: 32,
                      height: 1.08,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.message,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14.5,
                      height: 1.82,
                      letterSpacing: 0.25,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _ProfileOrb(
              onTap: () =>
                  OraclyNavigation.switchToTab(context, OraclyTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOrb extends StatelessWidget {
  const _ProfileOrb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.14), blurRadius: 28, spreadRadius: 0),
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.05), blurRadius: 48, spreadRadius: 8),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 6,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Icon(Icons.person_rounded, size: 21, color: AppColors.gold.withValues(alpha: 0.88)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
