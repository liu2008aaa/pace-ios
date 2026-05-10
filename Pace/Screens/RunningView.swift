//
//  RunningView.swift
//  Pace.
//
//  Phone 03 · 跑步进行中（用户口语称 Phone 02）。
//
//  v0.3.0 静态 mock 视觉版：所有数据来自 MockData.Running。
//  v0.5 接 HKWorkoutSession + CLLocationManager 后改为 @ObservedObject 驱动。
//
//  核心元素 (按 pace-demo/index.html#L2397-L2512 对照):
//    - 品牌条: 户外跑 · ● GPS 锁定 · 11°C
//    - 实时配速 caption + 巨大 5'24" 发光呼吸 + MIN/KM
//    - SPLIT 04 虚线分隔
//    - 距离 3.42km │ 时长 18:32
//    - 心率区间 Z3·TEMPO 5 段 zone bar
//    - 心率卡 ❤ 152 bpm
//    - 长按提示 → 暂停/结束
//
//  iOS 14 / Swift 5.4 兼容：
//    - 用 PlainButtonStyle()、.kerning()、Animation.linear 显式构造
//    - VStack 直接子元素 ≤ 10 (本文件 7 个 — 安全)
//    - 长按弹 ActionSheet 而非 iOS 15+ 的 confirmationDialog
//

import SwiftUI

struct RunningView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var showStopSheet = false
    @State private var glowPhase = false   // 巨大配速数字呼吸光晕
    @State private var pulsePhase = false  // GPS 锁定圆点呼吸

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
                hintRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        // 整屏长按 0.6s 唤起暂停/结束面板
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.6) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            showStopSheet = true
        }
        .actionSheet(isPresented: $showStopSheet) {
            ActionSheet(
                title: Text("跑步控制"),
                message: Text("已跑 \(String(format: "%.2f", MockData.Running.distanceKm)) km · \(MockData.Running.durationStr)"),
                buttons: [
                    .default(Text("继续跑步")),
                    .default(Text("暂停")) {
                        // v0.3.x: 切到暂停态 (Phone 12)
                    },
                    .destructive(Text("结束跑步")) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        presentationMode.wrappedValue.dismiss()
                    },
                    .cancel(Text("取消")),
                ]
            )
        }
        .onAppear {
            // 巨大配速数字 — 4.2s 呼吸光晕 (HTML glow-breathe)
            withAnimation(
                Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)
            ) {
                glowPhase = true
            }
            // GPS 锁定圆点 — 2s pulse-soft
            withAnimation(
                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
            ) {
                pulsePhase = true
            }
        }
    }

    // MARK: - 顶部品牌条
    private var brandStrip: some View {
        HStack(alignment: .center) {
            Text(MockData.Running.activityType)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.0)

            Spacer()

            HStack(spacing: 5) {
                // GPS 圆点 (脉动)
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 6, height: 6)
                    .opacity(pulsePhase ? 0.35 : 0.85)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 3)

                Text(MockData.Running.gpsStatus)
                    .font(PaceFont.cn(size: 10))
                    .foregroundColor(Theme.text2)
                    .kerning(1.6)
            }

            Spacer()

            Text(MockData.Running.temperature)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text2)
        }
        .padding(.top, 8)
    }

    // MARK: - Hero 实时配速
    private var heroSection: some View {
        VStack(spacing: 4) {
            Text("实时配速")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(3.2)
                .padding(.bottom, 4)

            // 巨大配速数字 — 三层 shadow 模拟 HTML glow-breathe
            // (HTML: 22px 0.55, 44px 0.30, 88px 0.12 → 50% 强化)
            // SwiftUI radius 约 CSS 模糊半径的一半
            Text(MockData.Running.pace)
                .font(.system(size: 76, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.accent)
                .kerning(-3.0)  // -0.04em × 76
                .shadow(
                    color: Theme.accent.opacity(glowPhase ? 0.72 : 0.55),
                    radius: glowPhase ? 15 : 11
                )
                .shadow(
                    color: Theme.accent.opacity(glowPhase ? 0.42 : 0.30),
                    radius: glowPhase ? 30 : 22
                )
                .shadow(
                    color: Theme.accent.opacity(glowPhase ? 0.20 : 0.12),
                    radius: glowPhase ? 55 : 44
                )

            Text("MIN / KM")
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(Theme.accent.opacity(0.75))
                .kerning(3.8)  // 0.4em × 9.5
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
                .font(PaceFont.mono(size: 8, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(2.4)

            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(height: 0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
        .padding(.vertical, 18)
    }

    // MARK: - 距离 │ 时长
    private var distanceTimeRow: some View {
        HStack(alignment: .bottom, spacing: 28) {
            // 距离
            VStack(spacing: 6) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%.2f", MockData.Running.distanceKm))
                        .font(PaceFont.mono(size: 26, weight: .semibold))
                        .foregroundColor(Theme.text1)
                        .kerning(-0.5)
                    Text("km")
                        .font(PaceFont.mono(size: 11, weight: .regular))
                        .foregroundColor(Theme.text3)
                }
                Text("距离")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.2)
            }

            // 中间分隔线
            Rectangle()
                .fill(Theme.hairlineBright)
                .frame(width: 0.5, height: 32)
                .padding(.bottom, 14)

            // 时长
            VStack(spacing: 6) {
                Text(MockData.Running.durationStr)
                    .font(PaceFont.mono(size: 26, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.5)
                Text("时长")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.2)
            }
        }
    }

    // MARK: - 心率区间 (header + 5 段 bar + 标签)
    private var hrZoneSection: some View {
        VStack(spacing: 6) {
            // header
            HStack {
                Text("心率区间")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.2)
                Spacer()
                Text(MockData.Running.hrZoneLabel)
                    .font(PaceFont.mono(size: 9.5, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .kerning(1.4)
            }

            // 5 段 zone bar + marker
            HRZoneBar(markerPosition: MockData.Running.hrZonePercent)
                .frame(height: 7)

            // Z1-Z5 标签
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
        .padding(.bottom, 14)
    }

    // MARK: - 心率卡
    private var hrCard: some View {
        HStack {
            HStack(spacing: 10) {
                // 心形图标 — 红
                HeartShape()
                    .fill(Theme.heart)
                    .frame(width: 14, height: 13)

                Text("心率")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(1.4)
            }

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("\(MockData.Running.heartRate)")
                    .font(PaceFont.mono(size: 22, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.4)
                Text("BPM")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 长按提示
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
}

// MARK: - 5 段心率 zone bar (z1..z5 颜色对照 HTML CSS)
private struct HRZoneBar: View {
    /// 0..1 marker 在 bar 上的 x 比例
    let markerPosition: Double

    // 5 段心率区间色 — 直接用 Theme 预设的 zone1..zone5
    // 对照 HTML CSS .z1-.z5 (index.html#L617-L621)
    private let zoneColors: [Color] = [
        Theme.zone1, Theme.zone2, Theme.zone3, Theme.zone4, Theme.zone5,
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 5 段背景
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(zoneColors[i])
                            .frame(maxWidth: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 3.5))

                // marker 圆点 (HTML 14×14 + 2px 黑边 + accent 阴影)
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Theme.bgApp, lineWidth: 2)
                    )
                    .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                    .position(
                        x: CGFloat(markerPosition) * geo.size.width,
                        y: geo.size.height / 2
                    )
            }
        }
    }
}

// MARK: - 心形 (HTML SVG path 翻译成 SwiftUI Path)
private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // HTML: M7 12 C2 9 0.5 6 0.5 3.5 C0.5 1.5 2 0.5 3.5 0.5 ...
        // viewBox 14×13, 缩放到 rect
        let s = { (x: Double, y: Double) -> CGPoint in
            CGPoint(x: rect.minX + CGFloat(x / 14) * w, y: rect.minY + CGFloat(y / 13) * h)
        }

        p.move(to: s(7, 12))
        p.addCurve(to: s(0.5, 3.5),
                   control1: s(2, 9), control2: s(0.5, 6))
        p.addCurve(to: s(3.5, 0.5),
                   control1: s(0.5, 1.5), control2: s(2, 0.5))
        p.addCurve(to: s(7, 3),
                   control1: s(5, 0.5), control2: s(6.5, 1.5))
        p.addCurve(to: s(10.5, 0.5),
                   control1: s(7.5, 1.5), control2: s(9, 0.5))
        p.addCurve(to: s(13.5, 3.5),
                   control1: s(12, 0.5), control2: s(13.5, 1.5))
        p.addCurve(to: s(7, 12),
                   control1: s(13.5, 6), control2: s(12, 9))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
struct RunningView_Previews: PreviewProvider {
    static var previews: some View {
        RunningView()
            .preferredColorScheme(.dark)
    }
}
#endif
