import Foundation
import UIKit
import WebKit

/// Embeddable NIV2FA verify for iOS host apps.
///
/// Verification works on **both** iOS and Android.
/// - Android: OS Phone permission → auto-read SIM1/SIM2 MSISDN.
/// - iOS: Apple blocks silent MSISDN reads. The user must **Allow** sharing
///   SIM line details, then confirm SIM1 (and optional SIM2). Those values are
///   injected into the verify WebView the same way Android’s bridge works.
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

    public struct SimLine {
        public let slot: String
        public let phone: String
        public init(slot: String, phone: String) {
            self.slot = slot
            self.phone = phone
        }
        public var asDict: [String: Any] {
            ["slot": slot, "phone": phone, "source": "user_share"]
        }
    }

    /// Ask the user to Allow / Don’t Allow sharing SIM details, then (if Allow)
    /// collect SIM1 / optional SIM2. Call before `openVerify` or let `openVerify` do it.
    public static func requestPermissions(
        from presenter: UIViewController,
        completion: @escaping (_ granted: Bool, _ sims: [SimLine]) -> Void
    ) {
        DispatchQueue.main.async {
            SharedSimStore.shared.requestShare(from: presenter, completion: completion)
        }
    }

    /// Lines the user chose to share (empty until permission + entry succeed).
    public static func getSimPhones() -> [[String: Any]] {
        SharedSimStore.shared.sims.map { $0.asDict }
    }

    public static func clearSharedSims() {
        SharedSimStore.shared.clear()
    }

    public static func openVerify(
        from presenter: UIViewController,
        sessionUrl: String,
        completion: @escaping (Result) -> Void
    ) {
        DispatchQueue.main.async {
            SharedSimStore.shared.requestShare(from: presenter) { granted, _ in
                if !granted {
                    completion(.init(
                        matched: false,
                        status: "cancelled",
                        code: "permission_denied",
                        message: "User declined to share SIM details"
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

// MARK: - Shared SIM consent store

final class SharedSimStore {
    static let shared = SharedSimStore()
    private(set) var sims: [Niv2faSdk.SimLine] = []
    private(set) var permissionGranted = false

    func clear() {
        sims = []
        permissionGranted = false
    }

    func requestShare(
        from presenter: UIViewController,
        completion: @escaping (Bool, [Niv2faSdk.SimLine]) -> Void
    ) {
        if permissionGranted, !sims.isEmpty {
            completion(true, sims)
            return
        }

        let alert = UIAlertController(
            title: "Share SIM details?",
            message: "NIV2FA needs your permission to use SIM1 / SIM2 line numbers on this iPhone to match your registered number.\n\nApple does not allow apps to read the number silently from the chip — you choose what to share (Settings → Cellular / About).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Don’t Allow", style: .cancel) { _ in
            self.clear()
            completion(false, [])
        })
        alert.addAction(UIAlertAction(title: "Allow", style: .default) { _ in
            self.permissionGranted = true
            let form = ShareSimViewController { lines in
                if lines.isEmpty {
                    self.clear()
                    completion(false, [])
                } else {
                    self.sims = lines
                    completion(true, lines)
                }
            }
            let nav = UINavigationController(rootViewController: form)
            nav.modalPresentationStyle = .formSheet
            presenter.present(nav, animated: true)
        })
        presenter.present(alert, animated: true)
    }
}

// MARK: - Share SIM form (user chooses what to share)

final class ShareSimViewController: UIViewController {
    private let onDone: ([Niv2faSdk.SimLine]) -> Void
    private let sim1Field = UITextField()
    private let sim2Field = UITextField()

    init(onDone: @escaping ([Niv2faSdk.SimLine]) -> Void) {
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Share SIM details"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Share", style: .done, target: self, action: #selector(shareTapped)
        )

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let hint = UILabel()
        hint.numberOfLines = 0
        hint.textColor = .secondaryLabel
        hint.font = .preferredFont(forTextStyle: .subheadline)
        hint.text = "Enter the phone number(s) on this device’s SIM(s). Find them in Settings → Cellular (or About → SIM). Dual-SIM: fill SIM1 and SIM2."

        configureField(sim1Field, placeholder: "SIM1 number (required)")
        configureField(sim2Field, placeholder: "SIM2 number (optional)")

        stack.addArrangedSubview(hint)
        stack.addArrangedSubview(labeled("SIM1", field: sim1Field))
        stack.addArrangedSubview(labeled("SIM2", field: sim2Field))

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func configureField(_ f: UITextField, placeholder: String) {
        f.placeholder = placeholder
        f.keyboardType = .phonePad
        f.borderStyle = .roundedRect
        f.autocorrectionType = .no
        f.textContentType = .telephoneNumber
    }

    private func labeled(_ title: String, field: UITextField) -> UIStackView {
        let l = UILabel()
        l.text = title
        l.font = .preferredFont(forTextStyle: .caption1)
        l.textColor = .secondaryLabel
        let s = UIStackView(arrangedSubviews: [l, field])
        s.axis = .vertical
        s.spacing = 4
        return s
    }

    private func digits(_ s: String?) -> String {
        String((s ?? "").filter { $0.isNumber })
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) { self.onDone([]) }
    }

    @objc private func shareTapped() {
        let s1 = digits(sim1Field.text)
        let s2 = digits(sim2Field.text)
        guard s1.count >= 8 else {
            let a = UIAlertController(title: "SIM1 required", message: "Enter at least 8 digits for SIM1.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }
        var lines = [Niv2faSdk.SimLine(slot: "sim1", phone: s1)]
        if s2.count >= 8 {
            lines.append(Niv2faSdk.SimLine(slot: "sim2", phone: s2))
        }
        dismiss(animated: true) { self.onDone(lines) }
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
        uc.addUserScript(WKUserScript(
            source: bridgeBootstrapJS(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))

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

    /// Same bridge contract as Android Agent / SDK WebView.
    private func bridgeBootstrapJS() -> String {
        let simsJson: String
        if let data = try? JSONSerialization.data(withJSONObject: SharedSimStore.shared.sims.map { $0.asDict }),
           let s = String(data: data, encoding: .utf8) {
            simsJson = s
        } else {
            simsJson = "[]"
        }
        return """
        window.__NIV2FA_SDK__ = true;
        window.__NIV2FA_PLATFORM__ = 'ios';
        window.__NIV2FA_SHARED_SIMS__ = \(simsJson);
        window.Niv2faHost = {
          onResult: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          },
          postMessage: function(json) {
            try { window.webkit.messageHandlers.Niv2faHost.postMessage(json); } catch (e) {}
          }
        };
        window.Niv2faAgent = {
          requestPermissions: function() { return JSON.stringify({ granted: true, platform: 'ios', mode: 'user_share' }); },
          requestPhonePermissions: function() { return this.requestPermissions(); },
          requestSimPermissions: function() { return this.requestPermissions(); },
          ensurePermissions: function() { return this.requestPermissions(); },
          askPermissions: function() { return this.requestPermissions(); },
          getSimPhones: function() { return JSON.stringify(window.__NIV2FA_SHARED_SIMS__ || []); },
          getSims: function() { return this.getSimPhones(); },
          readSims: function() { return this.getSimPhones(); }
        };
        window.AndroidBridge = window.Niv2faAgent;
        window.NivBridge = window.Niv2faAgent;
        """
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
