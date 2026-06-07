//
//  RunningView.swift
//  Pace.
//
//  Phone 03 · 跑步进行中。
//
//  v0.3.0 静态 mock 视觉
//  v0.3.1 字号上调 + 内嵌 Phone 12 暂停态
//  v0.5.0 engine-driven — 移除内嵌 paused, 改由 RunFlowView 切到 PausedView.
//         所有数据 (pace / distance / elapsed / HR) 从 engine 读.
//         长按 0.6s → engine.pause() → RunFlowView 自动切 PausedView.
//
//  字号对齐 HTML × 1.10 系数 (docs/HTML-to-SwiftUI-Guide.md §3)
//

import SwiftUI

struct RunningView: View {
    @EnvironmentObject var engine: RunSessionEngine

    @State private var glowPhase = false
    @State private var pulsePhase = false

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                brandStrip
                Spacer()
                heroSection
                splitDivider
                distanceTimeRow
                telemetryPanel
                Spacer()
                hrZoneSection
                hrCard
                hintRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        // 长按 0.6s → engine.pause() → RunFlowView 切到 PausedView
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    engine.pause()
                }
        )
        .onAppear { startBackgroundAnimations() }
    }

    // MARK: - 后台动画启动
    private func startBackgroundAnimations() {
        withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
            glowPhase = true
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulsePhase = true
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
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 6, height: 6)
                    .opacity(pulsePhase ? 0.35 : 0.85)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 3)

                Text(gpsLabel)
                    .font(PaceFont.cn(size: 10, weight: .regular))
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

    /// engine.gpsFixCount → "GPS 锁定 5/6" / "GPS 弱信号"
    private var gpsLabel: String {
        let n = engine.gpsFixCount
        return n >= 4 ? "GPS · \(min(6, n))/6" : "GPS 弱信号"
    }

    // MARK: - Hero 实时配速 (从 engine 读)
    private var heroSection: some View {
        VStack(spacing: 6) {
            Text("实时配速")
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.8)
                .padding(.bottom, 6)

            Text(engine.paceDisplay)
                .font(.system(size: 96, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.accent)
                .kerning(-3.8)
                .shadow(color: Theme.accent.opacity(glowPhase ? 0.72 : 0.55),
                        radius: glowPhase ? 18 : 14)
                .shadow(color: Theme.accent.opacity(glowPhase ? 0.42 : 0.30),
                        radius: glowPhase ? 36 : 28)
                .shadow(color: Theme.accent.opacity(glowPhase ? 0.22 : 0.14),
                        radius: glowPhase ? 64 : 52)

            Text("MIN / KM")
                .font(PaceFont.mono(size: 11, weight: .semibold))
                .foregroundColor(Theme.accent.opacity(0.85))
                .kerning(4.4)
                .padding(.top, 4)
        }
    }

    // MARK: - SPLIT 分隔 (公里数取整 +1 = 当前分段)
    private var splitDivider: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Theme.hairlineBright).frame(height: 0.5)

            Text("SPLIT \(String(format: "%02d", Int(engine.distanceKm) + 1))")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(2.7)

            Rectangle().fill(Theme.hairlineBright).frame(height: 0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
    }

    // MARK: - 距离 │ 时长 (实时)
    private var distanceTimeRow: some View {
        HStack(alignment: .bottom, spacing: 32) {
            VStack(spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(engine.distanceDisplay)
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
                Text(engine.elapsedDisplay)
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

    // MARK: - 实时 GPS / 速度诊断
    private var telemetryPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                telemetryItem(value: engine.speedDisplay, unit: "km/h", label: "速度")
                telemetryItem(value: engine.accuracyDisplay, unit: "", label: "精度")
                telemetryItem(value: "\(engine.routePointCount)", unit: "点", label: "轨迹")
            }

            HStack(spacing: 8) {
                Text("位置")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.0)
                Text(engine.coordinateDisplay)
                    .font(PaceFont.mono(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.bgCard.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.top, 16)
        .padding(.horizontal, 4)
    }

    private func telemetryItem(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(PaceFont.mono(size: 16, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                if !unit.isEmpty {
                    Text(unit)
                        .font(PaceFont.cn(size: 9, weight: .medium))
                        .foregroundColor(Theme.text3)
                }
            }
            Text(label)
                .font(PaceFont.cn(size: 9, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(1.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(Theme.bgCard.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 心率区间 (zone bar)
    private var hrZoneSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("心率区间")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.2)
                Spacer()
                Text(hrZoneLabel)
                    .font(PaceFont.mono(size: 9.5, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .kerning(1.4)
            }

            HRZoneBar(
                markerPosition: hrZonePercent,
                markerColor: Theme.accent
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
        .padding(.bottom, 14)
    }

    /// 简化 HR → zone 映射 (静息 60 → Z1, 最大 190 → Z5, 线性)
    private var hrZonePercent: Double {
        guard let hr = engine.currentHR else { return 0.0 }
        let pct = Double(max(60, min(190, hr)) - 60) / Double(190 - 60)
        return max(0.02, min(0.98, pct))
    }

    private var hrZoneLabel: String {
        guard let hr = engine.currentHR else { return "— · 等待心率" }
        let z = min(5, max(1, Int(hrZonePercent * 5) + 1))
        return "Z\(z) · 当前"
    }

    // MARK: - 心率卡
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
                Text(engine.currentHR.map { "\($0)" } ?? "--")
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
    }

    // MARK: - 底部长按提示
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
                    .overlay(Circle().stroke(Theme.bgApp, lineWidth: 2))
                    .shadow(color: markerColor.opacity(0.6), radius: 4)
                    .position(
                        x: CGFloat(markerPosition) * geo.size.width,
                        y: geo.size.height / 2
                    )
            }
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
        RunningView()
            .environmentObject(RunSessionEngine())
            .preferredColorScheme(.dark)
            .previewDisplayName("Running")
    }
}
#endif
