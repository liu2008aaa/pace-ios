//
//  CoachChatView.swift
//  Pace.
//
//  Phone 09 · AI 教练对话 (Coach Chat)
//
//  对照 pace-demo/index.html#L3789-L3924
//
//  v0.4.5 静态视觉版. 真实版接 LLM API.
//

import SwiftUI

struct CoachChatView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            Theme.bgApp.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                coachHeader
                Divider().background(Theme.hairline)
                chatScroll
                inputPill
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
            }
        }
        .swipeToDismiss()
    }

    // MARK: - 教练 header (头像 + 名字 + 在线状态 + 历史 chip)
    private var coachHeader: some View {
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

            // Avatar 32×32 圆角方
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.accent.opacity(0.22),
                                Theme.accent.opacity(0.05),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.accent.opacity(0.40), lineWidth: 1)
                    .frame(width: 36, height: 36)
                Text("✦")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(MockData.CoachChat.coachName)
                    .font(PaceFont.cn(size: 14, weight: .bold))
                    .foregroundColor(Theme.text1)
                    .kerning(0.4)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                        .shadow(color: Theme.accent.opacity(0.7), radius: 3)
                    Text(MockData.CoachChat.coachStatus)
                        .font(PaceFont.cn(size: 10, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(1.0)
                }
            }

            Spacer()

            // 历史 ›
            HStack(spacing: 3) {
                Text("历史")
                    .font(PaceFont.cn(size: 11, weight: .medium))
                    .foregroundColor(Theme.text3)
                    .kerning(1.8)
                Text("›")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Chat scroll
    private var chatScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 日期分隔
                HStack {
                    Spacer()
                    Text(MockData.CoachChat.dateLine)
                        .font(PaceFont.mono(size: 9.5, weight: .medium))
                        .foregroundColor(Theme.text4)
                        .kerning(2.4)
                    Spacer()
                }

                // 用户气泡
                HStack {
                    Spacer()
                    Text(MockData.CoachChat.userQuestion)
                        .font(PaceFont.cn(size: 13, weight: .medium))
                        .foregroundColor(Theme.text1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Theme.bgElev)
                        .clipShape(BubbleShape(isUser: true))
                        .frame(maxWidth: 280, alignment: .trailing)
                }

                // AI 气泡 + HRV chart
                aiBubble

                // 建议 chips
                HStack(spacing: 8) {
                    ForEach(MockData.CoachChat.suggestionChips, id: \.self) { c in
                        Text(c)
                            .font(PaceFont.cn(size: 12, weight: .medium))
                            .foregroundColor(Theme.text2)
                            .kerning(0.4)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.bgElev)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Theme.hairlineBright, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                    }
                    Spacer()
                }

                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
    }

    // MARK: - AI 气泡 (含嵌入式 HRV chart)
    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text("✦")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.accent)

                aiTextLine1
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .lineSpacing(4)
            }

            // 内嵌 HRV chart 卡
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("HRV · 7 天")
                        .font(PaceFont.cn(size: 10, weight: .medium))
                        .foregroundColor(Theme.text3)
                        .kerning(2.4)
                    Spacer()
                    Text("stable")
                        .font(PaceFont.mono(size: 10, weight: .medium))
                        .foregroundColor(Theme.accent)
                        .kerning(0.4)
                }

                HrvTrendChart(pointsY: MockData.CoachChat.hrvPointsY)
                    .frame(height: 48)

                HStack {
                    Text("平均 ")
                        .font(PaceFont.cn(size: 9, weight: .medium))
                        .foregroundColor(Theme.text3)
                    + Text("\(MockData.CoachChat.hrvAvgMs)ms")
                        .font(PaceFont.mono(size: 9, weight: .medium))
                        .foregroundColor(Theme.text1)
                    Spacer()
                    Text("峰值 ")
                        .font(PaceFont.cn(size: 9, weight: .medium))
                        .foregroundColor(Theme.text3)
                    + Text("\(MockData.CoachChat.hrvPeakMs)ms")
                        .font(PaceFont.mono(size: 9, weight: .medium))
                        .foregroundColor(Theme.text1)
                    Spacer()
                    Text(MockData.CoachChat.hrvTrend)
                        .font(PaceFont.cn(size: 9, weight: .semibold))
                        .foregroundColor(Theme.accent)
                        .kerning(1.0)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // 第二段文字
            HStack(alignment: .top, spacing: 6) {
                Text("→")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
                Text(MockData.CoachChat.aiPart2)
                    .font(PaceFont.cn(size: 13, weight: .medium))
                    .foregroundColor(Theme.text1)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.accent.opacity(0.05))
        .overlay(
            BubbleShape(isUser: false)
                .stroke(Theme.accent.opacity(0.32), lineWidth: 1)
        )
        .clipShape(BubbleShape(isUser: false))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var aiTextLine1: Text {
        Text(MockData.CoachChat.aiPart1Before).foregroundColor(Theme.text1)
        + Text(MockData.CoachChat.aiPart1Mid1).foregroundColor(Theme.accent).fontWeight(.bold)
        + Text(MockData.CoachChat.aiPart1Mid2).foregroundColor(Theme.text1)
        + Text(MockData.CoachChat.aiPart1Mid3).foregroundColor(Theme.accent).fontWeight(.bold)
        + Text(MockData.CoachChat.aiPart1After).foregroundColor(Theme.text1)
        + Text(MockData.CoachChat.aiPart1Finale).foregroundColor(Theme.text1).fontWeight(.bold)
        + Text(MockData.CoachChat.aiPart1Tail).foregroundColor(Theme.text1)
    }

    // MARK: - 输入条
    private var inputPill: some View {
        HStack(spacing: 10) {
            Text("+")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Theme.text3)
            Text(MockData.CoachChat.inputPlaceholder)
                .font(PaceFont.cn(size: 12, weight: .medium))
                .foregroundColor(Theme.text3)
                .kerning(0.4)
            Spacer()
            // send 按钮
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 28, height: 28)
                Circle()
                    .stroke(Theme.accent.opacity(0.50), lineWidth: 1)
                    .frame(width: 28, height: 28)
                Text("↗")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Theme.bgElev)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.hairlineBright, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - 气泡 Shape (user 右下角直 / ai 左下角直)
private struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let big: CGFloat = 16
        let small: CGFloat = 4
        // tl, tr, br, bl 顺序
        let tl: CGFloat = big
        let tr: CGFloat = big
        let br: CGFloat = isUser ? small : big
        let bl: CGFloat = isUser ? big   : small
        return roundedRectPath(in: rect, tl: tl, tr: tr, br: br, bl: bl)
    }

    private func roundedRectPath(in rect: CGRect, tl: CGFloat, tr: CGFloat, br: CGFloat, bl: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                 radius: tr, startAngle: .degrees(-90), endAngle: .zero, clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                 radius: br, startAngle: .zero, endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                 radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        p.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                 radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - HRV mini chart (7 点折线 + area fill + 末点呼吸圈)
private struct HrvTrendChart: View {
    let pointsY: [Double]   // viewBox 220×42

    @State private var endPulse = false
    private let pointsX: [Double] = [6, 40, 75, 110, 145, 180, 214]

    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = geo.size.width / 220
            let scaleY: CGFloat = geo.size.height / 42
            let lastIdx: Int = pointsY.count - 1

            ZStack {
                // baseline
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 22 * scaleY))
                    p.addLine(to: CGPoint(x: geo.size.width, y: 22 * scaleY))
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))

                // 区域 fill
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[lastIdx]) * scaleX, y: 38 * scaleY))
                    p.addLine(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: 38 * scaleY))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accent.opacity(0.30), Theme.accent.opacity(0.0),
                        ]),
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // 折线
                Path { p in
                    p.move(to: CGPoint(x: CGFloat(pointsX[0]) * scaleX, y: CGFloat(pointsY[0]) * scaleY))
                    for i in 1...lastIdx {
                        p.addLine(to: CGPoint(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY))
                    }
                }
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

                // 6 个普通节点
                ForEach(0..<lastIdx, id: \.self) { i in
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 3, height: 3)
                        .position(x: CGFloat(pointsX[i]) * scaleX, y: CGFloat(pointsY[i]) * scaleY)
                }
                // 末点突出
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(endPulse ? 0.45 : 0.25), lineWidth: 0.6)
                        .frame(width: endPulse ? 12 : 10, height: endPulse ? 12 : 10)
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 5, height: 5)
                }
                .position(x: CGFloat(pointsX[lastIdx]) * scaleX, y: CGFloat(pointsY[lastIdx]) * scaleY)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                endPulse = true
            }
        }
    }
}

#if DEBUG
struct CoachChatView_Previews: PreviewProvider {
    static var previews: some View {
        CoachChatView()
            .preferredColorScheme(.dark)
    }
}
#endif
