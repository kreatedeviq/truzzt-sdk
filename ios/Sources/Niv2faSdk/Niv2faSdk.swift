import Foundation
import UIKit
import WebKit

/// Embeddable NIV2FA verify for iOS host apps.
/// Note: Apple does not allow third-party apps to read SIM MSISDN.
/// This SDK opens the verify session in-app; Android SDK performs real SIM1/SIM2 match.
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

    public static func openVerify(
        from presenter: UIViewController,
        sessionUrl: String,
        completion: @escaping (Result) -> Void
    ) {
        let vc = Niv2faVerifyViewController(sessionUrl: sessionUrl, completion: completion)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }

    /// iOS cannot return SIM line numbers — always empty. Kept for API parity with Android.
    public static func getSimPhones() -> [[String: Any]] {
        return []
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
        window.Niv2faHost = {
          onResult: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          },
          postMessage: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          }
        };
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
