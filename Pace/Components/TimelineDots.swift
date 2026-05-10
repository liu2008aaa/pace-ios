//
//  TimelineDots.swift
//  Pace.
//
//  Phone 01 底部 14 天活力点：13 个历史点（按强度发光）+ 1 个空心冷绿环（今日）。
//
//  iOS 14 兼容修订版：
//  原 body 里 inline 多重 Double 计算 + CGFloat 转换 + ternary in modifier
//  导致 Swift 5.4 编译器类型推断超时（"unable to type-check this expression
//  in reasonable time"）。修法：把每个 dot 抽成独立子组件 HistoricalDot，
//  让每个表达式简单到编译器秒级解析。
//

import SwiftUI

struct TimelineDots: View {
    /// 历史 13 天的强度值 0-1。
    let intensities: [Double]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<intensities.count, id: \.self) { i in
                HistoricalDot(
                    intensity: intensities[i],
                    relativeAge: Double(intensities.count - i) / Double(intensities.count)
                )
                Spacer(minLength: 0)
            }
            TodayRing()
        }
        .padding(.vertical, 8)
        .overlay(CometStrip())
    }
}

// MARK: - 历史活力点（按强度 + 年龄计算颜色和大小）
private struct HistoricalDot: View {
    let intensity: Double      // 0-1
    let relativeAge: Double    // 1 = 最早 / 0 = 最近

    private var opacity: Double {
        let computed = 0.18 + (1.0 - relativeAge) * 0.8 * intensity
        return min(computed, 0.9)
    }

    private var size: CGFloat {
        CGFloat(4.0 + intensity * 4.0)
    }

    private var glow: Color {
        intensity > 0.7 ? Theme.accent.opacity(0.5) : Color.clear
    }

    var body: some View {
        Circle()
            .fill(Theme.accent.opacity(opacity))
            .frame(width: size, height: size)
            .shadow(color: glow, radius: 4)
    }
}

// MARK: - 今日空心冷绿环
private struct TodayRing: View {
    var body: some View {
        Circle()
            .stroke(Theme.accent, lineWidth: 1.5)
            .frame(width: 11, height: 11)
            .shadow(color: Theme.accent.opacity(0.6), radius: 5)
    }
}

// MARK: - 彗星扫描动画 (5s linear loop, head + halo + 2 trail particles)
//
// 实现思路：单一 @State phase: CGFloat 从 0 → 1 线性循环 5s，
// 头部位于 phase * width，两个尾粒子分别滞后 0.036 / 0.072 周期。
// phase < 0.072 时尾粒子位置为负，自然处于左边缘外不可见——无需条件渲染。
//
private struct CometStrip: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 光晕（halo）
                Circle()
                    .fill(Theme.accent.opacity(0.22))
                    .frame(width: 12, height: 12)
                    .blur(radius: 3)
                    .position(x: phase * geo.size.width, y: geo.size.height / 2)

                // 后尾粒子（最淡，最远）
                Circle()
                    .fill(Theme.accent.opacity(0.3))
                    .frame(width: 2, height: 2)
                    .position(x: (phase - 0.072) * geo.size.width, y: geo.size.height / 2)

                // 中尾粒子
                Circle()
                    .fill(Theme.accent.opacity(0.55))
                    .frame(width: 3, height: 3)
                    .position(x: (phase - 0.036) * geo.size.width, y: geo.size.height / 2)

                // 彗头
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 3.5, height: 3.5)
                    .shadow(color: Theme.accent.opacity(0.9), radius: 3)
                    .position(x: phase * geo.size.width, y: geo.size.height / 2)
            }
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 5).repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#if DEBUG
struct TimelineDots_Previews: PreviewProvider {
    static var previews: some View {
        TimelineDots(intensities: MockData.timeline)
            .padding()
            .background(Theme.bgApp)
            .previewLayout(.sizeThatFits)
    }
}
#endif
