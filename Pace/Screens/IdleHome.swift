//
//  IdleHome.swift
//  Pace.
//
//  Phone 01 · 待机首页
//
//  Swift 5.4 兼容版：把 body 拆分为多个小 sub-view 计算属性，避免单个
//  ViewBuilder 表达式过于复杂导致类型检查器超时（典型 "Extra argument
//  in call" 假错）。
//

import SwiftUI

struct IdleHome: View {

    // MARK: - Time-aware greeting prefix
    private var greetingPrefix: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "上午好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }

    // MARK: - Body (small, simple)
    //
    // 注意：SwiftUI 的 @ViewBuilder 在 iOS 14 / Swift 5.4 上每个容器
    // 最多支持 10 个直接子 view（buildBlock 重载到 10 参数为止）。
    // 超过 10 个会报 "Extra argument in call"。这里用 Group { } 把
    // 相关的合并成 1 个子元素，让 VStack 直接子元素 ≤ 10。
    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 顶部 7 个 → 合并为 1 个 Group 子元素 (≤ 10, 安全)
                Group {
                    brandStrip
                    greetingSection
                    hairlineDivider
                    metricsHeader
                    triadSection
                    aiSuggestion
                    weeklyRhythmSection
                }

                Spacer()

                StartButton {
                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.success)
                    // v0.2: navigate to /pre-run
                }

                // 底部仅剩 14 天点阵带（含彗星扫描动画）。
                // "上次" 一行已并入 WeeklyRhythmCard 的语义，故移除。
                timelineSection
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Brand strip (PACE. + Coach chip)
    private var brandStrip: some View {
        HStack {
            brandLogo

            Spacer()

            coachChip
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }

    // MARK: - Coach chip (top-right)
    private var coachChip: some View {
        HStack(spacing: 5) {
            Text("✦")
                .font(.system(size: 11))
                .foregroundColor(Theme.accent)
            Text("教练")
                .font(PaceFont.cn(size: 9))
                .foregroundColor(Theme.accent)
                .kerning(1.08)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
        .onTapGesture {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // MARK: - Greeting section (上午好 + weather)
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greetingPrefix),\(MockData.User.displayName)")
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(Theme.text1)
                .kerning(0.76)

            weatherRow
        }
        .padding(.top, 12)
    }

    // MARK: - Weather row
    private var weatherRow: some View {
        HStack(spacing: 6) {
            Text(MockData.Weather.city)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text2)
                .kerning(1.5)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text4)
            Text(MockData.Weather.condition)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text2)
                .kerning(1.5)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text4)
            Text("\(MockData.Weather.tempC)°C")
                .font(PaceFont.mono(size: 9.5))
                .foregroundColor(Theme.text2)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text4)
            Text(MockData.Weather.wind)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text2)
                .kerning(1.5)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text4)
            Text(MockData.Weather.suitability)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.accent)
                .kerning(1.5)
        }
    }

    // MARK: - Hairline divider
    private var hairlineDivider: some View {
        Hairline()
            .padding(.top, 16)
    }

    // MARK: - Metrics header
    private var metricsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("今日体感")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(3.6)
            Spacer()
            Text("DAILY METRICS")
                .font(PaceFont.mono(size: 8))
                .foregroundColor(Theme.text4)
                .kerning(1.76)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Triad of dials
    private var triadSection: some View {
        HStack(spacing: 7) {
            DialCard(
                cornerMark: "01",
                value: "\(MockData.Today.readiness)",
                unit: "/100",
                label: "状态",
                meta: "↑ \(MockData.Today.readinessDelta) vs 昨",
                percent: Double(MockData.Today.readiness),
                state: .good
            )
            DialCard(
                cornerMark: "02",
                value: String(format: "%.1f", MockData.Today.strain),
                unit: "/21",
                label: "负荷",
                meta: MockData.Today.strainStatus,
                percent: MockData.Today.strain / 21 * 100,
                state: .warn
            )
            DialCard(
                cornerMark: "03",
                value: "\(MockData.Today.sleepPercent)%",
                unit: MockData.Today.sleepHours,
                label: "睡眠",
                meta: "↑ \(MockData.Today.sleepDelta)%",
                percent: Double(MockData.Today.sleepPercent),
                state: .good
            )
        }
        .frame(minHeight: 138)
    }

    // MARK: - AI 一句话建议
    private var aiSuggestion: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("✦")
                .font(.system(size: 11))
                .foregroundColor(Theme.accent)

            aiText
                .font(PaceFont.cn(size: 11))
                .foregroundColor(Theme.text2)
                .lineSpacing(3)
        }
        .padding(.top, 12)
    }

    // MARK: - 本周节奏卡（7 日柱图 + 今日发光圆点 + 连跑 chip）
    private var weeklyRhythmSection: some View {
        WeeklyRhythmCard()
            .padding(.top, 16)
    }

    // MARK: - 14-day timeline
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近 14 天")
                    .font(PaceFont.cn(size: 8.5))
                    .foregroundColor(Theme.text4)
                    .kerning(1.53)
                Spacer()
                Text("今天")
                    .font(PaceFont.mono(size: 8.5))
                    .foregroundColor(Theme.accent)
                    .kerning(2.13)
            }
            TimelineDots(intensities: MockData.timeline)
        }
        .padding(.top, 16)
    }

    // MARK: - PACE. brand wordmark (Text + Text in computed property)
    private var brandLogo: Text {
        Text("PACE")
            .font(PaceFont.mono(size: 9.5, weight: .medium))
            .foregroundColor(Theme.text3)
            .kerning(1.7) +
        Text(".")
            .font(PaceFont.mono(size: 9.5, weight: .medium))
            .foregroundColor(Theme.accent)
    }

    // MARK: - AI 文案带高亮（"负荷偏高" 显示金色）
    private var aiText: Text {
        let raw = MockData.Today.aiSuggestion
        let highlight = MockData.Today.aiHighlight

        guard let range = raw.range(of: highlight) else {
            return Text(raw)
        }
        let before = String(raw[..<range.lowerBound])
        let mid = String(raw[range])
        let after = String(raw[range.upperBound...])

        return Text(before)
            + Text(mid).foregroundColor(Theme.gold).fontWeight(.semibold)
            + Text(after)
    }
}

// MARK: - 本周节奏卡 (内联到此文件以避免 Xcode 12 的 "Add Files to Project" 摩擦)
//
// 设计点：
// - 7 日柱图替代旧的"本周进度"线条（解决用户"天天画圆"重复感）
// - 休息日（km == 0）显示极矮平条 + 字号变灰
// - 今日柱顶点带发光脉冲圆点 + 自身有 accent 阴影发光
// - 顶部连跑 chip 用 gold 色，断了以后切金/灰由调用方判断
//
private struct WeeklyRhythmCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            wrcHeader
            wrcMainStats
            wrcBars
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairline, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var wrcHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("本周节奏")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
            Text("WEEKLY RHYTHM")
                .font(PaceFont.mono(size: 8))
                .foregroundColor(Theme.text4)
                .kerning(1.7)
            Spacer()
            wrcStreakChip
        }
    }

    private var wrcStreakChip: some View {
        HStack(spacing: 3) {
            Text("✦")
                .font(.system(size: 9))
                .foregroundColor(Theme.gold)
            Text("\(MockData.WeekRhythm.streakDays) 天连跑")
                .font(PaceFont.cn(size: 9))
                .foregroundColor(Theme.gold)
                .kerning(0.6)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(Theme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Theme.gold.opacity(0.28), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }

    private var wrcMainStats: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(MockData.WeekRhythm.totalKm)
                .font(PaceFont.mono(size: 28, weight: .semibold))
                .foregroundColor(Theme.text1)
            Text("km")
                .font(PaceFont.mono(size: 11))
                .foregroundColor(Theme.text3)
                .kerning(0.4)
            Spacer()
            Text("\(MockData.WeekRhythm.runs) 次")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text2)
                .kerning(0.5)
            Text("·")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text4)
            Text("均速 \(MockData.WeekRhythm.avgPace)")
                .font(PaceFont.mono(size: 10))
                .foregroundColor(Theme.text2)
        }
    }

    private var wrcBars: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(0..<7) { i in
                BarColumn(
                    km: MockData.WeekRhythm.dayKm[i],
                    label: MockData.WeekRhythm.dayLabels[i],
                    isToday: i == MockData.WeekRhythm.todayIndex
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 64)
    }
}

// MARK: - 单根柱 + 日字标签 + (今日)发光脉冲圆点
private struct BarColumn: View {
    let km: Double
    let label: String
    let isToday: Bool

    /// 一周柱图基准最大 km（决定柱高映射）
    private static let maxKm: Double = 6.5
    /// 柱区域高度（不含底部文字）
    private static let barAreaHeight: CGFloat = 50

    @State private var pulse: CGFloat = 1.0

    private var isRest: Bool { km == 0 }

    private var barHeight: CGFloat {
        if isRest { return 4 }
        let ratio = min(1.0, km / BarColumn.maxKm)
        return CGFloat(6.0 + ratio * 40.0)
    }

    private var barColor: Color {
        if isRest { return Theme.text4.opacity(0.5) }
        if isToday { return Theme.accentBright }
        return Theme.accent.opacity(0.65)
    }

    private var labelColor: Color {
        if isToday { return Theme.accent }
        if isRest { return Theme.text4 }
        return Theme.text3
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                // 占满整个柱区域，便于底部对齐
                Color.clear
                    .frame(height: BarColumn.barAreaHeight)

                // 柱体
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 6, height: barHeight)
                    .shadow(
                        color: isToday ? Theme.accent.opacity(0.7) : Color.clear,
                        radius: 4
                    )

                // 今日柱顶发光脉冲圆点
                if isToday {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6 * pulse, height: 6 * pulse)
                        .shadow(color: Theme.accent.opacity(0.9), radius: 4)
                        .offset(y: -(barHeight + 4))
                }
            }

            Text(label)
                .font(PaceFont.cn(size: 9))
                .foregroundColor(labelColor)
                .kerning(0.5)
        }
        .onAppear {
            if isToday {
                withAnimation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                ) {
                    pulse = 1.4
                }
            }
        }
    }
}

#if DEBUG
struct IdleHome_Previews: PreviewProvider {
    static var previews: some View {
        IdleHome()
            .preferredColorScheme(.dark)
    }
}
#endif
