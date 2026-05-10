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

            // v0.3.3: 重排 — 上下都加 Spacer 让 countdown 上半屏中线、checklist 下沉
            // 原版 brandStrip 紧贴顶, content 全堆顶部 → 下半屏空一半
            VStack(alignment: .leading, spacing: 0) {
                brandStrip

                Spacer()                     // 顶部弹性空间
                countdownSection
                Spacer()                     // 中段弹性空间 (countdown ↔ checklist)

                checklistSection

                Spacer().frame(height: 30)   // 固定下间距 (checklist ↔ hint)
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
//
// v0.3.3: 加心跳呼吸效果 — 整个圆环 1s 一次 ease-in-out 微缩放 (0.97 ↔ 1.0)
// + glow shadow opacity 同步呼吸, 视觉上像 "心脏鼓动等待出发"
//
private struct CountdownCircle: View {
    let value: Int
    let total: Int

    @State private var heartbeat = false

    var body: some View {
        ZStack {
            // 背景虚线靶环 (放大 4pt, dash 2-4)
            Circle()
                .stroke(
                    Theme.accent.opacity(0.10),
                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4])
                )
                .padding(-4)

            // 灰色底圈
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 2)

            // 进度环 — 字号大 + 渐变 + glow
            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.accent, Theme.accentBright]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)  // 2 → 3
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: value)
                .shadow(color: Theme.accent.opacity(heartbeat ? 0.55 : 0.30), radius: heartbeat ? 14 : 8)

            // 中央数字
            Text("\(value)")
                .font(.system(size: 64, weight: .bold, design: .monospaced))  // 56 → 64 + .bold
                .foregroundColor(Theme.text1)
                .kerning(-2)
                .shadow(color: Theme.accent.opacity(heartbeat ? 0.6 : 0.35), radius: heartbeat ? 16 : 10)
                .animation(nil, value: value)
        }
        .scaleEffect(heartbeat ? 1.03 : 1.0)
        .onAppear {
            // 1s 一次心跳 (ease-in-out, 自动反向往返 = 完整呼吸 2s)
            // 频率与 60BPM 静息心率一致, 给"待出发"的仪式感
            withAnimation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            ) {
                heartbeat = true
            }
        }
    }

    private var progressRatio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(value) / CGFloat(total)
    }
}

// MARK: - Checklist 一行 (✓ + label + detail)
//
// v0.3.3:
//   - 边框: Theme.hairline / 0.5pt (看不见) → Theme.hairlineBright / 1pt
//     (踩过的坑：SwiftUI 0.5pt 在 retina 上等于隐形, 1pt 才是 HTML 0.5px 的视觉)
//   - 字号上调: label 12 → 13 .medium → .semibold,  detail 10 → 11
//
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
                    .stroke(Theme.accent.opacity(0.55), lineWidth: 1)
                Text("✓")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 24, height: 24)

            Text(label)
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text2)
                .kerning(0.6)

            Spacer()

            Text(detail)
                .font(PaceFont.mono(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(0.4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.hairlineBright, lineWidth: 1)
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
