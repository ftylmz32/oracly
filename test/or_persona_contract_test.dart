/// Authoritative OR persona contract — one identity for every surface.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/core/personality/or_prompt_locale.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/prompt_engine/templates/sections/shared_sections.dart';
import 'package:oracly_new/features/tarot/interpretation/services/tarot_prompt_persona.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('contract encodes the felt presence without claiming humanity', () {
    final id = OrPersonaContract.identityTr.toLowerCase();
    expect(id, contains('sıcak'));
    expect(id, contains('sakin'));
    expect(id, contains('geniş bilgili'));
    expect(id, contains('meraklı'));
    expect(id, contains('gözlemci'));
    expect(id, contains('duygusal zekâ'));
    expect(id, contains('oyunbaz'));
    expect(id, contains('doğrudan'));
    expect(id, contains('karşında oturan'));
    expect(id, contains('insan olduğunu iddia etme'));
    expect(id, contains('müşteri hizmetleri'));
    expect(id, contains('robotik'));
    expect(id, contains('sahte pozitif'));
    expect(id, isNot(contains('ben bir insanım')));
    expect(OrPersonaContract.qualities, contains('highly knowledgeable'));
    expect(OrPersonaContract.never, contains('claim to be human'));
  });

  test('OrCore and OrPromptLocale are aliases of the contract', () {
    expect(OrCore.systemIdentity, OrPersonaContract.identityTr);
    expect(OrCore.interpretationStance, OrPersonaContract.stanceTr);
    expect(OrCore.epistemic, OrPersonaContract.epistemicTr);
    expect(OrPromptLocale.systemIdentity, OrPersonaContract.identityTr);
    OraclyL10n.bind('en');
    expect(OrPromptLocale.systemIdentity, OrPersonaContract.identityEn);
    OraclyL10n.bind('ru');
    expect(OrPromptLocale.systemIdentity, OrPersonaContract.identityRu);
  });

  test('chat, shared templates, and tarot reuse one identity', () {
    OraclyL10n.bind('tr');
    expect(ChatPromptBuilder.system, contains(OrPersonaContract.identityTr));
    expect(
      SharedTemplateSections.basePersona,
      contains(OrPersonaContract.identityTr),
    );
    expect(TarotPromptPersona.tr, contains(OrPersonaContract.identityTr));
    expect(TarotPromptPersona.en, contains(OrPersonaContract.identityEn));
    for (final style in AiPersonality.values) {
      final body =
          OrPersonality.conversationStyle(OrPersonality.chatKey(style));
      expect(body, startsWith(OrPersonaContract.identityTr));
    }
  });
}
