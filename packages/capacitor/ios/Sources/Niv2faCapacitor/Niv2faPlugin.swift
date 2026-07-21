import Foundation
import Capacitor
import Niv2faSdk
import UIKit

@objc(Niv2faPlugin)
public class Niv2faPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "Niv2faPlugin"
    public let jsName = "Niv2fa"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getSimPhones", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openVerify", returnType: CAPPluginReturnPromise)
    ]

    @objc func requestPermissions(_ call: CAPPluginCall) {
        call.resolve(["requested": true, "platform": "ios", "note": "iOS cannot grant SIM MSISDN access"])
    }

    @objc func getSimPhones(_ call: CAPPluginCall) {
        call.resolve(["sims": [], "platform": "ios"])
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
            Niv2faSdk.openVerify(from: vc, sessionUrl: url) { result in
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
