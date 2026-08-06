import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/memory.dart';
import 'package:oracly_new/features/companion/models/memory_permission.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';

void main() {
  group('CompanionResponder', () {
    const responder = CompanionResponder();

    test('follows listen reflect suggest without certainty language', () {
      final response = responder.respond(
        request: const InsightRequest(
          text: 'Son rüyamda deniz gördüm ve huzursuz hissettim.',
          kind: InsightRequestKind.dream,
        ),
        context: const ReflectionContext(),
      );

      expect(response.body, isNot(contains('kesin')));
      expect(response.body, isNot(contains('mutlaka')));
      expect(response.body, contains('\n\n'));
      expect(response.suggestions, isNotEmpty);
    });

    test('references saved memory only when relevant', () {
      final response = responder.respond(
        request: const InsightRequest(text: 'Bunu hatırlıyor musun?'),
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

      expect(response.body, contains('Kaydettiğin bir not var'));
    });
  });
}
