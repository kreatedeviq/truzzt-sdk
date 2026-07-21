import Flutter
import UIKit
import Niv2faSdk

public class Niv2faFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "niv2fa", binaryMessenger: registrar.messenger())
    let instance = Niv2faFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermissions":
      result(["requested": true, "platform": "ios"])
    case "getSimPhones":
      result(["sims": [], "platform": "ios"])
    case "openVerify":
      guard let args = call.arguments as? [String: Any],
            let url = args["url"] as? String, !url.isEmpty,
            let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        result(FlutterError(code: "missing_url", message: "url/root required", details: nil))
        return
      }
      var top = root
      while let presented = top.presentedViewController { top = presented }
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
