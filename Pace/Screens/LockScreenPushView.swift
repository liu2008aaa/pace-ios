//
//  LockScreenPushView.swift
//  Pace.
//
//  Phone 15 · 锁屏推送 (Lock Screen Push Preview)
//
//  对照 pace-demo/index.html#L4467-L4583
//
//  iOS 真实锁屏 push 用 Live Activity (iOS 16+) / 通知 (iOS 14+).
//  这屏是设计预览, 模拟"用户解锁前看到的状态卡"长什么样.
//

import SwiftUI

struct LockScreenPushView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // 锁屏深色壁纸 (双层 radial + 微噪点)
            lockBackground

            VStack(spacing: 0) {
                // 顶部 hint 关闭按钮
                HStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("✕")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 14)
                }
                .padding(.top, 10)

                // 锁图标
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 14)

                // 巨大时间
                Text(MockData.LockScreen.time)
                    .font(.system(size: 84, weight: .ultraLight))
                    .foregroundColor(.white)
                    .kerning(-3.5)
                    .padding(.top, 6)

                Text(MockData.LockScreen.date)
                    .font(PaceFont.cn(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.78))
                    .kerning(2.4)
                    .padding(.top, 2)

                Spacer()

                // 通知卡
                notificationCard
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)

                // 锁屏底部双 bubble (手电筒 / 相机) — 静态装饰
                HStack {
                    bubbleControl(symbol: "flashlight.off.fill")
                    Spacer()
                    bubbleControl(symbol: "camera.fill")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 18)
            }
        }
    }

    // MARK: - 锁屏背景 (深色 radial + dot 噪点)
    private var lockBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: 0x0A1714),
                    Color(hex: 0x050A08),
                    .black,
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            // accent 余光 radial
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.06),
                    .clear,
                ]),
                center: UnitPoint(x: 0.7, y: 0.2),
                startRadius: 0,
                endRadius: 220
            )
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: 0x00503C).opacity(0.18),
                    .clear,
                ]),
                center: UnitPoint(x: 0.3, y: 0.8),
                startRadius: 0,
                endRadius: 260
            )
            // 噪点层 (24pt 间距)
            NoiseDots()
                .opacity(0.6)
        }
        .ignoresSafeArea()
    }

    // MARK: - Pace 通知卡 (毛玻璃 + 状态摘要)
    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // header: icon + Pace. + 时间戳
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: 0x003B2C),
                                    Color(hex: 0x06281E),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.accent.opacity(0.5), lineWidth: 0.5)
                        .frame(width: 24, height: 24)
                    Text("✦")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.accent)
                }

                (Text("Pace")
                    .font(PaceFont.cn(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                + Text(".")
                    .font(PaceFont.cn(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accent))

                Spacer()

                Text(MockData.LockScreen.notifTimestamp)
                    .font(PaceFont.mono(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.50))
                    .kerning(0.8)
            }

            // 标题
            Text(MockData.LockScreen.notifTitle)
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .kerning(0.4)

            // 3 指标
            HStack(spacing: 8) {
                metricChip(label: "状态", value: "\(MockData.LockScreen.metricReadiness)", deltaSuffix: " " + MockData.LockScreen.metricReadinessDelta, isAccent: true)
                Text("·").foregroundColor(.white.opacity(0.18))
                metricChip(label: "负荷", value: String(format: "%.1f", MockData.LockScreen.metricStrain), deltaSuffix: "", isAccent: false, isGold: true)
                Text("·").foregroundColor(.white.opacity(0.18))
                metricChip(label: "睡眠", value: "\(MockData.LockScreen.metricSleep)%", deltaSuffix: "", isAccent: true)
                Spacer()
            }
            .font(PaceFont.mono(size: 11, weight: .medium))

            // sparkline
            LockSparkline(pointsY: MockData.LockScreen.sparklineY)
                .frame(height: 24)

            // AI line
            HStack(alignment: .top, spacing: 6) {
                Text("✦")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accent)
                Text(MockData.LockScreen.aiLine)
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .kerning(0.3)
                    .lineSpacing(3)
            }
            .padding(.top, 6)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        // ⚠️ iOS 14 没 .ultraThinMaterial (iOS 15+ API),
        // 用半透明深灰 + 顶部高光叠加近似毛玻璃效果
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0x3C3C41).opacity(0.70))
                // 顶部 1pt 高光带
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.12),
                                    .clear,
                                ]),
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 8)
                    Spacer()
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func metricChip(label: String, value: String, deltaSuffix: String, isAccent: Bool = false, isGold: Bool = false) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(PaceFont.cn(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
                .kerning(1.4)
            HStack(spacing: 0) {
                Text(value)
                    .font(PaceFont.mono(size: 11, weight: .bold))
                    .foregroundColor(isGold ? Theme.gold : (isAccent ? Theme.accent : .white))
                if !deltaSuffix.isEmpty {
                    Text(deltaSuffix)
                        .font(PaceFont.mono(size: 9, weight: .bold))
                        .foregroundColor(isAccent ? Theme.accent : .white.opacity(0.85))
                }
            }
        }
    }

    // MARK: - 锁屏底部 bubble (静态)
    @ViewBuilder
    private func bubbleControl(symbol: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0x32323A).opacity(0.55))
                .frame(width: 44, height: 44)
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                .frame(width: 44, height: 44)
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

// MARK: - 噪点 dot 背景
private struct NoiseDots: View {
    var body: some View {
        GeometryReader { geo in
            let cols: Int = Int(geo.size.width / 24) + 1
            let rows: Int = Int(geo.size.height / 24) + 1
            ZStack {
                ForEach(0..<rows, id: \.self) { r in
                    ForEach(0..<cols, id: \.self) { c in
                        Circle()
                            .fill(Color.white.opacity(0.014))
                            .frame(width: 1, height: 1)
                            .position(
                                x: CGFloat(c) * 24 + 12,
                                y: CGFloat(r) * 24 + 12
                            )
                    }
                }
            }
        }
    }
}

// MARK: - 通知卡内迷你 sparkline
private struct LockSparkline: View {
    let pointsY: [Double]

    private let pointsX: [Double] = [6, 40, 75, 110, 145, 180, 246]

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 252
            let scaleY: CGFloat = geo.size.height / 22
            let lastIdx: Int = pointsY.count - 1
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 12 * scaleY))
                    p.addLine(to: CGPoint(x: geo.size.width, y: 12 * scaleY))
                }
                .stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))

                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                }
                .stroke(Theme.accent.opacity(0.85), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Theme.accent)
                    .frame(width: 4, height: 4)
                    .position(x: CGFloat(pointsX[lastIdx]) * scaleX, y: CGFloat(pointsY[lastIdx]) * scaleY)
            }
        }
    }
}

#if DEBUG
struct LockScreenPushView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenPushView()
            .preferredColorScheme(.dark)
    }
}
#endif
