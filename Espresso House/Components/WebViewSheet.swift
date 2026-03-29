//
//  WebViewSheet.swift
//  Espresso House
//

import SwiftUI
import WebKit

struct WebViewSheet: View {
    let url: URL
    let title: String
    var onResponseOK: (() -> Void)?
    var onResponseCancel: (() -> Void)?
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebViewController(url: url, onResponseOK: {
                onResponseOK?()
                dismiss()
            }, onResponseCancel: {
                onResponseCancel?()
                dismiss()
            })
                .ignoresSafeArea()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            onDismiss?()
                            dismiss()
                        }
                    }
                }
        }
        .interactiveDismissDisabled(true)
    }
}

// MARK: - UIKit-managed WebView

struct WebViewController: UIViewControllerRepresentable {
    let url: URL
    var onResponseOK: (() -> Void)?
    var onResponseCancel: (() -> Void)?

    func makeUIViewController(context: Context) -> WebViewHostController {
        WebViewHostController(url: url, onResponseOK: onResponseOK, onResponseCancel: onResponseCancel)
    }

    func updateUIViewController(_ uiViewController: WebViewHostController, context: Context) {}
}

class WebViewHostController: UIViewController, WKNavigationDelegate {
    private let url: URL
    private var webView: WKWebView!
    private let spinner = UIActivityIndicatorView(style: .large)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var processTerminated = false
    private var initialLoadDone = false
    private var responseHandled = false

    var onResponseOK: (() -> Void)?
    var onResponseCancel: (() -> Void)?

    // Recovery overlay shown when web process dies after backgrounding
    private lazy var recoveryOverlay: UIView = {
        let overlay = UIView()
        overlay.backgroundColor = .systemBackground
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isHidden = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "arrow.clockwise.circle"))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 48).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "Page session expired"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        let messageLabel = UILabel()
        messageLabel.text = "If you already completed authorization,\ntap Done above. Otherwise, reload to try again."
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let reloadButton = UIButton(type: .system)
        reloadButton.setTitle("Reload Page", for: .normal)
        reloadButton.titleLabel?.font = .preferredFont(forTextStyle: .body, compatibleWith: nil)
        reloadButton.addTarget(self, action: #selector(reloadTapped), for: .touchUpInside)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(reloadButton)

        overlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -32),
        ])

        return overlay
    }()

    init(url: URL, onResponseOK: (() -> Void)? = nil, onResponseCancel: (() -> Void)? = nil) {
        self.url = url
        self.onResponseOK = onResponseOK
        self.onResponseCancel = onResponseCancel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        view.addSubview(recoveryOverlay)
        NSLayoutConstraint.activate([
            recoveryOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            recoveryOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            recoveryOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recoveryOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        spinner.startAnimating()
        webView.load(URLRequest(url: url))

        // Keep web process alive when app backgrounds
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

    // MARK: - Background task management

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

    // MARK: - Recovery

    @objc private func reloadTapped() {
        recoveryOverlay.isHidden = true
        spinner.startAnimating()
        processTerminated = false
        webView.load(URLRequest(url: url))
    }

    // MARK: - Response code detection

    private func checkForResponseCode(in url: URL) {
        guard initialLoadDone, !responseHandled else { return }

        let urlString = url.absoluteString.lowercased()
        if urlString.contains("responsecode=ok") {
            responseHandled = true
            onResponseOK?()
        } else if urlString.contains("responsecode=cancel") {
            responseHandled = true
            onResponseCancel?()
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url {
            checkForResponseCode(in: url)
        }
        return .allow
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        initialLoadDone = true
        if !processTerminated {
            recoveryOverlay.isHidden = true
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        spinner.stopAnimating()
        processTerminated = true
        recoveryOverlay.isHidden = false
    }
}
