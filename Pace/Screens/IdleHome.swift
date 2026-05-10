//
//  IdleHome.swift
//  Pace.
//
//  v0.2.0 — 架构转型：从纯 SwiftUI 改为 WKWebView 嵌 HTML demo。
//
//  动机：HTML demo 早就所见即所得，而手工逐 padding 翻译成 SwiftUI 太慢
//  （v0.1.13-17 5 个版本调一个屏，仍有视觉差距）。Phone 01 是纯展示屏，
//  不需要传感器/后台/触觉这些原生能力，最适合走 WebView 路线。
//
//  分工：
//    - HTML 静态展示屏（首页/总结/分享/月报） → WKWebView 嵌 HTML
//    - 跑步进行屏（GPS / HKWorkoutSession / Live Activity）→ 原生 SwiftUI
//
//  JS ↔ Swift 桥接：HTML 里 .start-button 的 click 事件
//  通过 window.webkit.messageHandlers.startRun.postMessage 抛给 Swift，
//  Swift 这边收到后做触觉反馈，并 (v0.2.1) 切换到原生 RunningView。
//

import SwiftUI
import WebKit

struct IdleHome: View {
    var body: some View {
        WebShell(
            file: "idle-home",
            ext: "html",
            onStartRun: {
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                // v0.2.1: NavigationLink push to RunningView
                print("[IdleHome] start run pressed (web bridge)")
            }
        )
        .ignoresSafeArea() // 让 HTML 的 env(safe-area-inset-*) 自己处理留白
    }
}

// MARK: - WebShell · UIViewRepresentable 包装 WKWebView
//
// 单参约定：file 是 bundle 里的 .html 文件名（不带扩展），ext 默认 "html"。
// onStartRun 是 JS 桥触发回调。
//
// 加载策略：loadFileURL(_:allowingReadAccessTo:) — 允许 HTML 通过相对路径
// 引用同目录其它资源（未来若拆出独立 .css/.js 时不用改）。
//
struct WebShell: UIViewRepresentable {
    let file: String
    var ext: String = "html"
    var onStartRun: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onStartRun: onStartRun)
    }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(context.coordinator, name: "startRun")

        // iOS 14 兼容：preferences.javaScriptEnabled (iOS 14+ 也仍可用，
        // 虽然 iOS 14 引入了新的 WKWebpagePreferences API)
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        cfg.preferences = prefs

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.isOpaque = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.scrollView.bounces = false               // 关掉橡皮筋, 不像页面像 app
        wv.scrollView.showsVerticalScrollIndicator = false
        wv.scrollView.showsHorizontalScrollIndicator = false

        if let url = Bundle.main.url(forResource: file, withExtension: ext) {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // bundle 里没找到 — 显示错误占位，便于快速发现"忘记加到 Xcode target"
            let html = """
            <html><body style='background:#000;color:#fff;font-family:-apple-system;
            padding:40px;line-height:1.6'>
            <h2 style='color:#FF6B3D'>WebShell · 资源未找到</h2>
            <p>Bundle.main 里找不到 <code>\(file).\(ext)</code></p>
            <p>请在 Xcode 中：右键 Pace 文件夹 → Add Files to "Pace"…
               → 选择 <code>Pace/WebContent/idle-home.html</code>
               → 勾选 target Pace
               → 确认 "Create folder references" (蓝色文件夹)</p>
            </body></html>
            """
            wv.loadHTMLString(html, baseURL: nil)
        }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 静态加载, 不需要更新
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onStartRun: () -> Void

        init(onStartRun: @escaping () -> Void) {
            self.onStartRun = onStartRun
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "startRun":
                DispatchQueue.main.async { [weak self] in
                    self?.onStartRun()
                }
            default:
                break
            }
        }
    }
}

#if DEBUG
struct IdleHome_Previews: PreviewProvider {
    static var previews: some View {
        IdleHome()
            .preferredColorScheme(.dark)
    }
}
#endif
