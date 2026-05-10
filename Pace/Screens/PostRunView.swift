//
//  PostRunView.swift
//  Pace.
//
//  Phone 04 · 结束总结 (Post-Run)
//
//  从 RunningView 二次确认结束后切到本屏。展示这次跑步的：
//    - 标题日期 + 时段 (夜跑)
//    - AI 一句话洞察 (可换一句 / 编辑 / 与教练讨论)
//    - 路线图 (route map + 起终点 marker)
//    - 三列主统计 (距离 / 时长 / 平均配速)
//    - 每公里配速折线图
//    - 底部双 CTA (分享 / + 备注)
//
//  按 docs/HTML-to-SwiftUI-Guide.md 上手即用经验值:
//    §3   HTML px × 1.15-1.30 字号系数
//    §2.2 边框 opacity × 1.6 / 背景 tint × 1.5
//    §4.3 三段呼吸布局
//    §5   一次提问一次改动 / 不信 px 算术信用户的眼睛
//
//  v0.4.0: 静态 mock 视觉. 路线图彗星动画延后 v0.4.x
//  对照 pace-demo/index.html#L2515-L2693
//

import SwiftUI

struct PostRunView: View {
    @Environment(\.presentationMode) private var presentationMode

    @State private var endPulse = false  // 路线终点呼吸标记

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            // ⚠️ ViewBuilder 10-child 限制 (§1.1): 上半部 9 个元素用 Group 合并成 1,
            // VStack 直接子 = 3 (Group + Spacer + actionRow), 安全
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    brandStrip
                    Spacer().frame(height: 12)
                    aiInsightCard
                    Spacer().frame(height: 10)
                    mapCard
                    Spacer().frame(height: 10)
                    statsRow
                    Spacer().frame(height: 14)
                    paceChart
                }

                Spacer()      // 主弹性吸收

                actionRow
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                endPulse = true
            }
        }
    }

    // MARK: - 顶部品牌条 (日期 · 总结 + 时段)
    private var brandStrip: some View {
        HStack {
            Text("\(MockData.PostRun.date) · 总结")
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text2)
                .kerning(2.0)

            Spacer()

            Text(MockData.PostRun.timeOfDay)
                .font(PaceFont.cn(size: 12, weight: .semibold))
                .foregroundColor(Theme.accent)
                .kerning(2.0)
        }
        .padding(.top, 8)
    }

    // MARK: - AI 洞察卡 (accent tint, 多行 + toolbar + coach link)
    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text("✦")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)

                aiText
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .lineSpacing(3.5)
            }

            // 工具条 (换一句 / 编辑 / counter)
            HStack(spacing: 14) {
                aiToolButton(icon: "↻", label: "换一句")
                aiToolButton(icon: "✏", label: "编辑")
                Spacer()
                Text(MockData.PostRun.aiCounter)
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(0.4)
            }
            .padding(.top, 4)

            // 与教练继续讨论
            HStack(spacing: 6) {
                Text("→")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accent)
                Text("与教练继续讨论这次跑步")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.accent)
                    .kerning(0.6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.10),  // HTML 0.07 × 1.5
                    Theme.accent.opacity(0.03),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.accent.opacity(0.36), lineWidth: 1)  // HTML 0.22 × 1.6
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // AI 文案带高亮的 Text+Text 拼接
    private var aiText: Text {
        Text(MockData.PostRun.aiBefore)
            .foregroundColor(Theme.text1) +
        Text(MockData.PostRun.aiHighlight)
            .foregroundColor(Theme.accent)
            .fontWeight(.semibold) +
        Text(MockData.PostRun.aiAfter)
            .foregroundColor(Theme.text2)
    }

    private func aiToolButton(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 11))
            Text(label)
                .font(PaceFont.cn(size: 10, weight: .medium))
                .kerning(0.4)
        }
        .foregroundColor(Theme.text2)
    }

    // MARK: - 路线图卡片
    private var mapCard: some View {
        ZStack(alignment: .topLeading) {
            // 深色底
            Color(hex: 0x050708)

            // 网格 + 路线 SVG 翻译
            RouteMapView()
                .frame(height: 100)

            // 顶左 ROUTE · 5.42 KM
            HStack {
                Text("ROUTE · \(String(format: "%.2f", MockData.PostRun.distanceKm)) KM")
                    .font(PaceFont.mono(size: 9, weight: .semibold))
                    .foregroundColor(Theme.text3)
                    .kerning(2.5)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 3)
                    Text(MockData.PostRun.coords)
                        .font(PaceFont.mono(size: 9, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.2)
                }
            }
            .padding(8)
        }
        .frame(height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.hairlineBright, lineWidth: 1)  // 边框可见 (§2.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 三列主统计
    private var statsRow: some View {
        HStack(spacing: 6) {
            StatCard(value: String(format: "%.2f", MockData.PostRun.distanceKm), label: "公里")
            StatCard(value: MockData.PostRun.durationStr, label: "时长")
            StatCard(value: MockData.PostRun.avgPace, label: "平均配速")
        }
    }

    // MARK: - 每公里配速折线图
    private var paceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("每公里配速")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.4)

                Spacer()

                Text(MockData.PostRun.lastKmDelta)
                    .font(PaceFont.mono(size: 10, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(0.6)
            }

            PaceChartView(splitsY: PaceChartConstants.splitsY, endPulse: endPulse)
                .frame(height: 72)
        }
    }

    // MARK: - 底部双 CTA
    private var actionRow: some View {
        HStack(spacing: 10) {
            // 分享 — primary 实心绿
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // v0.4.x: 切到 Phone 05 分享卡
            }) {
                Text("分享")
                    .font(PaceFont.cn(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x001A14))
                    .kerning(2.4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.42), radius: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(PlainButtonStyle())

            // + 备注 — secondary
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("+ 备注")
                    .font(PaceFont.cn(size: 14, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(1.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.bgElev)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.hairlineBright, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - 单个统计卡
private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(PaceFont.mono(size: 22, weight: .bold))   // HTML 18 × 1.22
                .foregroundColor(Theme.text1)
                .kerning(-0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(PaceFont.cn(size: 11, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 路线图 SVG 翻译
//
// HTML (index.html#L2583-L2635): viewBox 280×86, 4 段 cubic bezier
// 起点 (30, 65), 终点 (254, 60)
//
private struct RouteMapView: View {
    var body: some View {
        ZStack {
            // 网格背景
            GeometryReader { geo in
                let scaleX = geo.size.width / 280
                let scaleY = geo.size.height / 86

                // 4 条十字网格线 (HTML 2 横 + 2 竖)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 30 * scaleY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 30 * scaleY))
                    path.move(to: CGPoint(x: 0, y: 60 * scaleY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 60 * scaleY))
                    path.move(to: CGPoint(x: 80 * scaleX, y: 0))
                    path.addLine(to: CGPoint(x: 80 * scaleX, y: geo.size.height))
                    path.move(to: CGPoint(x: 200 * scaleX, y: 0))
                    path.addLine(to: CGPoint(x: 200 * scaleX, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
            }

            // 路线 — 双层: 底层模糊宽线 + 顶层渐变细线
            RouteShape()
                .stroke(Theme.accent.opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            RouteShape()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.6),
                            Theme.accent,
                            Theme.accentBright.opacity(0.95),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )

            // 起点 (绿色环 + 点)
            RouteEndpoint(at: CGPoint(x: 30, y: 65), kind: .start)

            // 终点 (亮绿点 + 外圈)
            RouteEndpoint(at: CGPoint(x: 254, y: 60), kind: .end)
        }
    }
}

// 路线 Shape
private struct RouteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX = rect.width / 280
        let scaleY = rect.height / 86
        let pt = { (x: Double, y: Double) -> CGPoint in
            CGPoint(x: rect.minX + CGFloat(x) * scaleX, y: rect.minY + CGFloat(y) * scaleY)
        }
        p.move(to: pt(30, 65))
        // M 30,65 C 50,67 70,46 90,44
        p.addCurve(to: pt(90, 44), control1: pt(50, 67), control2: pt(70, 46))
        // S 130,56 150,46 (smooth — cp1 mirror = 2*end - prev_cp2 = 2*(90,44) - (70,46) = (110,42))
        p.addCurve(to: pt(150, 46), control1: pt(110, 42), control2: pt(130, 56))
        // S 200,26 230,30 (mirror cp = 2*(150,46) - (130,56) = (170,36))
        p.addCurve(to: pt(230, 30), control1: pt(170, 36), control2: pt(200, 26))
        // S 258,46 254,60 (mirror cp = 2*(230,30) - (200,26) = (260,34))
        p.addCurve(to: pt(254, 60), control1: pt(260, 34), control2: pt(258, 46))
        return p
    }
}

// 路线起/终点标记
private struct RouteEndpoint: View {
    enum Kind { case start, end }
    let at: CGPoint  // viewBox 坐标
    let kind: Kind

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / 280
            let scaleY = geo.size.height / 86
            let pt = CGPoint(x: at.x * scaleX, y: at.y * scaleY)

            switch kind {
            case .start:
                ZStack {
                    Circle()
                        .stroke(Theme.accent, lineWidth: 1.5)
                        .frame(width: 11, height: 11)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 4, height: 4)
                }
                .position(pt)

            case .end:
                ZStack {
                    Circle()
                        .stroke(Theme.accentBright.opacity(0.5), lineWidth: 0.5)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Theme.accentBright)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.accentBright.opacity(0.7), radius: 4)
                }
                .position(pt)
            }
        }
    }
}

// MARK: - 配速折线图 - 视觉常量
// CGFloat 类型必须放在 import SwiftUI 的文件里, 不能放 MockData (只有 Foundation)
private enum PaceChartConstants {
    /// 5 km 配速 y 坐标 (HTML viewBox 280×64, y 越小越快)
    /// 第 5 公里最快 (12 = 最高位置)
    static let splitsY: [CGFloat] = [24, 34, 28, 38, 12]
}

// MARK: - 每公里配速折线图
//
// 5 个数据点 (splitsY), 折线连接 + 下方 area fill 渐变 + 节点圆环
// 末公里 (index 4) 用大圆突出
//
private struct PaceChartView: View {
    let splitsY: [CGFloat]   // viewBox y 坐标 (越小越快)
    let endPulse: Bool

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / 280
            let scaleY = geo.size.height / 64
            let xs: [CGFloat] = [14, 80, 146, 212, 266]

            ZStack {
                // 横虚线 (3 条)
                Path { p in
                    for y: CGFloat in [14, 32, 48] {
                        p.move(to: CGPoint(x: 0, y: y * scaleY))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y * scaleY))
                    }
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))

                // 区域填充 (path 闭合到 baseline)
                Path { p in
                    p.move(to: CGPoint(x: xs[0] * scaleX, y: splitsY[0] * scaleY))
                    for i in 1..<5 {
                        p.addLine(to: CGPoint(x: xs[i] * scaleX, y: splitsY[i] * scaleY))
                    }
                    p.addLine(to: CGPoint(x: xs[4] * scaleX, y: 60 * scaleY))
                    p.addLine(to: CGPoint(x: xs[0] * scaleX, y: 60 * scaleY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.45),
                            Theme.accent.opacity(0.0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 折线
                Path { p in
                    p.move(to: CGPoint(x: xs[0] * scaleX, y: splitsY[0] * scaleY))
                    for i in 1..<5 {
                        p.addLine(to: CGPoint(x: xs[i] * scaleX, y: splitsY[i] * scaleY))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                // 4 个普通节点 (空心 dot)
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Theme.bgCard)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 1.4))
                        .position(x: xs[i] * scaleX, y: splitsY[i] * scaleY)
                }

                // 末公里突出 (实心 + 外环呼吸)
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(endPulse ? 0.6 : 0.3), lineWidth: 0.7)
                        .frame(width: endPulse ? 16 : 12, height: endPulse ? 16 : 12)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 4)
                }
                .position(x: xs[4] * scaleX, y: splitsY[4] * scaleY)

                // x 轴标签 1-5
                ForEach(0..<5) { i in
                    Text("\(i + 1)")
                        .font(PaceFont.mono(size: 8, weight: .medium))
                        .foregroundColor(i == 4 ? Theme.accent : Theme.text4)
                        .position(x: xs[i] * scaleX, y: 60 * scaleY)
                }
            }
        }
    }
}

#if DEBUG
struct PostRunView_Previews: PreviewProvider {
    static var previews: some View {
        PostRunView()
            .preferredColorScheme(.dark)
    }
}
#endif
