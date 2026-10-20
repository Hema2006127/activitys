import ActivityKit
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // عشان إشعارات flutter_local_notifications تظهر والتطبيق مفتوح
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LiveActivityPlugin") {
      LiveActivityPlugin.register(with: registrar)
    }
  }
}

// MARK: - Live Activity (عداد الراحة)

/// القناة: habits/live_activity — بتتنادى من lib/core/services/live_activity_service.dart
final class LiveActivityPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "habits/live_activity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LiveActivityPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(nil)  // الأجهزة الأقدم: الإشعار بس
      return
    }

    switch call.method {
    case "showRest":
      guard
        let args = call.arguments as? [String: Any],
        let endsAt = args["endsAt"] as? Double,
        let total = args["totalSeconds"] as? Int,
        let label = args["label"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "missing arguments", details: nil))
        return
      }
      let state = RestTimerAttributes.ContentState(
        endsAt: Date(timeIntervalSince1970: endsAt),
        totalSeconds: total,
        pausedRemaining: args["pausedRemaining"] as? Int,
        label: label
      )
      Task {
        await RestActivityController.show(state)
        await MainActor.run { result(nil) }
      }

    case "end":
      Task {
        await RestActivityController.end()
        await MainActor.run { result(nil) }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

@available(iOS 16.2, *)
enum RestActivityController {
  static func show(_ state: RestTimerAttributes.ContentState) async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    // بعد وقت النهاية الـ Activity بتبقى "stale" وبتعرض "خلصت الراحة"
    let content = ActivityContent(
      state: state,
      staleDate: state.isPaused ? nil : state.endsAt
    )
    if let current = Activity<RestTimerAttributes>.activities.first {
      await current.update(content)
    } else {
      do {
        _ = try Activity.request(attributes: RestTimerAttributes(), content: content)
      } catch {
        NSLog("Live Activity request failed: \(error)")
      }
    }
  }

  static func end() async {
    for activity in Activity<RestTimerAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
}
