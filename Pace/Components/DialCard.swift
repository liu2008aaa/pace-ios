//
//  DialCard.swift
//  Pace.
//
//  WHOOP 风三联表盘单个 dial。环形进度 + 中央数字 + 标签 + 元信息。
//  3 种状态：good (冷绿) / warn (金) / empty (虚线灰)。
//
//  iOS 14 兼容修订版：
//  - .buttonStyle(PlainButtonStyle()) 替代 .buttonStyle(.plain) (iOS 15+)
//  - .kerning() 替代 .tracking() (iOS 16+)
//  - 显式 CGFloat 转换（Swift 5.4 不自动 Double <-> CGFloat）
//

import SwiftUI

enum DialState {
    case good, warn, empty
}

struct DialCard: View {
    let cornerMark: String       // 角标 "01" / "02" / "03"
    let value: String            // 中央值 "82" / "14.2" / "87%"
    let unit: String             // 中央副标 "/100" / "/21" / "7h 24m"
    let label: String            // 主标签 "状态" / "负荷" / "睡眠"
    let meta: String             // 元信息 "↑ 6 vs 昨"
    var percent: Double = 0      // 进度 0-100，empty 状态忽略
    let state: DialState
    var onPress: (() -> Void)?

    private let ringRadius: CGFloat = 32

    private var ringColor: Color {
        switch state {
        case .good: return Theme.accent
        case .warn: return Theme.gold
        case .empty: return Theme.text4
        }
    }

    private var bgColor: Color {
        switch state {
        case .good: return Theme.bgCard
        case .warn: return Theme.gold.opacity(0.04)
        case .empty: return Color.white.opacity(0.012)
        }
    }

    private var borderColor: Color {
        switch state {
        case .good: return Theme.hairline
        case .warn: return Theme.gold.opacity(0.22)
        case .empty: return Theme.hairlineBright
        }
    }

    private var valueColor: Color {
        state == .empty ? Theme.text4 : Theme.text1
    }

    private var metaColor: Color {
        switch state {
        case .good: return Theme.accent
        case .warn: return Theme.gold
        case .empty: return Theme.text3
        }
    }

    /// 把 percent (Double 0-100) 转成 CGFloat (0-1)，用于 .trim
    private var trimEnd: CGFloat {
        CGFloat(max(0.0, min(1.0, percent / 100)))
    }

    var body: some View {
        Button {
            onPress?()
        } label: {
            VStack(spacing: 0) {
                // 角标
                HStack {
                    Text(cornerMark)
                        .font(PaceFont.mono(size: 6.5, weight: .regular))
                        .foregroundColor(Theme.text4)
                        .kerning(1.3)
                    Spacer()
                }
                .padding(.top, 7)
                .padding(.horizontal, 6)

                // 环形 + 中央数字
                ZStack {
                    // 背景圈
                    Circle()
                        .stroke(
                            state == .empty
                                ? Theme.text4.opacity(0.6)
                                : ringColor.opacity(0.08),
                            style: state == .empty
                                ? StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [3, 4])
                                : StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: ringRadius * 2, height: ringRadius * 2)

                    // 进度圈
                    if state != .empty {
                        Circle()
                            .trim(from: 0, to: trimEnd)
                            .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: ringRadius * 2, height: ringRadius * 2)
                            .rotationEffect(.degrees(-90))
                    }

                    // 中央数字
                    VStack(spacing: 2) {
                        Text(value)
                            .font(PaceFont.mono(size: 22, weight: .semibold))
                            .foregroundColor(valueColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(unit)
                            .font(PaceFont.mono(size: 7, weight: .regular))
                            .foregroundColor(Theme.text3)
                            .kerning(0.5)
                    }
                }
                .frame(height: 76)
                .padding(.top, 4)

                // 主标签 — 12pt + .medium 给中文重量补偿苹方比 Noto Sans SC 更细
                Text(label)
                    .font(PaceFont.cn(size: 12, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(2)
                    .padding(.top, 6)

                // 元信息
                Text(meta)
                    .font(PaceFont.mono(size: 10))
                    .foregroundColor(metaColor)
                    .kerning(0.4)
                    .padding(.top, 4)
                    .padding(.bottom, 11)
            }
            .frame(maxWidth: .infinity)
            .background(bgColor)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(
                        borderColor,
                        style: state == .empty
                            ? StrokeStyle(lineWidth: 0.5, dash: [3, 3])
                            : StrokeStyle(lineWidth: 0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct DialCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 7) {
            DialCard(
                cornerMark: "01",
                value: "82",
                unit: "/100",
                label: "状态",
                meta: "↑ 6 vs 昨",
                percent: 82,
                state: .good
            )
            DialCard(
                cornerMark: "02",
                value: "14.2",
                unit: "/21",
                label: "负荷",
                meta: "7 日 · 偏高",
                percent: 67,
                state: .warn
            )
            DialCard(
                cornerMark: "03",
                value: "—",
                unit: "—",
                label: "睡眠",
                meta: "需 Apple Watch",
                state: .empty
            )
        }
        .padding()
        .background(Theme.bgApp)
        .previewLayout(.sizeThatFits)
    }
}
#endif
