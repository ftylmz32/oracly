/// Canonical insight from typed result sections — role-aware, never first-only.
library;

import '../presentation/reference/star_map_result_section.dart';
import 'yildizname_result_presentation.dart';
import 'yildizname_result_types.dart';

abstract final class YildiznameCanonicalInsight {
  YildiznameCanonicalInsight._();

  /// Priority: summary → chapter → any non-empty section body → title.
  static String of(YildiznameResultPresentation presentation) {
    final fromRole = _firstBody(presentation.sections, YildiznameSectionRole.summary) ??
        _firstBody(presentation.sections, YildiznameSectionRole.chapter);
    if (fromRole != null) return fromRole;
    for (final s in presentation.sections) {
      final body = s.body.trim();
      if (body.isNotEmpty) return body;
    }
    return presentation.title.trim();
  }

  static String? _firstBody(
    List<StarMapResultSection> sections,
    YildiznameSectionRole role,
  ) {
    for (final s in sections) {
      if (s.role != role) continue;
      final body = s.body.trim();
      if (body.isNotEmpty) return body;
    }
    return null;
  }
}
