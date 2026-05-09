//
//  StartButton.swift
//  Pace.
//
//  出发按钮 — Phone 01 主 CTA。
//
//  视觉层：
//  1. 实心深绿底 + 顶边高光（光从上来的物理感）
//  2. 内部三圈同心椭圆雷达靶环（极淡虚线）
//  3. 4 个角的取景器装饰
//  4. ▶ 三角图标 + "出发" 中文 + "LET'S GO" 英文副标
//  5. 持续呼吸光晕（外阴影 opacity 在 0.28 ↔ 0.42 间循环）
//  6. 按下缩放到 0.985 + 中等强度触觉反馈
//
//  注：HTML demo 里的 conic-gradient 扫描弧需要 Skia 或 Metal，
//  iOS 14 SwiftUI 还没现成 API（iOS 18+ 才有 ShaderLibrary），所以 v0.1 省略。
//

import SwiftUI

struct StartButton: View {
    var onPress: () -> Void

    @State private var isPressed = false
    @State private var glowPhase = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPress()
        } label: {
            ZStack {
                // 背景：径向 + 线性双层
                RoundedRectangle(cornerRadius: 58)
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.accent.opacity(0.32),
                                Theme.accentDeep.opacity(0.55),
                                Color(hex: 0x002319, opacity: 0.95),
                                Color(hex: 0x00120C),
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )

                // 顶部高光层（光从上来）
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 58)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 58))

                // 内部雷达靶环
                ZStack {
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.06), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .frame(width: 120, height: 64)
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.05), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .frame(width: 184, height: 92)
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.04), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .frame(width: 240, height: 116)
                }

                // 4 个角的取景器
                CornerMarks()
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)

                // 中央内容
                VStack(spacing: 4) {
                    HStack(spacing: 11) {
                        Triangle()
                            .fill(Theme.accentBright)
                            .frame(width: 10, height: 12)
                            .shadow(color: Theme.accent.opacity(0.6), radius: 4)

                        Text("出 发")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.accentBright)
                            .tracking(5.76) // 0.24em
                            .shadow(color: Theme.accent.opacity(0.6), radius: 8)
                    }

                    Text("LET'S GO")
                        .font(PaceFont.mono(size: 8, weight: .semibold))
                        .foregroundColor(Theme.accent.opacity(0.6))
                        .tracking(3.36) // 0.42em
                        .padding(.top, 3)
                }
            }
            .frame(height: 116)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 58)
                    .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
            )
            .shadow(
                color: Theme.accent.opacity(glowPhase ? 0.42 : 0.28),
                radius: glowPhase ? 44 : 32
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            // 启动呼吸光晕
            withAnimation(AppAnimation.glowBreathe) {
                glowPhase = true
            }
        }
    }
}

// MARK: - 子组件

/// 三角箭头 ▶
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 4 个角的取景器装饰
private struct CornerMarks: View {
    let size: CGFloat = 7
    let lineColor = Theme.accent.opacity(0.55)

    var body: some View {
        ZStack {
            // 左上
            VStack {
                HStack {
                    L_TopLeft().stroke(lineColor, lineWidth: 1).frame(width: size, height: size)
                    Spacer()
                    L_TopRight().stroke(lineColor, lineWidth: 1).frame(width: size, height: size)
                }
                Spacer()
                HStack {
                    L_BottomLeft().stroke(lineColor, lineWidth: 1).frame(width: size, height: size)
                    Spacer()
                    L_BottomRight().stroke(lineColor, lineWidth: 1).frame(width: size, height: size)
                }
            }
        }
    }
}

private struct L_TopLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
private struct L_TopRight: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
private struct L_BottomLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
private struct L_BottomRight: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

#if DEBUG
struct StartButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StartButton {
                print("START pressed")
            }
            .padding()
        }
        .background(Theme.bgApp)
        .previewLayout(.sizeThatFits)
    }
}
#endif
