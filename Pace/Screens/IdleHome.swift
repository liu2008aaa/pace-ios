//
//  IdleHome.swift
//  Pace.
//
//  Phone 01 · 待机首页
//
//  iOS 14 兼容修订版：
//  - 所有 .tracking() 改为 .kerning()（iOS 14+ Text 修饰符）
//  - HStack 上的 .tracking 不可用，分发到每个 Text 的 .kerning
//

import SwiftUI

struct IdleHome: View {

    /// 计算时间问候语
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "上午好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // MARK: Brand strip
                HStack {
                    brandLogo

                    Spacer()

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
                        // v0.2: 跳到 /coach
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 6)

                // MARK: Greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(greeting),\(MockData.User.displayName)")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundColor(Theme.text1)
                        .kerning(0.76)

                    HStack(spacing: 6) {
                        Text(MockData.Weather.city)
                            .font(PaceFont.cn(size: 9.5))
                            .foregroundColor(Theme.text2)
                            .kerning(1.5)
                        Text("·").font(PaceFont.cn(size: 9.5)).foregroundColor(Theme.text4)
                        Text(MockData.Weather.condition)
                            .font(PaceFont.cn(size: 9.5))
                            .foregroundColor(Theme.text2)
                            .kerning(1.5)
                        Text("·").font(PaceFont.cn(size: 9.5)).foregroundColor(Theme.text4)
                        Text("\(MockData.Weather.tempC)°C")
                            .font(PaceFont.mono(size: 9.5))
                            .foregroundColor(Theme.text2)
                            .kerning(0.4)
                        Text("·").font(PaceFont.cn(size: 9.5)).foregroundColor(Theme.text4)
                        Text(MockData.Weather.wind)
                            .font(PaceFont.cn(size: 9.5))
                            .foregroundColor(Theme.text2)
                            .kerning(1.5)
                        Text("·").font(PaceFont.cn(size: 9.5)).foregroundColor(Theme.text4)
                        Text(MockData.Weather.suitability)
                            .font(PaceFont.cn(size: 9.5))
                            .foregroundColor(Theme.accent)
                            .kerning(1.5)
                    }
                }
                .padding(.top, 12)

                // MARK: Hairline
                Hairline()
                    .padding(.top, 16)

                // MARK: 今日体感 header
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

                // MARK: 三联表盘
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

                // MARK: AI 一句话建议
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

                // MARK: 上限 80pt 的弹性间距 (避免在大屏上顶到中间形成大空洞)
                Spacer().frame(maxHeight: 80)

                // MARK: 出发按钮
                StartButton {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // v0.2: 跳到 /pre-run
                }

                // MARK: 上次跑步
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

                // MARK: 14 天时间线
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
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - PACE. 品牌字（Text + Text 拼接放计算属性里，避开 @ViewBuilder 解析坑）
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
