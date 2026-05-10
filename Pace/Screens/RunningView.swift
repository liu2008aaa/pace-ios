//
//  RunningView.swift
//  Pace.
//
//  Phone 03 · 跑步进行中（用户口语称 Phone 02）。
//
//  v0.3.0 静态 mock 视觉版
//  v0.3.1 字号上调 + 内嵌 Phone 12 暂停态（替代系统 ActionSheet）
//  v0.5  接 HKWorkoutSession + CLLocationManager 后改为 @ObservedObject 驱动
//
//  状态机
//    running → 长按 → paused
//    paused  → 点继续 → running
//    paused  → 第 1 次点结束 → confirming (按钮变"再点确认")
//    paused  → 第 2 次点结束 → dismiss (回 IdleHome)
//    confirming → 3 秒无操作 → 回 paused
//
//  字号对齐 HTML × 1.10 系数（按 docs/HTML-to-SwiftUI-Guide.md 第 3 章经验值微调）
//    pace-huge 84px → 92pt (HTML 84 × 1.10)
//    距离/时长  26px → 30pt
//    心率值    22px → 28pt
//

import SwiftUI

struct RunningView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var isPaused = false
    @State private var endConfirming = false   // 暂停态下首次点结束 → 进入二次确认窗口

    @State private var glowPhase = false       // 巨大配速数字呼吸光晕 (仅 running 时跑)
    @State private var pulsePhase = false      // GPS / 暂停 圆点呼吸

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                brandStrip
                Spacer()
                heroSection
                splitDivider
                distanceTimeRow
                Spacer()
                hrZoneSection
                hrCard
                bottomArea     // running: 长按提示 / paused: 两个大按钮 + 二次确认提示
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        // running 时整屏长按 0.6s 进入 paused (paused 时不响应长按)
        .contentShape(Rectangle())
        .gesture(
            isPaused ? nil :
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        isPaused = true
                    }
        )
        .onAppear { startBackgroundAnimations() }
    }

    // MARK: - 后台动画启动
    private func startBackgroundAnimations() {
        withAnimation(
            Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)
        ) {
            glowPhase = true
        }
        withAnimation(
            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
        ) {
            pulsePhase = true
        }
    }

    // MARK: - 顶部品牌条 (running / paused 两套)
    private var brandStrip: some View {
        HStack(alignment: .center) {
            Text(MockData.Running.activityType)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.0)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(isPaused ? Theme.gold : Theme.accent)
                    .frame(width: 6, height: 6)
                    .opacity(pulsePhase ? 0.35 : 0.85)
                    .shadow(color: (isPaused ? Theme.gold : Theme.accent).opacity(0.6), radius: 3)

                Text(isPaused ? "已暂停" : MockData.Running.gpsStatus)
                    .font(PaceFont.cn(size: 10, weight: isPaused ? .medium : .regular))
                    .foregroundColor(isPaused ? Theme.gold : Theme.text2)
                    .kerning(1.6)
            }

            Spacer()

            Text(MockData.Running.temperature)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text2)
        }
        .padding(.top, 8)
    }

    // MARK: - Hero 实时配速 (running) / 已暂停 (paused)
    // v0.3.3: 大胆放大 — 跑步 hero 是这屏的灵魂, 字号到顶到肩
    //   pace: 92 → 110pt + .bold (HTML 84 × 1.31, 接近 HTML px × 1.30 上限)
    //   caption: 10 → 12pt + .medium (重量补苹方比 Noto Sans SC 细)
    //   unit:   9.5 → 11pt + .semibold
    private var heroSection: some View {
        VStack(spacing: 6) {
            Text(isPaused ? "已暂停" : "实时配速")
                .font(PaceFont.cn(size: isPaused ? 13 : 12, weight: isPaused ? .semibold : .medium))
                .foregroundColor(isPaused ? Theme.gold : Theme.text3)
                .kerning(isPaused ? 5.2 : 3.8)
                .padding(.bottom, 6)

            // 巨大配速数字 — running 110pt .bold 呼吸 / paused 86pt 灰色静止
            Text(MockData.Running.pace)
                .font(.system(
                    size: isPaused ? 86 : 110,
                    weight: .bold,
                    design: .monospaced
                ))
                .foregroundColor(isPaused ? Color.white.opacity(0.4) : Theme.accent)
                .kerning(isPaused ? -3.4 : -4.4)
                .shadow(
                    color: isPaused ? .clear : Theme.accent.opacity(glowPhase ? 0.72 : 0.55),
                    radius: glowPhase ? 18 : 14
                )
                .shadow(
                    color: isPaused ? .clear : Theme.accent.opacity(glowPhase ? 0.42 : 0.30),
                    radius: glowPhase ? 36 : 28
                )
                .shadow(
                    color: isPaused ? .clear : Theme.accent.opacity(glowPhase ? 0.22 : 0.14),
                    radius: glowPhase ? 64 : 52
                )

            Text(isPaused ? "LAST PACE · 静止中" : "MIN / KM")
                .font(PaceFont.mono(size: isPaused ? 10 : 11, weight: .semibold))
                .foregroundColor(isPaused ? Theme.text4 : Theme.accent.opacity(0.85))
                .kerning(isPaused ? 3.6 : 4.4)
                .padding(.top, 4)
        }
    }

    // MARK: - SPLIT 分隔
    private var splitDivider: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(height: 0.5)

            Text("SPLIT \(String(format: "%02d", MockData.Running.splitNumber))")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(2.7)

            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(height: 0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .opacity(isPaused ? 0.5 : 1)
    }

    // MARK: - 距离 │ 时长 — v0.3.3 字号上调 30 → 36 + .bold
    private var distanceTimeRow: some View {
        HStack(alignment: .bottom, spacing: 32) {
            VStack(spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%.2f", MockData.Running.distanceKm))
                        .font(PaceFont.mono(size: 36, weight: .bold))
                        .foregroundColor(Theme.text1)
                        .kerning(-0.7)
                    Text("km")
                        .font(PaceFont.mono(size: 14, weight: .regular))
                        .foregroundColor(Theme.text3)
                }
                Text("距离")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.4)
            }

            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(width: 0.5, height: 42)
                .padding(.bottom, 18)

            VStack(spacing: 8) {
                Text(MockData.Running.durationStr)
                    .font(PaceFont.mono(size: 36, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.7)
                Text("时长")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.4)
            }
        }
    }

    // MARK: - 心率区间 (paused 时整体淡化 + marker 变金)
    private var hrZoneSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("心率区间")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.2)
                Spacer()
                Text(isPaused ? "Z2 · 静息中" : MockData.Running.hrZoneLabel)
                    .font(PaceFont.mono(size: 9.5, weight: .medium))
                    .foregroundColor(isPaused ? Theme.text3 : Theme.accent)
                    .kerning(1.4)
            }

            HRZoneBar(
                markerPosition: isPaused ? 0.32 : MockData.Running.hrZonePercent,
                markerColor: isPaused ? Theme.gold : Theme.accent
            )
            .frame(height: 7)

            HStack {
                ForEach(1...5, id: \.self) { i in
                    Text("Z\(i)")
                        .font(PaceFont.mono(size: 8, weight: .regular))
                        .foregroundColor(Theme.text4)
                        .kerning(1.0)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .opacity(isPaused ? 0.55 : 1)   // paused 时整体淡化, 模拟 HTML opacity: 0.55
        .padding(.bottom, 14)
    }

    // MARK: - 心率卡 — v0.3.3 字号 28 → 32 + .bold
    private var hrCard: some View {
        HStack {
            HStack(spacing: 10) {
                HeartShape()
                    .fill(Theme.heart)
                    .frame(width: 18, height: 17)

                Text("心率")
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(1.4)
            }

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(MockData.Running.heartRate)")
                    .font(PaceFont.mono(size: 32, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.6)
                Text("BPM")
                    .font(PaceFont.mono(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isPaused ? 0.7 : 1)
    }

    // MARK: - 底部区 (running: 长按提示 / paused: 双按钮 + 二次确认提示)
    @ViewBuilder
    private var bottomArea: some View {
        if isPaused {
            pausedActionButtons
        } else {
            hintRow
        }
    }

    // running 态的长按提示
    private var hintRow: some View {
        HStack(spacing: 8) {
            Circle()
                .stroke(Theme.text4, lineWidth: 1)
                .frame(width: 5, height: 5)

            Text("长按 → 暂停 / 结束")
                .font(PaceFont.cn(size: 9, weight: .regular))
                .foregroundColor(Theme.text4)
                .kerning(1.6)

            Circle()
                .stroke(Theme.text4, lineWidth: 1)
                .frame(width: 5, height: 5)
        }
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // paused 态的双大按钮 + 二次确认提示
    private var pausedActionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                PauseActionButton(
                    variant: .resume,
                    label: "继续",
                    enLabel: "CONTINUE"
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isPaused = false
                    endConfirming = false
                }

                PauseActionButton(
                    variant: .end,
                    label: endConfirming ? "再点确认" : "结束",
                    enLabel: endConfirming ? "TAP TO CONFIRM" : "END",
                    pulse: endConfirming
                ) {
                    handleEndTap()
                }
            }

            Text("点击「结束」需二次确认 · TAP TO CONFIRM")
                .font(PaceFont.cn(size: 9, weight: .regular))
                .foregroundColor(Theme.text4)
                .kerning(1.6)
                .padding(.top, 4)
        }
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // 二次确认结束 — 第一次进入 confirming 态, 3 秒后没第二次点击则回退
    private func handleEndTap() {
        if endConfirming {
            // 第二次点击 → 真结束
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentationMode.wrappedValue.dismiss()
        } else {
            // 第一次点击 → 进入 confirming, 3s 兜底回滚
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            endConfirming = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if endConfirming {
                    endConfirming = false
                }
            }
        }
    }
}

// MARK: - 5 段心率 zone bar
private struct HRZoneBar: View {
    let markerPosition: Double
    let markerColor: Color

    private let zoneColors: [Color] = [
        Theme.zone1, Theme.zone2, Theme.zone3, Theme.zone4, Theme.zone5,
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(zoneColors[i])
                            .frame(maxWidth: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 3.5))

                Circle()
                    .fill(markerColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Theme.bgApp, lineWidth: 2)
                    )
                    .shadow(color: markerColor.opacity(0.6), radius: 4)
                    .position(
                        x: CGFloat(markerPosition) * geo.size.width,
                        y: geo.size.height / 2
                    )
            }
        }
    }
}

// MARK: - 暂停态双按钮 (Phone 12 design)
//
// HTML 源 .action-btn.continue / .action-btn.end (index.html#L764-L813)
//   - 高 86px / 圆角 18px
//   - 双层背景: radial gradient + linear gradient
//   - 边框 + 多层 box-shadow + inset
//   - 内含 ▶/■ icon + 中文 label + 英文 LABEL (3 行)
//
private struct PauseActionButton: View {
    enum Variant { case resume, end }

    let variant: Variant
    let label: String
    let enLabel: String
    var pulse: Bool = false   // confirming 态时按钮发光呼吸
    let onTap: () -> Void

    @State private var pulsePhase = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(spacing: 4) {
                Text(iconChar)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(iconColor)
                    .shadow(color: iconColor.opacity(0.5), radius: 4)

                Text(label)
                    .font(PaceFont.cn(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .kerning(3.4)  // 0.22em × 17 = 3.74, 略缩

                Text(enLabel)
                    .font(PaceFont.mono(size: 8, weight: .medium))
                    .foregroundColor(textColor.opacity(0.7))
                    .kerning(2.8)  // 0.42em × 8 (HTML uppercase 字符间隙)
                    .padding(.top, 1)
            }
            .frame(height: 86)
            .frame(maxWidth: .infinity)
            .background(backgroundLayer)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: glowColor.opacity(pulse && pulsePhase ? 0.55 : 0.30),
                radius: pulse && pulsePhase ? 22 : 14
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if pulse {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulsePhase = true
                }
            }
        }
    }

    private var iconChar: String {
        switch variant {
        case .resume: return "▶"
        case .end:    return "■"
        }
    }

    private var iconColor: Color {
        switch variant {
        case .resume: return Theme.accentBright
        case .end:    return Theme.warn
        }
    }

    private var textColor: Color {
        switch variant {
        case .resume: return Theme.accentBright
        case .end:    return Theme.warn
        }
    }

    private var borderColor: Color {
        switch variant {
        case .resume: return Theme.accent.opacity(0.42)
        case .end:    return Theme.warn.opacity(0.35)
        }
    }

    private var glowColor: Color {
        switch variant {
        case .resume: return Theme.accent
        case .end:    return Theme.warn
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch variant {
        case .resume:
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.28),
                    Theme.accentDeep.opacity(0.5),
                    Color(hex: 0x002319, opacity: 0.9),
                ]),
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 100
            )
        case .end:
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.warn.opacity(0.18),
                    Color(hex: 0x8C321E, opacity: 0.35),
                    Color(hex: 0x281410, opacity: 0.9),
                ]),
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 100
            )
        }
    }
}

// MARK: - 心形 (HTML SVG path 翻译)
private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let s = { (x: Double, y: Double) -> CGPoint in
            CGPoint(x: rect.minX + CGFloat(x / 14) * w, y: rect.minY + CGFloat(y / 13) * h)
        }
        p.move(to: s(7, 12))
        p.addCurve(to: s(0.5, 3.5), control1: s(2, 9), control2: s(0.5, 6))
        p.addCurve(to: s(3.5, 0.5), control1: s(0.5, 1.5), control2: s(2, 0.5))
        p.addCurve(to: s(7, 3),     control1: s(5, 0.5), control2: s(6.5, 1.5))
        p.addCurve(to: s(10.5, 0.5),control1: s(7.5, 1.5), control2: s(9, 0.5))
        p.addCurve(to: s(13.5, 3.5),control1: s(12, 0.5), control2: s(13.5, 1.5))
        p.addCurve(to: s(7, 12),    control1: s(13.5, 6), control2: s(12, 9))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
struct RunningView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RunningView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Running")
        }
    }
}
#endif
