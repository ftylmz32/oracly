/// Dream result new-dream action is localized TR / EN / RU.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';

void main() {
  test('newDream follows TR EN RU product language', () {
    OraclyL10n.bind('tr');
    expect(DreamCopy.newDream, OraclyL10n.t('dream.new'));
    OraclyL10n.bind('en');
    expect(DreamCopy.newDream, OraclyL10n.t('dream.new'));
    expect(DreamCopy.newDream, 'New dream');
    OraclyL10n.bind('ru');
    expect(DreamCopy.newDream, OraclyL10n.t('dream.new'));
    OraclyL10n.bind('tr');
    expect(DreamCopy.newDream, isNot('New dream'));
  });
}
