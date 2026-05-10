//
//  PreRunView.swift
//  Pace.
//
//  Phone 02 · 跑前预热 (Pre-Flight Check)
//
//  v0.3.0 静态视觉
//  v0.3.2 倒计时 + 接 RunningView
//  v0.3.3 心跳呼吸 + 6s 倒计时
//  v0.3.4 layout 紧凑 + checklist ✓ 改实心 + 加 GPS 搜索状态变体 (Phone 14)
//
//  状态机
//    searching (2s) → counting (6s) → goRunning
//    长按任意时刻 → dismiss 回 IdleHome
//
//  对照 pace-demo/index.html
//    - PHONE 02 (#L2301-L2394) 正常预热 + 倒计时
//    - PHONE 14 (#L4351-L4444) GPS 搜索中变体
//

import SwiftUI

struct PreRunView: View {
    @Environment(\.presentationMode) private var presentationMode

    /// 当前阶段
    private enum Phase {
        case searching   // GPS 搜索中
        case counting    // 倒计时
        case goRunning   // 切到 RunningView
    }
    @State private var phase: Phase = .searching

    /// searching 阶段：当前已找到的卫星数，2 → 6
    @State private var satellites: Int = 2
    /// searching 阶段：已搜索秒数
    @State private var searchSeconds: Int = 0

    /// counting 阶段：剩余秒数
    @State private var counter: Int = MockData.PreRun.countdownStart

    /// 1 Hz 计时器（贯穿 searching + counting）
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if phase == .goRunning {
            RunningView()
        } else {
            preRunContent
        }
    }

    // MARK: - 主体
    private var preRunContent: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            // v0.3.5 应用「三段呼吸」模式 — 见 docs/HTML-to-SwiftUI-Guide.md §4.3
            // 旧版「上限封顶 + 一个无限吸收」会让 200+pt 富余高度集中在
            // 底部成大空洞。改用 3 个无封顶 Spacer, SwiftUI 自动均分,
            // 每段 ~70pt 都不算大空洞。
            VStack(alignment: .leading, spacing: 0) {
                brandStrip

                Spacer()                       // 段 1: brand ↔ hero

                heroSection
                    .frame(maxWidth: .infinity)

                Spacer()                       // 段 2: hero ↔ checklist

                checklistSection

                Spacer()                       // 段 3: checklist ↔ bottom

                bottomArea
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.6) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            presentationMode.wrappedValue.dismiss()
        }
        .onReceive(timer) { _ in tick() }
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: - 时序
    private func tick() {
        switch phase {
        case .searching:
            // 模拟卫星数递增, 2s 内从 2 → 6
            searchSeconds += 1
            if satellites < 6 {
                satellites = min(6, satellites + 2)
            }
            if searchSeconds >= 2 || satellites >= 6 {
                // GPS 锁定 → 进入倒计时
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                phase = .counting
            }
        case .counting:
            if counter > 1 {
                counter -= 1
                UISelectionFeedbackGenerator().selectionChanged()
            } else if counter == 1 {
                counter = 0
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                phase = .goRunning
            }
        case .goRunning:
            break
        }
    }

    // MARK: - 顶部标题条 (两态)
    private var brandStrip: some View {
        HStack {
            Text("准备开跑")
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.6)

            Spacer()

            // searching 时变成 PRE-FLIGHT · WAITING (金色)
            // counting 时正常 PRE-FLIGHT CHECK (text4)
            Text(phase == .searching ? "PRE-FLIGHT · WAITING" : "PRE-FLIGHT CHECK")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(phase == .searching ? Theme.gold : Theme.text4)
                .kerning(2.0)
        }
        .padding(.top, 8)
    }

    // MARK: - Hero (searching: 金 spinner + 卫星 / counting: 倒计时圆)
    @ViewBuilder
    private var heroSection: some View {
        switch phase {
        case .searching:
            VStack(spacing: 14) {
                Text("SEARCHING GPS · \(searchSeconds + 1) 秒")
                    .font(PaceFont.mono(size: 9, weight: .semibold))
                    .foregroundColor(Theme.gold)
                    .kerning(3.6)

                GpsSearchingCircle(satellites: satellites)
                    .frame(width: 132, height: 132)

                // "已找到 4 颗，需 ≥ 6 颗" — 4 用金色加重
                HStack(spacing: 4) {
                    Text("已找到")
                        .font(PaceFont.cn(size: 12, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(1.2)
                    Text("\(satellites)")
                        .font(PaceFont.mono(size: 13, weight: .bold))
                        .foregroundColor(Theme.gold)
                    Text("颗，需 ≥ 6 颗")
                        .font(PaceFont.cn(size: 12, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(1.2)
                }
            }

        case .counting:
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

        case .goRunning:
            EmptyView()
        }
    }

    // MARK: - Checklist (4 行, 不同状态)
    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("系统就绪 · SYSTEM CHECK")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(3.2)
                .padding(.bottom, 4)

            // GPS: searching 时 spinner + 金, counting 时 ✓
            ChecklistRow(
                state: phase == .searching ? .searching : .ok,
                label: "GPS",
                detail: phase == .searching
                    ? "搜索中 · \(satellites) / 6 颗"
                    : "已锁定 \(MockData.PreRun.gpsSatellites) 颗卫星"
            )

            ChecklistRow(
                state: .ok,
                label: "心率",
                detail: "\(MockData.PreRun.restingHR) BPM 静息"
            )

            // 音乐: searching 时显示警告 (HTML demo Phone 14 的设定)
            ChecklistRow(
                state: phase == .searching ? .warn : .ok,
                label: "音乐",
                detail: phase == .searching ? "未检测到" : MockData.PreRun.musicSource
            )

            ChecklistRow(
                state: .ok,
                label: "语音",
                detail: MockData.PreRun.voiceSetting
            )
        }
    }

    // MARK: - 底部 (searching: 双按钮 + 弱 GPS 提示 / counting: 长按取消提示)
    @ViewBuilder
    private var bottomArea: some View {
        if phase == .searching {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // 移到空旷处 — 次级 (灰边框)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("移到空旷处")
                            .font(PaceFont.cn(size: 12, weight: .medium))
                            .foregroundColor(Theme.text2)
                            .kerning(1.6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Theme.bgCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.hairlineBright, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 继续 (精度低) — 金色风险态
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        // 跳过 searching 直接进 counting
                        phase = .counting
                    }) {
                        Text("继续 (精度低)")
                            .font(PaceFont.cn(size: 12, weight: .semibold))
                            .foregroundColor(Theme.gold)
                            .kerning(1.6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Theme.gold.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.gold.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Text("树荫 / 室内 / 高楼附近 GPS 较弱")
                    .font(PaceFont.cn(size: 9, weight: .regular))
                    .foregroundColor(Theme.text4)
                    .kerning(2.0)
                    .padding(.top, 2)
            }
            .padding(.bottom, 4)
        } else {
            cancelHint
        }
    }

    // MARK: - 取消提示 (counting 阶段)
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

// MARK: - 倒计时圆环 (counting 阶段)
//
// 132×132, accent 渐变环 + 中央数字, 心跳呼吸 (1s ease-in-out 反向 ≈ 60 BPM)
//
private struct CountdownCircle: View {
    let value: Int
    let total: Int
    @State private var heartbeat = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Theme.accent.opacity(0.10),
                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4])
                )
                .padding(-4)

            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 2)

            Circle()
                .trim(from: 0, to: progressRatio)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.accent, Theme.accentBright]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: value)
                .shadow(color: Theme.accent.opacity(heartbeat ? 0.55 : 0.30), radius: heartbeat ? 14 : 8)

            Text("\(value)")
                .font(.system(size: 64, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.text1)
                .kerning(-2)
                .shadow(color: Theme.accent.opacity(heartbeat ? 0.6 : 0.35), radius: heartbeat ? 16 : 10)
                .animation(nil, value: value)
        }
        .scaleEffect(heartbeat ? 1.03 : 1.0)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            ) { heartbeat = true }
        }
    }

    private var progressRatio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(value) / CGFloat(total)
    }
}

// MARK: - GPS 搜索圆 (searching 阶段)
//
// 132×132, gold spinner (1.6s 旋转) + 中央卫星数 + "/ 6 SAT" 副标
// HTML stroke-dasharray "60 304" → SwiftUI .trim(from:0, to:0.165)
//
private struct GpsSearchingCircle: View {
    let satellites: Int
    @State private var spinAngle: Double = 0

    var body: some View {
        ZStack {
            // 外虚线靶环 (金)
            Circle()
                .stroke(
                    Theme.gold.opacity(0.12),
                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4])
                )
                .padding(-4)

            // 灰底圈
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 2)

            // 旋转金色圆弧
            Circle()
                .trim(from: 0, to: 0.165)  // ≈ 60° (HTML dasharray 60/364)
                .stroke(
                    Theme.gold,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(spinAngle))
                .shadow(color: Theme.gold.opacity(0.5), radius: 6)

            // 中央卫星数
            VStack(spacing: 2) {
                Text("\(satellites)")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text1)
                    .kerning(-1.5)
                    .shadow(color: Theme.gold.opacity(0.4), radius: 10)
                Text("/ 6 颗 SAT")
                    .font(PaceFont.mono(size: 8, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.0)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        }
    }
}

// MARK: - Checklist 行 — 三态
private struct ChecklistRow: View {
    enum State {
        case ok          // 绿 ✓
        case searching   // 金旋转圈
        case warn        // 金 !
    }

    let state: State
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
                .frame(width: 18, height: 18)

            Text(label)
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text2)
                .kerning(0.6)

            Spacer()

            Text(detail)
                .font(PaceFont.mono(size: 11, weight: .medium))
                .foregroundColor(detailColor)
                .kerning(0.4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(rowBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .ok:
            ZStack {
                Circle().fill(Theme.accent)
                Text("✓")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(Color(hex: 0x001A14))
            }
        case .searching:
            SpinnerArc()
        case .warn:
            ZStack {
                Circle().fill(Theme.gold)
                Text("!")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: 0x2A1F00))
            }
        }
    }

    private var detailColor: Color {
        switch state {
        case .ok:        return Theme.text3
        case .searching: return Theme.gold
        case .warn:      return Theme.gold
        }
    }

    private var rowBackground: Color {
        // 背景 tint 略提 — HTML 0.04 在 SwiftUI 也偏淡, 0.07 视觉刚好
        switch state {
        case .ok:        return Theme.accent.opacity(0.07)
        case .searching: return Theme.gold.opacity(0.08)
        case .warn:      return Theme.gold.opacity(0.07)
        }
    }

    private var rowBorder: Color {
        // v0.3.5: HTML border opacity × 1.6 ≈ SwiftUI 视觉对齐
        // 详见 docs/HTML-to-SwiftUI-Guide.md §2.7 边框可见度规则
        // SwiftUI 1pt 边框 retina anti-aliasing 比 CSS 0.5px 软 30-50%
        switch state {
        case .ok:        return Theme.accent.opacity(0.42)   // HTML 0.25 → 0.42
        case .searching: return Theme.gold.opacity(0.50)     // HTML 0.32 → 0.50
        case .warn:      return Theme.gold.opacity(0.45)     // HTML 0.28 → 0.45
        }
    }
}

// MARK: - 旋转圆弧 (checklist searching 状态用)
private struct SpinnerArc: View {
    @State private var angle: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Theme.gold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
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
