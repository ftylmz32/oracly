/// EPIC-011 — Home daily ritual card — observational, never scored.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/copy/birthday_ritual.dart';
import '../../../core/l10n/l10n.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../../../core/universe/oracly_universe_layer.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../home/reference/home_living_sweep.dart';
import '../../home/reference/home_reference_card_shell.dart';
import '../../home/reference/home_reference_scope.dart';
import '../../home/reference/home_reference_tokens.dart';
import '../models/daily_ritual_day.dart';
import '../presentation/card_of_the_day_screen.dart';
import '../services/card_of_the_day_service.dart';
import '../services/daily_ritual_reflections.dart';
import '../services/daily_ritual_service.dart';
import 'daily_ritual_card_body.dart';

/// Compact Home ritual — bounded glass slot; art cannot escape.
class DailyRitualCard extends ConsumerStatefulWidget {
  const DailyRitualCard({super.key});

  static String get title => OraclyL10n.t('ritual.title');

  @override
  ConsumerState<DailyRitualCard> createState() => _DailyRitualCardState();
}

class _DailyRitualCardState extends ConsumerState<DailyRitualCard> {
  DailyRitualDay? _day;

  DailyRitualService get _service => ref.read(dailyRitualServiceProvider);

  DailyRitualDay get _state => _day ?? _service.loadToday();

  Future<void> _readReflection() async {
    await _service.markReflectionRead();
    if (!mounted) return;
    setState(() => _day = _state.copyWith(reflectionRead: true));
  }

  Future<void> _openDailyCard() async {
    final storage = ref.read(localStorageProvider);
    final card = await CardOfTheDayService(
      storage,
      ritual: _service,
    ).openToday();
    if (!mounted) return;
    setState(() => _day = _service.loadToday());
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardOfTheDayScreen(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universe =
        OraclyUniverseScope.maybeOf(context) ?? OraclyUniverseState.current();
    final day = _state;
    final birth = ref.watch(
      birthInformationProvider.select((async) => async.valueOrNull),
    );
    final birthday = BirthdayRitual.isToday(
      birthDate: birth?.birthDate,
      now: universe.moment,
    );
    final body = day.reflectionRead
        ? DailyRitualReflections.reflection(universe)
        : DailyRitualReflections.welcome(universe, isBirthday: birthday);
    final layout = HomeReferenceScope.maybeOf(context);
    final art = layout?.heroArtSize ?? 96;
    // Edge-to-edge cinematic artwork; copy padding lives in [DailyRitualCardBody].
    const pad = EdgeInsets.zero;
    final energySize = layout?.energyFontSize ?? 28;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        final slotW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        // Hard clip lives on the glass shell — avoid double ClipRRect.
        return HomeReferenceCardShell(
          height: slotH,
          width: slotW,
          premium: true,
          borderRadius: HomeReferenceTokens.heroRadius,
          padding: pad,
          onTap: !day.cardDrawn
              ? _openDailyCard
              : (day.reflectionRead ? null : _readReflection),
          child: ClipRRect(
            borderRadius: HomeReferenceTokens.heroRadius,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DailyRitualCardBody(
                    universe: universe,
                    body: body,
                    art: art,
                    energySize: energySize,
                    cardDrawn: day.cardDrawn,
                    onDraw: _openDailyCard,
                  ),
                  const HomeLivingSweep(seed: 17, intensity: 0.055),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
