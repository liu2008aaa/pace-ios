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
//  v0.5.0 engine-driven — 内部状态机搬到 RunSessionEngine, 这屏仅做 UI 渲染.
//         engine.phase ∈ {.preflight, .ready, .countdown} 都由这屏显示;
//         .running 之后 RunFlowView 切到 RunningView.
//
//  对照 pace-demo/index.html
//    - PHONE 02 (#L2301-L2394) 正常预热 + 倒计时
//    - PHONE 14 (#L4351-L4444) GPS 搜索中变体
//

import SwiftUI

struct PreRunView: View {
    @EnvironmentObject var engine: RunSessionEngine

    /// engine 暴露的 fixCount (0..6), 显示为"卫星数"
    private var satellites: Int { min(6, max(0, engine.gpsFixCount)) }
    /// engine.preflightSeconds — 已搜索秒
    private var searchSeconds: Int { engine.preflightSeconds }
    /// engine.countdown — countdown 剩余秒
    private var counter: Int { engine.countdown }

    /// .preflight = GPS 搜星中; .ready/.countdown = 倒计时
    private var isSearching: Bool { engine.phase == .preflight }
    private var isLocationDenied: Bool { isSearching && engine.locationDenied }
    private var shouldShowGpsIssue: Bool {
        isSearching && (engine.waitingForGps || engine.locationDenied)
    }
    private var isCountdown: Bool {
        engine.phase == .countdown || engine.phase == .ready
    }

    var body: some View {
        preRunContent
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
            engine.cancelPreflight()
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            Text(isSearching ? "PRE-FLIGHT · WAITING" : "PRE-FLIGHT CHECK")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(isSearching ? Theme.gold : Theme.text4)
                .kerning(2.0)
        }
        .padding(.top, 8)
    }

    // MARK: - Hero (searching: 金 spinner + 卫星 / counting: 倒计时圆)
    @ViewBuilder
    private var heroSection: some View {
        if shouldShowGpsIssue {
            VStack(spacing: 14) {
                Text(isLocationDenied
                     ? "LOCATION PERMISSION"
                     : "SEARCHING GPS · \(searchSeconds + 1) 秒")
                    .font(PaceFont.mono(size: 9, weight: .semibold))
                    .foregroundColor(Theme.gold)
                    .kerning(3.6)

                GpsSearchingCircle(satellites: satellites)
                    .frame(width: 132, height: 132)

                // "已找到 4 颗，需 ≥ 6 颗" — 4 用金色加重
                HStack(spacing: 4) {
                    Text(isLocationDenied ? "定位权限" : "已找到")
                        .font(PaceFont.cn(size: 12, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(1.2)
                    Text(isLocationDenied ? "未开启" : "\(satellites)")
                        .font(PaceFont.mono(size: 13, weight: .bold))
                        .foregroundColor(Theme.gold)
                    Text(isLocationDenied ? "，无法锁定 GPS" : "颗，需 ≥ 6 颗")
                        .font(PaceFont.cn(size: 12, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(1.2)
                }
            }
        } else if isSearching {
            VStack(spacing: 14) {
                Text("PREPARING")
                    .font(PaceFont.mono(size: 9, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(3.6)

                CountdownCircle(value: 3)
                    .frame(width: 132, height: 132)

                Text("正在初始化 GPS 与心率")
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(2.4)
            }
        } else {
            // .ready / .countdown 共用倒计时 hero. .ready 短暂 0.2s 视为 countdown=3
            VStack(spacing: 14) {
                Text("COUNTDOWN")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(3.6)

                Group {
                    if engine.phase == .countdown {
                        CountdownCircle(value: max(1, counter))
                            .id("countdown-progress")
                    } else {
                        CountdownCircle(value: 3)
                            .id("countdown-ready")
                    }
                }
                .frame(width: 132, height: 132)

                Text("深呼吸，跑姿调整")
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(2.4)
            }
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
                state: shouldShowGpsIssue ? .searching : .ok,
                label: "GPS",
                detail: isLocationDenied
                    ? "定位权限未开启"
                    : shouldShowGpsIssue
                    ? "搜索中 · \(satellites) / 6 颗"
                    : satellites > 0
                    ? "已收到定位信号"
                    : "后台初始化中"
            )

            ChecklistRow(
                state: engine.currentHR == nil ? .warn : .ok,
                label: "心率",
                detail: engine.currentHR.map { "\($0) BPM" }
                    ?? "等待 Apple Watch"
            )

            ChecklistRow(
                state: .ok,
                label: "记录",
                detail: "路线 · 配速 · 时间"
            )

            ChecklistRow(
                state: .ok,
                label: "开始",
                detail: isSearching ? "即将倒计时" : "倒计时中"
            )
        }
    }

    // MARK: - 底部 (searching: 双按钮 + 弱 GPS 提示 / counting: 长按取消提示)
    @ViewBuilder
    private var bottomArea: some View {
        if shouldShowGpsIssue {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // 移到空旷处 / 返回 — 次级 (取消, 回 IdleHome)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        engine.cancelPreflight()
                    }) {
                        Text(isLocationDenied ? "返回首页" : "移到空旷处")
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

                    // 继续 (精度低) — 金色风险态 → 跳过 GPS 等
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        engine.skipGpsAndProceed()
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

                Text(isLocationDenied ? "请在系统设置中允许定位，或继续低精度记录" : "树荫 / 室内 / 高楼附近 GPS 较弱")
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
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 3, lineCap: .butt)
                )
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

    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Theme.accent, Theme.accentBright]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            .environmentObject(RunSessionEngine())
            .preferredColorScheme(.dark)
    }
}
#endif
