import Foundation
import UIKit
import Niv2faSdk

@objc(Niv2fa)
class Niv2fa: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { true }

  @objc func requestPermissions(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    resolve(["requested": true, "platform": "ios"] as [String: Any])
  }

  @objc func getSimPhones(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    resolve(["sims": [] as [Any], "platform": "ios"] as [String: Any])
  }

  @objc func openVerify(_ opts: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    let url = (opts["url"] as? String) ?? (opts["sessionUrl"] as? String) ?? ""
    guard !url.isEmpty else {
      reject("missing_url", "url required", nil)
      return
    }
    DispatchQueue.main.async {
      guard let root = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow })?
        .rootViewController else {
        reject("no_root", "No root view controller", nil)
        return
      }
      var top = root
      while let p = top.presentedViewController { top = p }
      Niv2faSdk.openVerify(from: top, sessionUrl: url) { r in
        resolve([
          "matched": r.matched,
          "status": r.status ?? "",
          "matchedSlot": r.matchedSlot as Any,
          "sessionId": r.sessionId as Any,
          "code": r.code as Any,
          "message": r.message as Any,
          "platform": "ios"
        ] as [String: Any])
      }
    }
  }
}
