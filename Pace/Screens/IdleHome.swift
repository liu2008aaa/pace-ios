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
                // 顶部 6 个 → 合并为 1 个 Group 子元素
                Group {
                    brandStrip
                    greetingSection
                    hairlineDivider
                    metricsHeader
                    triadSection
                    aiSuggestion
                }

                Spacer()

                StartButton {
                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.success)
                    // v0.2: navigate to /pre-run
                }

                // 底部 2 个 → 合并为 1 个 Group 子元素
                Group {
                    lastRunLine
                    timelineSection
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
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
        .frame(minHeight: 110)
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

    // MARK: - Last run line
    private var lastRunLine: some View {
        HStack(spacing: 0) {
            Text("上次")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(1.8)
            Text("  \(MockData.LastRun.date) · \(String(format: "%.2f", MockData.LastRun.distance)) km · \(MockData.LastRun.pace)")
                .font(PaceFont.mono(size: 10))
                .foregroundColor(Theme.text2)
            Text("/km")
                .font(PaceFont.mono(size: 10))
                .foregroundColor(Theme.text3)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 12)
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

#if DEBUG
struct IdleHome_Previews: PreviewProvider {
    static var previews: some View {
        IdleHome()
            .preferredColorScheme(.dark)
    }
}
#endif
