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

            // v0.4.0.7: 三段呼吸 ❌ 不适用于"连贯数据流" section
            //
            // PostRun 的 map→stats→chart 是同一个数据故事 (路线 → 总结数字 →
            // 趋势分析), 中间塞 Spacer 会硬切成无关三块, 视觉断裂.
            // (PreRun 的 countdown ↔ checklist 才是语义独立的, 才适合三段呼吸)
            //
            // 正确做法: 数据流紧凑堆叠, 单一底部 Spacer 吃 void
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    brandStrip
                    Spacer().frame(height: 12)
                    aiInsightCard
                    Spacer().frame(height: 14)
                    mapCard
                    Spacer().frame(height: 10)
                    statsRow
                    Spacer().frame(height: 14)
                    paceChart
                }                    // 9 个子 ≤ 10, ViewBuilder 安全

                Spacer()              // 单一底部弹性 — 吃所有 void

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

    // MARK: - 路线图卡片 (v0.4.0.7: 100 → 140, 让 map 真有"卡片"分量)
    private var mapCard: some View {
        ZStack(alignment: .topLeading) {
            // 深色底
            Color(hex: 0x050708)

            // 网格 + 路线 SVG 翻译
            RouteMapView()
                .frame(height: 140)

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
            .padding(10)
        }
        .frame(height: 140)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.hairlineBright, lineWidth: 1)
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

            // v0.4.0.7: 100 → 130 进一步放大, 减少底部 void
            PaceChartView(splitsY: PaceChartConstants.splitsY, endPulse: endPulse)
                .frame(height: 130)
        }
    }

    // MARK: - 底部双 CTA (v0.4.0.7: 高度 48 → 56)
    private var actionRow: some View {
        HStack(spacing: 10) {
            // 分享 — primary 实心绿
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // v0.4.x: 切到 Phone 05 分享卡
            }) {
                Text("分享")
                    .font(PaceFont.cn(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x001A14))
                    .kerning(2.6)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.accent)
                    .shadow(color: Theme.accent.opacity(0.42), radius: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .buttonStyle(PlainButtonStyle())

            // + 备注 — secondary
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("+ 备注")
                    .font(PaceFont.cn(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(2.0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.bgElev)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Theme.hairlineBright, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
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
// 起点 (30, 65), 终点 (254, 60), 4s linear comet 沿路径循环
//
private struct RouteMapView: View {
    @State private var cometT: Double = 0

    var body: some View {
        ZStack {
            // 暗格背景 (HTML <pattern> 20×20 mapGrid 翻译)
            DenseGridShape()
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)

            // 4 条主十字网格 (HTML 2 横 + 2 竖, 比 dense grid 略亮)
            MajorGridShape()
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))

            // 路线底层 — 模糊宽线
            RouteShape()
                .stroke(Theme.accent.opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // 路线顶层 — 渐变细线
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

            // 起点
            RouteEndpoint(at: CGPoint(x: 30, y: 65), kind: .start)

            // 终点
            RouteEndpoint(at: CGPoint(x: 254, y: 60), kind: .end)

            // 彗星粒子 — 沿 bezier 4s linear 循环
            // (按 HTML 4 颗粒, 用 Animatable Shape 让 path() 每帧重算位置)
            RouteCometShape(t: cometT, radius: 5)
                .fill(Theme.accentBright.opacity(0.40))
                .blur(radius: 3)
            RouteCometShape(t: cometT, radius: 2)
                .fill(Theme.accentBright)

            // 尾粒子 (相位偏移 -0.05 / -0.10, HTML 4s 周期里的 -0.2s / -0.4s)
            // 显式 0.0 (而非 0) 避免 Swift 5.4 max(Int, Double) 推断歧义
            RouteCometShape(t: max(0.0, cometT - 0.05), radius: 1.4)
                .fill(Theme.accent.opacity(0.5))
            RouteCometShape(t: max(0.0, cometT - 0.10), radius: 1.0)
                .fill(Color(hex: 0x008866).opacity(0.4))
        }
        .onAppear {
            // 4s linear 循环 (HTML <animateMotion dur="4s" repeatCount="indefinite">)
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                cometT = 1
            }
        }
    }
}

// MARK: - 暗格背景 (HTML <pattern id="mapGrid">)
// 20×20 viewBox 单位的网格, 在 280×86 viewBox 上是 14 列 × 4.3 行
//
// v0.4.0.6: 全程 CGFloat — 之前 var x: Double 跟 scaleX (推断 CGFloat)
// 相乘炸"Double × CGFloat", 这次循环变量也改 CGFloat
//
private struct DenseGridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 86
        let step: CGFloat = 20

        var x: CGFloat = 0
        while x <= 280 {
            p.move(to: CGPoint(x: x * scaleX, y: 0))
            p.addLine(to: CGPoint(x: x * scaleX, y: rect.height))
            x += step
        }

        var y: CGFloat = 0
        while y <= 86 {
            p.move(to: CGPoint(x: 0, y: y * scaleY))
            p.addLine(to: CGPoint(x: rect.width, y: y * scaleY))
            y += step
        }
        return p
    }
}

// MARK: - 主十字网格 (突出于密格之上的虚线)
private struct MajorGridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 86

        // 2 条横 (y=30, 60) — 循环变量 CGFloat
        for y: CGFloat in [30, 60] {
            p.move(to: CGPoint(x: 0, y: y * scaleY))
            p.addLine(to: CGPoint(x: rect.width, y: y * scaleY))
        }
        // 2 条竖 (x=80, 200)
        for x: CGFloat in [80, 200] {
            p.move(to: CGPoint(x: x * scaleX, y: 0))
            p.addLine(to: CGPoint(x: x * scaleX, y: rect.height))
        }
        return p
    }
}

// MARK: - 彗星粒子 (Animatable Shape)
//
// 实现策略 (v0.4.0.5 改写):
//   原方案在 path() 里实时算 cubic bezier, Swift 5.4 严格类型在
//   CGFloat × Double 混算上反复炸 (8 个错改了 2 次还在). 改成
//   预计算 lookup table - 240 个点的 (Double, Double) 数组在
//   static 函数里全 Double 算一次性算完, path() 只做查表 + 缩放.
//   这样 path() 里完全不混 CGFloat/Double, 编译器没机会发飙.
//
// 240 点 = 60fps × 4s 一帧一个, 视觉完全平滑.
//
private struct RouteCometShape: Shape {
    var t: Double
    var radius: CGFloat

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    /// 预计算 240 个点 (viewBox 280×86 坐标), static 一次性算完
    private static let lookup: [(Double, Double)] = computeLookup()

    private static func computeLookup() -> [(Double, Double)] {
        // 4 段 bezier (P0, P1, P2, P3), 全 Double, viewBox 280×86 坐标
        let segs: [((Double, Double), (Double, Double), (Double, Double), (Double, Double))] = [
            ((30, 65),  (50, 67),  (70, 46),  (90, 44)),
            ((90, 44),  (110, 42), (130, 56), (150, 46)),
            ((150, 46), (170, 36), (200, 26), (230, 30)),
            ((230, 30), (260, 34), (258, 46), (254, 60)),
        ]
        let count = 240
        var points: [(Double, Double)] = []
        points.reserveCapacity(count)
        for i in 0..<count {
            let g = Double(i) / Double(count - 1)            // 0...1
            let segIdx = min(3, Int(g * 4))
            let local = (g * 4) - Double(segIdx)
            let s = segs[segIdx]
            // cubic bezier 全 Double 算 (没有 CGPoint, 不用担心类型)
            // 拆子表达式避免 Swift 5.4 类型检查器在长 polynomial 上超时
            let mt: Double = 1 - local
            let mt2: Double = mt * mt
            let mt3: Double = mt2 * mt
            let l2: Double = local * local
            let l3: Double = l2 * local
            let three: Double = 3
            // x
            let xa: Double = mt3 * s.0.0
            let xb: Double = three * mt2 * local * s.1.0
            let xc: Double = three * mt * l2 * s.2.0
            let xd: Double = l3 * s.3.0
            // y
            let ya: Double = mt3 * s.0.1
            let yb: Double = three * mt2 * local * s.1.1
            let yc: Double = three * mt * l2 * s.2.1
            let yd: Double = l3 * s.3.1
            points.append((xa + xb + xc + xd, ya + yb + yc + yd))
        }
        return points
    }

    func path(in rect: CGRect) -> Path {
        // path() 里只做查表 + CGFloat 缩放, 不做 bezier 数学
        let clamped: Double = max(0.0, min(1.0, t))
        let lastIdx: Int = Self.lookup.count - 1
        let idx: Int = min(lastIdx, Int(clamped * Double(lastIdx)))
        let raw = Self.lookup[idx]
        // (Double, Double) → CGPoint 只在这一处转换, 集中统一
        // 显式 CGFloat 类型避免 Swift 5.4 推断歧义
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 86
        let cx: CGFloat = CGFloat(raw.0) * scaleX
        let cy: CGFloat = CGFloat(raw.1) * scaleY
        let r: CGFloat = radius
        let d: CGFloat = r * 2
        return Path(ellipseIn: CGRect(
            x: cx - r,
            y: cy - r,
            width: d,
            height: d
        ))
    }
}

// 路线 Shape
//
// v0.4.0.6: 删 closure pt = {...}, 用 helper func 显式 CGFloat 类型,
// 避免 Swift 5.4 在闭包捕获 + 类型推断的双重歧义炸
//
private struct RouteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 86

        // helper: viewBox(x,y) → 实际 rect 中的 CGPoint
        // 显式参数 + 返回 CGFloat, 不依赖闭包类型推断
        func vp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        p.move(to: vp(30, 65))
        p.addCurve(to: vp(90, 44),  control1: vp(50, 67),  control2: vp(70, 46))
        p.addCurve(to: vp(150, 46), control1: vp(110, 42), control2: vp(130, 56))
        p.addCurve(to: vp(230, 30), control1: vp(170, 36), control2: vp(200, 26))
        p.addCurve(to: vp(254, 60), control1: vp(260, 34), control2: vp(258, 46))
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
            // 显式 CGFloat 类型避免 Swift 5.4 推断歧义
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 86
            let pt: CGPoint = CGPoint(x: at.x * scaleX, y: at.y * scaleY)

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
            // 显式 CGFloat 类型避免 Swift 5.4 推断歧义
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 64
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
