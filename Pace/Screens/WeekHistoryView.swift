//
//  WeekHistoryView.swift
//  Pace.
//
//  Phone 06 · 周历史 (Week History)
//
//  对照 pace-demo/index.html#L2924-L3064
//
//  v0.4.2: 静态视觉版.
//  布局: §4.4 准则 — 连贯数据流, 紧凑堆叠 + 单一底部 Spacer (不用三段呼吸).
//

import SwiftUI

struct WeekHistoryView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            // v0.4.2.2: 套 ScrollView — dotmap 自然全宽展开后高度 ~600pt,
            // 加上 hero/recovery/bars/stats 总高 ~900-1000pt, 12 Pro 屏装不下,
            // 必须可滚.
            ScrollView(showsIndicators: false) {
                // ViewBuilder §1.1: 用 Group 把上半部 9 个子合并, VStack 总 4 子
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        brandStrip
                        Spacer().frame(height: 22)
                        weekHeroSection
                        Spacer().frame(height: 20)
                        weekRecoveryStrip
                        Spacer().frame(height: 20)
                        dotmapSection
                        Spacer().frame(height: 20)
                        weekBarsChart
                    }
                    Spacer().frame(height: 14)
                    bottomStatsRow
                    Spacer().frame(height: 20)   // 底部留点呼吸不贴 home indicator
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - 顶部条 (← 返回 + 历史 + 周/月/年 + ✦ chip)
    private var brandStrip: some View {
        HStack(spacing: 10) {
            // 返回按钮 (v0.4.2.1 加)
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("←")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.text2)
                    .frame(width: 30, height: 30)
                    .background(Theme.bgElev)
                    .overlay(
                        Circle()
                            .stroke(Theme.hairlineBright, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())

            Text("历史")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text2)
                .kerning(2.8)

            Spacer()

            // 周/月/年 分段控件 (active = 周)
            HStack(spacing: 0) {
                segmentTab("周", active: true)
                segmentTab("月", active: false)
                segmentTab("年", active: false)
            }
            .padding(2)
            .background(Theme.bgElev)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // ✦ coach chip (圆形)
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.10))
                    .frame(width: 28, height: 28)
                Circle()
                    .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                    .frame(width: 28, height: 28)
                Text("✦")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func segmentTab(_ label: String, active: Bool) -> some View {
        Text(label)
            .font(PaceFont.cn(size: 11, weight: active ? .semibold : .regular))
            .foregroundColor(active ? Theme.accent : Theme.text3)
            .kerning(1.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(active ? Theme.bgCanvas : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: active ? Theme.accent.opacity(0.20) : .clear, radius: 6)
    }

    // MARK: - 本周 hero (38.4 公里 + ↑12% + 副信息行)
    private var weekHeroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("本周")
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.8)

            HStack(alignment: .bottom, spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(String(format: "%.1f", MockData.WeekHistory.weekDistanceKm))
                        .font(.system(size: 78, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text1)
                        .kerning(-3.8)
                    Text("公里")
                        .font(PaceFont.cn(size: 18, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.4)
                }
                Spacer()

                // ↑12% chip
                HStack(spacing: 2) {
                    Text("↑")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text("12%")
                        .font(PaceFont.mono(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Theme.accent.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .padding(.bottom, 4)
            }

            // 副信息行
            HStack {
                Text("\(MockData.WeekHistory.weekRuns) 次跑步")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.8)
                Spacer()
                Text(MockData.WeekHistory.weekTimeStr)
                    .font(PaceFont.mono(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                Spacer()
                HStack(spacing: 0) {
                    Text(MockData.WeekHistory.weekAvgPace)
                        .font(PaceFont.mono(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text3)
                    Text("/km")
                        .font(PaceFont.mono(size: 11, weight: .regular))
                        .foregroundColor(Theme.text4)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 本周恢复 strip (7 天 day-seg + 平均分)
    private var weekRecoveryStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("本周恢复")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                HStack(spacing: 4) {
                    Text("平均")
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.6)
                    Text("\(MockData.WeekHistory.recoveryAvg)")
                        .font(PaceFont.mono(size: 12, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text("/100")
                        .font(PaceFont.mono(size: 11, weight: .regular))
                        .foregroundColor(Theme.text4)
                }
            }

            HStack(spacing: 4) {
                ForEach(0..<MockData.WeekHistory.recoveryDays.count, id: \.self) { i in
                    DaySegment(day: MockData.WeekHistory.recoveryDays[i])
                }
            }
            .frame(height: 50)
        }
    }

    // MARK: - 活动 84 天 dotmap
    private var dotmapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("活动 · 84 天")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                HStack(spacing: 4) {
                    Text("少")
                        .font(PaceFont.cn(size: 10, weight: .regular))
                        .foregroundColor(Theme.text3)
                        .kerning(1.4)
                    ForEach(0..<4) { i in
                        let alpha: Double = [0.15, 0.40, 0.70, 1.0][i]
                        Circle()
                            .fill(Theme.accent.opacity(alpha))
                            .frame(width: 7, height: 7)
                    }
                    Text("多")
                        .font(PaceFont.cn(size: 10, weight: .regular))
                        .foregroundColor(Theme.text3)
                        .kerning(1.4)
                }
            }

            // 12 行 × 7 列 grid
            DotMapGrid(intensities: MockData.WeekHistory.dotmapDays)
        }
    }

    // MARK: - 每周公里 4 周柱图
    private var weekBarsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text("每周公里")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text("最近 4 周")
                    .font(PaceFont.cn(size: 11, weight: .regular))
                    .foregroundColor(Theme.text4)
                    .kerning(1.8)
            }

            WeekBarsView(bars: MockData.WeekHistory.weekBars)
                .frame(height: 72)
        }
    }

    // MARK: - 底部 2 列 stats
    private var bottomStatsRow: some View {
        HStack(spacing: 8) {
            statCard(title: "平均配速",
                     valueLine: PaceMonoLine(
                        main: MockData.WeekHistory.weekAvgPace,
                        sub: "/km"
                     ))
            statCard(title: "连续跑步",
                     valueLine: PaceMonoLine(
                        main: "\(MockData.WeekHistory.streakDays)",
                        sub: " 天",
                        subIsCn: true
                     ))
        }
    }

    @ViewBuilder
    private func statCard(title: String, valueLine: PaceMonoLine) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(valueLine.main)
                    .font(PaceFont.mono(size: 20, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.4)
                if valueLine.subIsCn {
                    Text(valueLine.sub)
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.2)
                        .padding(.leading, 4)
                } else {
                    Text(valueLine.sub)
                        .font(PaceFont.mono(size: 11, weight: .regular))
                        .foregroundColor(Theme.text4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 用于 stat 卡的主值 + 副值组合
private struct PaceMonoLine {
    let main: String
    let sub: String
    var subIsCn: Bool = false
}

// MARK: - 单个 day 卡 (recovery strip)
private struct DaySegment: View {
    let day: (label: String, value: Int, state: MockData.WeekHistory.RecoveryState, today: Bool)

    private var bgColor: Color {
        switch day.state {
        case .good: return Theme.accent.opacity(0.18)
        case .ok:   return Theme.gold.opacity(0.18)
        case .bad:  return Theme.warn.opacity(0.18)
        }
    }
    private var borderColor: Color {
        switch day.state {
        case .good: return Theme.accent.opacity(0.45)
        case .ok:   return Theme.gold.opacity(0.45)
        case .bad:  return Theme.warn.opacity(0.45)
        }
    }
    private var labelColor: Color {
        switch day.state {
        case .good: return Theme.accent.opacity(0.85)
        case .ok:   return Theme.gold.opacity(0.9)
        case .bad:  return Theme.warn.opacity(0.9)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(day.label)
                .font(PaceFont.cn(size: 9, weight: .medium))
                .foregroundColor(labelColor)
                .kerning(0.5)
            Text("\(day.value)")
                .font(PaceFont.mono(size: 12, weight: .bold))
                .foregroundColor(Theme.text1)
                .kerning(-0.3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(bgColor)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(
                    day.today ? Theme.accent : borderColor,
                    lineWidth: day.today ? 1.2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: day.today ? Theme.accent.opacity(0.42) : .clear, radius: 8)
    }
}

// MARK: - DotMap (12 行 × 7 列)
//
// v0.4.2.2: 删除 .aspectRatio(7/12, .fit) — 之前那个把 grid 压成窄高条
// (用户截图发现右半空白). 改用 GeometryReader 算 cellW = (totalW - gaps)/7,
// 行高 = cellW (圆), 容器高度 = 12*cellW + 11*gap. 全宽铺满, 自然撑高.
//
private struct DotMapGrid: View {
    let intensities: [Double]

    private let rows: Int = 12
    private let cols: Int = 7
    private let gap: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let totalW: CGFloat = geo.size.width
            let cellW: CGFloat = (totalW - CGFloat(cols - 1) * gap) / CGFloat(cols)

            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { c in
                            let idx: Int = r * cols + c
                            let alpha: Double = idx < intensities.count ? intensities[idx] : 0
                            let isLast: Bool = (idx == intensities.count - 1)
                            DotMapCell(alpha: alpha, isLast: isLast)
                                .frame(width: cellW, height: cellW)
                        }
                    }
                }
            }
        }
        // 容器高度 = 12 行 × cellW (≈ 47pt) + 11 个 gap = ~561pt
        // 用 .frame(height:) 显式撑开, 让 GeometryReader 拿到正确高度
        // SwiftUI 推断不出来时, 12 Pro 390 屏宽 - 32 padding = 358
        // cellW = (358 - 24) / 7 ≈ 47.7, 总高 ≈ 47.7*12 + 11*4 ≈ 616pt
        .frame(height: 616)
    }
}

private struct DotMapCell: View {
    let alpha: Double
    let isLast: Bool

    var body: some View {
        ZStack {
            if alpha < 0.01 {
                // 空格 — 极淡白
                Circle().fill(Color.white.opacity(0.04))
            } else {
                Circle()
                    .fill(Theme.accent.opacity(alpha))
                    .shadow(
                        color: alpha > 0.7 ? Theme.accent.opacity(0.5) : .clear,
                        radius: alpha > 0.7 ? 3 : 0
                    )
            }
            if isLast {
                Circle()
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 4)
            }
        }
    }
}

// MARK: - 4 周 bar chart
//
// HTML 4 个 rect, 高 22/30/34/42, baseline y=50, label y=14 (上方)
// 用 SwiftUI 4 列 HStack, 每列上面数字 + 下面 bar + 顶 highlight
//
private struct WeekBarsView: View {
    let bars: [(label: String, km: Double, current: Bool)]

    var body: some View {
        GeometryReader { geo in
            // 显式 CGFloat
            let height: CGFloat = geo.size.height
            let maxKm: Double = bars.map { $0.km }.max() ?? 1
            let barAreaH: CGFloat = height - 14   // 顶部留 14pt 给数字 label

            ZStack(alignment: .bottom) {
                // baseline (HTML y=50 处的细线)
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)
                }

                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<bars.count, id: \.self) { i in
                        let b = bars[i]
                        let ratio: CGFloat = CGFloat(b.km / maxKm)
                        let barH: CGFloat = barAreaH * ratio
                        VStack(spacing: 0) {
                            Text(String(format: "%.1f", b.km))
                                .font(PaceFont.mono(size: 11, weight: b.current ? .bold : .medium))
                                .foregroundColor(b.current ? Theme.accent : Theme.text3)
                                .padding(.bottom, 2)

                            // bar 主体
                            ZStack(alignment: .top) {
                                // bar body
                                Rectangle()
                                    .fill(Theme.accent.opacity(b.current ? 0.36 : 0.22))
                                    .frame(height: barH)
                                    .cornerRadius(2)
                                    .shadow(color: b.current ? Theme.accent.opacity(0.3) : .clear, radius: 4)
                                // top highlight 2pt
                                Rectangle()
                                    .fill(b.current ? Theme.accent : Theme.accent.opacity(0.7))
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                            .frame(width: 42)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct WeekHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        WeekHistoryView()
            .preferredColorScheme(.dark)
    }
}
#endif
