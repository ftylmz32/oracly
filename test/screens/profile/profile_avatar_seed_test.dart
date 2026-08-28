/// Emblem seed stays stable for one identity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/screens/profile/reference/profile_avatar_letter.dart';
import 'package:oracly_new/screens/profile/reference/profile_avatar_seed.dart';

void main() {
  test('same identity hashes to the same seed', () {
    expect(ProfileAvatarSeed.of('Fatih'), ProfileAvatarSeed.of('Fatih'));
    expect(ProfileAvatarSeed.of('  FATIH '), ProfileAvatarSeed.of('fatih'));
  });

  test('different people with the same initial keep different marks', () {
    expect(
      ProfileAvatarSeed.of('Fatih'),
      isNot(ProfileAvatarSeed.of('Ferhat')),
    );
  });

  test('empty identity still yields a usable seed', () {
    expect(ProfileAvatarSeed.of(''), isNonZero);
  });

  test('letter is the first initial only', () {
    expect(ProfileAvatarLetter.of('Fatih'), 'F');
    expect(ProfileAvatarLetter.of('ipek'), 'İ');
  });
}
