//
//  StartButton.swift
//  Pace.
//
//  出发按钮 — Phone 01 主 CTA。物理质感设计。
//
//  iOS 14 兼容修订版：
//  - LinearGradient/RadialGradient 改用 gradient: Gradient(colors:) 形式
//  - .buttonStyle(PlainButtonStyle()) 替代 .buttonStyle(.plain)
//  - .kerning() 替代 .tracking()
//

import SwiftUI

struct StartButton: View {
    var onPress: () -> Void

    @State private var isPressed = false
    @State private var glowPhase = false
    @State private var scanAngle: Double = 0   // 雷达扫描旋转角度

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPress()
        } label: {
            ZStack {
                // 背景：径向渐变（主层）
                RoundedRectangle(cornerRadius: 58)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.accent.opacity(0.32),
                                Theme.accentDeep.opacity(0.55),
                                Color(hex: 0x002319, opacity: 0.95),
                                Color(hex: 0x00120C),
                            ]),
                            center: .top,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )

                // 雷达扫描圈 — AngularGradient (iOS 14+) 12s 旋转一周
                // 模拟 HTML conic-gradient + spin-slow, 仅末段 ~70° 亮起像扫描光束
                //
                // v0.2.6 性能优化：
                //  - 7s → 12s 慢转 (旧 Mac 模拟器集显跑得动, 真机本来就不卡)
                //  - 去掉 .blendMode(.plusLighter) — offscreen render pass 是
                //    动画里最重的开销，去掉后用提高的 opacity 补偿视觉
                //  - opacity 0.7 → 0.85 (补偿丢失的加色叠加亮度)
                RoundedRectangle(cornerRadius: 58)
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.80),
                                .init(color: Theme.accent.opacity(0.45), location: 0.93),
                                .init(color: Theme.accentBright.opacity(0.75), location: 0.99),
                                .init(color: .clear, location: 1.0),
                            ]),
                            center: .center,
                            angle: .degrees(scanAngle)
                        )
                    )
                    .opacity(0.85)
                    .clipShape(RoundedRectangle(cornerRadius: 58))

                // 顶部高光层（HTML inset 0 1.5px 0 rgba(0,255,200,0.4) 等价）
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0, green: 1.0, blue: 0.78).opacity(0.18),
                            .clear,
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 58)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 58))

                // 内部雷达靶环（静态椭圆虚线 ×3，opacity 略增让它可见）
                ZStack {
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.10), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .frame(width: 120, height: 64)
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.07), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
                        .frame(width: 184, height: 92)
                    Ellipse()
                        .stroke(Theme.accent.opacity(0.05), style: StrokeStyle(lineWidth: 0.5, dash: [2, 5]))
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
                            .shadow(color: Theme.accent.opacity(0.7), radius: 5)

                        // "出 发" — HTML 双层 text-shadow (18px 0.6 + 36px 0.3) 用 .shadow 链式堆叠
                        Text("出 发")
                            .font(.system(size: 26, weight: .heavy))     // 24/.bold → 26/.heavy
                            .foregroundColor(Theme.accentBright)
                            .kerning(6.24)                                // 0.24em × 26
                            .shadow(color: Theme.accent.opacity(0.6), radius: 9)   // 内层 (HTML 18px)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 18)  // 外层 (HTML 36px)
                    }

                    Text("LET'S GO")
                        .font(PaceFont.mono(size: 8, weight: .semibold))
                        .foregroundColor(Theme.accent.opacity(0.6))
                        .kerning(3.36) // 0.42em
                        .padding(.top, 3)
                }
            }
            .frame(height: 116)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 58)
                    .stroke(Theme.accent.opacity(0.42), lineWidth: 1)
            )
            // 多层外光晕：HTML box-shadow 64px 0.32 + 24px 0.18 用链式 .shadow 堆叠
            .shadow(
                color: Theme.accent.opacity(glowPhase ? 0.42 : 0.32),
                radius: glowPhase ? 38 : 32
            )
            .shadow(
                color: Theme.accent.opacity(glowPhase ? 0.24 : 0.18),
                radius: 14
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            // 呼吸光晕
            withAnimation(AppAnimation.glowBreathe) {
                glowPhase = true
            }
            // 雷达扫描 — 12s 一周, linear 永续
            // (iOS 在 app backgrounding 时会自动暂停 Core Animation,
            //  不需要手动接 scenePhase, 系统已处理省电)
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                scanAngle = 360
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
