import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/services/conversation_question_guard.dart';

void main() {
  test('drops the same bespoke trailing question on consecutive replies', () {
    const prior =
        'Burada hızdan çok netlik işe yarar. Bunu bugün yapmak sana gerçekçi geliyor mu?';
    const current =
        'Önce tek ölçüt seçmek kararı sadeleştirir. Bunu bugün yapmak sana gerçekçi geliyor mu?';

    final shaped = ConversationQuestionGuard.shape(
      current,
      allowTrailingQuestion: true,
      priorAssistant: prior,
    );

    expect(shaped, 'Önce tek ölçüt seçmek kararı sadeleştirir.');
  });

  test('keeps a genuinely different earned question', () {
    const prior =
        'Burada hızdan çok netlik işe yarar. Bunu bugün yapmak sana gerçekçi geliyor mu?';
    const current =
        'İki seçeneğin bedelini ayrı ayrı yazmak iyi olabilir. Hangisinin bedeli sana daha ağır geliyor?';

    final shaped = ConversationQuestionGuard.shape(
      current,
      allowTrailingQuestion: true,
      priorAssistant: prior,
    );

    expect(shaped, current);
  });

  test('honors explicit no-trailing-question mode', () {
    const current =
        'Bugün tek bir ölçüt belirlemek yeterli olabilir. Hangisi daha somut geliyor?';

    final shaped = ConversationQuestionGuard.shape(
      current,
      allowTrailingQuestion: false,
    );

    expect(shaped, 'Bugün tek bir ölçüt belirlemek yeterli olabilir.');
  });
}
