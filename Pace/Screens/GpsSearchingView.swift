//
//  GpsSearchingView.swift
//  Pace.
//
//  Phone 14 · GPS 搜索中 (GPS Searching)
//
//  对照 pace-demo/index.html#L4371-L4464
//
//  入口: PreRunView 检测 GPS 弱时 → 这屏. v0.5+ 真 CoreLocation 集成后接.
//
//  v0.4.12 静态视觉版.
//

import SwiftUI

struct GpsSearchingView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var bigRotation: Double = 0
    @State private var smallRotation: Double = 0

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // ⚠️ ViewBuilder ≤10 子 (雷 1) — Group 前 6, 余下作 VStack 直接子
                Group {
                    brandStrip
                    Spacer().frame(height: 18)
                    spinnerSection
                    Spacer().frame(height: 22)
                    systemCheckSection
                    Spacer()   // flex push
                }
                actionButtons
                Spacer().frame(height: 10)
                hint
                Spacer().frame(height: 14)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                bigRotation = 360
            }
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                smallRotation = 360
            }
        }
    }

    // MARK: - 顶部条 (准备开跑 · PRE-FLIGHT · WAITING)
    private var brandStrip: some View {
        HStack {
            Text(MockData.GpsSearch.title)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(3.2)
            Spacer()
            Text(MockData.GpsSearch.subtitle)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.gold)
                .kerning(2.0)
        }
    }

    // MARK: - 132×132 大 GPS 转盘
    private var spinnerSection: some View {
        VStack(spacing: 14) {
            Text(MockData.GpsSearch.searchingHeader)
                .font(PaceFont.mono(size: 9, weight: .medium))
                .foregroundColor(Theme.gold)
                .kerning(5.4)

            GpsSpinner(
                rotation: bigRotation,
                satFound: MockData.GpsSearch.satFound,
                satNeeded: MockData.GpsSearch.satNeeded
            )
            .frame(width: 132, height: 132)

            // "已找到 4 颗,需 ≥ 6 颗"
            HStack(spacing: 4) {
                Text("已找到")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(1.0)
                Text("\(MockData.GpsSearch.satFound)")
                    .font(PaceFont.mono(size: 12, weight: .bold))
                    .foregroundColor(Theme.gold)
                Text("颗,需 ≥ \(MockData.GpsSearch.satNeeded) 颗")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(1.0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 系统就绪 checklist 卡
    private var systemCheckSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("系统就绪 · SYSTEM CHECK")
                .font(PaceFont.mono(size: 9, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(4.4)

            VStack(spacing: 6) {
                ForEach(0..<MockData.GpsSearch.checklist.count, id: \.self) { i in
                    let row = MockData.GpsSearch.checklist[i]
                    checklistRow(label: row.label, value: row.value, state: row.state)
                }
            }
        }
    }

    @ViewBuilder
    private func checklistRow(label: String, value: String, state: String) -> some View {
        HStack(spacing: 10) {
            stateIcon(state: state)
            Text(label)
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text1)
                .kerning(0.4)
            Spacer()
            Text(value)
                .font(PaceFont.mono(size: 9.5, weight: .medium))
                .foregroundColor(valueColor(state: state))
                .kerning(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBg(state: state))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder(state: state), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func stateIcon(state: String) -> some View {
        switch state {
        case "wait":
            // 旋转空心 ring (gold, 缺口 ~25%)
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Theme.gold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(smallRotation))
                .shadow(color: Theme.gold.opacity(0.5), radius: 3)
        case "alert":
            // gold ! 实心圆
            ZStack {
                Circle()
                    .fill(Theme.gold)
                    .frame(width: 14, height: 14)
                Text("!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0x2A1F00))
            }
        default:
            // ok: accent ✓ 实心圆
            ZStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 14, height: 14)
                Text("✓")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: 0x001A14))
            }
        }
    }

    private func valueColor(state: String) -> Color {
        switch state {
        case "wait", "alert": return Theme.gold
        default:               return Theme.text2
        }
    }

    private func rowBg(state: String) -> Color {
        switch state {
        case "wait":  return Theme.gold.opacity(0.05)
        case "alert": return Theme.gold.opacity(0.03)
        default:      return Theme.bgCard
        }
    }

    private func rowBorder(state: String) -> Color {
        switch state {
        case "wait":  return Theme.gold.opacity(0.50)
        case "alert": return Theme.gold.opacity(0.32)
        default:      return Theme.hairlineBright
        }
    }

    // MARK: - 双按钮 (移到空旷处 / 继续 精度低)
    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                // v0.5+: 提示用户走出树荫等, 等位置再回来
            }) {
                Text(MockData.GpsSearch.leftBtnLabel)
                    .font(PaceFont.cn(size: 12, weight: .medium))
                    .foregroundColor(Theme.text1)
                    .kerning(0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.bgElev)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Theme.hairlineBright, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                // v0.5+: 绕过 GPS 检查, 强行开跑 (精度低)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(MockData.GpsSearch.rightBtnLabel)
                    .font(PaceFont.cn(size: 12, weight: .semibold))
                    .foregroundColor(Theme.gold)
                    .kerning(0.6)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.gold.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Theme.gold.opacity(0.50), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var hint: some View {
        Text(MockData.GpsSearch.hint)
            .font(PaceFont.cn(size: 9.5, weight: .medium))
            .foregroundColor(Theme.text4)
            .kerning(2.0)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - 132×132 GPS 旋转转盘 + 中心 sat 数字
private struct GpsSpinner: View {
    let rotation: Double
    let satFound: Int
    let satNeeded: Int

    // 显式 CGFloat 避免 Swift 5.4 推断歧义 (雷 3)
    private let arcFraction: CGFloat = 60.0 / 364.0

    var body: some View {
        ZStack {
            // 底环 (浅白)
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 2)
                .frame(width: 116, height: 116)

            // 外圈虚线 (gold 极淡)
            Circle()
                .stroke(Theme.gold.opacity(0.08),
                        style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                .frame(width: 124, height: 124)

            // 旋转 gold arc — 60/364 ≈ 16.5% 弧 (HTML stroke-dasharray="60 304")
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(Theme.gold,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 116, height: 116)
                .rotationEffect(.degrees(rotation))
                .shadow(color: Theme.gold.opacity(0.5), radius: 6)

            // 中心 sat 数字
            VStack(spacing: 3) {
                Text("\(satFound)")
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(-1.2)
                Text("/ \(satNeeded) 颗 SAT")
                    .font(PaceFont.mono(size: 7, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.4)
            }
        }
    }
}

#if DEBUG
struct GpsSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        GpsSearchingView()
            .preferredColorScheme(.dark)
    }
}
#endif
