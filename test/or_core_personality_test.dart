/// OR core personality — realistic warmth, memory, no people-pleasing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_knowledge_depth.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  const responder = CompanionResponder();

  setUp(() => OraclyL10n.bind('tr'));

  CompanionResponse _say(
    String text, {
    String? personality,
    List<ConversationTurn> turns = const [],
    ReflectionContext context = const ReflectionContext(),
  }) {
    return responder.respond(
      request: InsightRequest(text: text),
      context: context,
      turns: turns,
      personality: personality,
    );
  }

  test('natural greeting is a hello, not a help desk', () {
    final body = _say('Selam', personality: 'gentle').body;
    expect(body.toLowerCase(), anyOf(contains('selam'), contains('merhaba')));
    expect(OrCore.looksCustomerService(body), isFalse);
  });

  test('low mood asks what is stuck, not a therapist script', () {
    final body = _say('Bugün canım sıkkın.', personality: 'direct').body;
    expect(body.toLowerCase(), contains('takıldın'));
    expect(OrCore.looksTherapistScript(body), isFalse);
    expect(OrCore.looksForcedPositivity(body), isFalse);
  });

  test('job thread is retained across turns', () {
    const turns = [
      ConversationTurn(role: ConversationTurn.userRole, text: 'İş değiştirmeyi düşünüyorum.'),
      ConversationTurn(role: ConversationTurn.assistantRole, text: 'Ne zamandır?'),
      ConversationTurn(role: ConversationTurn.userRole, text: 'Yaklaşık üç aydır.'),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'iş tamam. Asıl sıkışma ne?',
      ),
    ];
    // No canned job FAQ — live provider owns depth; local keeps the thread.
    final first = _say('İş değiştirmeyi düşünüyorum.', personality: 'direct');
    expect(first.body.trim(), isNotEmpty);
    expect(first.body.toLowerCase(), isNot(contains('istifa')));
    final later = _say(
      'Değişmekten korkuyorum.',
      personality: 'direct',
      turns: turns,
    );
    expect(later.body.toLowerCase(), contains('iş'));
    expect(later.body.toLowerCase(), contains('kork'));
  });

  test('modes change expression, not the core', () {
    final bodies = {
      for (final style in AiPersonality.values)
        style: OrPersonality.conversationStyle(OrPersonality.chatKey(style)),
    };
    for (final body in bodies.values) {
      expect(body.toLowerCase(), contains('zeki'));
      expect(body.toLowerCase(), contains('gerçekçi'));
      expect(body.toLowerCase(), isNot(contains('yapay zek')));
    }
    expect(bodies[AiPersonality.direct], contains('DİREKT'));
    expect(bodies[AiPersonality.gentle], contains('SAKİN'));
    expect(bodies.values.toSet(), hasLength(4));
  });

  test('personal context is observational and never invented', () {
    final known = responder.respond(
      request: const InsightRequest(
        text: 'Sabah yuruyus aliskanligimi hatirliyor musun?',
      ),
      context: ReflectionContext(
        savedMemories: [
          Memory(
            id: '1',
            content: 'Sabah yuruyus aliskanligi her gun',
            category: 'ritual',
            permission: MemoryPermission.saved,
            createdAt: DateTime(2024, 1, 1),
          ),
        ],
      ),
    );
    expect(known.body.toLowerCase(), contains('yuruyus'));
    final unknown = _say('Beni analiz et, sen şöylesin de.');
    expect(unknown.body.toLowerCase(), isNot(contains('sen şöylesin')));
  });

  test('no forced positivity or deterministic prediction', () {
    final back = _say('Bu insan kesin geri dönecek mi?').body;
    expect(back.toLowerCase(), contains('kesin söyleyemem'));
    expect(OrPersonality.forbidsCertainty(back), isFalse);
    expect(OrCore.looksForcedPositivity(back), isFalse);
  });

  test('symbolic fortune vs medical/death claims', () {
    final coffee = _say('Kahve falıma bak.').body;
    expect(coffee.trim(), isNotEmpty);
    expect(coffee.toLowerCase(), isNot(contains('kesin gelecek')));
    final guarded = SensitiveTopicGate.maybeRespond('Falımda ölüm görüyor musun?');
    expect(guarded, isNotNull);
    expect(guarded!.toLowerCase(), contains('sembolik'));
    final death = _say('Falımda ölüm görüyor musun?').body;
    expect(death.toLowerCase(), isNot(contains('öleceksin')));
    expect(death.toLowerCase(), isNot(contains('kesin')));
  });

  test('normal knowledge conversation is not dragged into mysticism', () {
    final body = _say('Python\'da async nasıl çalışıyor?').body;
    // Local path is not a knowledge FAQ; live provider owns depth.
    expect(body.toLowerCase(), isNot(contains('event loop')));
    expect(body.toLowerCase(), isNot(contains('tarot')));
    expect(body.toLowerCase(), isNot(contains('burç')));
    expect(ChatPromptBuilder.system, contains(OrKnowledgeDepth.promptTr));
  });

  test('multilingual personality stays language-pure', () {
    OraclyL10n.bind('en');
    expect(
      _say('Selam', personality: 'gentle').body.toLowerCase(),
      anyOf(contains('how are you'), contains('hello'), contains('hey')),
    );
    expect(_say('Selam', personality: 'gentle').body, isNot(contains('Nasılsın')));
    OraclyL10n.bind('ru');
    expect(
      _say('Selam', personality: 'gentle').body.toLowerCase(),
      anyOf(contains('привет'), contains('здравств'), contains('как ты')),
    );
    expect(_say('Selam', personality: 'gentle').body, isNot(contains('Nasılsın')));
    OraclyL10n.bind('tr');
  });

  test('generic shares are heard, not treated as low mood', () {
    final body = _say('Sadece duruyorum biraz.', personality: 'poetic').body;
    expect(body, contains('Anladım'));
    expect(body.toLowerCase(), isNot(contains('takıldın')));
  });

  test('chrome copy sounds like OR, not raw Flutter', () {
    expect(CoffeeCopy.analyzing.toLowerCase(), contains('fincan'));
    expect(
      PalmCopy.analyzing.toLowerCase(),
      anyOf(contains('çizgi'), contains('ayrıntı'), contains('avuç'), contains('iz')),
    );
    expect(SoulMateCopy.drawing, contains('Portrede'));
    expect(ResilienceCopy.offline, contains('Bağlantı kurulamadı'));
    expect(ResilienceCopy.oracleSendFailed, contains('Bağlantı koptu'));
    expect(CompanionCopy.connectionError, contains('Bir daha deneyelim'));
    expect(ResilienceCopy.offline.toLowerCase(), isNot(contains('unexpected')));
    expect(ResilienceCopy.offline.toLowerCase(), isNot(contains('bir hata oluştu')));
  });
}
