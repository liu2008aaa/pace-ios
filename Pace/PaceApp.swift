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
                .statusBarHidden(false)       // 保留 iOS 状态栏（不像 RN 版本画了假的）
        }
    }
}
