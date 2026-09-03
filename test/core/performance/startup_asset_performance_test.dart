/// P3 - Splash / Home startup path stays lean.
library;

import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:oracly_new/core/constants/app_assets.dart";

void main() {
  test("splash critical boot excludes deferred warm-up work", () {
    final splash = File(
      "lib/screens/splash/splash_screen.dart",
    ).readAsStringSync();
    final boot = File("lib/screens/splash/splash_boot.dart").readAsStringSync();
    expect(splash, contains("splashFastOnboarding"));
    expect(splash, contains("splashScheduleWarmup"));
    expect(boot, contains("beginSession"));
    expect(boot, contains("oraclyNotificationCoordinatorProvider"));
    expect(splash, isNot(contains("beginSession")));
    expect(splash, isNot(contains("oraclyNotificationCoordinatorProvider")));
  });

  test("brand overlay uses final timeline without cinema", () {
    final overlay = File(
      "lib/screens/splash/splash_brand_overlay.dart",
    ).readAsStringSync();
    expect(overlay, contains("SplashFinalTimeline"));
    expect(overlay, isNot(contains("SplashCinema")));
    expect(overlay, isNot(contains("SplashCinematicScene")));
    final screen = File(
      "lib/screens/splash/splash_screen.dart",
    ).readAsStringSync();
    expect(screen, contains("FinalOraclySplash"));
    expect(screen, contains("SplashDestination.build"));
    expect(screen, isNot(contains("SplashCinema(")));
    expect(screen, isNot(contains("SplashCinematicScene")));
    expect(screen, isNot(contains("SplashSimpleOpening")));
  });

  test("android native splash is dark-only before Flutter branding", () {
    final v31 = File(
      "android/app/src/main/res/values-v31/styles.xml",
    ).readAsStringSync();
    final nightV31 = File(
      "android/app/src/main/res/values-night-v31/styles.xml",
    ).readAsStringSync();
    final launch = File(
      "android/app/src/main/res/drawable/launch_background.xml",
    ).readAsStringSync();
    final launchV21 = File(
      "android/app/src/main/res/drawable-v21/launch_background.xml",
    ).readAsStringSync();
    final icon = File(
      "android/app/src/main/res/drawable/splash_transparent_icon.xml",
    ).readAsStringSync();
    expect(v31, contains("Theme.SplashScreen.IconBackground"));
    expect(nightV31, contains("Theme.SplashScreen.IconBackground"));
    expect(v31, contains("postSplashScreenTheme"));
    expect(v31, contains("splash_transparent_icon"));
    expect(nightV31, contains("splash_transparent_icon"));
    expect(v31, contains("launch_background"));
    expect(v31, isNot(contains("splash_logo_icon")));
    expect(nightV31, isNot(contains("splash_logo_icon")));
    expect(launch, isNot(contains("splash_brand_logo")));
    expect(launchV21, isNot(contains("splash_brand_logo")));
    expect(launch, contains("@color/launch_background"));
    // Solid midnight icon — transparent falls back to launcher mark.
    expect(icon, contains("@color/launch_background"));
    expect(icon, isNot(contains("@android:color/transparent")));
    expect(icon, contains("<vector"));
  });

  test("MainActivity installs SplashScreen without keeping native brand", () {
    final main = File(
      "android/app/src/main/kotlin/app/oracly/MainActivity.kt",
    ).readAsStringSync();
    expect(main, contains("installSplashScreen()"));
    expect(main, contains("setKeepOnScreenCondition { false }"));
  });
  test("iOS native launch screen is dark-only before Flutter branding", () {
    final launch = File(
      "ios/Runner/Base.lproj/LaunchScreen.storyboard",
    ).readAsStringSync();
    expect(launch, contains('red="0.027450980392156862"'));
    expect(launch, contains('green="0.0196078431372549"'));
    expect(launch, contains('blue="0.050980392156862745"'));
    expect(launch, isNot(contains("imageView")));
    expect(launch, isNot(contains('image="LaunchImage"')));
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
    final boot = File(
      "lib/core/telemetry/crash_telemetry_bootstrap.dart",
    ).readAsStringSync();
    expect(boot, contains("unawaited(service.initialize())"));
    expect(boot, isNot(contains("await service.initialize()")));
  });

  test("bootstrapProviders does not block first paint on anonymous auth", () {
    final app = File("lib/app/oracly_app.dart").readAsStringSync();
    expect(app, contains("AnonymousAuthBootstrap.ensure"));
    expect(app, contains("unawaited("));
    expect(app, isNot(contains("await AnonymousAuthBootstrap.ensure")));
  });

  test("pubspec does not directory-include all images (PNG masters)", () {
    final yaml = File("pubspec.yaml").readAsStringSync();
    expect(yaml.contains("- lib/assets/images/\n"), isFalse);
    expect(yaml, contains("lib/assets/images/coffee_ritual_hero.webp"));
    expect(yaml, contains("lib/assets/images/tarot/major_arcana/00_deli.webp"));
  });

  test("chamber camera releases on pause and reboots on resume", () {
    final camera = File(
      "lib/shared/camera/oracly_chamber_camera_screen.dart",
    ).readAsStringSync();
    expect(camera, contains("WidgetsBindingObserver"));
    expect(camera, contains("didChangeAppLifecycleState"));
    expect(camera, contains("_releaseCamera"));
    expect(camera, contains("AppLifecycleState.resumed"));
    // Must not release on inactive — Android emits it mid-shutter.
    expect(camera, isNot(contains("AppLifecycleState.inactive")));
    expect(camera, contains("if (_busy) return"));
  });
}
