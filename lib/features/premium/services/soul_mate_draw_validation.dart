/// Soul-mate form validation — required name and birth only.
library;

import '../copy/soul_mate_copy.dart';

abstract final class SoulMateDrawValidation {
  SoulMateDrawValidation._();

  static String? missingField({
    required String name,
    DateTime? birth,
  }) {
    if (name.trim().isEmpty) return SoulMateCopy.nameRequired;
    if (birth == null) return SoulMateCopy.birthRequired;
    return null;
  }
}
