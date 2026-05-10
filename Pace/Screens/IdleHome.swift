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

    // v0.3.0: 出发按钮 → fullScreenCover RunningView
    @State private var showRunning = false

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
                    // v0.3: 直接进 RunningView
                    // v0.4 计划: IdleHome → PreRun (GPS 等待) → RunningView
                    showRunning = true
                }

                // 底部仅剩 14 天点阵带（含彗星扫描动画）。
                // "上次" 一行已并入 WeeklyRhythmCard 的语义，故移除。
                timelineSection
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        // 出发按钮 → 全屏接管的 RunningView
        // 用 fullScreenCover 而非 NavigationLink，因为跑步是"接管屏"
        // 不应该有 navigation bar / back swipe
        .fullScreenCover(isPresented: $showRunning) {
            RunningView()
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
        .padding(.top, 12)
    }

    // MARK: - Coach chip (top-right)
    private var coachChip: some View {
        HStack(spacing: 5) {
            Text("✦")
                .font(.system(size: 12))
                .foregroundColor(Theme.accent)
            Text("教练")
                .font(PaceFont.cn(size: 11))
                .foregroundColor(Theme.accent)
                .kerning(0.5)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("\(greetingPrefix),\(MockData.User.displayName)")
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(0.76)

            weatherRow
        }
        .padding(.top, 22)
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
                .foregroundColor(Theme.text3)
            Text(MockData.Weather.condition)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text2)
                .kerning(1.5)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text3)
            Text("\(MockData.Weather.tempC)°C")
                .font(PaceFont.mono(size: 9.5))
                .foregroundColor(Theme.text2)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text3)
            Text(MockData.Weather.wind)
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text2)
                .kerning(1.5)
            Text("·")
                .font(PaceFont.cn(size: 9.5))
                .foregroundColor(Theme.text3)
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
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(3.6)
            Spacer()
            Text("DAILY METRICS")
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text4)
                .kerning(1.76)
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
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
        .padding(.top, 18)
    }

    // MARK: - 本周节奏卡（7 日柱图 + 今日发光圆点 + 连跑 chip）
    private var weeklyRhythmSection: some View {
        WeeklyRhythmCard()
            .padding(.top, 24)
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
        VStack(alignment: .leading, spacing: 14) {
            wrcHeader
            wrcBars
            wrcFooter
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // 顶栏只放 title，不挂 chip — chip 已下沉到 footer 右
    private var wrcHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("本周节奏")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
            Text("RHYTHM")
                .font(PaceFont.mono(size: 8))
                .foregroundColor(Theme.text4)
                .kerning(1.7)
            Spacer()
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
    }

    // 底栏：左 "本周 26.0 km"，右 ↗ 12 天 chip
    private var wrcFooter: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("本周")
                .font(PaceFont.cn(size: 9))
                .foregroundColor(Theme.text3)
                .kerning(1.0)
            Text(MockData.WeekRhythm.totalKm)
                .font(PaceFont.mono(size: 17, weight: .semibold))
                .foregroundColor(Theme.text1)
            Text("km")
                .font(PaceFont.mono(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(0.4)
            Spacer()
            wrcStreakChip
        }
    }

    // chip: ↗ 12 天 — 数字 12 用白色 (HTML .rhythm-num-sm color: var(--text-1)),
    // 箭头和"天"用 accent 绿色 (继承自 .rhythm-streak.good color: var(--accent))
    private var wrcStreakChip: some View {
        HStack(spacing: 3) {
            Text("↗")
                .font(.system(size: 9))
                .foregroundColor(Theme.accent)
            Text("\(MockData.WeekRhythm.streakDays)")
                .font(PaceFont.mono(size: 10, weight: .semibold))
                .foregroundColor(Theme.text1)  // 白色 — 与 HTML 对齐
            Text("天")
                .font(PaceFont.cn(size: 9))
                .foregroundColor(Theme.accent)
                .kerning(0.4)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(Theme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Theme.accent.opacity(0.32), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

// MARK: - 单根柱 + 日字标签 + (今日)发光脉冲圆点
//
// HTML 源参照（index.html#L4908-L4928）：
// - viewBox 280×76, baseline y=64, 柱宽 28pt 占列 28/40 = 70%
// - 静息柱: rgba(255,255,255,0.08) 白雾, height=6
// - 活跃柱: accent 0.5-0.65
// - 今日柱: #29F0BD + drop-shadow(0 0 4px ...)
// - 脉冲点: r=2.5 → 3.5 → 2.5 over 2.4s, 贴柱顶上方 4pt
//
private struct BarColumn: View {
    let km: Double
    let label: String
    let isToday: Bool

    /// 一周柱图基准最大 km（决定柱高映射）
    private static let maxKm: Double = 6.5
    /// 柱区域高度（不含底部文字）— 真机 393pt 比 HTML 308pt 宽，要相应抬高
    private static let barAreaHeight: CGFloat = 64

    @State private var pulse: CGFloat = 1.0

    private var isRest: Bool { km == 0 }

    private var barHeight: CGFloat {
        if isRest { return 6 }
        let ratio = min(1.0, km / BarColumn.maxKm)
        // 12 + 50 = 62pt 顶, 占柱区 ~97%；最矮活跃柱 ~12pt 也清晰可见
        return CGFloat(12.0 + ratio * 50.0)
    }

    private var barColor: Color {
        if isRest { return Color.white.opacity(0.08) }
        if isToday { return Theme.accentBright }
        // 0.55 → 0.42：拉大与今日柱（1.0 + glow）的明度差，让今日真正"立"起来
        return Theme.accent.opacity(0.42)
    }

    private var labelColor: Color {
        if isToday { return Theme.accent }
        if isRest { return Theme.text4.opacity(0.6) }
        return Theme.text3
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottom) {
                // 占满整个柱区域 — ZStack(alignment:.bottom) 让其它子项自然底对齐
                Color.clear
                    .frame(height: BarColumn.barAreaHeight)

                // 基准线（HTML index.html#L4910 的 rgba(255,255,255,0.06)）
                // 每列独立画一段 0.5pt 横线，相邻列首尾相接拼成完整地面线
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)

                // 柱体（24pt 定宽，约占列宽 50% — 接近 HTML 28/40 比例）
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 24, height: barHeight)
                    .shadow(
                        color: isToday ? Theme.accent.opacity(0.7) : Color.clear,
                        radius: 6  // 4 → 6：在 393pt 真机上让 halo 真的能看见
                    )

                // 今日柱顶发光脉冲圆点（4pt 基准 → 5.6pt 顶点，贴柱顶 3pt）
                if isToday {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 4 * pulse, height: 4 * pulse)
                        .shadow(color: Theme.accent.opacity(0.95), radius: 4)
                        .offset(y: -(barHeight + 3))
                }
            }

            Text(label)
                .font(PaceFont.cn(size: 8.5, weight: isToday ? .medium : .regular))
                .foregroundColor(labelColor)
                .kerning(0.4)
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
