import Foundation
import Niv2faSdk
import UIKit

@objc(Niv2faCordovaPlugin)
class Niv2faCordovaPlugin: CDVPlugin {
    @objc(requestPermissions:)
    func requestPermissions(command: CDVInvokedUrlCommand) {
        guard let vc = self.viewController else {
            let r = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "no_view_controller")
            commandDelegate.send(r, callbackId: command.callbackId)
            return
        }
        Niv2faSdk.requestPermissions(from: vc) { granted, sims in
            let payload: [String: Any] = [
                "requested": true,
                "granted": granted,
                "platform": "ios",
                "mode": "user_share",
                "simCount": sims.count
            ]
            let r = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: payload)
            self.commandDelegate.send(r, callbackId: command.callbackId)
        }
    }

    @objc(getSimPhones:)
    func getSimPhones(command: CDVInvokedUrlCommand) {
        let r = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
            "sims": Niv2faSdk.getSimPhones(),
            "platform": "ios",
            "mode": "user_share"
        ])
        commandDelegate.send(r, callbackId: command.callbackId)
    }

    @objc(openVerify:)
    func openVerify(command: CDVInvokedUrlCommand) {
        let opts = command.argument(at: 0) as? [String: Any]
        let url = (opts?["url"] as? String) ?? (opts?["sessionUrl"] as? String) ?? ""
        guard !url.isEmpty, let vc = self.viewController else {
            let r = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "url is required")
            commandDelegate.send(r, callbackId: command.callbackId)
            return
        }
        Niv2faSdk.openVerify(from: vc, sessionUrl: url) { result in
            let payload: [String: Any] = [
                "matched": result.matched,
                "status": result.status ?? "",
                "matchedSlot": result.matchedSlot as Any,
                "sessionId": result.sessionId as Any,
                "code": result.code as Any,
                "message": result.message as Any,
                "platform": "ios"
            ]
            let r = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: payload)
            self.commandDelegate.send(r, callbackId: command.callbackId)
        }
    }
}
