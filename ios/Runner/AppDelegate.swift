import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 1. Apple Yerel Bildirim Merkezi (UNUserNotificationCenter) Kurulumu
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
          }
        }
      }
    }

    // 2. Flutter MethodChannel ile Apple Bildirim Merkezine Bildirim Ekleme
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let notificationChannel = FlutterMethodChannel(name: "com.example.pdks_flutter/apple_notifications",
                                                  binaryMessenger: controller.binaryMessenger)
    notificationChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "showAppleNotification" {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
        }

        if #available(iOS 10.0, *) {
          let content = UNMutableNotificationContent()
          content.title = title
          content.body = body
          content.sound = UNNotificationSound.default
          content.badge = 1

          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

          UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
              result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(true)
            }
          }
        } else {
          result(false)
        }
      } else if call.method == "requestPermission" {
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            result(granted)
          }
        } else {
          result(true)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Uygulama açıkken (Ön Planda / Foreground) dahi Apple Bildirim Merkezinde & Banner olarak göster
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}
