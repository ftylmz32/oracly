/// P3 - Splash / Home startup path stays lean.
library;

import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:oracly_new/core/constants/app_assets.dart";

void main() {
  test("splash critical boot excludes deferred warm-up work", () {
    final splash = File("lib/screens/splash/splash_screen.dart").readAsStringSync();
    final boot = File("lib/screens/splash/splash_boot.dart").readAsStringSync();
    expect(splash, contains("splashFastOnboarding"));
    expect(splash, contains("splashScheduleWarmup"));
    expect(boot, contains("beginSession"));
    expect(boot, contains("oraclyNotificationCoordinatorProvider"));
    expect(splash, isNot(contains("beginSession")));
    expect(splash, isNot(contains("oraclyNotificationCoordinatorProvider")));
  });

  test("brand overlay uses final timeline without cinema", () {
    final overlay =
        File("lib/screens/splash/splash_brand_overlay.dart").readAsStringSync();
    expect(overlay, contains("SplashFinalTimeline"));
    expect(overlay, isNot(contains("SplashCinema")));
    expect(overlay, isNot(contains("SplashCinematicScene")));
    final screen =
        File("lib/screens/splash/splash_screen.dart").readAsStringSync();
    expect(screen, contains("FinalOraclySplash"));
    expect(screen, contains("SplashDestination.build"));
    expect(screen, isNot(contains("SplashCinema(")));
    expect(screen, isNot(contains("SplashCinematicScene")));
    expect(screen, isNot(contains("SplashSimpleOpening")));
  });

  test("android native splash uses brand logo not empty icon", () {
    final v31 =
        File("android/app/src/main/res/values-v31/styles.xml").readAsStringSync();
    final launch = File(
      "android/app/src/main/res/drawable/launch_background.xml",
    ).readAsStringSync();
    expect(v31, contains("splash_logo_icon"));
    expect(v31, contains("launch_background"));
    expect(v31, isNot(contains("splash_transparent_icon")));
    expect(launch, contains("splash_brand_logo"));
    expect(launch, contains("@color/launch_background"));
    expect(
      File("android/app/src/main/res/drawable-xxhdpi/splash_brand_logo.png")
          .existsSync(),
      isTrue,
    );
    expect(
      File("android/app/src/main/res/drawable-xxhdpi/splash_logo_icon.png")
          .existsSync(),
      isTrue,
    );
  });

  test("Home first-paint assets prefer lean WebP cinema plates", () {
    expect(AppAssets.dailyEnergyMoon.endsWith(".webp"), isTrue);
    expect(AppAssets.homeOrGuide.endsWith(".webp"), isTrue);
    expect(File(AppAssets.dailyEnergyMoon).existsSync(), isTrue);
    expect(File(AppAssets.homeOrGuide).existsSync(), isTrue);
    expect(
      File("lib/assets/images/daily_energy_moon.png").existsSync(),
      isFalse,
    );
  });

  test("crash telemetry install does not await sink initialize inline", () {
    final boot =
        File("lib/core/telemetry/crash_telemetry_bootstrap.dart").readAsStringSync();
    expect(boot, contains("unawaited(service.initialize())"));
    expect(boot, isNot(contains("await service.initialize()")));
  });

  test("bootstrapProviders does not block first paint on anonymous auth", () {
    final app = File("lib/app/oracly_app.dart").readAsStringSync();
    expect(app, contains("AnonymousAuthBootstrap.ensure"));
    expect(app, contains("unawaited("));
    expect(app, isNot(contains("await AnonymousAuthBootstrap.ensure")));
  });
}
