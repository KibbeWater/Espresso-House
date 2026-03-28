//
//  SafariPresenter.swift
//  Espresso House
//

import UIKit
import WebKit

/// Presents a WKWebView in its own UIWindow, completely independent of SwiftUI.
/// Survives NavigationStack resets, sheet dismissals, and app lifecycle events.
/// Intercepts redirect URLs for responseCode=OK/Cancel and bankid:// deep links.
class SafariPresenter: NSObject {
    static let shared = SafariPresenter()

    private var window: UIWindow?
    private var navController: UINavigationController?
    private var onSuccess: (() -> Void)?
    private var onDismiss: (() -> Void)?

    var isPresented: Bool { window != nil }

    func present(url: URL, onSuccess: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        if isPresented { dismiss(animated: false) }

        self.onSuccess = onSuccess
        self.onDismiss = onDismiss

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        let vc = CardRegistrationViewController(url: url) { [weak self] in
            // Done button tapped
            self?.dismiss(animated: true)
        } onResponseOK: { [weak self] in
            // PSP says OK — notify caller, but DON'T dismiss.
            // WebView keeps loading. Dismiss happens when polling confirms PaymentCardVerified.
            self?.onSuccess?()
        } onResponseCancel: { [weak self] in
            self?.dismiss(animated: true)
        }

        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false

        // Match app's light appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        self.navController = nav

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }

    func dismiss(animated: Bool = true) {
        guard isPresented else { return }
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.window?.alpha = 0
            }, completion: { _ in
                self.cleanup()
            })
        } else {
            cleanup()
        }
    }

    private func cleanup() {
        navController = nil
        window?.isHidden = true
        window = nil
        onDismiss?()
        onSuccess = nil
        onDismiss = nil
    }
}

// MARK: - Card Registration View Controller

class CardRegistrationViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private let initialURL: URL
    private let onDone: () -> Void
    private let onResponseOK: () -> Void
    private let onResponseCancel: () -> Void
    private var webView: WKWebView!
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private var lastLoadedURL: URL?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var initialLoadDone = false
    private var responseHandled = false

    init(url: URL, onDone: @escaping () -> Void, onResponseOK: @escaping () -> Void, onResponseCancel: @escaping () -> Void) {
        self.initialURL = url
        self.onDone = onDone
        self.onResponseOK = onResponseOK
        self.onResponseCancel = onResponseCancel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "Add Card"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        // Use Safari's mobile user agent so Nets/3DS pages offer direct BankID
        // deep links instead of the "any device" QR code fallback
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1"
        view.addSubview(webView)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        spinner.startAnimating()
        lastLoadedURL = initialURL
        webView.load(URLRequest(url: initialURL))

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    deinit {
        endBackgroundTask()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func doneTapped() {
        onDone()
    }

    // MARK: - URL handling

    /// Check URL for responseCode signals. Does NOT cancel navigation —
    /// the WebView continues loading the redirect target.
    private func checkResponseCode(_ url: URL) {
        let urlString = url.absoluteString.lowercased()
        guard initialLoadDone, !responseHandled else { return }

        if urlString.contains("responsecode=ok") {
            responseHandled = true
            print("[CardRegistration] responseCode=OK detected, starting verification polling")
            onResponseOK()
        } else if urlString.contains("responsecode=cancel") {
            responseHandled = true
            print("[CardRegistration] responseCode=Cancel detected")
            onResponseCancel()
        }
    }

    /// Check URL for custom schemes or BankID that need external handling.
    /// Returns true if navigation should be cancelled.
    private func handleDeepLink(_ url: URL) -> Bool {
        // bankid:// scheme deep link
        if let scheme = url.scheme?.lowercased(), scheme == "bankid" {
            print("[CardRegistration] Opening BankID scheme link: \(url)")
            openExternalURL(url)
            return true
        }

        // https://app.bankid.com/ — launch BankID app via bankid:// scheme
        if let host = url.host?.lowercased(), host == "app.bankid.com" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let autostarttoken = components?.queryItems?.first(where: { $0.name == "autostarttoken" })?.value
            var bankIDURLString = "bankid:///"
            if let token = autostarttoken {
                bankIDURLString += "?autostarttoken=\(token)&redirect=espresso-hause://bankid-complete"
            }
            guard let bankIDURL = URL(string: bankIDURLString) else { return true }
            print("[CardRegistration] Launching BankID: \(bankIDURL)")
            UIApplication.shared.open(bankIDURL) { [weak self] success in
                if !success {
                    // BankID not installed — show alert, stay in app
                    DispatchQueue.main.async {
                        self?.showBankIDNotInstalledAlert()
                    }
                }
            }
            return true
        }

        // intent: URLs (Android-style, shared PSP pages may emit them)
        if url.absoluteString.lowercased().starts(with: "intent:") {
            print("[CardRegistration] Opening BankID from intent: URL")
            if let bankID = URL(string: "bankid:///") {
                openExternalURL(bankID)
            }
            return true
        }

        return false
    }

    private func openExternalURL(_ url: URL) {
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                print("[CardRegistration] Failed to open URL: \(url)")
            }
        }
    }

    private func showBankIDNotInstalledAlert() {
        let alert = UIAlertController(
            title: "BankID Required",
            message: "The BankID app is required to verify your card. Please install it from the App Store.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "App Store", style: .default) { _ in
            if let url = URL(string: "https://apps.apple.com/app/bankid-sakerhetsapp/id433151512") {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    // MARK: - Background task

    @objc private func appDidEnterBackground() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        initialLoadDone = true
        if let url = webView.url {
            lastLoadedURL = url
            checkResponseCode(url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // WKWebView fails on custom URL schemes — extract and open externally
        let nsError = error as NSError
        print("[CardRegistration] didFailProvisionalNavigation: \(nsError.domain) code=\(nsError.code)")
        if let failingURL = nsError.userInfo["NSErrorFailingURLKey"] as? URL {
            print("[CardRegistration]   failingURL: \(failingURL)")
            if handleDeepLink(failingURL) { return }
            checkResponseCode(failingURL)
        }
        if let failingURLString = nsError.userInfo["NSErrorFailingURLStringKey"] as? String,
           let url = URL(string: failingURLString) {
            print("[CardRegistration]   failingURLString: \(failingURLString)")
            if handleDeepLink(url) { return }
            checkResponseCode(url)
        }
        spinner.stopAnimating()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        print("[CardRegistration] navigation: \(url.absoluteString)")
        lastLoadedURL = url

        // Only cancel navigation for deep links (bankid://, intent:)
        if handleDeepLink(url) {
            decisionHandler(.cancel)
            return
        }

        // Check for responseCode but DON'T cancel — let WebView continue loading
        checkResponseCode(url)

        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        spinner.startAnimating()
        if let url = lastLoadedURL {
            webView.load(URLRequest(url: url))
        } else {
            webView.load(URLRequest(url: initialURL))
        }
    }

    // MARK: - WKUIDelegate (handle popups / window.open)

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Handle target="_blank" and window.open — load in the same WebView
        if let url = navigationAction.request.url {
            if handleDeepLink(url) { return nil }
            checkResponseCode(url)
            webView.load(navigationAction.request)
        }
        return nil
    }
}
