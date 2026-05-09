//
//  PaceApp.swift
//  Pace.
//
//  App 入口。@main 标记 iOS 14+ App protocol 实现。
//  暗色模式锁定（Pace. 是 dark-only by design）。
//

import SwiftUI

@main
struct PaceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 锁暗色，无视系统设置
            // iOS 状态栏默认显示，无需显式开关
            // (.statusBarHidden 是 iOS 16+，旧版用 .statusBar(hidden:))
        }
    }
}
