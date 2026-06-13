import SwiftUI
import WebKit

// Renders HTML from TYPO3 RTE fields. Uses WKWebView bridged into SwiftUI.
struct RichTextView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrappedHTML, baseURL: URL(string: "https://das-alte-dresden.de"))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private var wrappedHTML: String {
        """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
        <style>
          body {
            font-family: -apple-system, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: \(UITraitCollection.current.userInterfaceStyle == .dark ? "#e0d8cf" : "#2c1a0e");
            background: transparent;
            margin: 0; padding: 0;
          }
          img { max-width: 100%; height: auto; border-radius: 8px; }
          a { color: #8B5E3C; }
          h2, h3 { color: #6B3F1F; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Open external links in Safari rather than inside the web view
            if action.navigationType == .linkActivated, let url = action.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
