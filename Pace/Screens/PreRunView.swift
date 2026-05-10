//
//  PreRunView.swift
//  Pace.
//
//  Phone 02 · 跑前预热 (Pre-Flight Check)
//
//  IdleHome 出发 → PreRunView → 倒计时归零 → RunningView
//  整屏长按 0.6s 取消, dismiss 回 IdleHome
//
//  对照 pace-demo/index.html#L2301-L2394
//

import SwiftUI

struct PreRunView: View {
    @Environment(\.presentationMode) private var presentationMode

    /// 倒计时秒数（每秒 -1, 归 0 进 RunningView）
    @State private var counter: Int = MockData.PreRun.countdownStart

    /// 倒计时归零 → 切到 RunningView
    @State private var goRunning = false

    /// 1 Hz 计时器
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        // 倒计时归零后整体替换为 RunningView (复用同一 fullScreenCover 层)
        if goRunning {
            RunningView()
        } else {
            preRunContent
        }
    }

    private var preRunContent: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                brandStrip
                Spacer().frame(height: 24)
                countdownSection
                Spacer().frame(height: 28)
                checklistSection
                Spacer()
                cancelHint
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.6) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            presentationMode.wrappedValue.dismiss()
        }
        .onReceive(timer) { _ in
            tickCountdown()
        }
        .onAppear {
            // 进入页面给一次 light haptic 表示 "即将开始"
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func tickCountdown() {
        if counter > 1 {
            counter -= 1
            UISelectionFeedbackGenerator().selectionChanged()
        } else if counter == 1 {
            counter = 0
            // 倒计时归零, success haptic + 切到 RunningView
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            goRunning = true
        }
    }

    // MARK: - 顶部标题条
    private var brandStrip: some View {
        HStack {
            Text("准备开跑")
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.4)

            Spacer()

            Text("PRE-FLIGHT CHECK")
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(2.0)
        }
        .padding(.top, 8)
    }

    // MARK: - 倒计时圆环 + COUNTDOWN caption + 提示文案
    private var countdownSection: some View {
        VStack(spacing: 14) {
            Text("COUNTDOWN")
                .font(PaceFont.mono(size: 9, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.6)

            CountdownCircle(value: counter, total: MockData.PreRun.countdownStart)
                .frame(width: 132, height: 132)

            Text("深呼吸，跑姿调整")
                .font(PaceFont.cn(size: 13, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 系统就绪 checklist
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("系统就绪 · SYSTEM CHECK")
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.2)
                .padding(.bottom, 4)

            ChecklistRow(
                label: "GPS",
                detail: "已锁定 \(MockData.PreRun.gpsSatellites) 颗卫星"
            )
            ChecklistRow(
                label: "心率",
                detail: "\(MockData.PreRun.restingHR) BPM 静息"
            )
            ChecklistRow(
                label: "音乐",
                detail: MockData.PreRun.musicSource
            )
            ChecklistRow(
                label: "语音",
                detail: MockData.PreRun.voiceSetting
            )
        }
    }

    // MARK: - 取消提示
    private var cancelHint: some View {
        HStack(spacing: 8) {
            Spacer()
            Text("长按取消")
                .font(PaceFont.cn(size: 9, weight: .regular))
                .foregroundColor(Theme.text4)
                .kerning(2.0)
            Text("·")
                .foregroundColor(Theme.text3)
            Text("HOLD TO CANCEL")
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(3.0)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - 倒计时圆环 (132x132, accent 渐变环 + 中央数字)
private struct CountdownCircle: View {
    let value: Int       // 当前剩余秒数
    let total: Int       // 总秒数 (用于环填充比例)

    var body: some View {
        ZStack {
            // 背景虚线圈 (HTML stroke-dasharray="2 4")
            Circle()
                .stroke(
                    Theme.accent.opacity(0.10),
                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4])
                )
                .padding(-4)

            // 灰色底圈
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 2)

            // 进度环 (accent → accentBright 渐变)
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.accent, Theme.accentBright]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: value)

            // 中央数字
            Text("\(value)")
                .font(.system(size: 56, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text1)
                .kerning(-2)
                .shadow(color: Theme.accent.opacity(0.4), radius: 12)
                .animation(nil, value: value)  // 数字本身不要动画淡入淡出
        }
    }

    private var progressRatio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(value) / CGFloat(total)
    }
}

// MARK: - Checklist 一行 (✓ + label + detail)
private struct ChecklistRow: View {
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            // 圆形 ✓ 徽标
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                Circle()
                    .stroke(Theme.accent.opacity(0.5), lineWidth: 0.8)
                Text("✓")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 22, height: 22)

            Text(label)
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(0.6)

            Spacer()

            Text(detail)
                .font(PaceFont.mono(size: 10, weight: .regular))
                .foregroundColor(Theme.text3)
                .kerning(0.4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.hairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#if DEBUG
struct PreRunView_Previews: PreviewProvider {
    static var previews: some View {
        PreRunView()
            .preferredColorScheme(.dark)
    }
}
#endif
