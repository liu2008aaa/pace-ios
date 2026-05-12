//
//  PaceApp.swift
//  Pace.
//
//  App 入口。@main 标记 iOS 14+ App protocol 实现。
//  暗色模式锁定 (Pace. 是 dark-only by design).
//
//  v0.5.0: 注入 RunSessionEngine + RunSessionStore 到环境.
//          所有需要实时跑步数据的 View 通过 @EnvironmentObject 读.
//

import SwiftUI

@main
struct PaceApp: App {
    @StateObject private var engine = RunSessionEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(engine)
                .environmentObject(engine.store)
            // iOS 状态栏默认显示，无需显式开关
            // (.statusBarHidden 是 iOS 16+，旧版用 .statusBar(hidden:))
        }
    }
}
