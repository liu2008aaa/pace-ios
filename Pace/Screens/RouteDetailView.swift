//
//  RouteDetailView.swift
//  Pace.
//
//  Phone 16 · 路线详情 (Map Detail)
//
//  对照 pace-demo/index.html#L3514-L3770
//  入口: PostRunView 点路线地图 → 这屏 (drilldown 大地图 + 分段分析)
//

import SwiftUI
import CoreLocation

struct RouteDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var engine: RunSessionEngine

    private var record: RunRecord? { engine.lastRecord }

    private var titleMeta: String {
        guard let record = record else { return MockData.RouteDetail.dateStr }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M·dd"
        return "\(f.string(from: record.startDate)) · \(String(format: "%.2f", record.distanceKm)) KM"
    }

    private var distanceText: String {
        String(format: "%.2f", record?.distanceKm ?? MockData.RouteDetail.distanceKm)
    }

    private var durationText: String {
        record?.durationDisplay ?? MockData.RouteDetail.durationStr
    }

    private var paceText: String {
        record?.paceDisplay ?? MockData.RouteDetail.avgPace
    }

    private var routePoints: [RoutePoint] {
        record?.routePoints ?? []
    }

    private var splitRows: [(label: String, pace: String, tier: Int)] {
        guard let record = record,
              let generated = generatedSplits(for: record),
              !generated.isEmpty else {
            return MockData.RouteDetail.splits
        }
        return generated
    }

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        brandStrip
                        Spacer().frame(height: 10)
                        bigMapCard
                        Spacer().frame(height: 12)
                        statStrip
                        Spacer().frame(height: 18)
                        elevationSection
                        Spacer().frame(height: 14)
                        splitsSection
                    }
                    Spacer().frame(height: 20)
                }
                .padding(.bottom, 6)
            }
        }
        .swipeToDismiss()
    }

    // MARK: - 顶部条
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

            Text("路线详情")
                .font(PaceFont.cn(size: 13, weight: .semibold))
                .foregroundColor(Theme.text1)
                .kerning(2.4)
            Spacer()
            Text(titleMeta)
                .font(PaceFont.mono(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - 大地图卡 (232pt 高)
    private var bigMapCard: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0x040608)

            // 网格
            BigMapGridShape()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)

            if routePoints.count >= 2 {
                RoutePolylineView(points: routePoints)
                    .padding(14)
            } else {
                // 路线 5 段渐变色
                BigRouteShapes()

                // 起终点 + KM markers
                BigRouteMarkers()

                // 彗星粒子
                BigRouteComet()
            }

            // 浮动控件 (scale + compass)
            mapOverlays
        }
        .frame(height: 232)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
    }

    private var mapOverlays: some View {
        VStack {
            HStack {
                // SCALE (top-left)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SCALE")
                        .font(PaceFont.mono(size: 8, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(2.4)
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 28, height: 1)
                        Text("100m")
                            .font(PaceFont.mono(size: 9.5, weight: .medium))
                            .foregroundColor(.white)
                            .kerning(0.5)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(hex: 0x0B0C0F).opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.hairlineBright, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                // COMPASS (top-right)
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x0B0C0F).opacity(0.78))
                    Circle()
                        .stroke(Theme.hairlineBright, lineWidth: 1)
                    VStack(spacing: 1) {
                        CompassArrow()
                            .fill(Theme.accent)
                            .frame(width: 10, height: 12)
                        Text("N")
                            .font(PaceFont.mono(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 34, height: 34)
            }
            .padding(8)
            Spacer()
        }
    }

    // MARK: - 3 列统计 strip
    private var statStrip: some View {
        HStack(spacing: 0) {
            statCell(value: distanceText, unit: "km", label: "距离")
            Rectangle().fill(Theme.hairlineBright).frame(width: 0.5, height: 32)
            statCell(value: durationText, unit: "", label: "时长")
            Rectangle().fill(Theme.hairlineBright).frame(width: 0.5, height: 32)
            statCell(value: paceText, unit: "/km", label: "配速")
        }
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func statCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(PaceFont.mono(size: 17, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(-0.4)
                if !unit.isEmpty {
                    Text(unit)
                        .font(PaceFont.mono(size: 10, weight: .regular))
                        .foregroundColor(Theme.text3)
                }
            }
            Text(label)
                .font(PaceFont.cn(size: 10, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(2.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 高度变化
    private var elevationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("高度变化")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(2.6)
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Text("↑").foregroundColor(Theme.accent)
                        Text(MockData.RouteDetail.elevationUp).foregroundColor(Theme.text2)
                    }
                    Text(MockData.RouteDetail.elevationDown)
                        .foregroundColor(Theme.text3)
                }
                .font(PaceFont.mono(size: 11, weight: .medium))
            }

            ElevationProfile(
                pointsY: MockData.RouteDetail.elevationY,
                peakIdx: MockData.RouteDetail.peakIdx
            )
            .frame(height: 56)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 分段配速
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分段配速 · SPLITS")
                .font(PaceFont.mono(size: 9.5, weight: .semibold))
                .foregroundColor(Theme.text3)
                .kerning(2.6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(0..<splitRows.count, id: \.self) { i in
                        let s = splitRows[i]
                        SplitChip(label: s.label, pace: s.pace, tier: s.tier)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func generatedSplits(for record: RunRecord) -> [(label: String, pace: String, tier: Int)]? {
        let points = record.routePoints
        guard points.count >= 2 else { return nil }

        var splits: [(label: String, seconds: Int)] = []
        var accumulatedMeters: Double = 0
        var nextKm: Double = 1000
        var segmentStartTime = points[0].timestamp

        for i in 1..<points.count {
            let previous = points[i - 1]
            let current = points[i]
            let previousLocation = CLLocation(latitude: previous.lat, longitude: previous.lng)
            let currentLocation = CLLocation(latitude: current.lat, longitude: current.lng)
            let distance = currentLocation.distance(from: previousLocation)
            guard distance > 0 else { continue }

            let before = accumulatedMeters
            let after = accumulatedMeters + distance

            while after >= nextKm {
                let ratio = max(0, min(1, (nextKm - before) / distance))
                let splitTime = previous.timestamp + (current.timestamp - previous.timestamp) * ratio
                let seconds = max(1, Int(round(splitTime - segmentStartTime)))
                splits.append((label: "KM \(splits.count + 1)", seconds: seconds))
                segmentStartTime = splitTime
                nextKm += 1000
            }

            accumulatedMeters = after
        }

        let partialMeters = accumulatedMeters - (nextKm - 1000)
        if partialMeters >= 100,
           let last = points.last {
            let partialSeconds = max(1, last.timestamp - segmentStartTime)
            let seconds = max(1, Int(round((partialSeconds / partialMeters) * 1000)))
            splits.append((label: "KM \(splits.count + 1)", seconds: seconds))
        }

        guard !splits.isEmpty else { return nil }
        let minSeconds = splits.map { $0.seconds }.min() ?? 1
        let maxSeconds = splits.map { $0.seconds }.max() ?? minSeconds
        let span = max(1, maxSeconds - minSeconds)

        return splits.map { split in
            let speedRank = 1.0 - (Double(split.seconds - minSeconds) / Double(span))
            let tier = max(0, min(4, Int(round(speedRank * 4))))
            return (label: split.label, pace: paceDisplay(seconds: split.seconds), tier: tier)
        }
    }

    private func paceDisplay(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)'\(String(format: "%02d", s))\""
    }
}

// MARK: - 单个 split chip (颜色按 tier 0-4 渐变)
private struct SplitChip: View {
    let label: String
    let pace: String
    let tier: Int  // 0 = 最慢, 4 = 最快

    private var color: Color {
        // pace1..pace5 Theme 预设 (慢→快)
        [Theme.pace1, Theme.pace2, Theme.pace3, Theme.pace4, Theme.pace5][min(4, max(0, tier))]
    }
    private var isBest: Bool { tier == 4 }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(PaceFont.mono(size: 8, weight: .medium))
                .foregroundColor(isBest ? Theme.accent : Theme.text3)
                .kerning(1.6)
            Text(pace)
                .font(PaceFont.mono(size: 12, weight: isBest ? .bold : .semibold))
                .foregroundColor(isBest ? Theme.accentBright : Theme.text1)
                .kerning(-0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.20))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(isBest ? 0.65 : 0.45), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: isBest ? Theme.accent.opacity(0.30) : .clear, radius: 8)
    }
}

// MARK: - 地图网格 (40pt 间距)
private struct BigMapGridShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 232
        var x: CGFloat = 0
        while x <= 280 {
            p.move(to: CGPoint(x: x * scaleX, y: 0))
            p.addLine(to: CGPoint(x: x * scaleX, y: rect.height))
            x += 40
        }
        var y: CGFloat = 0
        while y <= 232 {
            p.move(to: CGPoint(x: 0, y: y * scaleY))
            p.addLine(to: CGPoint(x: rect.width, y: y * scaleY))
            y += 40
        }
        return p
    }
}

// MARK: - 5 段路线 (慢→快 渐变色)
//
// ⚠️ iOS 14 ViewBuilder closure 内不能声明 func, 只能 let (雷 7)
// 改成 let vp closure 绑定 (闭包不是 declaration, 是 value)
//
private struct BigRouteShapes: View {
    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 232
            let vp: (CGFloat, CGFloat) -> CGPoint = { x, y in
                CGPoint(x: x * scaleX, y: y * scaleY)
            }

            // 底层 glow
            Path { p in
                p.move(to: vp(45, 215))
                p.addCurve(to: vp(160, 210), control1: vp(80, 217), control2: vp(130, 215))
                p.addCurve(to: vp(235, 140), control1: vp(190, 205), control2: vp(230, 175))
                p.addCurve(to: vp(180, 50),  control1: vp(240, 105), control2: vp(220, 60))
                p.addCurve(to: vp(65, 105),  control1: vp(140, 40), control2: vp(80, 55))
                p.addCurve(to: vp(50, 213),  control1: vp(50, 155), control2: vp(35, 205))
            }
            .stroke(Theme.accent.opacity(0.18), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))

            // 5 段 (慢→快 渐变色 pace1..pace5)
            // Seg 1: 45,215 → 160,210
            Path { p in
                p.move(to: vp(45, 215))
                p.addCurve(to: vp(160, 210), control1: vp(80, 217), control2: vp(130, 215))
            }.stroke(Theme.pace1, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { p in
                p.move(to: vp(160, 210))
                p.addCurve(to: vp(235, 140), control1: vp(200, 205), control2: vp(230, 175))
            }.stroke(Theme.pace2, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { p in
                p.move(to: vp(235, 140))
                p.addCurve(to: vp(180, 50), control1: vp(240, 95), control2: vp(220, 60))
            }.stroke(Theme.pace3, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { p in
                p.move(to: vp(180, 50))
                p.addCurve(to: vp(65, 105), control1: vp(130, 45), control2: vp(80, 55))
            }.stroke(Theme.pace4, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            Path { p in
                p.move(to: vp(65, 105))
                p.addCurve(to: vp(50, 213), control1: vp(50, 155), control2: vp(35, 205))
            }
            .stroke(Theme.pace5, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .shadow(color: Theme.accent.opacity(0.6), radius: 4)
        }
    }
}

// MARK: - 起点 + 终点 + 4 个 KM markers
private struct BigRouteMarkers: View {
    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 280
            let scaleY: CGFloat = geo.size.height / 232

            // 起点 (45, 215)
            ZStack {
                Circle().stroke(Theme.accent, lineWidth: 1.5).frame(width: 12, height: 12)
                Circle().fill(Theme.accent).frame(width: 5, height: 5)
            }
            .position(x: 45 * scaleX, y: 215 * scaleY)

            // 终点 (50, 213)
            ZStack {
                Circle().stroke(Theme.accentBright.opacity(0.45), lineWidth: 0.8).frame(width: 18, height: 18)
                Circle().fill(Theme.accentBright).frame(width: 8, height: 8)
                    .shadow(color: Theme.accentBright.opacity(0.7), radius: 6)
            }
            .position(x: 50 * scaleX, y: 213 * scaleY)

            // KM markers 1-4
            ForEach(0..<4, id: \.self) { i in
                let coords: [(CGFloat, CGFloat)] = [(160, 210), (235, 140), (180, 50), (65, 105)]
                let pos = coords[i]
                ZStack {
                    Circle().fill(Theme.bgCard).frame(width: 15, height: 15)
                    Circle().stroke(Theme.accent, lineWidth: 1.2).frame(width: 15, height: 15)
                    Text("\(i + 1)")
                        .font(PaceFont.mono(size: 8.5, weight: .bold))
                        .foregroundColor(.white)
                }
                .position(x: pos.0 * scaleX, y: pos.1 * scaleY)
            }
        }
    }
}

// MARK: - 路线彗星 (复用 lookup + 插值)
private struct BigRouteComet: View {
    @State private var cometT: Double = 0

    var body: some View {
        ZStack {
            BigCometShape(t: cometT, radius: 6)
                .fill(Theme.accentBright.opacity(0.45))
                .blur(radius: 4)
            BigCometShape(t: cometT, radius: 2.5)
                .fill(Theme.accentBright)
            BigCometShape(t: max(0.0, cometT - 0.04), radius: 1.8)
                .fill(Theme.accent.opacity(0.55))
            BigCometShape(t: max(0.0, cometT - 0.08), radius: 1.4)
                .fill(Color(hex: 0x00B488).opacity(0.4))
            BigCometShape(t: max(0.0, cometT - 0.12), radius: 1.0)
                .fill(Color(hex: 0x008866).opacity(0.3))
        }
        .onAppear {
            withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: false)) {
                cometT = 1
            }
        }
    }
}

// MARK: - 彗星 Animatable Shape (5 段 bezier 沿路线)
private struct BigCometShape: Shape {
    var t: Double
    var radius: CGFloat

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    /// 240 点 lookup table (5 段 bezier)
    private static let lookup: [(Double, Double)] = computeLookup()

    private static func computeLookup() -> [(Double, Double)] {
        // 5 段 bezier (P0, P1, P2, P3)
        let segs: [((Double, Double), (Double, Double), (Double, Double), (Double, Double))] = [
            ((45, 215),  (80, 217),  (130, 215), (160, 210)),
            ((160, 210), (190, 205), (230, 175), (235, 140)),
            ((235, 140), (240, 105), (220, 60),  (180, 50)),
            ((180, 50),  (140, 40),  (80, 55),   (65, 105)),
            ((65, 105),  (50, 155),  (35, 205),  (50, 213)),
        ]
        let count = 240
        var pts: [(Double, Double)] = []
        pts.reserveCapacity(count)
        for i in 0..<count {
            let g: Double = Double(i) / Double(count - 1)
            let segIdx: Int = min(4, Int(g * 5))
            let local: Double = (g * 5) - Double(segIdx)
            let s = segs[segIdx]
            let mt: Double = 1 - local
            let mt2 = mt * mt
            let mt3 = mt2 * mt
            let l2 = local * local
            let l3 = l2 * local
            let three: Double = 3
            let x = mt3 * s.0.0 + three * mt2 * local * s.1.0 + three * mt * l2 * s.2.0 + l3 * s.3.0
            let y = mt3 * s.0.1 + three * mt2 * local * s.1.1 + three * mt * l2 * s.2.1 + l3 * s.3.1
            pts.append((x, y))
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
        let scaleX: CGFloat = rect.width / 280
        let scaleY: CGFloat = rect.height / 232
        let cx: CGFloat = CGFloat(rawX) * scaleX
        let cy: CGFloat = CGFloat(rawY) * scaleY
        let r: CGFloat = radius
        return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }
}

// MARK: - 指南针箭头
private struct CompassArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w, y: rect.minY + h * 0.85))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.65))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.85))
        p.closeSubpath()
        return p
    }
}

// MARK: - 高度变化折线 + peak marker
private struct ElevationProfile: View {
    let pointsY: [Double]
    let peakIdx: Int

    private let pointsX: [Double] = [4, 50, 96, 142, 188, 230, 248]

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 252
            let scaleY: CGFloat = geo.size.height / 44
            let lastIdx: Int = pointsY.count - 1

            ZStack {
                // baseline
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 38 * scaleY))
                    p.addLine(to: CGPoint(x: geo.size.width, y: 38 * scaleY))
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)

                // area fill
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[lastIdx]) * scaleX, y: 44 * scaleY))
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: 44 * scaleY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.text2.opacity(0.22),
                            Theme.text2.opacity(0.0),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // line
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                }
                .stroke(Theme.text2, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))

                // peak marker (gold)
                ZStack {
                    Circle().stroke(Theme.gold.opacity(0.45), lineWidth: 0.7).frame(width: 12, height: 12)
                    Circle().fill(Theme.gold).frame(width: 5, height: 5)
                }
                .position(x: CGFloat(pointsX[peakIdx]) * scaleX, y: CGFloat(pointsY[peakIdx]) * scaleY)

                // PEAK label
                Text("PEAK")
                    .font(PaceFont.mono(size: 8, weight: .bold))
                    .foregroundColor(Theme.gold)
                    .kerning(1.6)
                    .position(x: CGFloat(pointsX[peakIdx]) * scaleX, y: CGFloat(pointsY[peakIdx]) * scaleY - 14)
            }
        }
    }
}

#if DEBUG
struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RouteDetailView()
            .preferredColorScheme(.dark)
            .environmentObject(RunSessionEngine())
    }
}
#endif
