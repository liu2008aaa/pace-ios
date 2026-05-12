//
//  AchievementsView.swift
//  Pace.
//
//  Phone 08 · 里程碑 / 成就 (Milestones)
//
//  对照 pace-demo/index.html#L3222-L3354
//
//  布局策略 (§4.4 准则): 数据流紧凑 + 单一底部 Spacer.
//  Hero (最新解锁 gold tinted) + 距离 grid (2×2) + 速度 grid (2×1) + streak banner.
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        brandStrip
                        Spacer().frame(height: 16)
                        latestUnlockHero
                        Spacer().frame(height: 18)
                        distanceSection
                        Spacer().frame(height: 16)
                        speedSection
                        Spacer().frame(height: 18)
                        streakBanner
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    // MARK: - 顶部条 (← 返回 + 里程碑 + MILESTONES · 12/24)
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

            Text("里程碑")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(2.8)

            Spacer()

            Text("MILESTONES · \(MockData.Milestones.unlockedCount) / \(MockData.Milestones.totalCount)")
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.0)
        }
        .padding(.top, 10)
    }

    // MARK: - 最新解锁 hero (gold tinted card + 钻石装饰)
    private var latestUnlockHero: some View {
        ZStack(alignment: .topLeading) {
            // 右上角装饰钻石 (低 opacity)
            VStack {
                HStack {
                    Spacer()
                    DiamondMark()
                        .stroke(Theme.gold, lineWidth: 0.5)
                        .frame(width: 80, height: 80)
                        .opacity(0.18)
                        .offset(x: 10, y: -10)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("最新解锁")
                    .font(PaceFont.cn(size: 10, weight: .medium))
                    .foregroundColor(Theme.gold)
                    .kerning(3.6)

                Text("◆ \(MockData.Milestones.latestUnlockTitle)")
                    .font(PaceFont.cn(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(0.6)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(MockData.Milestones.latestUnlockValue)
                        .font(PaceFont.mono(size: 26, weight: .bold))
                        .foregroundColor(Theme.gold)
                        .kerning(-0.6)
                    Text(MockData.Milestones.latestUnlockMeta)
                        .font(PaceFont.mono(size: 11, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(0.5)
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.gold.opacity(0.14),
                    Theme.gold.opacity(0.03),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.gold.opacity(0.50), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 距离 grid (2×2)
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("距离 · DISTANCE")
                .font(PaceFont.mono(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(3.0)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    achievementCard(MockData.Milestones.distanceAchievements[0])
                    achievementCard(MockData.Milestones.distanceAchievements[1])
                }
                HStack(spacing: 8) {
                    achievementCard(MockData.Milestones.distanceAchievements[2])
                    achievementCard(MockData.Milestones.distanceAchievements[3])
                }
            }
        }
    }

    // MARK: - 速度 grid (2×1)
    private var speedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("速度 · SPEED")
                .font(PaceFont.mono(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(3.0)

            HStack(spacing: 8) {
                achievementCard(MockData.Milestones.speedAchievements[0])
                achievementCard(MockData.Milestones.speedAchievements[1])
            }
        }
    }

    // MARK: - streak banner (连续打卡 12 天)
    private var streakBanner: some View {
        HStack {
            HStack(spacing: 8) {
                Text("●")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.accent)
                Text("连续打卡")
                    .font(PaceFont.cn(size: 12, weight: .medium))
                    .foregroundColor(Theme.text1)
                    .kerning(0.6)
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(MockData.Milestones.streakDays)")
                    .font(PaceFont.mono(size: 20, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text("天")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accent.opacity(0.32), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 单个成就卡
    @ViewBuilder
    private func achievementCard(
        _ item: (name: String, value: String, unit: String, meta: String, state: MockData.Milestones.AchState, symbol: String)
    ) -> some View {
        AchievementCard(item: item)
    }
}

// MARK: - 成就卡组件 (内部决定颜色/状态)
private struct AchievementCard: View {
    let item: (name: String, value: String, unit: String, meta: String, state: MockData.Milestones.AchState, symbol: String)

    private var iconColor: Color {
        switch item.state {
        case .unlocked: return Theme.accent
        case .gold:     return Theme.gold
        case .locked:   return Theme.text3
        }
    }
    private var valueColor: Color {
        switch item.state {
        case .unlocked: return Theme.accent
        case .gold:     return Theme.gold
        case .locked:   return Theme.text3
        }
    }
    private var borderColor: Color {
        switch item.state {
        case .unlocked: return Theme.accent.opacity(0.42)
        case .gold:     return Theme.gold.opacity(0.50)
        case .locked:   return Theme.hairlineBright
        }
    }
    private var bgGradient: LinearGradient {
        let colors: [Color]
        switch item.state {
        case .unlocked:
            colors = [Theme.accent.opacity(0.08), Theme.accent.opacity(0.02)]
        case .gold:
            colors = [Theme.gold.opacity(0.10), Theme.gold.opacity(0.02)]
        case .locked:
            colors = [Theme.bgCard, Theme.bgCard]
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: item.symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(iconColor)

            Text(item.name)
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text1)
                .kerning(0.4)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(item.value)
                    .font(PaceFont.mono(size: 14, weight: .bold))
                    .foregroundColor(valueColor)
                    .kerning(-0.3)
                if !item.unit.isEmpty {
                    Text(item.unit)
                        .font(PaceFont.mono(size: 10, weight: .regular))
                        .foregroundColor(Theme.text3)
                }
            }

            Text(item.meta)
                .font(PaceFont.mono(size: 8.5, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(1.4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(bgGradient)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(item.state == .locked ? 0.55 : 1)
    }
}

// MARK: - 装饰钻石 (用 Path 翻译 HTML SVG 双层菱形)
private struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 80
        let scaleY: CGFloat = rect.height / 80
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        // 外层菱形: 40,8 → 56,32 → 40,56 → 24,32 → 闭
        p.move(to: pt(40, 8))
        p.addLine(to: pt(56, 32))
        p.addLine(to: pt(40, 56))
        p.addLine(to: pt(24, 32))
        p.closeSubpath()
        // 内层菱形: 40,16 → 50,32 → 40,48 → 30,32 → 闭
        p.move(to: pt(40, 16))
        p.addLine(to: pt(50, 32))
        p.addLine(to: pt(40, 48))
        p.addLine(to: pt(30, 32))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsView()
            .preferredColorScheme(.dark)
    }
}
#endif
