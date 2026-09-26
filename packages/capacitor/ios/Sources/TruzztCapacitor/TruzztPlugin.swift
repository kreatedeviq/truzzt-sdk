import Foundation
import Capacitor
import TruzztSdk
import UIKit

@objc(TruzztPlugin)
public class TruzztPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TruzztPlugin"
    public let jsName = "Truzzt"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getSimPhones", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openVerify", returnType: CAPPluginReturnPromise)
    ]

    @objc func requestPermissions(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else {
                call.reject("no_view_controller")
                return
            }
            TruzztSdk.requestPermissions(from: vc) { granted in
                call.resolve([
                    "requested": true,
                    "granted": granted,
                    "platform": "ios"
                ])
            }
        }
    }

    @objc func getSimPhones(_ call: CAPPluginCall) {
        call.resolve([
            "sims": TruzztSdk.getSimPhones(),
            "platform": "ios"
        ])
    }

    @objc func openVerify(_ call: CAPPluginCall) {
        guard let url = call.getString("url") ?? call.getString("sessionUrl"), !url.isEmpty else {
            call.reject("url is required")
            return
        }
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else {
                call.reject("no_view_controller")
                return
            }
            TruzztSdk.openVerify(from: vc, sessionUrl: url) { result in
                call.resolve([
                    "matched": result.matched,
                    "status": result.status ?? "",
                    "matchedSlot": result.matchedSlot as Any,
                    "sessionId": result.sessionId as Any,
                    "code": result.code as Any,
                    "message": result.message as Any,
                    "platform": "ios"
                ])
            }
        }
    }
}
