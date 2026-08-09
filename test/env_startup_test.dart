import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/config/app_config.dart';
import 'package:oracly_new/core/config/environment_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    dotenv.clean();
    AppConfig.reset();
  });

  test('optional empty env initializes dotenv and AppConfig without secrets',
      () async {
    // Mirrors missing/empty .env after isOptional load + EmptyEnvFileError path.
    dotenv.testLoad(fileInput: '');

    expect(dotenv.isInitialized, isTrue);
    expect(dotenv.env['OPENAI_API_KEY'], isNull);

    await AppConfig.initialize(EnvironmentConfig.fromEnv());
    expect(AppConfig.isInitialized, isTrue);
    expect(AppConfig.instance.apiBaseUrl, isNotEmpty);
  });

  test('EnvironmentConfig.fromEnv uses safe defaults when map is empty', () {
    final config = EnvironmentConfig.fromEnv(const {});
    expect(config.apiBaseUrl, isNotEmpty);
    expect(config.apiVersion, 'v1');
  });
}
