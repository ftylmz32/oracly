import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_or_atmosphere.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_or_living_tokens.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_or_presence.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  test('idle glow stays quieter than thinking and speaking', () {
    const mode = AiPersonality.mystical;
    final idle = CompanionOrAtmosphere.of(mode, CompanionOrPresence.idle);
    final think = CompanionOrAtmosphere.of(
      mode,
      CompanionOrPresence.thinking,
    );
    final speak = CompanionOrAtmosphere.of(
      mode,
      CompanionOrPresence.speaking,
    );
    expect(idle.glowMin, lessThan(think.glowMin));
    expect(idle.glowSpan, lessThan(think.glowSpan));
    expect(idle.breath.inMilliseconds, greaterThan(think.breath.inMilliseconds));
    expect(speak.glowMin, greaterThan(idle.glowMin));
    expect(speak.breath, CompanionOrLivingTokens.speakingPulse);
  });

  test('modes shift warmth without a second layout', () {
    const idle = CompanionOrPresence.idle;
    final calm = CompanionOrAtmosphere.of(AiPersonality.gentle, idle);
    final mystic = CompanionOrAtmosphere.of(AiPersonality.mystical, idle);
    final warm = CompanionOrAtmosphere.of(AiPersonality.poetic, idle);
    final direct = CompanionOrAtmosphere.of(AiPersonality.direct, idle);
    expect(calm.wash, lessThan(mystic.wash));
    expect(mystic.showDust, isTrue);
    expect(calm.showDust, isFalse);
    expect(direct.blur, lessThan(mystic.blur));
    expect(direct.wash, lessThan(warm.wash));
  });

  test('error atmosphere matches idle — no red flash', () {
    const mode = AiPersonality.mystical;
    final idle = CompanionOrAtmosphere.of(mode, CompanionOrPresence.idle);
    final error = CompanionOrAtmosphere.of(mode, CompanionOrPresence.error);
    expect(error.glowMin, idle.glowMin);
    expect(error.glowSpan, idle.glowSpan);
    expect(error.breath, idle.breath);
  });

  test('presence resolve: speech then thinking then idle; error stays idle', () {
    expect(
      CompanionOrPresenceResolve.from(
        phase: CompanionPhase.thinking,
        busy: true,
        speaking: true,
        voiceMode: true,
      ),
      CompanionOrPresence.speaking,
    );
    expect(
      CompanionOrPresenceResolve.from(
        phase: CompanionPhase.thinking,
        busy: true,
        speaking: true,
        voiceMode: false,
      ),
      CompanionOrPresence.thinking,
    );
    expect(
      CompanionOrPresenceResolve.from(
        phase: CompanionPhase.thinking,
        busy: true,
        speaking: false,
      ),
      CompanionOrPresence.thinking,
    );
    expect(
      CompanionOrPresenceResolve.from(
        phase: CompanionPhase.error,
        busy: false,
        speaking: false,
      ),
      CompanionOrPresence.idle,
    );
    expect(
      CompanionOrPresenceResolve.from(
        phase: CompanionPhase.welcome,
        busy: false,
        speaking: false,
      ),
      CompanionOrPresence.idle,
    );
  });
}

