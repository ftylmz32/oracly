/// Regression coverage for a real-device-confirmed bug: the
/// ReadingOperation HTTP sender treated `ORACLY_AI_PROXY_URL` (the FULL
/// `/v1/ai/complete` endpoint, per every dart-define/doc example in this
/// codebase) as a bare backend origin, then appended other backend paths
/// directly onto it — producing a doubled, 404-ing path like
/// `.../v1/ai/complete/v1/reading-operations`. Confirmed live against the
/// local backend: `GET /v1/ai/complete/v1/reading-flow/active` and
/// `POST /v1/ai/complete/v1/reading-operations` both 404'd, which is
/// exactly why Coffee's "prepare" step (`ReadingFeatureRunner.submit` ->
/// `flow.begin` -> `POST /v1/reading-operations`) failed with an honest
/// "Bu hazırlık tamamlanamadı" even after AI transport config + App Check
/// were both fixed and OR chat worked live.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';

void main() {
  group('readingOperationBackendOrigin', () {
    test('strips the /v1/ai/complete suffix to recover the backend origin', () {
      expect(
        readingOperationBackendOrigin('http://127.0.0.1:8787/v1/ai/complete'),
        'http://127.0.0.1:8787',
      );
      expect(
        readingOperationBackendOrigin('https://api.oracly.app/v1/ai/complete'),
        'https://api.oracly.app',
      );
    });

    test('trims a trailing slash before/after suffix stripping', () {
      expect(
        readingOperationBackendOrigin('http://127.0.0.1:8787/v1/ai/complete/'),
        'http://127.0.0.1:8787',
      );
    });

    test('leaves a URL without the suffix unchanged (trailing slash only)', () {
      expect(
        readingOperationBackendOrigin('https://api.oracly.app'),
        'https://api.oracly.app',
      );
      expect(
        readingOperationBackendOrigin('https://api.oracly.app/'),
        'https://api.oracly.app',
      );
    });

    test(
        'appending a reading-operation path never doubles /v1/ai/complete '
        '(the exact bug confirmed live on device)', () {
      final origin =
          readingOperationBackendOrigin('http://127.0.0.1:8787/v1/ai/complete');
      final url = '$origin/v1/reading-operations';
      expect(url, 'http://127.0.0.1:8787/v1/reading-operations');
      expect(url, isNot(contains('/v1/ai/complete/v1/')));
    });

    test('stable production proxy strips to service origin, not a tag host', () {
      const proxy =
          'https://oracly-api-uya7zqzwra-ew.a.run.app/v1/ai/complete';
      final origin = readingOperationBackendOrigin(proxy);
      expect(origin, 'https://oracly-api-uya7zqzwra-ew.a.run.app');
      expect(Uri.parse(origin).host.contains('---'), isFalse);
      expect(
        '$origin/v1/gems/balance',
        'https://oracly-api-uya7zqzwra-ew.a.run.app/v1/gems/balance',
      );
    });
  });
}
