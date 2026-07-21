import Flutter
import UIKit
import Niv2faSdk

public class Niv2faFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "niv2fa", binaryMessenger: registrar.messenger())
    let instance = Niv2faFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let root = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
      ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
    guard var top = root else { return nil }
    while let presented = top.presentedViewController { top = presented }
    return top
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      guard let top = topViewController() else {
        result(FlutterError(code: "no_root", message: "No view controller", details: nil))
        return
      }
      Niv2faSdk.requestPermissions(from: top) { granted, sims in
        result([
          "requested": true,
          "granted": granted,
          "platform": "ios",
          "mode": "user_share",
          "simCount": sims.count
        ])
      }
    case "getSimPhones":
      result(["sims": Niv2faSdk.getSimPhones(), "platform": "ios", "mode": "user_share"])
    case "openVerify":
      guard let args = call.arguments as? [String: Any],
            let url = args["url"] as? String, !url.isEmpty,
            let top = topViewController() else {
        result(FlutterError(code: "missing_url", message: "url/root required", details: nil))
        return
      }
      Niv2faSdk.openVerify(from: top, sessionUrl: url) { r in
        result([
          "matched": r.matched,
          "status": r.status ?? "",
          "matchedSlot": r.matchedSlot as Any,
          "sessionId": r.sessionId as Any,
          "code": r.code as Any,
          "message": r.message as Any,
          "platform": "ios"
        ])
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
