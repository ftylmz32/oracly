/// Dev proxy auto-default — mobile emulator + transport error parsing.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';

import '../../support/test_app_check_token.dart';

void main() {
  test('dev proxy auto-default uses host loopback per platform', () {
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.windows,
        isWeb: false,
      ),
      AiRuntimeConfig.localDevProxyUrl,
    );
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      AiRuntimeConfig.androidEmulatorDevProxyUrl,
    );
    expect(
      AiRuntimeConfig.devProxyAutoDefaultUrl(
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      AiRuntimeConfig.localDevProxyUrl,
    );
  });

  test('non-200 JSON error preserves backend vision code through palm parser',
      () async {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: 'https://api.oracly.app/v1/ai/complete',
    );
    final transport = await ProxyAiTransport(
      config: config,
      appCheckToken: testAppCheckToken,
      accessToken: ({bool forceRefresh = false}) async => 'token',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'image_analysis_unavailable'},
          }),
          503,
          headers: {'content-type': 'application/json'},
        ),
      ),
    ).execute(
      const AiProxyRequest(
        operation: AiOperation.palmAnalysis,
        payload: {'imageBase64': 'abc', 'mimeType': 'image/jpeg'},
      ),
    );
    final outcome = OpenAiServiceResults.palm(transport);
    expect(outcome.isFailure, isTrue);
    expect(outcome.failure?.kind, AiFailureKind.imageAnalysisUnavailable);
    expect(outcome.failure?.userMessage, PalmCopy.analysisUnavailable);
  });
}
