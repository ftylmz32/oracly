import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';

void main() {
  group('CompanionResponder', () {
    const responder = CompanionResponder();

    test('answers dream questions without certainty language', () {
      final response = responder.respond(
        request: const InsightRequest(
          text: 'Son rüyamda deniz gördüm ve huzursuz hissettim.',
          kind: InsightRequestKind.dream,
        ),
        context: const ReflectionContext(),
      );

      expect(response.body, isNot(contains('kesin')));
      expect(response.body, isNot(contains('mutlaka')));
      expect(response.body.toLowerCase(), contains('rüya'));
    });

    test('answers tarot with an interpretation, not only a question', () {
      final response = responder.respond(
        request: const InsightRequest(
          text: 'Tarot açılımımı yorumlar mısın?',
          kind: InsightRequestKind.tarot,
        ),
        context: const ReflectionContext(),
      );

      expect(response.body.toLowerCase(), contains('tarot'));
      expect(response.body.trim().endsWith('?'), isFalse);
    });

    test('answers coffee without injecting a reading', () {
      final response = responder.respond(
        request: const InsightRequest(text: 'Kahve falı ne anlatır?'),
        context: const ReflectionContext(),
      );
      expect(response.body.toLowerCase(), contains('kahve'));
      expect(response.body.trim().endsWith('?'), isFalse);
    });

    test('answers energy and love prompts directly', () {
      final energy = responder.respond(
        request: const InsightRequest(text: 'Bugünkü enerjim nasıl?'),
        context: const ReflectionContext(),
      );
      final love = responder.respond(
        request: const InsightRequest(text: 'Aşk hayatımda ne görüyorsun?'),
        context: const ReflectionContext(),
      );

      expect(energy.body.toLowerCase(), contains('tempo'));
      expect(love.body.toLowerCase(), contains('aşk'));
    });

    test('references saved memory only when relevant', () {
      final response = responder.respond(
        request: const InsightRequest(
          text: 'Sabah meditasyonumu hatırlıyor musun?',
        ),
        context: ReflectionContext(
          savedMemories: [
            Memory(
              id: '1',
              content: 'Sabah meditasyonu yapmayı seviyorum',
              category: 'ritual',
              permission: MemoryPermission.saved,
              createdAt: DateTime(2024, 1, 1),
            ),
          ],
        ),
      );

      expect(response.body, contains('Daha önce bıraktığın bir not'));
      expect(response.body.toLowerCase(), contains('meditasyon'));
    });

    test('personalities ask the undecided question in different tones', () {
      final lines = {
        for (final style in AiPersonality.values)
          style: responder
              .respond(
                request: const InsightRequest(text: 'Bugün biraz kararsızım.'),
                context: const ReflectionContext(),
                personality: OrPersonality.chatKey(style),
              )
              .body,
      };
      expect(lines.values.toSet(), hasLength(4));
      expect(lines[AiPersonality.direct], contains('iş konusunda mı'));
      expect(lines[AiPersonality.poetic], contains('Anladım'));
      expect(lines[AiPersonality.gentle], isNot(contains('eşik')));
    });

    test('remembers the job vs general clarification', () {
      final held = responder.respond(
        request: const InsightRequest(text: 'İş konusunda.'),
        context: const ReflectionContext(),
        turns: const [
          ConversationTurn(
            role: ConversationTurn.userRole,
            text: 'Bugün biraz kararsızım.',
          ),
          ConversationTurn(
            role: ConversationTurn.assistantRole,
            text: 'Daha çok iş konusunda mı, yoksa genel olarak mı?',
          ),
        ],
        personality: 'direct',
      );
      expect(held.body.toLowerCase(), contains('iş'));
      expect(held.body, isNot(contains('yoksa genel')));
    });

    test('connects fear of change to the job thread', () {
      const turns = [
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'Bugün biraz kararsızım.',
        ),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'Daha çok iş konusunda mı, yoksa genel olarak mı?',
        ),
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'İş konusunda.',
        ),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'iş tamam. Asıl sıkışma ne?',
        ),
      ];
      final lines = {
        for (final style in AiPersonality.values)
          style: responder
              .respond(
                request: const InsightRequest(text: 'Değişmekten korkuyorum.'),
                context: const ReflectionContext(),
                turns: turns,
                personality: OrPersonality.chatKey(style),
              )
              .body,
      };
      expect(lines.values.toSet(), hasLength(4));
      for (final body in lines.values) {
        expect(body.toLowerCase(), contains('kork'));
        expect(body, isNot(contains('yoksa genel')));
      }
      expect(lines[AiPersonality.direct]!.toLowerCase(), contains('yanlış'));
      expect(lines[AiPersonality.poetic], contains('Anladım'));
      expect(lines[AiPersonality.gentle]!.toLowerCase(), contains('iş'));
      expect(lines[AiPersonality.mystical]!.toLowerCase(), contains('değiş'));
    });

    test('error copy is honest and empty send is not a new topic', () {
      expect(CompanionCopy.connectionError, contains('ulaşamadım'));
      expect(
        responder
            .respond(
              request: const InsightRequest(text: 'selam'),
              context: const ReflectionContext(),
              personality: 'direct',
            )
            .body
            .toLowerCase(),
        isNot(contains('iş')),
      );
    });

    test('second selam is not the same greeting', () {
      const firstTurn = ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'selam',
      );
      const reply = ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Selam. Söyle, neye bakıyoruz?',
      );
      final first = responder.respond(
        request: const InsightRequest(text: 'selam'),
        context: const ReflectionContext(),
        personality: 'direct',
      );
      final second = responder.respond(
        request: const InsightRequest(text: 'selam'),
        context: const ReflectionContext(),
        turns: const [firstTurn, reply],
        personality: 'direct',
      );
      expect(first.body.trim(), isNotEmpty);
      expect(first.body.length, lessThan(120));
      expect(second.body, isNot(equals(first.body)));
      expect(second.body.toLowerCase(), isNot(contains('iş')));
    });

    test('generic shares change tone with personality', () {
      final lines = {
        for (final style in AiPersonality.values)
          style: responder
              .respond(
                request: const InsightRequest(text: 'Sadece duruyorum biraz.'),
                context: const ReflectionContext(),
                personality: OrPersonality.chatKey(style),
              )
              .body,
      };
      expect(lines.values.toSet(), hasLength(4));
      expect(lines[AiPersonality.poetic], contains('Anladım'));
      expect(lines[AiPersonality.direct], contains('Duydum'));
      expect(lines[AiPersonality.gentle], contains('duydum'));
    });

    test('low mood asks a follow-up instead of a fortune', () {
      final lines = {
        for (final style in AiPersonality.values)
          style: responder
              .respond(
                request: const InsightRequest(text: 'Canım sıkkın.'),
                context: const ReflectionContext(),
                personality: OrPersonality.chatKey(style),
              )
              .body,
      };
      expect(lines.values.toSet(), hasLength(4));
      expect(lines[AiPersonality.gentle], contains('takıldın'));
      expect(lines[AiPersonality.poetic], contains('duruyor'));
      expect(lines[AiPersonality.direct], contains('tam olarak'));
      for (final body in lines.values) {
        expect(body.toLowerCase(), isNot(contains('tarot')));
        expect(body.toLowerCase(), isNot(contains('kahve')));
        expect(body.toLowerCase(), isNot(contains('burç')));
      }
    });

    test('coffee replies follow the depth preference, never padding', () {
      const long =
          'Kahve falıma baktım; fincanda açık bir yol vardı ve bunu '
          'işimle nasıl bağlayabileceğimi birlikte okumak istiyorum.';
      final short = responder.respond(
        request: const InsightRequest(text: long),
        context: const ReflectionContext(),
        personality: 'gentle',
        depth: OrResponseDepth.short,
      );
      final deep = responder.respond(
        request: const InsightRequest(text: long),
        context: const ReflectionContext(),
        personality: 'gentle',
        depth: OrResponseDepth.deep,
      );
      expect(short.body.toLowerCase(), contains('kahve'));
      expect(deep.body.toLowerCase(), contains('kahve'));
      expect(deep.body.length, greaterThan(short.body.length));
    });
  });
}
