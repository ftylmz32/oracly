import Flutter
import UIKit
import UserNotifications
import firebase_messaging
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UIScene registers plugins after this method returns, but Apple requires
    // the notification-center delegate to be set before it does.
    //
    // FlutterAppDelegate must own the delegate: it relays foreground
    // presentation and taps to every plugin registered with
    // addApplicationDelegate. flutter_local_notifications only receives
    // callbacks that way (it never becomes the delegate itself).
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    // Order matters. firebase_messaging 16.6.0 keeps an existing delegate
    // that conforms to FlutterAppLifeCycleProvider (FlutterAppDelegate) and
    // receives the relayed calls instead; its UIScene cold-start tap comes
    // from scene:willConnectToSession:options:. Called first, it would take
    // the delegate itself and could not forward local-notification taps.
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Lets the background isolate that handles notification actions reach
    // plugins.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
