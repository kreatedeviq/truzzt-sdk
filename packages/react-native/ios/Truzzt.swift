import Foundation
import UIKit
import TruzztSdk

@objc(Truzzt)
class Truzzt: NSObject {
  @objc static func requiresMainQueueSetup() -> Bool { true }

  private func topVC() -> UIViewController? {
    let root = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?
      .rootViewController
    guard var top = root else { return nil }
    while let p = top.presentedViewController { top = p }
    return top
  }

  @objc func requestPermissions(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async {
      guard let top = self.topVC() else {
        reject("no_root", "No root view controller", nil)
        return
      }
      TruzztSdk.requestPermissions(from: top) { granted in
        resolve(["requested": true, "granted": granted, "platform": "ios"] as [String: Any])
      }
    }
  }

  @objc func getSimPhones(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
    resolve(["sims": TruzztSdk.getSimPhones(), "platform": "ios"] as [String: Any])
  }

  @objc func openVerify(_ opts: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    let url = (opts["url"] as? String) ?? (opts["sessionUrl"] as? String) ?? ""
    guard !url.isEmpty else {
      reject("missing_url", "url required", nil)
      return
    }
    DispatchQueue.main.async {
      guard let top = self.topVC() else {
        reject("no_root", "No root view controller", nil)
        return
      }
      TruzztSdk.openVerify(from: top, sessionUrl: url) { r in
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
