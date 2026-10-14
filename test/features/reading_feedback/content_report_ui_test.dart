import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/quality/quality_feature.dart';
import 'package:oracly_new/core/quality/quality_issue.dart';
import 'package:oracly_new/core/services/analytics_service.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/features/reading_feedback/copy/reading_feedback_copy.dart';
import 'package:oracly_new/features/reading_feedback/data/reading_feedback_store.dart';
import 'package:oracly_new/features/reading_feedback/presentation/widgets/reading_quality_actions.dart';
import 'package:oracly_new/features/reading_feedback/providers/reading_feedback_providers.dart';
import 'package:oracly_new/features/reading_feedback/services/content_report_gateway.dart';
import 'package:oracly_new/features/reading_feedback/services/reading_feedback_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    OraclyL10n.bind('tr');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final feature in QualityFeature.values) {
    testWidgets('${feature.name} exposes an in-app report action', (
      tester,
    ) async {
      final service = ReadingFeedbackService(
        ReadingFeedbackStore(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
        delivery: ContentReportGateway(
          createReportId: () => 'report_0123456789abcdef',
          send: (method, path, body) async => const ReadingOperationWire(
            statusCode: 201,
            json: {
              'data': {'accepted': true, 'reportId': 'report_0123456789abcdef'},
            },
          ),
        ),
      );
      await _pump(tester, service, feature: feature);
      expect(find.text(ReadingFeedbackCopy.action), findsOneWidget);
    });
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform shows success only after backend acceptance', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final service = ReadingFeedbackService(
        ReadingFeedbackStore(storage),
        delivery: ContentReportGateway(
          createReportId: () => 'report_0123456789abcdef',
          send: (method, path, body) async => const ReadingOperationWire(
            statusCode: 201,
            json: {
              'data': {'accepted': true, 'reportId': 'report_0123456789abcdef'},
            },
          ),
        ),
      );
      await _pump(tester, service);
      await _sendReport(tester);
      expect(find.text(ReadingFeedbackCopy.thanks), findsOneWidget);
      expect(storage.getStringList(ReadingFeedbackStore.key), isNotEmpty);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('rejection shows failure and does not store a delivered event', (
    tester,
  ) async {
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = ReadingFeedbackService(
      ReadingFeedbackStore(storage),
      delivery: ContentReportGateway(
        createReportId: () => 'report_0123456789abcdef',
        send: (method, path, body) async => const ReadingOperationWire(
          statusCode: 403,
          json: {
            'error': {'code': 'forbidden'},
          },
        ),
      ),
    );
    await _pump(tester, service);
    await _sendReport(tester);
    expect(find.text(ReadingFeedbackCopy.sendFail), findsOneWidget);
    expect(storage.getStringList(ReadingFeedbackStore.key), isNull);
  });

  testWidgets('failed report still preserves and runs the free retry', (
    tester,
  ) async {
    var retried = 0;
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = ReadingFeedbackService(
      ReadingFeedbackStore(storage),
      delivery: ContentReportGateway(
        createReportId: () => 'report_0123456789abcdef',
        send: (method, path, body) async => const ReadingOperationWire(
          statusCode: 503,
          json: {
            'error': {'code': 'internal_error'},
          },
        ),
      ),
    );
    await _pump(
      tester,
      service,
      retry: () async {
        retried++;
        return true;
      },
    );
    await _sendReport(tester, retry: true);
    expect(retried, 1);
    expect(find.text(ReadingFeedbackCopy.retryOk), findsOneWidget);
    expect(find.text(ReadingFeedbackCopy.thanks), findsNothing);
  });

  testWidgets('content is opt-in and double tap creates only one delivery', (
    tester,
  ) async {
    var calls = 0;
    Map<String, Object>? sent;
    final service = ReadingFeedbackService(
      ReadingFeedbackStore(LocalStorage(await SharedPreferences.getInstance())),
      delivery: ContentReportGateway(
        createReportId: () => 'report_0123456789abcdef',
        send: (method, path, body) async {
          calls++;
          sent = body;
          return const ReadingOperationWire(
            statusCode: 201,
            json: {
              'data': {'accepted': true, 'reportId': 'report_0123456789abcdef'},
            },
          );
        },
      ),
    );
    await _pump(tester, service, selectedContent: 'only this AI answer');
    await tester.tap(find.text(ReadingFeedbackCopy.action));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final category = find.text(
      ReadingFeedbackCopy.category(QualityIssue.harmful),
    );
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pump();
    final include = find.text(ReadingFeedbackCopy.includeContent);
    await tester.ensureVisible(include);
    await tester.tap(include);
    await tester.pump();
    final send = find.text(ReadingFeedbackCopy.send);
    await tester.ensureVisible(send);
    await tester.pump();
    await tester.tap(send);
    await tester.tap(send, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
    expect(sent?['selectedContent'], 'only this AI answer');
    expect(sent?['contentConsent'], isTrue);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ReadingFeedbackService service, {
  Future<bool> Function()? retry,
  String? selectedContent,
  QualityFeature feature = QualityFeature.coffee,
  double height = 1200,
}) {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        readingFeedbackServiceProvider.overrideWithValue(service),
        analyticsServiceProvider.overrideWithValue(AnalyticsService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ReadingQualityActions(
            feature: feature,
            retry: retry,
            selectedContent: selectedContent,
          ),
        ),
      ),
    ),
  );
}

Future<void> _sendReport(WidgetTester tester, {bool retry = false}) async {
  await tester.tap(find.text(ReadingFeedbackCopy.action));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  final category = find.text(
    ReadingFeedbackCopy.category(QualityIssue.harmful),
  );
  await tester.ensureVisible(category);
  await tester.pump();
  await tester.tap(category);
  await tester.pump(const Duration(milliseconds: 100));
  final send = find.text(
    retry ? ReadingFeedbackCopy.retry : ReadingFeedbackCopy.send,
  );
  await tester.ensureVisible(send);
  await tester.pump();
  await tester.tap(send);
  await tester.pump(const Duration(seconds: 1));
}
