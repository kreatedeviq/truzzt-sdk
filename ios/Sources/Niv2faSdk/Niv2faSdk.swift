import Foundation
import UIKit
import WebKit

/// Embeddable NIV2FA verify for iOS host apps.
///
/// Product rule (same as Android): the **SDK** reads device line identity and
/// confirms a match — users never type SIM numbers into the verify UI.
///
/// Note: Apple does not expose SIM MSISDN to third-party App Store apps the way
/// Android `READ_PHONE_NUMBERS` does. On iOS, open the verify session in the SDK
/// WebView after the user Allows access; match succeeds when a readable line is
/// available to the bridge. Prefer Android SDK / Agent for dual-SIM chip MSISDN.
public enum Niv2faSdk {
    public struct Result: Codable {
        public let matched: Bool
        public let status: String?
        public let matchedSlot: String?
        public let sessionId: String?
        public let code: String?
        public let message: String?
        public let platform: String?

        public init(matched: Bool, status: String? = nil, matchedSlot: String? = nil,
                    sessionId: String? = nil, code: String? = nil, message: String? = nil,
                    platform: String? = "ios") {
            self.matched = matched
            self.status = status
            self.matchedSlot = matchedSlot
            self.sessionId = sessionId
            self.code = code
            self.message = message
            self.platform = platform
        }
    }

    /// Ask the user to Allow the SDK to use phone / SIM identity for this verification.
    /// No manual number entry — numbers come from the native bridge only.
    public static func requestPermissions(
        from presenter: UIViewController,
        completion: @escaping (_ granted: Bool) -> Void
    ) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Allow phone identity?",
                message: "NIV2FA will read this device’s line identity through the SDK to confirm your number. You will not type SIM numbers.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Don’t Allow", style: .cancel) { _ in
                completion(false)
            })
            alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
                completion(true)
            })
            presenter.present(alert, animated: true)
        }
    }

    /// SIM lines from the native bridge (empty when the OS does not expose MSISDN).
    public static func getSimPhones() -> [[String: Any]] {
        return []
    }

    public static func openVerify(
        from presenter: UIViewController,
        sessionUrl: String,
        completion: @escaping (Result) -> Void
    ) {
        requestPermissions(from: presenter) { granted in
            if !granted {
                completion(.init(
                    matched: false,
                    status: "cancelled",
                    code: "permission_denied",
                    message: "User declined phone identity access"
                ))
                return
            }
            let vc = Niv2faVerifyViewController(sessionUrl: sessionUrl, completion: completion)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            presenter.present(nav, animated: true)
        }
    }
}

final class Niv2faVerifyViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private let sessionUrl: String
    private let completion: (Niv2faSdk.Result) -> Void
    private var webView: WKWebView!
    private var finished = false

    init(sessionUrl: String, completion: @escaping (Niv2faSdk.Result) -> Void) {
        self.sessionUrl = sessionUrl
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "NIV2FA"
        view.backgroundColor = UIColor(red: 0.07, green: 0.04, blue: 0.16, alpha: 1)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let uc = config.userContentController
        uc.add(self, name: "Niv2faHost")
        let js = """
        window.__NIV2FA_SDK__ = true;
        window.__NIV2FA_PLATFORM__ = 'ios';
        window.Niv2faHost = {
          onResult: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          },
          postMessage: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          }
        };
        window.Niv2faAgent = {
          requestPermissions: function() { return JSON.stringify({ granted: true, platform: 'ios' }); },
          requestPhonePermissions: function() { return this.requestPermissions(); },
          requestSimPermissions: function() { return this.requestPermissions(); },
          ensurePermissions: function() { return this.requestPermissions(); },
          askPermissions: function() { return this.requestPermissions(); },
          getSimPhones: function() { return JSON.stringify([]); },
          getSims: function() { return this.getSimPhones(); },
          readSims: function() { return this.getSimPhones(); }
        };
        window.AndroidBridge = window.Niv2faAgent;
        window.NivBridge = window.Niv2faAgent;
        """
        uc.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let url = URL(string: sessionUrl) {
            webView.load(URLRequest(url: url))
        } else {
            finish(.init(matched: false, status: "error", code: "bad_url", message: "Invalid session URL"))
        }
    }

    @objc private func closeTapped() {
        finish(.init(matched: false, status: "cancelled", code: "cancelled", message: "User cancelled"))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "Niv2faHost" else { return }
        let raw: String
        if let s = message.body as? String {
            raw = s
        } else if let dict = message.body as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let s = String(data: data, encoding: .utf8) {
            raw = s
        } else {
            raw = "{\"matched\":false,\"status\":\"error\",\"code\":\"bad_payload\"}"
        }
        finish(parse(raw))
    }

    private func parse(_ raw: String) -> Niv2faSdk.Result {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .init(matched: false, status: "error", code: "parse", message: raw)
        }
        return .init(
            matched: (obj["matched"] as? Bool) ?? false,
            status: obj["status"] as? String,
            matchedSlot: obj["matchedSlot"] as? String,
            sessionId: obj["sessionId"] as? String,
            code: obj["code"] as? String,
            message: obj["message"] as? String,
            platform: "ios"
        )
    }

    private func finish(_ result: Niv2faSdk.Result) {
        guard !finished else { return }
        finished = true
        dismiss(animated: true) { self.completion(result) }
    }
}
