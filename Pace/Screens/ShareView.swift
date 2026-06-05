//
//  ShareView.swift
//  Pace.
//
//  Phone 05 · 分享卡 (Share Card)
//
//  从 PostRunView "分享"按钮 fullScreenCover 进入. 4 种样式 2×2 缩略图,
//  选中后可保存 / 复制 / 分享 (v0.4.x 接系统 share sheet).
//
//  对照 pace-demo/index.html#L2696-L2905 (PHONE 05)
//
//  v0.4.1 静态视觉版, 4 个 mini 都是缩略预览, 不可逐字像素完美.
//
//  布局: §4.4 准则 — 列表/选择型, 紧凑顶对齐, 不要 Spacer.
//

import SwiftUI

struct ShareView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var engine: RunSessionEngine

    @State private var selectedStyle: MockData.Share.Style = .classic

    private var displayDate: String {
        guard let record = engine.lastRecord else { return MockData.PostRun.date }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: record.startDate)
    }

    private var displayDateCompact: String {
        guard let record = engine.lastRecord else { return "05·07" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MM·dd"
        return f.string(from: record.startDate)
    }

    private var displayDistanceKm: Double {
        engine.lastRecord?.distanceKm ?? MockData.PostRun.distanceKm
    }

    private var displayDuration: String {
        engine.lastRecord?.durationDisplay ?? MockData.PostRun.durationStr
    }

    private var displayPace: String {
        engine.lastRecord?.paceDisplay ?? MockData.PostRun.avgPace
    }

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            // ViewBuilder §1.1: 10 子正好临界, 用 Group 包前 9 个保险
            // (Spacer.frame() 也算一个子, 总数 = 9 in Group + bottom Spacer = 2)
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    topBar
                    Spacer().frame(height: 16)
                    sectionTitle
                    Spacer().frame(height: 14)
                    miniGallery
                    Spacer().frame(height: 14)
                    selectedInfoRow
                    Spacer().frame(height: 12)
                    actionRow
                }
                Spacer()      // 单一底部弹性吃 void
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)   // 12 → 4: 安全区已留出 ~34pt home indicator 空间, 自加 4pt 微调
        }
        .swipeToDismiss()
    }

    // MARK: - 顶部条
    private var topBar: some View {
        HStack {
            Text("分享配图")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(2.8)

            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 4) {
                    Text("关闭")
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text2)
                        .kerning(2.2)
                    Text("✕")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.text2)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)
    }

    // MARK: - 副标题行
    private var sectionTitle: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("选择样式")
                    .font(PaceFont.cn(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text1)
                    .kerning(0.6)
                Text("SELECT STYLE · \(MockData.Share.Style.allCases.count) / 4")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(3.0)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(displayDate) · \(String(format: "%.2f", displayDistanceKm)) km")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text2)
                    .kerning(0.6)
                Text("\(MockData.Share.canvasRatio) · \(MockData.Share.canvasSize)")
                    .font(PaceFont.mono(size: 9, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(1.6)
            }
        }
    }

    // MARK: - 2×2 mini gallery
    private var miniGallery: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MiniClassic(active: selectedStyle == .classic,
                            date: displayDateCompact,
                            distanceKm: displayDistanceKm)
                    .onTapGesture { tap(.classic) }
                MiniMinimal(active: selectedStyle == .minimal,
                            date: displayDate,
                            distanceKm: displayDistanceKm,
                            duration: displayDuration)
                    .onTapGesture { tap(.minimal) }
            }
            HStack(spacing: 8) {
                MiniPoster(active: selectedStyle == .poster)
                    .onTapGesture { tap(.poster) }
                MiniData(active: selectedStyle == .data,
                         distanceKm: displayDistanceKm)
                    .onTapGesture { tap(.data) }
            }
        }
    }

    private func tap(_ style: MockData.Share.Style) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeOut(duration: 0.18)) {
            selectedStyle = style
        }
    }

    // MARK: - 已选信息行
    private var selectedInfoRow: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("已选")
                    .font(PaceFont.cn(size: 12, weight: .medium))
                    .foregroundColor(Theme.text2)
                Text(selectedStyle.cn)
                    .font(PaceFont.cn(size: 15, weight: .bold))
                    .foregroundColor(Theme.accent)
                    .kerning(1.0)
                Text("/ \(selectedStyle.en.capitalized)")
                    .font(PaceFont.mono(size: 10, weight: .medium))
                    .foregroundColor(Theme.text4)
                    .kerning(0.8)
            }

            Spacer()

            // 预览全屏 chip
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                Text("预览全屏")
                    .font(PaceFont.cn(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .kerning(0.6)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 三按钮行 (保存 / 复制 / 分享)
    private var actionRow: some View {
        HStack(spacing: 8) {
            SharePillButton(label: "保存", primary: false) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            SharePillButton(label: "复制", primary: false) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            SharePillButton(label: "分享", primary: true) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // v0.4.x: UIActivityViewController 接 share sheet
            }
        }
    }
}

// MARK: - 共用 pill 按钮 (保存/复制/分享)
private struct SharePillButton: View {
    let label: String
    let primary: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(PaceFont.cn(size: 15, weight: primary ? .bold : .semibold))
                .foregroundColor(primary ? Color(hex: 0x001A14) : Theme.text1)
                .kerning(1.8)
                .frame(maxWidth: .infinity)
                .frame(height: 54)   // 50 → 54 配合 mini 加大
                .background(primary ? Theme.accent : Theme.bgElev)
                .overlay(
                    RoundedRectangle(cornerRadius: 27)
                        .stroke(
                            primary ? Color.clear : Theme.hairlineBright,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: primary ? Theme.accent.opacity(0.42) : Color.clear,
                    radius: 12
                )
                .clipShape(RoundedRectangle(cornerRadius: 27))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mini 共用框架
//
// 每个 mini 是 174pt 高的卡片, 4 种样式继承同一个角标 + active 边框 mechanism.
//
private struct MiniFrame<Content: View>: View {
    let style: MockData.Share.Style
    let active: Bool
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // 角标 cn (top-left)
            Text(style.cn)
                .font(PaceFont.cn(size: 11, weight: active ? .heavy : .medium))
                .foregroundColor(active ? Color(hex: 0x001A14) : .white)
                .kerning(1.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(active ? Theme.accent : Color.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 999))
                .padding(7)

            // 角标 en (top-right)
            HStack {
                Spacer()
                Text(style.en)
                    .font(PaceFont.mono(size: 7.5, weight: .medium))
                    .foregroundColor(active ? Theme.accent.opacity(0.7) : Theme.text4)
                    .kerning(1.6)
                    .padding(.top, 9)
                    .padding(.trailing, 8)
            }
        }
        // v0.4.1.2: 174 → 232 (HTML × 1.33)
        // v0.4.1.4: 232 → 258 (再次按用户反馈加大 — 232 仍留 ~40pt 底部 void)
        //          258 = HTML × 1.48, 单卡 ~31% 屏高, 配合 actionRow 加高
        //          后能填到底部接近 0 留白
        .frame(height: 258)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    active ? Theme.accent : Theme.hairlineBright,
                    lineWidth: active ? 1.5 : 1
                )
        )
        .shadow(color: active ? Theme.accent.opacity(0.30) : .clear, radius: 14)
    }
}

// MARK: - Mini 1: 经典 (左上 PACE. + 大数字 + 曲线 + 4 列数据 + 金句)
private struct MiniClassic: View {
    let active: Bool
    let date: String
    let distanceKm: Double

    var body: some View {
        MiniFrame(style: .classic, active: active) {
            ZStack {
                // 渐变底色 + 顶部 radial 余光
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0x0A1714),
                        Color(hex: 0x050A08),
                        Color(hex: 0x000403),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.12), .clear,
                        ]),
                        center: UnitPoint(x: 0.2, y: 0),
                        startRadius: 0, endRadius: 90
                    )
                )

                VStack(alignment: .leading, spacing: 4) {
                    Spacer().frame(height: 22)  // 让出顶部 tag 位置

                    // 品牌行 + 日期
                    HStack(alignment: .firstTextBaseline) {
                        Text("Pace")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        + Text(".")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        Text(date)
                            .font(PaceFont.mono(size: 8, weight: .medium))
                            .foregroundColor(Theme.text3)
                            .kerning(1.2)
                    }

                    Text(String(format: "%.2f", distanceKm))
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .kerning(-1.2)
                        .padding(.top, 6)

                    // 迷你曲线 SVG (HTML index.html#L2756-L2760)
                    // 改 ZStack: 曲线描边 + 起点空心环 + 终点实心点
                    MiniClassicCurveLayer()
                        .frame(height: 28)
                        .padding(.top, 6)

                    // 4 列小数据
                    HStack {
                        ForEach(MockData.Share.classicStats, id: \.self) { v in
                            Text(v)
                                .font(PaceFont.mono(size: 8, weight: .medium))
                                .foregroundColor(Theme.text2)
                                .kerning(0.3)
                            if v != MockData.Share.classicStats.last { Spacer() }
                        }
                    }
                    .padding(.top, 6)

                    Spacer()

                    Text(MockData.Share.classicQuote)
                        .font(PaceFont.cn(size: 9, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .italic()
                        .kerning(0.4)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Mini 1 内嵌的迷你曲线 (经典样式专属)
// v0.4.1.3: 改成 layer view, 包含曲线 stroke + 起点空心环 + 终点实心点
// 原 MiniClassicCurve (Shape) 没加 .stroke() 默认 fill, 渲染成黑块 → 修复.
private struct MiniClassicCurveLayer: View {
    var body: some View {
        GeometryReader { geo in
            // 显式 CGFloat 类型避免 Swift 5.4 推断歧义
            let scaleX: CGFloat = geo.size.width / 110
            let scaleY: CGFloat = geo.size.height / 20
            // viewBox 起点 (4, 16), 终点 (106, 14)
            let startX: CGFloat = 4 * scaleX
            let startY: CGFloat = 16 * scaleY
            let endX: CGFloat = 106 * scaleX
            let endY: CGFloat = 14 * scaleY

            ZStack {
                // 曲线 stroke (accent, 1.2pt linecap round)
                MiniClassicCurveShape()
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

                // 起点空心环 (r=2 stroke 0.8)
                Circle()
                    .stroke(Theme.accent, lineWidth: 0.8)
                    .frame(width: 3.5, height: 3.5)
                    .position(x: startX, y: startY)

                // 终点实心点 (accentBright)
                Circle()
                    .fill(Theme.accentBright)
                    .frame(width: 3.5, height: 3.5)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 2)
                    .position(x: endX, y: endY)
            }
        }
    }
}

// 曲线 Shape (只画路径, stroke/fill 由调用方决定)
private struct MiniClassicCurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 110
        let scaleY: CGFloat = rect.height / 20
        func vp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        // HTML: M 4 16 C 18 16, 26 4, 40 6 S 64 12, 78 4 S 100 10, 106 14
        p.move(to: vp(4, 16))
        p.addCurve(to: vp(40, 6),  control1: vp(18, 16), control2: vp(26, 4))
        // S 64 12, 78 4: mirror cp1 = 2*(40,6) - (26,4) = (54, 8)
        p.addCurve(to: vp(78, 4),  control1: vp(54, 8),  control2: vp(64, 12))
        // S 100 10, 106 14: mirror cp1 = 2*(78,4) - (64,12) = (92, -4)
        p.addCurve(to: vp(106, 14), control1: vp(92, -4), control2: vp(100, 10))
        return p
    }
}

// MARK: - Mini 2: 极简 (左上 P. + 居中大数字 + 左下日期 + 右下 ✦)
private struct MiniMinimal: View {
    let active: Bool
    let date: String
    let distanceKm: Double
    let duration: String

    var body: some View {
        MiniFrame(style: .minimal, active: active) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0x06080A), Color(hex: 0x000000),
                    ]),
                    startPoint: .top, endPoint: .bottom
                )

                // 左上品牌 P.
                VStack {
                    HStack {
                        (Text("P").font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                         + Text(".").font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.accent))
                        Spacer()
                    }
                    .padding(.top, 24)
                    .padding(.leading, 9)
                    Spacer()
                }

                // 居中大数字 (mini 卡 232 高, 数字也得撑场子)
                VStack(spacing: 8) {
                    Text(String(format: "%.2f", distanceKm))
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .kerning(-1.8)
                    Text("公里")
                        .font(PaceFont.cn(size: 11, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(3.8)
                }

                // 左下日期
                VStack {
                    Spacer()
                    HStack {
                        Text("\(date) · \(duration)")
                            .font(PaceFont.mono(size: 8, weight: .medium))
                            .foregroundColor(Theme.text3)
                            .kerning(1.4)
                        Spacer()
                        Text("✦")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.accent.opacity(0.5))
                    }
                    .padding(.horizontal, 9)
                    .padding(.bottom, 9)
                }
            }
        }
    }
}

// MARK: - Mini 3: 海报 (深底 + 散星 + 路线 + 彗星 + 底部 overlay)
private struct MiniPoster: View {
    let active: Bool
    @State private var cometT: Double = 0

    var body: some View {
        MiniFrame(style: .poster, active: active) {
            ZStack(alignment: .bottomLeading) {
                // 径向深色底
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0x0A3024).opacity(0.85),
                        .black,
                    ]),
                    center: UnitPoint(x: 0.3, y: 0.3),
                    startRadius: 0, endRadius: 130
                )

                // 散星
                MiniPosterStars()
                    .opacity(0.4)

                // 路线 (双层 + 彗星)
                ZStack {
                    MiniRouteShape()
                        .stroke(Theme.accent.opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    MiniRouteShape()
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                    // 起终点
                    MiniRouteDot(at: CGPoint(x: 10, y: 88), filled: false)
                    MiniRouteDot(at: CGPoint(x: 120, y: 70), filled: true)

                    // 彗星 (3.5s linear, 线性插值跨帧率丝滑)
                    MiniCometShape(t: cometT, radius: 4)
                        .fill(Theme.accentBright.opacity(0.4))
                        .blur(radius: 2)
                    MiniCometShape(t: cometT, radius: 1.4)
                        .fill(Theme.accentBright)
                    MiniCometShape(t: max(0.0, cometT - 0.05), radius: 1.0)
                        .fill(Theme.accent.opacity(0.5))
                }

                // 底部 overlay 渐变 + 文字
                VStack(alignment: .leading, spacing: 4) {
                    Text("PACE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                    + Text(".")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accent)

                    Text(MockData.Share.posterTitle)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .kerning(-0.5)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 10)

                    Text(MockData.Share.posterSub)
                        .font(PaceFont.mono(size: 7, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .kerning(1.5)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.85)]),
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                cometT = 1
            }
        }
    }
}

// 海报背景散星 (静态)
private struct MiniPosterStars: View {
    /// 显式 CGFloat 类型避免 Swift 5.4 推断歧义
    private let starPoints: [(CGFloat, CGFloat, CGFloat)] = [
        (20, 40, 0.6), (42, 80, 0.5), (70, 38, 0.5), (100, 92, 0.6),
        (60, 115, 0.5), (22, 92, 0.5), (105, 55, 0.5),
    ]

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 130
            let scaleY: CGFloat = geo.size.height / 174
            ZStack {
                ForEach(0..<starPoints.count, id: \.self) { i in
                    let s = starPoints[i]
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: s.2 * 2, height: s.2 * 2)
                        .position(x: s.0 * scaleX, y: s.1 * scaleY)
                }
            }
        }
    }
}

// 海报里的路线 Shape
private struct MiniRouteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 130
        let scaleY: CGFloat = rect.height / 174
        func vp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }
        // M 10 88 C 30 92, 50 60, 70 64 S 100 78, 120 70
        p.move(to: vp(10, 88))
        p.addCurve(to: vp(70, 64), control1: vp(30, 92), control2: vp(50, 60))
        // S 100 78, 120 70: mirror cp = 2*(70,64) - (50,60) = (90, 68)
        p.addCurve(to: vp(120, 70), control1: vp(90, 68), control2: vp(100, 78))
        return p
    }
}

// 海报里的起终点圆环
private struct MiniRouteDot: View {
    let at: CGPoint  // viewBox 130×174 坐标
    let filled: Bool

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 130
            let scaleY: CGFloat = geo.size.height / 174
            let cx: CGFloat = at.x * scaleX
            let cy: CGFloat = at.y * scaleY

            ZStack {
                if filled {
                    Circle()
                        .fill(Theme.accentBright)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .stroke(Theme.accent, lineWidth: 1)
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 1.6, height: 1.6)
                }
            }
            .position(x: cx, y: cy)
        }
    }
}

// 海报里彗星 Animatable Shape (复用 PostRun 的 lookup + 线性插值法)
private struct MiniCometShape: Shape {
    var t: Double
    var radius: CGFloat

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    /// 60 个点预算 (海报路线只 2 段, 不用 240)
    private static let lookup: [(Double, Double)] = computeLookup()

    private static func computeLookup() -> [(Double, Double)] {
        // 2 段 bezier (viewBox 130×174 坐标)
        // Seg 1: (10,88) → (70,64) cps (30,92)(50,60)
        // Seg 2: (70,64) → (120,70) cps (90,68)(100,78)
        let segs: [((Double, Double), (Double, Double), (Double, Double), (Double, Double))] = [
            ((10, 88), (30, 92), (50, 60), (70, 64)),
            ((70, 64), (90, 68), (100, 78), (120, 70)),
        ]
        let count = 60
        var pts: [(Double, Double)] = []
        pts.reserveCapacity(count)
        for i in 0..<count {
            let g: Double = Double(i) / Double(count - 1)
            let segIdx: Int = min(1, Int(g * 2))
            let local: Double = (g * 2) - Double(segIdx)
            let s = segs[segIdx]
            let mt: Double = 1 - local
            let mt2 = mt * mt
            let mt3 = mt2 * mt
            let l2 = local * local
            let l3 = l2 * local
            let three: Double = 3
            let xa = mt3 * s.0.0
            let xb = three * mt2 * local * s.1.0
            let xc = three * mt * l2 * s.2.0
            let xd = l3 * s.3.0
            let ya = mt3 * s.0.1
            let yb = three * mt2 * local * s.1.1
            let yc = three * mt * l2 * s.2.1
            let yd = l3 * s.3.1
            pts.append((xa + xb + xc + xd, ya + yb + yc + yd))
        }
        return pts
    }

    func path(in rect: CGRect) -> Path {
        let clamped: Double = max(0.0, min(1.0, t))
        let lastIdx: Int = Self.lookup.count - 1
        let exact: Double = clamped * Double(lastIdx)
        let loIdx: Int = max(0, min(lastIdx, Int(exact)))
        let hiIdx: Int = min(lastIdx, loIdx + 1)
        let frac: Double = exact - Double(loIdx)
        let lo = Self.lookup[loIdx]
        let hi = Self.lookup[hiIdx]
        let rawX: Double = lo.0 * (1 - frac) + hi.0 * frac
        let rawY: Double = lo.1 * (1 - frac) + hi.1 * frac
        let scaleX: CGFloat = rect.width / 130
        let scaleY: CGFloat = rect.height / 174
        let cx: CGFloat = CGFloat(rawX) * scaleX
        let cy: CGFloat = CGFloat(rawY) * scaleY
        let r: CGFloat = radius
        return Path(ellipseIn: CGRect(
            x: cx - r, y: cy - r, width: r * 2, height: r * 2
        ))
    }
}

// MARK: - Mini 4: 数据 (顶部 brand+meta + 折线 + 5 行 splits + 底部 HR)
private struct MiniData: View {
    let active: Bool
    let distanceKm: Double

    var body: some View {
        MiniFrame(style: .data, active: active) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: 0x0A0C0A), Color(hex: 0x050706),
                    ]),
                    startPoint: .top, endPoint: .bottom
                )

                VStack(spacing: 0) {
                    Spacer().frame(height: 22)  // 让出顶部 tag

                    // header
                    HStack(alignment: .firstTextBaseline) {
                        (Text("Pace").font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                         + Text(".").font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.accent))
                        Spacer()
                        Text("\(String(format: "%.2f", distanceKm)) KM")
                            .font(PaceFont.mono(size: 8, weight: .semibold))
                            .foregroundColor(Theme.accent)
                            .kerning(0.6)
                    }
                    .padding(.bottom, 4)

                    // 迷你折线图
                    MiniDataCurve()
                        .frame(height: 32)
                        .padding(.bottom, 4)

                    // 5 行 splits
                    VStack(spacing: 0) {
                        ForEach(0..<MockData.Share.dataSplits.count, id: \.self) { i in
                            let s = MockData.Share.dataSplits[i]
                            let highlight = (i == MockData.Share.dataSplits.count - 1)
                            HStack {
                                Text("\(s.0)")
                                    .frame(width: 8, alignment: .leading)
                                Spacer()
                                Text(s.1)
                            }
                            .font(PaceFont.mono(size: 8, weight: highlight ? .bold : .medium))
                            .foregroundColor(highlight ? Theme.accent : .white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(highlight ? Theme.accent.opacity(0.10) : .clear)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(0.04))
                                    .frame(height: 0.5),
                                alignment: .bottom
                            )
                        }
                    }

                    Spacer()

                    // 底部 HR
                    // ⚠️ iOS 14: .kerning() 是 Text-only, 不能挂 HStack
                    // 把 kerning 移到每个 Text 内, .font/.foregroundColor 保留在
                    // HStack 上 (这俩是 View modifier, 会传递给 descendant Text)
                    HStack {
                        Text(MockData.Share.dataFooter.0)
                            .kerning(1.0)
                        Spacer()
                        Text(MockData.Share.dataFooter.1)
                            .kerning(1.0)
                    }
                    .font(PaceFont.mono(size: 7, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .padding(.top, 3)
                    .overlay(
                        Rectangle()
                            .fill(Theme.hairlineBright)
                            .frame(height: 0.5),
                        alignment: .top
                    )
                }
                .padding(.horizontal, 7)
                .padding(.bottom, 7)
            }
        }
    }
}

// 数据样式的迷你折线
private struct MiniDataCurve: View {
    var body: some View {
        GeometryReader { geo in
            // 显式 CGFloat 避免推断歧义
            let scaleX: CGFloat = geo.size.width / 110
            let scaleY: CGFloat = geo.size.height / 28
            let pts: [(CGFloat, CGFloat)] = [(4, 13), (26, 20), (48, 16), (70, 22), (100, 5)]

            ZStack {
                // 横虚线 2 条
                Path { p in
                    for y: CGFloat in [9, 20] {
                        p.move(to: CGPoint(x: 0, y: y * scaleY))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y * scaleY))
                    }
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [1, 3]))

                // 折线
                Path { p in
                    p.move(to: CGPoint(x: pts[0].0 * scaleX, y: pts[0].1 * scaleY))
                    for i in 1..<pts.count {
                        p.addLine(to: CGPoint(x: pts[i].0 * scaleX, y: pts[i].1 * scaleY))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))

                // 4 个普通节点
                ForEach(0..<pts.count - 1, id: \.self) { i in
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 2, height: 2)
                        .position(x: pts[i].0 * scaleX, y: pts[i].1 * scaleY)
                }
                // 末点突出
                Circle()
                    .fill(Theme.accentBright)
                    .frame(width: 3, height: 3)
                    .position(x: pts[4].0 * scaleX, y: pts[4].1 * scaleY)
            }
        }
    }
}

#if DEBUG
struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView()
            .preferredColorScheme(.dark)
            .environmentObject(RunSessionEngine())
    }
}
#endif
