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

        // 多策略查找：先扁平 (forResource 默认递归)，再显式带 subdirectory，再扫整个 bundle
        let url = Self.locateResource(file: file, ext: ext)
        if let url = url {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            wv.loadHTMLString(Self.diagnosticPage(file: file, ext: ext), baseURL: nil)
        }
        return wv
    }

    /// 三步查找资源
    private static func locateResource(file: String, ext: String) -> URL? {
        // 策略 1：默认查找（forResource:withExtension: 已会递归到 subdirectory）
        if let u = Bundle.main.url(forResource: file, withExtension: ext) {
            return u
        }
        // 策略 2：显式 WebContent 子目录（folder reference 时路径保留）
        if let u = Bundle.main.url(forResource: file, withExtension: ext, subdirectory: "WebContent") {
            return u
        }
        // 策略 3：bundle 里全盘扫描，按文件名匹配（兜底，应对 group 引用打平的情况）
        let resURL = Bundle.main.resourceURL ?? Bundle.main.bundleURL
        let target = "\(file).\(ext)"
        if let enumerator = FileManager.default.enumerator(
            at: resURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let candidate as URL in enumerator where candidate.lastPathComponent == target {
                return candidate
            }
        }
        return nil
    }

    /// 资源没找到时的诊断页 — 列 bundle 实际内容，便于一眼看出是
    /// Xcode 没把文件 copy 进 bundle，还是 copy 进了但路径不对
    private static func diagnosticPage(file: String, ext: String) -> String {
        let bundlePath = Bundle.main.bundlePath
        let resURL = Bundle.main.resourceURL ?? Bundle.main.bundleURL

        var htmlFiles: [String] = []
        var allTopLevel: [String] = []

        if let enumerator = FileManager.default.enumerator(
            at: resURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                let rel = url.path.replacingOccurrences(of: bundlePath + "/", with: "")
                if url.pathExtension == "html" {
                    htmlFiles.append(rel)
                }
            }
        }

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: resURL.path) {
            allTopLevel = contents.sorted()
        }

        let htmlSection: String
        if htmlFiles.isEmpty {
            htmlSection = """
            <p style='color:#FF6B3D'>❌ Bundle 里完全没有 .html 文件。</p>
            <p>这说明 Xcode 根本没把 WebContent 文件夹 copy 进打包产物。</p>
            <p><b>修复</b>：选中 Pace target → Build Phases →
               展开 <b>Copy Bundle Resources</b> →
               检查里面是否有 WebContent 文件夹引用（蓝色）。
               如果没有，点左下 + 加进去。</p>
            <p>或者：删除 navigator 里的 WebContent → 重新 Add Files →
               这次确保 dialog 里 <b>Targets ▸ Pace</b> 勾上了，
               并且选了 <b>Create folder references</b>（不是 Create groups）。</p>
            """
        } else {
            let listed = htmlFiles.map { "<li><code>\($0)</code></li>" }.joined()
            htmlSection = """
            <p style='color:#29F0BD'>✅ Bundle 里有 .html 文件：</p>
            <ul>\(listed)</ul>
            <p>但 <code>locateResource("\(file)", "\(ext)")</code> 没找到。
               说明 Swift 查找逻辑漏了某条路径，请把这页截图发我修。</p>
            """
        }

        let topLevel = allTopLevel.prefix(40).map { "<li>\($0)</li>" }.joined()

        return """
        <html><body style='background:#000;color:#fff;font-family:-apple-system,sans-serif;
        padding:24px;line-height:1.55;font-size:14px'>
        <h2 style='color:#FF6B3D;margin-top:0'>WebShell · 资源未找到</h2>
        <p>查找目标：<code>\(file).\(ext)</code></p>
        <hr style='border-color:#222'>
        \(htmlSection)
        <hr style='border-color:#222'>
        <details>
          <summary style='color:#9CA0AB;cursor:pointer'>Bundle 顶层内容（前 40 项）</summary>
          <ul style='color:#9CA0AB;font-size:11px'>\(topLevel)</ul>
          <p style='color:#5A5E68;font-size:10px'>路径：<br>\(bundlePath)</p>
        </details>
        </body></html>
        """
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
