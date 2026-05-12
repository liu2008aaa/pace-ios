//
//  RunFlowView.swift
//  Pace.
//
//  v0.5.0: 跑步流程协调器 (state-driven switch).
//
//  IdleHome 的 fullScreenCover 现在统一拉起这一个 View. 内部根据
//  engine.phase 切换显示哪一屏:
//
//    .preflight / .ready / .countdown → PreRunView (新版, engine-driven)
//    .running                          → RunningView
//    .paused                           → PausedView
//    .ended                            → PostRunView
//    .idle                             → (理论上不会发生, IdleHome 已 dismiss
//                                          fullScreenCover, 这是兜底)
//
//  好处:
//  - PreRun / Running / Paused / PostRun 之间切换走 SwiftUI 自然过渡,
//    不需要每屏管 @State / fullScreenCover 嵌套
//  - 单一 source of truth = engine.phase
//

import SwiftUI

struct RunFlowView: View {
    @EnvironmentObject var engine: RunSessionEngine

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            switch engine.phase {
            case .preflight, .ready, .countdown:
                PreRunView()
            case .running:
                RunningView()
            case .paused:
                PausedView()
            case .ended:
                PostRunView()
            case .idle:
                // 兜底: 理论上 IdleHome 应该已 dismiss. 防御性显示空白
                Color.clear
            }
        }
    }
}
