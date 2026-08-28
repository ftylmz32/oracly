import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/insight_copy/insight_copy_strings.dart';
import 'package:oracly_new/core/insight_copy/insight_copy_text.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

void main() {
  test('markdown links keep visible label text', () {
    expect(
      InsightCopyText.clean('[calm note](https://example.com)'),
      'calm note',
    );
  });

  test('clean insight text drops markdown, ids, and debug labels', () {
    expect(InsightCopyText.clean('## Title'), 'Title');
    expect(
      InsightCopyText.clean('**Bold** and *soft* with `ticks`.'),
      'Bold and soft with ticks.',
    );
    expect(
      InsightCopyText.clean('[TarotInterpretation]\nStay.'),
      'Stay.',
    );
    expect(
      InsightCopyText.clean('coffee_991122\nStay.'),
      'Stay.',
    );
    expect(
      InsightCopyText.clean('id: msg_aa11\nStay.'),
      'Stay.',
    );
    expect(
      InsightCopyText.clean('DEBUG: skip this\nStay.'),
      'Stay.',
    );
    expect(
      InsightCopyText.clean('{ "sessionId": "abc" }\nStay.'),
      'Stay.',
    );
    expect(
      InsightCopyText.clean(
        '[TarotInterpretation]\ncoffee_991122\nid: msg_aa11\n'
        'DEBUG: skip this\n[calm note](https://example.com)\n'
        '{ "sessionId": "abc" }\nKeep this sentence.',
      ),
      'calm note\n\nKeep this sentence.',
    );
  });

  test('copy labels are localized with the required confirmation', () {
    OraclyL10n.bind('tr');
    expect(InsightCopyStrings.action, 'Kopyala');
    expect(InsightCopyStrings.copied, 'Kopyalandı.');

    OraclyL10n.bind('en');
    expect(InsightCopyStrings.action, 'Copy');
    expect(InsightCopyStrings.copied, 'Copied.');

    OraclyL10n.bind('ru');
    expect(InsightCopyStrings.action, 'Копировать');
    expect(InsightCopyStrings.copied, 'Скопировано.');
  });
}
