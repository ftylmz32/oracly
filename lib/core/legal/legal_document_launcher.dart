/// Opens configured legal HTTPS URLs — fails honestly when absent.
library;

import 'package:url_launcher/url_launcher.dart';

import 'legal_document_kind.dart';
import 'oracly_legal_urls.dart';

enum LegalOpenResult { opened, missingUrl, launchFailed }

abstract final class LegalDocumentLauncher {
  LegalDocumentLauncher._();

  static Future<LegalOpenResult> open(LegalDocumentKind kind) async {
    final uri = switch (kind) {
      LegalDocumentKind.privacyPolicy => OraclyLegalUrls.privacyPolicyUri,
      LegalDocumentKind.termsOfUse => OraclyLegalUrls.termsOfUseUri,
    };
    if (uri == null) return LegalOpenResult.missingUrl;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok ? LegalOpenResult.opened : LegalOpenResult.launchFailed;
    } catch (_) {
      return LegalOpenResult.launchFailed;
    }
  }
}