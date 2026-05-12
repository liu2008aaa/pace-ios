//
//  PausedView.swift
//  Pace.
//
//  Phone 12 · 暂停状态 (Paused)
//
//  对照 pace-demo/index.html#L4103-L4210
//
//  入口: InRunView 暂停按钮 → 这屏. v0.5+ 真 Timer/HealthKit 集成后接.
//
//  v0.4.12 静态视觉版.
//

import SwiftUI

struct PausedView: View {
    @EnvironmentObject var engine: RunSessionEngine
    @State private var pulse: Bool = false
    @State private var endConfirming: Bool = false   // v0.5.0: 二次确认结束

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                // ⚠️ ViewBuilder ≤10 子 (雷 1) — Group 前 8, 后续作 VStack 直接子
                Group {
                    brandStrip
                    Spacer().frame(height: 22)
                    heroSection
                    Spacer().frame(height: 28)
                    frozenStats
                    Spacer().frame(height: 24)
                    hrZoneSection
                    Spacer()   // flex push
                }
                actionButtons
                Spacer().frame(height: 8)
                confirmHint
                Spacer().frame(height: 14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - 顶部条 (户外跑 · ●已暂停 · 11°C)
    private var brandStrip: some View {
        HStack {
            Text(MockData.Paused.activityType)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.6)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.gold)
                    .frame(width: 6, height: 6)
                    .shadow(color: Theme.gold.opacity(0.6), radius: 5)
                    .opacity(pulse ? 1.0 : 0.55)
                Text(MockData.Paused.pausedChip)
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.gold)
                    .kerning(2.2)
            }
            Spacer()
            Text(MockData.Paused.weather)
                .font(PaceFont.mono(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
        }
    }

    // MARK: - hero (已暂停 + 大号 last pace + caption)
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text(MockData.Paused.pausedKickLabel)
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.gold)
                .kerning(5.6)
            Text(engine.paceDisplay)
                .font(.system(size: 64, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.40))
                .kerning(-2.5)
            Text(MockData.Paused.lastPaceCaption)
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(3.6)
        }
    }

    // MARK: - 冻结的数据 (距离 · 时长 — 从 engine 读)
    private var frozenStats: some View {
        HStack(alignment: .bottom, spacing: 26) {
            statBlock(value: engine.distanceDisplay,
                      unit: "km",
                      label: MockData.Paused.distanceLabel)
            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(width: 0.5, height: 38)
                .padding(.bottom, 16)
            statBlock(value: engine.elapsedDisplay,
                      unit: "",
                      label: MockData.Paused.timeLabel)
        }
    }

    @ViewBuilder
    private func statBlock(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(PaceFont.mono(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .kerning(-0.6)
                if !unit.isEmpty {
                    Text(unit)
                        .font(PaceFont.cn(size: 12, weight: .regular))
                        .foregroundColor(Theme.text3)
                }
            }
            Text(label)
                .font(PaceFont.cn(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.6)
        }
    }

    // MARK: - HR 区间条 (整体 opacity 0.55 表示冻结)
    private var hrZoneSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("心率区间")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text(MockData.Paused.hrZoneLabel)
                    .font(PaceFont.mono(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.6)
            }
            HrZoneBar(markerPct: MockData.Paused.hrMarkerPct)
                .frame(height: 16)
        }
        .opacity(0.55)
    }

    // MARK: - 双按钮 (继续 ▶ → engine.resume / 结束 ■ → 二次确认 → engine.end)
    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                engine.resume()
            }) {
                actionLabel(icon: "▶", cn: "继续", en: "CONTINUE", primary: true)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { handleEndTap() }) {
                actionLabel(
                    icon: "■",
                    cn: endConfirming ? "再点确认" : "结束",
                    en: endConfirming ? "TAP TO CONFIRM" : "END",
                    primary: false
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    /// 第一次点 → 进入 confirming, 3s 不操作自动回滚.
    /// 第二次点 → engine.end() (RunFlowView 切到 PostRunView)
    private func handleEndTap() {
        if endConfirming {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            engine.end()
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            endConfirming = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if endConfirming { endConfirming = false }
            }
        }
    }

    @ViewBuilder
    private func actionLabel(icon: String, cn: String, en: String, primary: Bool) -> some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(primary ? Theme.accentBright : Theme.warn)
                .shadow(color: (primary ? Theme.accent : Theme.warn).opacity(0.5), radius: 6)
            Text(cn)
                .font(PaceFont.cn(size: 16, weight: .bold))
                .foregroundColor(.white)
                .kerning(4.0)
            Text(en)
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Color.white.opacity(0.55))
                .kerning(2.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 84)
        .background(actionBg(primary: primary))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(primary ? Theme.accent.opacity(0.42) : Theme.warn.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: (primary ? Theme.accent : Theme.warn).opacity(primary ? 0.28 : 0.18),
                radius: primary ? 16 : 12)
    }

    // 双层渐变 (linear 底 + radial top accent/warn glow), 对照 HTML .action-btn
    @ViewBuilder
    private func actionBg(primary: Bool) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: primary
                    ? [Color(hex: 0x062A20), Color(hex: 0x001A14)]
                    : [Color(hex: 0x2A1410), Color(hex: 0x0F0805)]),
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                gradient: Gradient(colors: primary
                    ? [Theme.accent.opacity(0.28),
                       Color(hex: 0x004E38).opacity(0.5),
                       Color(hex: 0x00231A).opacity(0.0)]
                    : [Theme.warn.opacity(0.18),
                       Color(hex: 0x8C321E).opacity(0.35),
                       Color(hex: 0x280F0A).opacity(0.0)]),
                center: UnitPoint(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: 90
            )
        }
    }

    private var confirmHint: some View {
        Text(MockData.Paused.confirmHint)
            .font(PaceFont.cn(size: 9.5, weight: .medium))
            .foregroundColor(Theme.text4)
            .kerning(2.0)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - HR 5 区段 + 当前 marker (gold for paused, accent for InRun)
private struct HrZoneBar: View {
    let markerPct: Double   // 0..1

    // 5 段比例平分, 颜色 by HTML .z1-.z5
    private let zoneColors: [Color] = [
        Color.white.opacity(0.10),                  // Z1
        Color(hex: 0x00E5A8).opacity(0.22),         // Z2 accent
        Color(hex: 0x00E5A8).opacity(0.55),         // Z3 accent
        Color(hex: 0xFFC864).opacity(0.55),         // Z4 暖黄
        Color(hex: 0xFF6B3D).opacity(0.70),         // Z5 warn
    ]

    var body: some View {
        GeometryReader { geo in
            let w: CGFloat = geo.size.width
            let h: CGFloat = geo.size.height
            let segW: CGFloat = w / 5

            ZStack(alignment: .leading) {
                // 5 段水平堆叠 (整体圆角 clip)
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Rectangle()
                            .fill(zoneColors[i])
                            .frame(width: segW, height: h)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // marker (gold for paused) - 双层圈, 外圈是 bg-app 切口
                ZStack {
                    Circle()
                        .fill(Theme.bgApp)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 12, height: 12)
                }
                .shadow(color: Theme.gold.opacity(0.6), radius: 6)
                .position(x: CGFloat(markerPct) * w, y: h / 2)
            }
        }
    }
}

#if DEBUG
struct PausedView_Previews: PreviewProvider {
    static var previews: some View {
        PausedView()
            .environmentObject(RunSessionEngine())
            .preferredColorScheme(.dark)
    }
}
#endif
