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
    @EnvironmentObject var store: RunSessionStore

    /// v0.4.3: 加 segment 切换支持 week / month / year (Phone 06 + 07 + placeholder)
    enum Segment { case week, month, year }
    @State private var segment: Segment = .week

    private var hasRealRuns: Bool { !store.records.isEmpty }
    private var weekDistanceKm: Double {
        hasRealRuns ? store.thisWeekDistanceKm : MockData.WeekHistory.weekDistanceKm
    }
    private var weekRuns: Int {
        hasRealRuns ? store.thisWeekRuns : MockData.WeekHistory.weekRuns
    }
    private var weekAvgPace: String {
        hasRealRuns ? store.thisWeekAveragePaceDisplay : MockData.WeekHistory.weekAvgPace
    }
    private var weekDuration: String {
        hasRealRuns ? store.thisWeekDurationDisplay : MockData.WeekHistory.weekTimeStr
    }
    private var weekDelta: String {
        hasRealRuns ? store.thisWeekDeltaDisplay : "↑12%"
    }
    private var monthDelta: String {
        hasRealRuns ? store.thisMonthDeltaDisplay : MockData.MonthlyStats.trendStr
    }
    private var yearDelta: String {
        hasRealRuns ? store.thisYearDeltaDisplay : MockData.YearHistory.yearTrendStr
    }
    private var streakDays: Int {
        hasRealRuns ? store.currentStreakDays() : MockData.WeekHistory.streakDays
    }
    private var weekBars: [(label: String, km: Double, current: Bool)] {
        hasRealRuns ? store.lastFourWeekBars() : MockData.WeekHistory.weekBars
    }
    private var dotmapIntensities: [Double] {
        hasRealRuns ? store.recentDayIntensities(days: 84) : MockData.WeekHistory.dotmapDays
    }

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            // ScrollView 套全屏内容 — dotmap (week) / calendar+trend (month) 都
            // 可能比 12 Pro 屏高, 统一可滚
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    brandStrip
                    Spacer().frame(height: 22)
                    segmentContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch segment {
        case .week:  weekContent
        case .month: monthContent
        case .year:  yearContent  // v0.4.11: 从 placeholder → 真实现
        }
    }

    // MARK: - Week 内容 (原 Phone 06 layout)
    private var weekContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
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
            Spacer().frame(height: 20)
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

            // 周/月/年 分段控件 (v0.4.3: 可点击切换)
            HStack(spacing: 0) {
                segmentTab("周", value: .week)
                segmentTab("月", value: .month)
                segmentTab("年", value: .year)
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
    private func segmentTab(_ label: String, value: Segment) -> some View {
        let active: Bool = (segment == value)
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.easeOut(duration: 0.18)) {
                segment = value
            }
        }) {
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
        .buttonStyle(PlainButtonStyle())
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
                    Text(String(format: "%.1f", weekDistanceKm))
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
                    Text(weekDelta)
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
                Text("\(weekRuns) 次跑步")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.8)
                Spacer()
                Text(weekDuration)
                    .font(PaceFont.mono(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                Spacer()
                HStack(spacing: 0) {
                    Text(weekAvgPace)
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
            DotMapGrid(intensities: dotmapIntensities)
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

            WeekBarsView(bars: weekBars)
                .frame(height: 72)
        }
    }

    // MARK: - 底部 2 列 stats
    private var bottomStatsRow: some View {
        HStack(spacing: 8) {
            statCard(title: "平均配速",
                     valueLine: PaceMonoLine(
                        main: weekAvgPace,
                        sub: "/km"
                     ))
            statCard(title: "连续跑步",
                     valueLine: PaceMonoLine(
                        main: "\(streakDays)",
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

    /// v0.4.2.3: "亮点自呼吸" — alpha > 0.5 的 dot 各自缓慢呼吸,
    /// 随机相位错峰, 整体像群星各自闪烁 (对照 pace-demo dot-breathe 动画).
    @State private var breathPhase: Double = 0

    private var shouldBreathe: Bool { alpha > 0.5 }

    var body: some View {
        ZStack {
            if alpha < 0.01 {
                // 空格 — 极淡白
                Circle().fill(Color.white.opacity(0.04))
            } else {
                // breath 期间, scale + shadow 同步起伏
                let baseShadowOpacity: Double = alpha > 0.7 ? 0.5 : 0
                let baseShadowRadius: Double = alpha > 0.7 ? 3 : 0
                Circle()
                    .fill(Theme.accent.opacity(alpha))
                    .scaleEffect(1.0 + 0.12 * CGFloat(breathPhase))
                    .shadow(
                        color: Theme.accent.opacity(baseShadowOpacity + 0.45 * breathPhase),
                        radius: CGFloat(baseShadowRadius + 5 * breathPhase)
                    )
            }
            if isLast {
                Circle()
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .shadow(color: Theme.accent.opacity(0.6), radius: 4)
            }
        }
        .onAppear {
            // 随机相位 0-4s 延迟启动, 保证 cells 之间错峰
            // 不同步呼吸 = 整体活的, 而非 generic 同步动画
            guard shouldBreathe else { return }
            let delay: Double = Double.random(in: 0.0...4.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    breathPhase = 1
                }
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

// MARK: ============================================================
// MARK: Month 内容 (Phone 07 月度统计)
// MARK: ============================================================
//
// 对照 pace-demo/index.html#L3087-L3219.
// 内容: 月份导航 + 月度跑量 hero + 进度环 + 31 天日历 heatmap +
//      6 个月趋势折线 + PB 列表 (5K / 10K / 半马)
//

extension WeekHistoryView {
    var monthContent: some View {
        // ViewBuilder §1.1: 10 子临界, Group 包前 9 个稳妥
        VStack(alignment: .leading, spacing: 0) {
            Group {
                monthNavRow
                Spacer().frame(height: 18)
                monthHero
                Spacer().frame(height: 22)
                calendarSection
                Spacer().frame(height: 20)
                sixMonthTrendSection
                Spacer().frame(height: 16)
                pbSection
            }
            Spacer().frame(height: 20)
        }
    }

    // 月份导航行: ‹ 2026 · 5月 ›  右侧 MAY · 2026
    var monthNavRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("‹")
                    .font(PaceFont.cn(size: 14, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.6)
                Text(hasRealRuns ? store.currentMonthTitleCN() : MockData.MonthlyStats.yearMonthCn)
                    .font(PaceFont.cn(size: 12, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(2.4)
                Text("›")
                    .font(PaceFont.cn(size: 14, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.6)
            }
            Spacer()
            Text(hasRealRuns ? store.currentMonthTitleEN() : MockData.MonthlyStats.yearMonthEn)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
        }
    }

    // 月度跑量 hero: 138.5 km + ↑18% chip + 78pt 进度环
    var monthHero: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("月度跑量")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(3.4)
                    .padding(.bottom, 4)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", hasRealRuns ? store.thisMonthDistanceKm : MockData.MonthlyStats.distanceKm))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text1)
                        .kerning(-2.4)
                    Text("km")
                        .font(PaceFont.cn(size: 14, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.2)
                }

                // ↑18% vs 4月 chip
                HStack(spacing: 4) {
                    Text(monthDelta)
                        .font(PaceFont.mono(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text(hasRealRuns ? "vs 上月" : MockData.MonthlyStats.trendCompare)
                        .font(PaceFont.cn(size: 10, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(0.6)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Theme.accent.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 4)
            }

            Spacer()

            // 进度环 78pt 显示 progress %
            MonthRingProgress(
                progress: hasRealRuns
                    ? min(1.0, store.thisMonthDistanceKm / MockData.MonthlyStats.goalKm)
                    : MockData.MonthlyStats.progress,
                goalKm: MockData.MonthlyStats.goalKm
            )
            .frame(width: 96, height: 96)
        }
    }

    // 日历 heatmap 区
    var calendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("日历")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text("M  T  W  T  F  S  S")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(2.0)
            }
            CalendarHeatmap(
                daysInMonth: hasRealRuns ? store.daysInCurrentMonth() : MockData.MonthlyStats.daysInMonth,
                startCol: hasRealRuns ? store.currentMonthStartColumnMondayFirst() : MockData.MonthlyStats.startCol,
                today: hasRealRuns ? store.currentMonthToday() : MockData.MonthlyStats.today,
                intensities: hasRealRuns ? store.dailyIntensityThisMonth() : MockData.MonthlyStats.runDayIntensities
            )
        }
    }

    // 6 个月趋势折线
    var sixMonthTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("6 个月趋势")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text(MockData.MonthlyStats.trendDeltaStr)
                    .font(PaceFont.mono(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(0.6)
            }
            SixMonthTrend(
                pointsY: MockData.MonthlyStats.trendPointsY,
                labels: MockData.MonthlyStats.trendLabels
            )
            .frame(height: 72)
        }
    }

    // PB 列表 (5K / 10K / 半马)
    var pbSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("个人最佳 · PB")
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.6)

            VStack(spacing: 0) {
                ForEach(0..<MockData.MonthlyStats.pbs.count, id: \.self) { i in
                    let row = MockData.MonthlyStats.pbs[i]
                    HStack {
                        Text(row.distance)
                            .font(PaceFont.cn(size: 13, weight: .medium))
                            .foregroundColor(Theme.text1)
                            .kerning(0.6)
                        Spacer()
                        Text(row.time)
                            .font(PaceFont.mono(size: 15, weight: .bold))
                            .foregroundColor(row.isPb ? Theme.accent : Theme.text1)
                            .kerning(-0.3)
                        Spacer()
                        Text(row.note)
                            .font(PaceFont.mono(size: 10, weight: .medium))
                            .foregroundColor(row.isPb ? Theme.text3 : Theme.text4)
                            .kerning(1.0)
                            .frame(minWidth: 56, alignment: .trailing)
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .overlay(
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
                    .opacity(i == MockData.MonthlyStats.pbs.count - 1 ? 1 : 1)
                }
            }
            .background(Theme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - v0.4.11 年度 tab 内容 (无 HTML demo 参照, 视觉延续 monthContent)
extension WeekHistoryView {
    var yearContent: some View {
        // ViewBuilder §1.1: Group 包前 9 (≤10), 末尾 Spacer 作 VStack 直接子
        VStack(alignment: .leading, spacing: 0) {
            Group {
                yearNavRow
                Spacer().frame(height: 18)
                yearHero
                Spacer().frame(height: 22)
                yearHeatmapSection
                Spacer().frame(height: 22)
                twelveMonthTrendSection
                Spacer().frame(height: 16)
                yearPbSection
            }
            Spacer().frame(height: 20)
        }
    }

    // 年份导航行: ‹ 2026 ›   右侧 YEAR · 2026
    var yearNavRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("‹")
                    .font(PaceFont.cn(size: 14, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.6)
                Text(hasRealRuns ? store.currentYearTitleCN() : MockData.YearHistory.yearCn)
                    .font(PaceFont.cn(size: 12, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(2.4)
                Text("›")
                    .font(PaceFont.cn(size: 14, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.6)
            }
            Spacer()
            Text(hasRealRuns ? store.currentYearTitleEN() : MockData.YearHistory.yearEn)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
        }
    }

    // 年度跑量 hero: 大数字 + ↑18% chip + 右侧 双 stat (跑步天数 / 平均配速)
    var yearHero: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("年度跑量")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(3.4)
                    .padding(.bottom, 4)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", hasRealRuns ? store.thisYearDistanceKm : MockData.YearHistory.yearKm))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text1)
                        .kerning(-2.4)
                    Text("km")
                        .font(PaceFont.cn(size: 14, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.2)
                }

                // ↑18% vs 2025 chip
                HStack(spacing: 4) {
                    Text(yearDelta)
                        .font(PaceFont.mono(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text(hasRealRuns ? "vs 去年" : MockData.YearHistory.yearTrendCompare)
                        .font(PaceFont.cn(size: 10, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(0.6)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Theme.accent.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, 4)
            }

            Spacer()

            // 双 stat 列 (代替 month tab 的 ring — 年度没有 goal target)
            VStack(alignment: .trailing, spacing: 14) {
                yearSubStat(
                    label: MockData.YearHistory.runDaysLabel,
                    value: "\(hasRealRuns ? store.thisYearRunDays : MockData.YearHistory.runDays)",
                    unit: "天"
                )
                yearSubStat(
                    label: MockData.YearHistory.avgPaceLabel,
                    value: hasRealRuns ? store.thisYearAveragePaceDisplay : MockData.YearHistory.avgPaceStr,
                    unit: "/km"
                )
            }
            .frame(width: 96)
        }
    }

    @ViewBuilder
    func yearSubStat(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(PaceFont.cn(size: 9, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.6)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(PaceFont.mono(size: 22, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.4)
                Text(unit)
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(0.8)
            }
        }
    }

    // 12 月 heatmap (1 行 × 12 列, 月份字母 + 强度色, 当前月 accent 边框)
    var yearHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("12 月分布")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text("KM / MONTH")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(2.0)
            }
            YearMonthlyHeatmap(
                monthlyKm: hasRealRuns ? store.monthlyDistancesThisYear() : MockData.YearHistory.monthlyKm,
                monthLabels: MockData.YearHistory.monthLabelsEn,
                currentMonth: hasRealRuns
                    ? Calendar(identifier: .gregorian).component(.month, from: Date())
                    : MockData.YearHistory.currentMonth,
                maxKm: hasRealRuns
                    ? max(store.monthlyDistancesThisYear().max() ?? 1, 1)
                    : MockData.YearHistory.monthlyKmMax
            )
            .frame(height: 70)
        }
    }

    // 12 个月趋势折线 (实线到 currentMonth, 之后虚线占位)
    var twelveMonthTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("12 个月趋势")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text(MockData.YearHistory.trendDeltaStr)
                    .font(PaceFont.mono(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(0.6)
            }
            TwelveMonthTrend(
                pointsY: MockData.YearHistory.trendPointsY,
                splitIdx: MockData.YearHistory.currentMonth - 1
            )
            .frame(height: 56)
        }
    }

    // 年度 PB · 3 ITEMS, 含 NEW / -42s delta vs 去年 chip
    var yearPbSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("年度 PB")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                Text("\(MockData.YearHistory.yearPBs.count) ITEMS")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(2.0)
            }

            VStack(spacing: 0) {
                ForEach(0..<MockData.YearHistory.yearPBs.count, id: \.self) { i in
                    yearPbRow(MockData.YearHistory.yearPBs[i],
                              isLast: i == MockData.YearHistory.yearPBs.count - 1)
                }
            }
            .background(Theme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.hairlineBright, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    func yearPbRow(_ row: (distance: String, time: String, delta: String, isPb: Bool),
                   isLast: Bool) -> some View {
        HStack {
            Text(row.distance)
                .font(PaceFont.cn(size: 13, weight: .medium))
                .foregroundColor(Theme.text1)
                .kerning(0.6)
            Spacer()
            Text(row.time)
                .font(PaceFont.mono(size: 15, weight: .bold))
                .foregroundColor(row.isPb ? Theme.accent : Theme.text1)
                .kerning(-0.3)
            Spacer()
            yearPbDelta(row.delta)
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .overlay(
            Rectangle()
                .fill(isLast ? Color.clear : Theme.hairline)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    @ViewBuilder
    func yearPbDelta(_ delta: String) -> some View {
        if delta == "NEW" {
            Text("NEW")
                .font(PaceFont.mono(size: 9, weight: .bold))
                .foregroundColor(Theme.gold)
                .kerning(2.0)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.gold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.gold.opacity(0.5), lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            HStack(spacing: 3) {
                Text("↓")
                    .font(PaceFont.mono(size: 10, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text(delta)
                    .font(PaceFont.mono(size: 10, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .kerning(0.5)
            }
        }
    }
}

// MARK: - 12 月 heatmap row (1 行 × 12 cell)
private struct YearMonthlyHeatmap: View {
    let monthlyKm: [Double]
    let monthLabels: [String]
    let currentMonth: Int   // 1-indexed
    let maxKm: Double

    private let cols: Int = 12
    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let totalW: CGFloat = geo.size.width
            let cellW: CGFloat = (totalW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let cellH: CGFloat = geo.size.height

            HStack(spacing: gap) {
                ForEach(0..<cols, id: \.self) { i in
                    YearMonthCell(
                        monthLabel: monthLabels[i],
                        km: monthlyKm[i],
                        intensity: maxKm > 0 ? min(1.0, monthlyKm[i] / maxKm) : 0,
                        isCurrent: (i + 1) == currentMonth,
                        isFuture: (i + 1) > currentMonth
                    )
                    .frame(width: cellW, height: cellH)
                }
            }
        }
    }
}

private struct YearMonthCell: View {
    let monthLabel: String
    let km: Double
    let intensity: Double
    let isCurrent: Bool
    let isFuture: Bool

    private var bg: Color {
        if isFuture { return Color.white.opacity(0.02) }
        if intensity > 0 { return Theme.accent.opacity(0.15 + 0.55 * intensity) }
        return Color.white.opacity(0.04)
    }

    private var labelColor: Color {
        if isFuture { return Theme.text4 }
        if intensity > 0 { return .white }
        return Theme.text3
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5).fill(bg)
            VStack(spacing: 3) {
                Text(monthLabel)
                    .font(PaceFont.mono(size: 9, weight: .bold))
                    .foregroundColor(labelColor)
                    .kerning(0.4)
                kmLabel
            }
            if isCurrent {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 4)
            }
        }
    }

    @ViewBuilder
    private var kmLabel: some View {
        if !isFuture && km > 0 {
            Text("\(Int(km.rounded()))")
                .font(PaceFont.mono(size: 8, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(-0.2)
        } else {
            Text("·")
                .font(.system(size: 8))
                .foregroundColor(Theme.text4)
        }
    }
}

// MARK: - 12 月趋势折线 (实线 splitIdx 之前, 之后虚线占位)
private struct TwelveMonthTrend: View {
    let pointsY: [Double]   // viewBox y (越小=月里程越多)
    let splitIdx: Int       // 实线最后一点的 index (含); = currentMonth - 1

    @State private var endPulse: Bool = false

    private let pointsX: [Double] = [
        11, 35, 59, 83, 107, 131, 155, 179, 203, 227, 251, 269,
    ]

    var body: some View {
        GeometryReader { geo in
            // 显式 CGFloat (Swift 5.4 不自动 Double↔CGFloat, §1.2)
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 52
            let lastIdx: Int = pointsY.count - 1
            let solidLast: Int = max(0, min(splitIdx, lastIdx))

            ZStack {
                solidAreaPath(scaleX: scaleX, scaleY: scaleY, solidLast: solidLast)
                solidLinePath(scaleX: scaleX, scaleY: scaleY, solidLast: solidLast)
                if solidLast < lastIdx {
                    dashedFuturePath(scaleX: scaleX, scaleY: scaleY,
                                     solidLast: solidLast, lastIdx: lastIdx)
                }
                solidDots(scaleX: scaleX, scaleY: scaleY, solidLast: solidLast)
                endMarker(scaleX: scaleX, scaleY: scaleY, solidLast: solidLast)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                endPulse = true
            }
        }
    }

    private func solidAreaPath(scaleX: CGFloat, scaleY: CGFloat, solidLast: Int) -> some View {
        Path { p in
            p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
            if solidLast >= 1 {
                for i in 1...solidLast {
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX,
                                          y: CGFloat(pointsY[i]) * scaleY))
                }
            }
            p.addLine(to: CGPoint(x: CGFloat(pointsX[solidLast]) * scaleX, y: 48 * scaleY))
            p.addLine(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: 48 * scaleY))
            p.closeSubpath()
        }
        .fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.35),
                    Theme.accent.opacity(0.0),
                ]),
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private func solidLinePath(scaleX: CGFloat, scaleY: CGFloat, solidLast: Int) -> some View {
        Path { p in
            p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
            if solidLast >= 1 {
                for i in 1...solidLast {
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX,
                                          y: CGFloat(pointsY[i]) * scaleY))
                }
            }
        }
        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        .shadow(color: Theme.accent.opacity(0.5), radius: 4, y: 2)
    }

    private func dashedFuturePath(scaleX: CGFloat, scaleY: CGFloat,
                                  solidLast: Int, lastIdx: Int) -> some View {
        Path { p in
            p.move(to: CGPoint(x: CGFloat(pointsX[solidLast]) * scaleX,
                               y: CGFloat(pointsY[solidLast]) * scaleY))
            for i in (solidLast + 1)...lastIdx {
                p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX,
                                      y: CGFloat(pointsY[i]) * scaleY))
            }
        }
        .stroke(
            Color.white.opacity(0.18),
            style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [3, 4])
        )
    }

    private func solidDots(scaleX: CGFloat, scaleY: CGFloat, solidLast: Int) -> some View {
        ForEach(0..<max(0, solidLast), id: \.self) { i in
            Circle()
                .fill(Theme.bgCard)
                .frame(width: 5, height: 5)
                .overlay(Circle().stroke(Theme.accent, lineWidth: 1.2))
                .position(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY)
        }
    }

    private func endMarker(scaleX: CGFloat, scaleY: CGFloat, solidLast: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Theme.accent.opacity(endPulse ? 0.6 : 0.3), lineWidth: 0.7)
                .frame(width: endPulse ? 16 : 12, height: endPulse ? 16 : 12)
            Circle()
                .fill(Theme.accentBright)
                .frame(width: 7, height: 7)
                .shadow(color: Theme.accent.opacity(0.6), radius: 4)
        }
        .position(x: CGFloat(pointsX[solidLast]) * scaleX,
                  y: CGFloat(pointsY[solidLast]) * scaleY)
    }
}

// MARK: - 进度环 (96pt 大圈, accent → accentBright 渐变, 中心 % + /goalKm)
private struct MonthRingProgress: View {
    let progress: Double   // 0..1
    let goalKm: Double

    var body: some View {
        ZStack {
            // 底圈
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 5)

            // 进度环
            Circle()
                .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Theme.accent, Theme.accentBright]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8)

            // 中心: 69% + /200km
            VStack(spacing: 2) {
                Text("\(Int(round(progress * 100)))%")
                    .font(PaceFont.mono(size: 18, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.4)
                Text("/\(Int(goalKm))km")
                    .font(PaceFont.mono(size: 8, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.0)
            }
        }
    }
}

// MARK: - 日历 heatmap (31 天, 5 行 × 7 列, 周一开始)
//
// 数据驱动: startCol 个 empty cells, 然后 1-31 天.
// 5/1 是周五 → startCol = 4 → 第一行前 4 cells 为空, 第一行从 col 4 开始放 day 1-3.
//
private struct CalendarHeatmap: View {
    let daysInMonth: Int
    let startCol: Int
    let today: Int
    let intensities: [Int: Double]

    private let cols: Int = 7
    private let gap: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let totalW: CGFloat = geo.size.width
            let cellSize: CGFloat = (totalW - CGFloat(cols - 1) * gap) / CGFloat(cols)
            let totalCells: Int = startCol + daysInMonth
            let rows: Int = Int(ceil(Double(totalCells) / Double(cols)))

            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { c in
                            let cellIdx: Int = r * cols + c
                            let day: Int = cellIdx - startCol + 1
                            CalendarCell(
                                day: day,
                                inMonth: (day >= 1 && day <= daysInMonth),
                                isToday: (day == today),
                                isFuture: (day > today),
                                intensity: intensities[day] ?? 0
                            )
                            .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        // 5 行 × cellSize + 4 gap. cellSize ≈ (358-18)/7 ≈ 48pt → 高 ~252pt
        .frame(height: 5 * 48 + 4 * 3)
    }
}

private struct CalendarCell: View {
    let day: Int
    let inMonth: Bool
    let isToday: Bool
    let isFuture: Bool
    let intensity: Double  // 0 表示没跑 / 没数据

    private var bg: Color {
        if !inMonth { return Color.white.opacity(0.02) }
        if isFuture { return .clear }
        if intensity > 0 { return Theme.accent.opacity(intensity) }
        return Color.white.opacity(0.02)
    }

    private var fg: Color {
        if !inMonth { return .clear }
        if isFuture { return Theme.text4 }
        if intensity > 0 { return .white }
        return Theme.text3
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(bg)
            if inMonth {
                Text("\(day)")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(fg)
                    .kerning(-0.2)
            }
            // today 高亮 inset 边框
            if isToday {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.accent, lineWidth: 1.5)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 4)
            }
        }
    }
}

// MARK: - 6 个月趋势折线 (viewBox 280×52, 末点高亮 + 呼吸)
private struct SixMonthTrend: View {
    let pointsY: [Double]   // viewBox y 坐标, 越小越靠上 = 月度跑量越多
    let labels: [String]

    @State private var endPulse: Bool = false

    private let pointsX: [Double] = [12, 60, 108, 156, 204, 252]   // viewBox 280 等分

    var body: some View {
        GeometryReader { geo in
            // 显式 CGFloat 类型避免 Swift 5.4 推断歧义
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 52
            let lastIdx: Int = pointsY.count - 1

            ZStack {
                // 区域填充
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1..<pointsY.count {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[lastIdx]) * scaleX, y: 48 * scaleY))
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: 48 * scaleY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.35),
                            Theme.accent.opacity(0.0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 折线
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1..<pointsY.count {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .shadow(color: Theme.accent.opacity(0.5), radius: 4, y: 2)

                // 5 个普通节点 (空心 dot)
                ForEach(0..<lastIdx, id: \.self) { i in
                    Circle()
                        .fill(Theme.bgCard)
                        .frame(width: 5, height: 5)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 1.2))
                        .position(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY)
                }

                // 末点突出 (实心 + 呼吸外环)
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(endPulse ? 0.6 : 0.3), lineWidth: 0.7)
                        .frame(width: endPulse ? 16 : 12, height: endPulse ? 16 : 12)
                    Circle()
                        .fill(Theme.accentBright)
                        .frame(width: 7, height: 7)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                }
                .position(x: CGFloat(pointsX[lastIdx]) * scaleX, y: CGFloat(pointsY[lastIdx]) * scaleY)

                // x 轴标签 12 / 1 / 2 / 3 / 4 / 5
                ForEach(0..<labels.count, id: \.self) { i in
                    Text(labels[i])
                        .font(PaceFont.mono(size: 9, weight: i == lastIdx ? .bold : .medium))
                        .foregroundColor(i == lastIdx ? Theme.accent : Theme.text4)
                        .kerning(0.5)
                        .position(x: CGFloat(pointsX[i]) * scaleX, y: 50 * scaleY)
                }
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
struct WeekHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        WeekHistoryView()
            .preferredColorScheme(.dark)
    }
}
#endif
