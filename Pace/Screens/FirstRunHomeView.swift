//
//  FirstRunHomeView.swift
//  Pace.
//
//  Phone 13 · 首次启动 (Empty Home)
//
//  对照 pace-demo/index.html#L4213-L4368
//  IdleHome 的空数据变体: 三表盘 empty + AI welcome + FIRST RUN 按钮 + 空 timeline
//
//  v0.4.8: 静态 mock. 接入流程 v0.5+ 加 isFirstRun flag 决定显示 IdleHome 还是这屏.
//

import SwiftUI

struct FirstRunHomeView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var engine: RunSessionEngine
    @EnvironmentObject var store: RunSessionStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Group {
                    brandStrip
                    greetingSection
                    hairlineDivider
                    metricsHeader
                    emptyTriad
                    aiWelcome
                }
                Spacer()
                StartButton {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    engine.startPreflight()
                }
                firstRunHint
                emptyTimeline
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 顶部条 (PACE. + 教练 locked chip)
    private var brandStrip: some View {
        HStack {
            (Text("PACE")
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(1.7)
            + Text(".")
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(Theme.accent))

            Spacer()

            // 教练 locked (opacity 0.5)
            HStack(spacing: 5) {
                Text("✦")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accent)
                Text("教练")
                    .font(PaceFont.cn(size: 11))
                    .foregroundColor(Theme.accent)
                    .kerning(0.5)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Theme.accent.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Theme.accent.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .opacity(0.5)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }

    // MARK: - 欢迎 (欢迎，刘宇 + 天气)
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(MockData.FirstRun.welcome)
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(0.76)

            HStack(spacing: 6) {
                Text(MockData.FirstRun.weather)
                    .font(PaceFont.cn(size: 10))
                    .foregroundColor(Theme.text2)
                    .kerning(1.5)
                Text("·")
                    .font(PaceFont.cn(size: 10))
                    .foregroundColor(Theme.text4)
                Text(MockData.FirstRun.weatherTag)
                    .font(PaceFont.cn(size: 10))
                    .foregroundColor(Theme.accent)
                    .kerning(1.5)
            }
        }
        .padding(.top, 22)
    }

    // MARK: - hairline 分隔
    private var hairlineDivider: some View {
        Hairline()
            .padding(.top, 16)
    }

    // MARK: - 今日体感 + NO DATA 标签
    private var metricsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("今日体感")
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.6)
            Spacer()
            Text("未连接 · NO DATA")
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(2.2)
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - 三表盘 全 empty 状态
    private var emptyTriad: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                DialCard(
                    cornerMark: String(format: "%02d", i + 1),
                    value: "—",
                    unit: "—",
                    label: MockData.FirstRun.dialLabels[i],
                    meta: MockData.FirstRun.dialEmptyMetas[i],
                    state: .empty
                )
            }
        }
        .frame(minHeight: 138)
    }

    // MARK: - AI welcome
    private var aiWelcome: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("✦")
                .font(.system(size: 11))
                .foregroundColor(Theme.accent)
            Text(MockData.FirstRun.aiWelcome)
                .font(PaceFont.cn(size: 11))
                .foregroundColor(Theme.text2)
                .lineSpacing(3)
        }
        .padding(.top, 18)
    }

    // MARK: - 首跑提示
    private var firstRunHint: some View {
        HStack(spacing: 8) {
            Text(MockData.FirstRun.firstRunHint1)
                .font(PaceFont.cn(size: 10, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(2.0)
            Text(MockData.FirstRun.firstRunHint2)
                .font(PaceFont.cn(size: 10, weight: .regular))
                .foregroundColor(Theme.text3)
                .kerning(1.4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 14)
    }

    // MARK: - 空 14 天 timeline
    private var emptyTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近 14 天")
                    .font(PaceFont.cn(size: 8.5))
                    .foregroundColor(Theme.text4)
                    .kerning(1.53)
                Spacer()
                Text("今天")
                    .font(PaceFont.mono(size: 8.5))
                    .foregroundColor(Theme.accent)
                    .kerning(2.13)
            }

            HStack(spacing: 0) {
                ForEach(0..<13, id: \.self) { _ in
                    Circle()
                        .stroke(Theme.hairlineBright, lineWidth: 1)
                        .frame(width: 5, height: 5)
                    Spacer(minLength: 0)
                }
                // 今日空心 accent 环
                Circle()
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .frame(width: 11, height: 11)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 5)
            }
            .padding(.vertical, 8)
        }
        .padding(.top, 16)
    }
}

#if DEBUG
struct FirstRunHomeView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunHomeView()
            .preferredColorScheme(.dark)
            .environmentObject(RunSessionEngine())
            .environmentObject(RunSessionStore.shared)
    }
}
#endif
