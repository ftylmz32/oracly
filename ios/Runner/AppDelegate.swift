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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OraclyCupMapStorage") {
      CupMapStorage.register(messenger: registrar.messenger())
    }
  }
}

/// Fincan Haritası photos + map file: `Library/Application Support/
/// coffee_cup_map`, which iOS never purges, with isExcludedFromBackup set on
/// the directory and on every file the app writes into it (re-applied after
/// each atomic replace). Dart derives the same path; nothing outside that
/// directory is ever touched or reported excluded.
private enum CupMapStorage {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "app.oracly/cup_map_storage",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      do {
        let dir = try directory()
        switch call.method {
        case "excludeFromBackup":
          guard let file = inside(dir, call.arguments) else { return result(false) }
          try exclude(file)
          result(try isExcluded(file))
        case "isExcludedFromBackup":
          guard let file = inside(dir, call.arguments) else { return result(false) }
          result(try isExcluded(file))
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(
          code: "cup_map_storage",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  static func directory() throws -> URL {
    let support = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let dir = support.appendingPathComponent("coffee_cup_map", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try exclude(dir)
    return dir
  }

  static func inside(_ dir: URL, _ arguments: Any?) -> URL? {
    guard let path = (arguments as? [String: Any])?["path"] as? String else { return nil }
    let file = URL(fileURLWithPath: path).resolvingSymlinksInPath()
    let root = dir.resolvingSymlinksInPath().path + "/"
    guard file.path.hasPrefix(root),
          FileManager.default.fileExists(atPath: file.path) else { return nil }
    return file
  }

  static func exclude(_ url: URL) throws {
    var target = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try target.setResourceValues(values)
  }

  static func isExcluded(_ url: URL) throws -> Bool {
    try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
  }
}
