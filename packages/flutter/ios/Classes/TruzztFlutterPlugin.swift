import Flutter
import UIKit
import TruzztSdk

public class TruzztFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "truzzt", binaryMessenger: registrar.messenger())
    let instance = TruzztFlutterPlugin()
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
    case "configure":
      if let args = call.arguments as? [String: Any] {
        let key = args["apiKey"] as? String ?? ""
        let proj = args["projectId"] as? String ?? ""
        let base = args["baseUrl"] as? String
        var theme: [String: String]? = nil
        if let t = args["theme"] as? [String: Any] {
          theme = t.compactMapValues { v in (v as? String) ?? String(describing: v) }
        }
        TruzztSdk.configure(apiKey: key, projectId: proj, baseUrl: base, theme: theme)
      }
      result(["ok": TruzztSdk.isConfigured])
    case "requestPermissions":
      guard let top = topViewController() else {
        result(FlutterError(code: "no_root", message: "No view controller", details: nil))
        return
      }
      TruzztSdk.requestPermissions(from: top) { granted in
        result(["requested": true, "granted": granted, "platform": "ios"])
      }
    case "getSimPhones":
      result(["sims": TruzztSdk.getSimPhones(), "platform": "ios"])
    case "openVerify":
      guard let args = call.arguments as? [String: Any],
            let url = args["url"] as? String, !url.isEmpty,
            let top = topViewController() else {
        result(FlutterError(code: "missing_url", message: "url/root required", details: nil))
        return
      }
      TruzztSdk.openVerify(from: top, sessionUrl: url) { r in
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
