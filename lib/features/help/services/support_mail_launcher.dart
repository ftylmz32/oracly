/// Opens the system mail client; clipboard fallback if mailto is unavailable.
library;

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'support_report_payload.dart';

enum SupportMailResult { opened, copied }

abstract final class SupportMailLauncher {
  SupportMailLauncher._();

  static Future<SupportMailResult> send(SupportReportPayload payload) async {
    final uri = payload.toMailtoUri();
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return SupportMailResult.opened;
    } catch (_) {}
    await Clipboard.setData(
      ClipboardData(
        text: '${SupportReportPayload.supportEmail}\n\n${payload.body}',
      ),
    );
    return SupportMailResult.copied;
  }
}
