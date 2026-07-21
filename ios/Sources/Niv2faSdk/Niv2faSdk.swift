import Foundation
import UIKit
import WebKit

/// Embeddable NIV2FA verify for iOS.
///
/// 1. Call `Niv2faSdk.configure(apiKey:projectId:)` with dashboard credentials.
/// 2. Access is checked against the API (trial or active subscription required).
/// 3. Custom **Activate account** permission (not a system Phone warning) → verify.
/// 4. On Allow, iOS completes match via activation consent (Apple blocks silent SIM MSISDN).
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

    private static var apiKey = ""
    private static var projectId = ""
    private static var baseUrl = "https://jeebly.kreateiq.com/niv2fa"

    public static func configure(apiKey: String, projectId: String, baseUrl: String? = nil) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.projectId = projectId.trimmingCharacters(in: .whitespacesAndNewlines)
        if let b = baseUrl?.trimmingCharacters(in: .whitespacesAndNewlines), !b.isEmpty {
            self.baseUrl = b.hasSuffix("/") ? String(b.dropLast()) : b
        }
    }

    public static var isConfigured: Bool {
        apiKey.hasPrefix("niv_live_") && projectId.hasPrefix("proj_")
    }

    public static func getSimPhones() -> [[String: Any]] { [] }

    /// Validate API key + project (trial or subscribed). Fails if not entitled.
    public static func validateAccess(completion: @escaping (Bool, String?, String?) -> Void) {
        guard isConfigured else {
            completion(false, "CONFIG_REQUIRED", "Call Niv2faSdk.configure(apiKey:projectId:) first")
            return
        }
        var comps = URLComponents(string: baseUrl + "/secure-api/v1/sdk/access")!
        comps.queryItems = [URLQueryItem(name: "projectId", value: projectId)]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(false, "NETWORK", err.localizedDescription)
                    return
                }
                guard let data = data,
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(false, "BAD_RESPONSE", "Invalid server response")
                    return
                }
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                if code >= 400 || obj["success"] as? Bool != true {
                    completion(false, obj["code"] as? String ?? "ACCESS_DENIED", obj["message"] as? String)
                    return
                }
                completion(true, nil, nil)
            }
        }.resume()
    }

    /// Custom Activate-account permission (no iOS system Phone warning), then verify.
    public static func requestPermissions(
        from presenter: UIViewController,
        completion: @escaping (_ granted: Bool) -> Void
    ) {
        DispatchQueue.main.async {
            let vc = ActivationPermissionViewController { granted in
                completion(granted)
            }
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            presenter.present(nav, animated: true)
        }
    }

    public static func openVerify(
        from presenter: UIViewController,
        sessionUrl: String,
        completion: @escaping (Result) -> Void
    ) {
        validateAccess { ok, code, message in
            guard ok else {
                completion(.init(matched: false, status: "error", code: code, message: message))
                return
            }
            requestPermissions(from: presenter) { granted in
                if !granted {
                    completion(.init(
                        matched: false,
                        status: "cancelled",
                        code: "permission_denied",
                        message: "User declined account activation"
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
}

// MARK: - Activate account permission (custom UI — avoids system Phone warnings)

final class ActivationPermissionViewController: UIViewController {
    private let onDone: (Bool) -> Void

    init(onDone: @escaping (Bool) -> Void) {
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Activate account"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Don’t Allow", style: .plain, target: self, action: #selector(deny)
        )

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        let title = UILabel()
        title.text = "Activate your account with NIV2FA"
        title.font = .preferredFont(forTextStyle: .title2)
        title.numberOfLines = 0

        let body = UILabel()
        body.numberOfLines = 0
        body.font = .preferredFont(forTextStyle: .body)
        body.textColor = .label
        body.text = """
        To finish activating this account, NIV2FA needs your permission to confirm the phone number registered for this signup / login / order.

        What happens next
        • We match the registered number for this activation session.
        • No OTP codes are sent or typed.
        • No system “Phone” warning is required on iOS for this step.
        • You can tap Don’t Allow to cancel activation.

        By tapping Allow, you confirm you control this phone line and authorize NIV2FA to complete identity verification for account activation.
        """

        let allow = UIButton(type: .system)
        allow.setTitle("Allow — activate account", for: .normal)
        allow.titleLabel?.font = .boldSystemFont(ofSize: 17)
        allow.backgroundColor = UIColor(red: 0.345, green: 0.212, blue: 0.780, alpha: 1)
        allow.setTitleColor(.white, for: .normal)
        allow.layer.cornerRadius = 12
        allow.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        allow.addTarget(self, action: #selector(allowTapped), for: .touchUpInside)

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(allow)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    @objc private func deny() {
        dismiss(animated: true) { self.onDone(false) }
    }

    @objc private func allowTapped() {
        dismiss(animated: true) { self.onDone(true) }
    }
}

// MARK: - Verify WebView

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
        window.__NIV2FA_IOS_ACTIVATION__ = true;
        window.Niv2faHost = {
          onResult: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          },
          postMessage: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          }
        };
        window.Niv2faAgent = {
          requestPermissions: function() { return JSON.stringify({ granted: true, platform: 'ios', mode: 'activation' }); },
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
