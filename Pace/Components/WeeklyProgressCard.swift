//
//  WeeklyProgressCard.swift
//  Pace.
//
//  Phone 01 中段填充组件 — 本周跑量进度条卡片
//
//  灵感来自 Keep / WHOOP / Apple Fitness 的「daily/weekly progress」
//  小组件 —— 给首页填一个有用的、激励性的内容，避免按钮周围空荡。
//
//  布局（约 110pt 高）：
//  ┌──────────────────────────┐
//  │ 本周                  WEEK │   header
//  │                            │
//  │ 12.4 / 30 km        ↑12% │   big number + delta chip
//  │                            │
//  │ ████████░░░░░░░░░░       │   progress bar
//  │                            │
//  │ 4 次跑步 · 均速 5'18"/km │   footer
//  └──────────────────────────┘
//
//  Swift 5.4 兼容：每个子布局独立，children 数 ≤ 5 per container。
//

import SwiftUI

struct WeeklyProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            mainStatRow
            progressBar
            footerRow
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

    // MARK: - Header (本周 / WEEK)
    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("本周")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
            Spacer()
            Text("WEEK")
                .font(PaceFont.mono(size: 8))
                .foregroundColor(Theme.text4)
                .kerning(1.7)
        }
    }

    // MARK: - Big stat row (12.4 / 30 km + delta chip)
    private var mainStatRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(String(format: "%.1f", MockData.WeekProgress.kmThisWeek))
                .font(PaceFont.mono(size: 28, weight: .semibold))
                .foregroundColor(Theme.text1)

            Text("/ \(Int(MockData.WeekProgress.kmGoal)) km")
                .font(PaceFont.mono(size: 11))
                .foregroundColor(Theme.text3)
                .kerning(0.4)

            Spacer()

            deltaChip
        }
    }

    // MARK: - Delta chip (↑12%)
    private var deltaChip: some View {
        Text("↑\(MockData.WeekProgress.deltaPercent)%")
            .font(PaceFont.mono(size: 10, weight: .medium))
            .foregroundColor(Theme.accent)
            .kerning(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.accent.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Progress bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 底色
                Capsule()
                    .fill(Theme.text4.opacity(0.3))
                // 填充
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.accent.opacity(0.7),
                                Theme.accentBright,
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(MockData.WeekProgress.ratio))
                    .shadow(color: Theme.accent.opacity(0.4), radius: 4)
            }
        }
        .frame(height: 5)
    }

    // MARK: - Footer (4 次跑步 · 均速 5'18"/km)
    private var footerRow: some View {
        HStack(spacing: 6) {
            Text("\(MockData.WeekProgress.runs) 次跑步")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text2)
                .kerning(1.0)
            Text("·")
                .foregroundColor(Theme.text4)
            Text("均速 \(MockData.WeekProgress.avgPace)/km")
                .font(PaceFont.cn(size: 10))
                .foregroundColor(Theme.text2)
                .kerning(0.5)
            Spacer()
        }
    }
}

#if DEBUG
struct WeeklyProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyProgressCard()
            .padding()
            .background(Theme.bgApp)
            .previewLayout(.sizeThatFits)
    }
}
#endif
