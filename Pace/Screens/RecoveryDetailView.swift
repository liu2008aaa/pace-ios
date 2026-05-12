//
//  RecoveryDetailView.swift
//  Pace.
//
//  Phone 11 · 状态详情 (Recovery Detail)
//
//  对照 pace-demo/index.html#L3356-L3511
//
//  入口: IdleHome triad 的 "状态" DialCard 点击 → 这屏 (drilldown)
//

import SwiftUI

struct RecoveryDetailView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        brandStrip
                        Spacer().frame(height: 18)
                        heroSection
                        Spacer().frame(height: 18)
                        weekTrendCard
                        Spacer().frame(height: 18)
                        breakdownSection
                        Spacer().frame(height: 16)
                        aiExplanation
                        Spacer().frame(height: 18)
                        recoSection
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - 顶部条
    private var brandStrip: some View {
        HStack(spacing: 10) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("←")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.text2)
                    .frame(width: 30, height: 30)
                    .background(Theme.bgElev)
                    .overlay(Circle().stroke(Theme.hairlineBright, lineWidth: 1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            Text("状态详情")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(2.4)
            Spacer()
            Text(MockData.RecoveryDetail.dateStr)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
        }
        .padding(.top, 10)
    }

    // MARK: - Hero (80pt 大数字 + status chip + ↑6 vs 昨)
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("恢复指数 · RECOVERY")
                    .font(PaceFont.mono(size: 10, weight: .semibold))
                    .foregroundColor(Theme.text3)
                    .kerning(3.4)
                Spacer()
                Text(MockData.RecoveryDetail.recoveryStatus)
                    .font(PaceFont.cn(size: 10, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(1.6)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(MockData.RecoveryDetail.recoveryScore)")
                    .font(.system(size: 92, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text1)
                    .kerning(-3.6)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 22)
                Text("/100")
                    .font(PaceFont.mono(size: 16, weight: .medium))
                    .foregroundColor(Theme.text3)

                Spacer()

                HStack(spacing: 3) {
                    Text("↑")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text("6")
                        .font(PaceFont.mono(size: 11, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text("vs 昨")
                        .font(PaceFont.cn(size: 10, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(0.6)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Theme.accent.opacity(0.32), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    // MARK: - 7 天趋势卡
    private var weekTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("7 天趋势")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text(MockData.RecoveryDetail.weekTrendStr)
                    .font(PaceFont.mono(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }

            RecoveryWeekChart(
                pointsY: MockData.RecoveryDetail.weekPointsY,
                isAccentDot: MockData.RecoveryDetail.weekDotIsAccent
            )
            .frame(height: 52)

            HStack {
                ForEach(0..<MockData.RecoveryDetail.weekLabels.count, id: \.self) { i in
                    let isLast = (i == MockData.RecoveryDetail.weekLabels.count - 1)
                    Text(MockData.RecoveryDetail.weekLabels[i])
                        .font(PaceFont.cn(size: 9.5, weight: isLast ? .bold : .regular))
                        .foregroundColor(isLast ? Theme.accent : Theme.text4)
                        .kerning(0.4)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 成因分解
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("成因分解 · BREAKDOWN")
                .font(PaceFont.mono(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(3.4)

            VStack(spacing: 0) {
                ForEach(0..<MockData.RecoveryDetail.contribs.count, id: \.self) { i in
                    let c = MockData.RecoveryDetail.contribs[i]
                    contribRow(c)
                    if i < MockData.RecoveryDetail.contribs.count - 1 {
                        Rectangle().fill(Theme.hairline)
                            .frame(height: 0.5)
                            .padding(.horizontal, 14)
                    }
                }
                // 分隔
                Rectangle().fill(Theme.hairline)
                    .frame(height: 0.5)
                    .padding(.horizontal, 14)
                // 基线 + 今日
                HStack {
                    Text("基线")
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(0.6)
                    Spacer()
                    Text("\(MockData.RecoveryDetail.baseline)")
                        .font(PaceFont.mono(size: 13, weight: .medium))
                        .foregroundColor(Theme.text2)
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
                HStack {
                    HStack(spacing: 4) {
                        Text("✦")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.accent)
                        Text("今日")
                            .font(PaceFont.cn(size: 11, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .kerning(0.6)
                    }
                    Spacer()
                    Text("\(MockData.RecoveryDetail.recoveryScore)")
                        .font(PaceFont.mono(size: 15, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 14).padding(.vertical, 6)
            }
            .background(Theme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func contribRow(_ c: MockData.RecoveryDetail.Contrib) -> some View {
        HStack(spacing: 10) {
            // name + detail
            VStack(alignment: .leading, spacing: 1) {
                Text(c.name)
                    .font(PaceFont.cn(size: 11, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(0.4)
                Text(c.detail)
                    .font(PaceFont.cn(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(0.4)
            }
            .frame(width: 78, alignment: .leading)

            // bar
            GeometryReader { geo in
                let totalW: CGFloat = geo.size.width
                let fillW: CGFloat = totalW * CGFloat(c.ratio)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                    Capsule()
                        .fill(c.value > 0 ? Theme.accent : Theme.warn)
                        .frame(width: fillW)
                }
            }
            .frame(height: 4)

            // value
            Text(c.value > 0 ? "+\(c.value)" : "\(c.value)")
                .font(PaceFont.mono(size: 11, weight: .bold))
                .foregroundColor(c.value > 0 ? Theme.accent : Theme.warn)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
    }

    // MARK: - AI 解释
    private var aiExplanation: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("✦")
                .font(.system(size: 13))
                .foregroundColor(Theme.accent)
            (Text(MockData.RecoveryDetail.aiBefore).foregroundColor(Theme.text1)
            + Text(MockData.RecoveryDetail.aiMid1).foregroundColor(Theme.accent).fontWeight(.semibold)
            + Text(MockData.RecoveryDetail.aiBetween).foregroundColor(Theme.text1)
            + Text(MockData.RecoveryDetail.aiMid2).foregroundColor(Theme.accent).fontWeight(.semibold)
            + Text(MockData.RecoveryDetail.aiAfter).foregroundColor(Theme.text1))
                .font(PaceFont.cn(size: 12, weight: .medium))
                .lineSpacing(4)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.08),
                    Theme.accent.opacity(0.02),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accent.opacity(0.32), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 推荐 chips
    private var recoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("今日建议")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text("\(MockData.RecoveryDetail.recoOptions.count) OPTIONS")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(2.2)
            }

            HStack(spacing: 8) {
                ForEach(0..<MockData.RecoveryDetail.recoOptions.count, id: \.self) { i in
                    let item = MockData.RecoveryDetail.recoOptions[i]
                    recoChip(label: item.0, primary: item.1)
                }
            }
        }
    }

    @ViewBuilder
    private func recoChip(label: String, primary: Bool) -> some View {
        Text(label)
            .font(PaceFont.cn(size: 12, weight: primary ? .bold : .medium))
            .foregroundColor(primary ? Color(hex: 0x001A14) : Theme.text2)
            .kerning(0.6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(primary ? Theme.accent : Theme.bgElev)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(primary ? Color.clear : Theme.hairlineBright, lineWidth: 1)
            )
            .shadow(color: primary ? Theme.accent.opacity(0.35) : .clear, radius: 12)
            .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

// MARK: - 7 天恢复折线
private struct RecoveryWeekChart: View {
    let pointsY: [Double]
    let isAccentDot: [Bool]

    @State private var endPulse = false
    private let pointsX: [Double] = [12, 50, 88, 126, 164, 202, 240]

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 252
            let scaleY: CGFloat = geo.size.height / 40
            let lastIdx: Int = pointsY.count - 1

            ZStack {
                // baseline
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 22 * scaleY))
                    p.addLine(to: CGPoint(x: geo.size.width, y: 22 * scaleY))
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))

                // area
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[lastIdx]) * scaleX, y: 36 * scaleY))
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: 36 * scaleY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.30), Theme.accent.opacity(0.0),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // line
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

                // dots (6 个普通 + 1 末点)
                ForEach(0..<lastIdx, id: \.self) { i in
                    Circle()
                        .fill(isAccentDot[i] ? Theme.accent : Theme.gold)
                        .frame(width: 3.6, height: 3.6)
                        .position(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY)
                }
                // 末点
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(endPulse ? 0.5 : 0.25), lineWidth: 0.8)
                        .frame(width: endPulse ? 14 : 11, height: endPulse ? 14 : 11)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                }
                .position(x: CGFloat(pointsX[lastIdx]) * scaleX, y: CGFloat(pointsY[lastIdx]) * scaleY)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                endPulse = true
            }
        }
    }
}

#if DEBUG
struct RecoveryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryDetailView()
            .preferredColorScheme(.dark)
    }
}
#endif
